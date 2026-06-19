"""Support tickets — endpoints utilisateur + WebSocket chat en temps réel."""
import uuid
from datetime import datetime

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, WebSocket, WebSocketDisconnect
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from sqlalchemy.orm import selectinload

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.support_ticket import SupportTicket, TicketStatus
from app.models.ticket_message import TicketMessage
from app.models.user import User
from app.services.cloudinary_service import upload_support_media
from app.services.notification_service import send_to_user, NotificationType
from app.services.ws_manager import ticket_ws_manager

router = APIRouter(prefix="/support", tags=["Support"])


# ── Schemas ────────────────────────────────────────────────────────────────────

class TicketCreate(BaseModel):
    subject: str
    message: str


class MessageCreate(BaseModel):
    content: str | None = None
    media_url: str | None = None
    media_type: str | None = None   # IMAGE | VIDEO | FILE


class MessageOut(BaseModel):
    id: uuid.UUID
    ticket_id: uuid.UUID
    sender_type: str
    sender_id: uuid.UUID | None
    content: str | None
    media_url: str | None
    media_type: str | None
    is_read: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class TicketOut(BaseModel):
    id: uuid.UUID
    subject: str
    status: TicketStatus
    created_at: datetime
    updated_at: datetime
    messages: list[MessageOut] = []

    model_config = {"from_attributes": True}


class TicketSummary(BaseModel):
    id: uuid.UUID
    subject: str
    status: TicketStatus
    last_message: str | None
    unread_count: int
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


# ── REST endpoints ─────────────────────────────────────────────────────────────

@router.post("/upload", summary="Upload d'image pour le chat support")
async def upload_support_image(
    file: UploadFile = File(...),
    user: User = Depends(get_current_user),
):
    url = await upload_support_media(file)
    return {"url": url}


@router.get("/tickets", response_model=list[TicketSummary])
async def list_my_tickets(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(SupportTicket)
        .where(SupportTicket.user_id == user.id)
        .options(selectinload(SupportTicket.ticket_messages))
        .order_by(desc(SupportTicket.updated_at))
    )
    tickets = result.scalars().all()
    out = []
    for t in tickets:
        msgs = t.ticket_messages
        last = msgs[-1].content if msgs else t.message
        unread = sum(1 for m in msgs if not m.is_read and m.sender_type == "ADMIN")
        out.append(TicketSummary(
            id=t.id, subject=t.subject, status=t.status,
            last_message=last, unread_count=unread,
            created_at=t.created_at, updated_at=t.updated_at,
        ))
    return out


@router.post("/tickets", response_model=TicketOut, status_code=201)
async def create_ticket(
    body: TicketCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    ticket = SupportTicket(
        user_id=user.id,
        subject=body.subject,
        message=body.message,
        status=TicketStatus.OPEN,
    )
    db.add(ticket)
    await db.flush()

    # Premier message (le message initial de l'utilisateur)
    first_msg = TicketMessage(
        ticket_id=ticket.id,
        sender_type="USER",
        sender_id=user.id,
        content=body.message,
    )
    db.add(first_msg)
    await db.commit()
    await db.refresh(ticket)

    # Recharger avec messages
    result = await db.execute(
        select(SupportTicket)
        .where(SupportTicket.id == ticket.id)
        .options(selectinload(SupportTicket.ticket_messages))
    )
    return result.scalar_one()


@router.get("/tickets/{ticket_id}", response_model=TicketOut)
async def get_ticket(
    ticket_id: uuid.UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(SupportTicket)
        .where(SupportTicket.id == ticket_id, SupportTicket.user_id == user.id)
        .options(selectinload(SupportTicket.ticket_messages))
    )
    ticket = result.scalar_one_or_none()
    if not ticket:
        raise HTTPException(404, "Ticket introuvable")

    # Marquer les messages admin comme lus
    for m in ticket.ticket_messages:
        if m.sender_type == "ADMIN" and not m.is_read:
            m.is_read = True
    await db.commit()
    await db.refresh(ticket)
    return ticket


@router.post("/tickets/{ticket_id}/messages", response_model=MessageOut, status_code=201)
async def send_message(
    ticket_id: uuid.UUID,
    body: MessageCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(SupportTicket).where(
            SupportTicket.id == ticket_id,
            SupportTicket.user_id == user.id,
            SupportTicket.status != TicketStatus.CLOSED,
        )
    )
    ticket = result.scalar_one_or_none()
    if not ticket:
        raise HTTPException(404, "Ticket introuvable ou fermé")

    msg = TicketMessage(
        ticket_id=ticket_id,
        sender_type="USER",
        sender_id=user.id,
        content=body.content,
        media_url=body.media_url,
        media_type=body.media_type,
    )
    db.add(msg)
    ticket.status = TicketStatus.IN_PROGRESS
    await db.commit()
    await db.refresh(msg)

    # Diffuser en temps réel
    await ticket_ws_manager.broadcast(str(ticket_id), {
        "type": "new_message",
        "message": {
            "id": str(msg.id),
            "ticket_id": str(msg.ticket_id),
            "sender_type": msg.sender_type,
            "sender_id": str(msg.sender_id) if msg.sender_id else None,
            "content": msg.content,
            "media_url": msg.media_url,
            "media_type": msg.media_type,
            "is_read": msg.is_read,
            "created_at": msg.created_at.isoformat(),
        },
    })
    return msg


# ── WebSocket ─────────────────────────────────────────────────────────────────

@router.websocket("/tickets/{ticket_id}/ws")
async def ticket_ws(
    ticket_id: str,
    websocket: WebSocket,
    db: AsyncSession = Depends(get_db),
):
    """
    Le client se connecte ici après auth Firebase.
    Il envoie { "token": "<firebase_id_token>" } comme premier message pour s'authentifier.
    """
    await ticket_ws_manager.connect(ticket_id, websocket)
    try:
        while True:
            # On attend juste les pings du client pour garder la connexion vivante
            data = await websocket.receive_text()
            # Optionnel : gérer un ping/pong
            if data == "ping":
                await websocket.send_text("pong")
    except WebSocketDisconnect:
        ticket_ws_manager.disconnect(ticket_id, websocket)
