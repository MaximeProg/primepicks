from uuid import UUID
from datetime import datetime, timedelta, timezone
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, update
from sqlalchemy.orm import selectinload

from app.models.subscription import Subscription, SubscriptionStatus
from app.models.plan import Plan
from app.models.transaction import Transaction
from app.models.user import User


async def get_active_subscription(db: AsyncSession, user_id: UUID) -> Subscription | None:
    now = datetime.utcnow()
    result = await db.execute(
        select(Subscription)
        .where(
            and_(
                Subscription.user_id == user_id,
                Subscription.status == SubscriptionStatus.ACTIVE,
                Subscription.end_date > now,
            )
        )
        .options(selectinload(Subscription.plan))
    )
    return result.scalar_one_or_none()


async def activate_subscription(
    db: AsyncSession,
    user_id: UUID,
    plan_id: UUID,
    transaction_id: UUID,
) -> Subscription:
    result = await db.execute(select(Plan).where(Plan.id == plan_id))
    plan = result.scalar_one_or_none()
    if not plan:
        raise ValueError("Plan introuvable")

    now = datetime.utcnow()
    await db.execute(
        update(Subscription)
        .where(
            and_(
                Subscription.user_id == user_id,
                Subscription.status == SubscriptionStatus.ACTIVE,
            )
        )
        .values(status=SubscriptionStatus.CANCELLED)
    )

    sub = Subscription(
        user_id=user_id,
        plan_id=plan_id,
        transaction_id=transaction_id,
        status=SubscriptionStatus.ACTIVE,
        start_date=now,
        end_date=now + timedelta(days=plan.duration_days),
    )
    db.add(sub)
    await db.flush()
    return sub


async def expire_due_subscriptions(db: AsyncSession) -> int:
    now = datetime.utcnow()
    result = await db.execute(
        update(Subscription)
        .where(
            and_(
                Subscription.status == SubscriptionStatus.ACTIVE,
                Subscription.end_date <= now,
            )
        )
        .values(status=SubscriptionStatus.EXPIRED)
        .returning(Subscription.id)
    )
    expired_ids = result.fetchall()
    await db.commit()
    return len(expired_ids)


async def get_subscriptions_expiring_in(
    db: AsyncSession, days: int
) -> list[Subscription]:
    now = datetime.utcnow()
    deadline = now + timedelta(days=days)
    notified_field = Subscription.notified_d3 if days == 3 else Subscription.notified_d1

    result = await db.execute(
        select(Subscription).where(
            and_(
                Subscription.status == SubscriptionStatus.ACTIVE,
                Subscription.end_date > now,
                Subscription.end_date <= deadline,
                notified_field == False,
            )
        )
    )
    return result.scalars().all()
