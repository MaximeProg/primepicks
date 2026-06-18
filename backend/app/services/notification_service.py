import enum
import uuid
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.firebase import send_fcm_multicast
from app.models.fcm_token import FcmToken
from app.models.subscription import Subscription, SubscriptionStatus
from app.models.notification_log import NotificationLog
from app.models.notification_inbox import NotificationInbox
from datetime import datetime, timezone


class NotificationType(str, enum.Enum):
    NEW_COUPON      = "NEW_COUPON"
    COUPON_WON      = "COUPON_WON"
    COUPON_LOST     = "COUPON_LOST"
    COUPON_CANCELLED = "COUPON_CANCELLED"
    SUB_ACTIVATED   = "SUB_ACTIVATED"
    SUB_EXPIRY_D3   = "SUB_EXPIRY_D3"
    SUB_EXPIRY_D1   = "SUB_EXPIRY_D1"
    SUB_EXPIRED     = "SUB_EXPIRED"
    PAYMENT_SUCCESS = "PAYMENT_SUCCESS"
    PROMO           = "PROMO"
    ROLE_CHANGED    = "ROLE_CHANGED"
    PAYOUT_APPROVED = "PAYOUT_APPROVED"
    TICKET_REPLIED  = "TICKET_REPLIED"


def _chunks(lst: list, n: int):
    for i in range(0, len(lst), n):
        yield lst[i : i + n]


async def _get_user_tokens(db: AsyncSession, user_id: UUID) -> list[str]:
    result = await db.execute(
        select(FcmToken.token).where(FcmToken.user_id == user_id)
    )
    return [row[0] for row in result.fetchall()]


async def _get_active_subscriber_ids(db: AsyncSession) -> list[UUID]:
    now = datetime.utcnow()
    result = await db.execute(
        select(Subscription.user_id)
        .where(
            Subscription.status == SubscriptionStatus.ACTIVE,
            Subscription.end_date > now,
            Subscription.user_id.is_not(None),
        )
        .distinct()
    )
    return [row[0] for row in result.fetchall()]


async def _get_tokens_for_users(db: AsyncSession, user_ids: list[UUID]) -> list[str]:
    if not user_ids:
        return []
    result = await db.execute(
        select(FcmToken.token).where(FcmToken.user_id.in_(user_ids)).distinct()
    )
    return [row[0] for row in result.fetchall()]


async def _get_admin_tokens(db: AsyncSession) -> list[str]:
    from app.models.user import User, UserRole
    result = await db.execute(
        select(FcmToken.token)
        .join(User, User.id == FcmToken.user_id)
        .where(User.role.in_([UserRole.SUPER_ADMIN, UserRole.ADMIN]), User.is_active == True)
        .distinct()
    )
    return [row[0] for row in result.fetchall()]


async def _get_admin_user_ids(db: AsyncSession) -> list[UUID]:
    from app.models.user import User, UserRole
    result = await db.execute(
        select(User.id).where(
            User.role.in_([UserRole.SUPER_ADMIN, UserRole.ADMIN]),
            User.is_active == True,
        )
    )
    return [row[0] for row in result.fetchall()]


def _send_fcm_batched(tokens: list[str], title: str, body: str, data: dict) -> dict:
    total_success = 0
    total_failure = 0
    for batch in _chunks(tokens, 500):
        r = send_fcm_multicast(batch, title, body, data)
        total_success += r["success"]
        total_failure += r["failure"]
    return {"success": total_success, "failure": total_failure}


def _inbox_rows(user_ids: list[UUID], title: str, body: str,
                notif_type: NotificationType, data: dict) -> list[NotificationInbox]:
    return [
        NotificationInbox(
            id=uuid.uuid4(),
            user_id=uid,
            title=title,
            body=body,
            type=notif_type.value,
            data=data or None,
        )
        for uid in user_ids
    ]


# ── Public API ────────────────────────────────────────────────────────────────

