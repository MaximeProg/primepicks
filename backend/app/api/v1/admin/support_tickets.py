from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc, func
from sqlalchemy.orm import selectinload
from pydantic import BaseModel

from app.core.database import get_db
from app.core.dependencies import require_admin
from app.core.audit import log_action
from app.models.user import User
from app.models.support_ticket import SupportTicket, TicketStatus
from app.models.ticket_message import TicketMessage
from app.schemas.support_ticket import SupportTicketAdminUpdate, SupportTicketResponse
from app.schemas.paginated import Paginated
from app.services.notification_service import send_to_user, NotificationType
from app.services.ws_manager import ticket_ws_manager

router = APIRouter(prefix="/admin/support", tags=["Admin — Support"])


class AdminMessageCreate(BaseModel):
    content: str | None = None
    media_url: str | None = None
    media_type: str | None = None


@router.get("", response_model=Paginated[SupportTicketResponse])
async def list_tickets(
    status: TicketStatus | None = None,
    limit: int = Query(20, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    q = select(SupportTicket)
    cq = select(SupportTicket)
    if status:
        q = q.where(SupportTicket.status == status)
        cq = cq.where(SupportTicket.status == status)

    total_r = await db.execute(select(func.count()).select_from(cq.subquery()))
    total = total_r.scalar() or 0

    r = await db.execute(q.order_by(desc(SupportTicket.created_at)).limit(limit).offset(offset))
    return Paginated(items=r.scalars().all(), total=total, limit=limit, offset=offset)


@router.post("/{ticket_id}/messages", status_code=201)
async def admin_send_message(
    ticket_id: UUID,
    body: AdminMessageCreate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    """L'admin envoie un message dans le fil de conversation du ticket."""
    r = await db.execute(
        select(SupportTicket)
        .where(SupportTicket.id == ticket_id)
        .options(selectinload(SupportTicket.ticket_messages))
    )
    ticket = r.scalar_one_or_none()
    if not ticket:
        raise HTTPException(404, "Ticket introuvable")

    msg = TicketMessage(
        ticket_id=ticket_id,
        sender_type="ADMIN",
        sender_id=admin.id,
        content=body.content,
        media_url=body.media_url,
        media_type=body.media_type,
    )
    db.add(msg)

    # Mettre à jour le statut et le champ admin_reply (rétrocompat)
    ticket.status = TicketStatus.IN_PROGRESS
    ticket.admin_reply = body.content  # gardé pour la rétrocompatibilité

    await db.commit()
    await db.refresh(msg)

    # Diffuser en temps réel vers le Flutter client
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

    # Notification push Firebase
    if ticket.user_id:
        await send_to_user(
            db, user_id=ticket.user_id,
            title="Nouveau message support",
            body=body.content or "L'équipe a envoyé un fichier.",
            notif_type=NotificationType.TICKET_REPLIED,
            data={"ticket_id": str(ticket_id)},
        )

    return {"id": str(msg.id)}


@router.patch("/{ticket_id}", response_model=SupportTicketResponse)
async def update_ticket(
    ticket_id: UUID,
    data: SupportTicketAdminUpdate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    r = await db.execute(select(SupportTicket).where(SupportTicket.id == ticket_id))
    ticket = r.scalar_one_or_none()
    if not ticket:
        raise HTTPException(404, "Ticket introuvable")

    old_status = ticket.status
    changes = data.model_dump(exclude_none=True)

    for field, value in changes.items():
        setattr(ticket, field, value)

    await log_action(db, admin, "UPDATE_TICKET", "support_ticket", ticket_id,
                     old_data={"status": old_status.value},
                     new_data=changes)

    await db.commit()
    await db.refresh(ticket)
    return ticket
