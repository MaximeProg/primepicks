from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete, update, func
from sqlalchemy.dialects.postgresql import insert as pg_insert

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.fcm_token import FcmToken
from app.models.notification_inbox import NotificationInbox
from datetime import datetime

router = APIRouter(prefix="/notifications", tags=["Notifications"])


# ── FCM token ─────────────────────────────────────────────────────────────────

class FcmTokenRequest(BaseModel):
    token: str
    device_type: str = "WEB"


@router.post("/token", summary="Enregistrer/rafraîchir un token FCM")
async def register_fcm_token(
    data: FcmTokenRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # UPSERT atomique — évite la race condition SELECT+INSERT
    stmt = pg_insert(FcmToken).values(
        user_id=user.id,
        token=data.token,
        device_type=data.device_type,
    ).on_conflict_do_update(
        constraint="uq_fcm_tokens_user_device",
        set_={"token": data.token},
    )
    await db.execute(stmt)
    await db.commit()
    return {"message": "Token enregistré"}


@router.delete("/token", summary="Supprimer le token FCM (logout)")
async def delete_fcm_token(
    device_type: str = "WEB",
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await db.execute(
        delete(FcmToken).where(
            FcmToken.user_id == user.id,
            FcmToken.device_type == device_type,
        )
    )
    await db.commit()
    return {"message": "Token supprimé"}


# ── Inbox ─────────────────────────────────────────────────────────────────────

class InboxItem(BaseModel):
    id: UUID
    title: str
    body: str
    type: str
    data: dict | None
    is_read: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class UnreadCount(BaseModel):
    count: int


@router.get("/inbox", response_model=list[InboxItem])
async def get_inbox(
    limit: int = Query(30, le=100),
    offset: int = Query(0, ge=0),
    unread_only: bool = False,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    q = select(NotificationInbox).where(NotificationInbox.user_id == user.id)
    if unread_only:
        q = q.where(NotificationInbox.is_read == False)
    q = q.order_by(NotificationInbox.created_at.desc()).limit(limit).offset(offset)
    result = await db.execute(q)
    return result.scalars().all()


@router.get("/inbox/unread-count", response_model=UnreadCount)
async def get_unread_count(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(func.count()).select_from(NotificationInbox).where(
            NotificationInbox.user_id == user.id,
            NotificationInbox.is_read == False,
        )
    )
    return UnreadCount(count=result.scalar() or 0)


@router.patch("/inbox/{notif_id}/read", response_model=InboxItem)
async def mark_read(
    notif_id: UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(NotificationInbox).where(
            NotificationInbox.id == notif_id,
            NotificationInbox.user_id == user.id,
        )
    )
    notif = result.scalar_one_or_none()
    if not notif:
        raise HTTPException(404, "Notification introuvable")
    notif.is_read = True
    await db.commit()
    await db.refresh(notif)
    return notif


@router.post("/inbox/read-all")
async def mark_all_read(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await db.execute(
        update(NotificationInbox)
        .where(NotificationInbox.user_id == user.id, NotificationInbox.is_read == False)
        .values(is_read=True)
    )
    await db.commit()
    return {"message": "Toutes les notifications marquées comme lues"}


@router.delete("/inbox/{notif_id}", status_code=204)
async def delete_notification(
    notif_id: UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(NotificationInbox).where(
            NotificationInbox.id == notif_id,
            NotificationInbox.user_id == user.id,
        )
    )
    notif = result.scalar_one_or_none()
    if not notif:
        raise HTTPException(404, "Notification introuvable")
    await db.delete(notif)
    await db.commit()


@router.delete("/inbox", status_code=204)
async def clear_inbox(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await db.execute(
        delete(NotificationInbox).where(NotificationInbox.user_id == user.id)
    )
    await db.commit()