async def send_to_user(
    db: AsyncSession,
    user_id: UUID,
    title: str,
    body: str,
    notif_type: NotificationType,
    data: dict = {},
) -> None:
    tokens = await _get_user_tokens(db, user_id)
    result = {"success": 0, "failure": 0}
    if tokens:
        result = _send_fcm_batched(tokens, title, body, {"type": notif_type.value, **data})

    # Inbox individuelle
    db.add(NotificationInbox(
        user_id=user_id, title=title, body=body,
        type=notif_type.value, data=data or None,
    ))
    # Log d'envoi
    db.add(NotificationLog(
        user_id=user_id, title=title, body=body, type=notif_type.value,
        data=data, success_count=result["success"], failure_count=result["failure"],
    ))
    await db.flush()


async def send_to_users(
    db: AsyncSession,
    user_ids: list[UUID],
    title: str,
    body: str,
    notif_type: NotificationType,
    data: dict = {},
) -> dict:
    """Envoie à une liste précise d'utilisateurs."""
    tokens = await _get_tokens_for_users(db, user_ids)
    fcm_data = {"type": notif_type.value, **data}
    result = _send_fcm_batched(tokens, title, body, fcm_data) if tokens else {"success": 0, "failure": 0}

    db.add_all(_inbox_rows(user_ids, title, body, notif_type, data))
    db.add(NotificationLog(
        user_id=None, title=title, body=body, type=notif_type.value, data=data,
        success_count=result["success"], failure_count=result["failure"],
    ))
    await db.flush()
    return result


async def broadcast_to_subscribers(
    db: AsyncSession,
    title: str,
    body: str,
    notif_type: NotificationType,
    data: dict = {},
) -> dict:
    user_ids = await _get_active_subscriber_ids(db)
    tokens = await _get_tokens_for_users(db, user_ids)
    fcm_data = {"type": notif_type.value, **data}
    result = _send_fcm_batched(tokens, title, body, fcm_data) if tokens else {"success": 0, "failure": 0}

    db.add_all(_inbox_rows(user_ids, title, body, notif_type, data))
    db.add(NotificationLog(
        user_id=None, title=title, body=body, type=notif_type.value, data=data,
        success_count=result["success"], failure_count=result["failure"],
    ))
    await db.flush()
    return result


async def broadcast_to_admins(
    db: AsyncSession,
    title: str,
    body: str,
    notif_type: NotificationType,
    data: dict = {},
) -> dict:
    user_ids = await _get_admin_user_ids(db)
    tokens = await _get_admin_tokens(db)
    fcm_data = {"type": notif_type.value, **data}
    result = _send_fcm_batched(tokens, title, body, fcm_data) if tokens else {"success": 0, "failure": 0}

    db.add_all(_inbox_rows(user_ids, title, body, notif_type, data))
    db.add(NotificationLog(
        user_id=None, title=title, body=body, type=notif_type.value, data=data,
        success_count=result["success"], failure_count=result["failure"],
    ))
    await db.flush()
    return result


async def broadcast_to_all(
    db: AsyncSession,
    title: str,
    body: str,
    notif_type: NotificationType,
    data: dict = {},
) -> dict:
    """Broadcast à TOUS les utilisateurs actifs."""
    from app.models.user import User
    uid_r = await db.execute(select(User.id).where(User.is_active == True))
    user_ids = [row[0] for row in uid_r.fetchall()]
    tokens = await _get_tokens_for_users(db, user_ids)
    fcm_data = {"type": notif_type.value, **data}
    result = _send_fcm_batched(tokens, title, body, fcm_data) if tokens else {"success": 0, "failure": 0}

    db.add_all(_inbox_rows(user_ids, title, body, notif_type, data))
    db.add(NotificationLog(
        user_id=None, title=title, body=body, type=notif_type.value, data=data,
        success_count=result["success"], failure_count=result["failure"],
    ))
    await db.flush()
    return result
