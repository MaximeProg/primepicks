from uuid import UUID
from typing import Literal
from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc

from app.core.database import get_db
from app.core.dependencies import require_admin
from app.core.audit import log_action
from app.models.user import User
from app.models.notification_log import NotificationLog
from app.services.notification_service import (
    send_to_users, broadcast_to_subscribers, broadcast_to_admins,
    broadcast_to_all, NotificationType,
)

router = APIRouter(prefix="/admin/notifications", tags=["Admin — Notifications"])


class NotificationSendRequest(BaseModel):
    title: str
    body: str
    type: NotificationType = NotificationType.PROMO
    # "subscribers" | "all_users" | "admins" | "custom"
    target: Literal["subscribers", "all_users", "admins", "custom"] = "subscribers"
    user_ids: list[UUID] | None = None   # uniquement si target="custom"
    data: dict = {}


class NotificationLogResponse(BaseModel):
    id: UUID
    user_id: UUID | None
    title: str
    body: str
    type: str
    success_count: int
    failure_count: int

    model_config = {"from_attributes": True}


@router.get("/history", response_model=list[NotificationLogResponse])
async def list_notifications(
    limit: int = Query(50, le=200),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    result = await db.execute(
        select(NotificationLog)
        .order_by(desc(NotificationLog.sent_at))
        .limit(limit)
        .offset(offset)
    )
    return result.scalars().all()


@router.post("/send")
async def send_notification(
    data: NotificationSendRequest,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    fcm_data = data.data

    if data.target == "custom":
        ids = data.user_ids or []
        result = await send_to_users(db, ids, data.title, data.body, data.type, fcm_data)
        await log_action(db, admin, "SEND_NOTIFICATION_CUSTOM", None, None,
                         new_data={"title": data.title, "user_count": len(ids), "type": data.type.value})
        await db.commit()
        return {"message": f"Envoyé à {len(ids)} utilisateur(s)", **result}

    if data.target == "admins":
        result = await broadcast_to_admins(db, data.title, data.body, data.type, fcm_data)
        label = "admins"
    elif data.target == "all_users":
        result = await broadcast_to_all(db, data.title, data.body, data.type, fcm_data)
        label = "tous les utilisateurs"
    else:
        result = await broadcast_to_subscribers(db, data.title, data.body, data.type, fcm_data)
        label = "abonnés actifs"

    await log_action(db, admin, "SEND_NOTIFICATION_BROADCAST", None, None,
                     new_data={"title": data.title, "target": data.target, "type": data.type.value, **result})
    await db.commit()
    return {"message": f"Broadcast envoyé aux {label}", **result}
