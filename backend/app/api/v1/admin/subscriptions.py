from uuid import UUID
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc, func
from sqlalchemy.orm import selectinload

from app.core.database import get_db
from app.core.dependencies import require_admin
from app.models.user import User
from app.models.subscription import Subscription, SubscriptionStatus
from app.schemas.subscription import SubscriptionResponse, SubscriptionAdminUpdate
from app.schemas.paginated import Paginated

router = APIRouter(prefix="/admin/subscriptions", tags=["Admin — Abonnements"])


@router.get("", response_model=Paginated[SubscriptionResponse])
async def list_subscriptions(
    status: SubscriptionStatus | None = None,
    limit: int = Query(20, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    query = select(Subscription).options(selectinload(Subscription.plan))
    if status:
        query = query.where(Subscription.status == status)

    count_query = select(Subscription)
    if status:
        count_query = count_query.where(Subscription.status == status)
    total_r = await db.execute(select(func.count()).select_from(count_query.subquery()))
    total = total_r.scalar() or 0

    result = await db.execute(
        query.order_by(desc(Subscription.created_at)).limit(limit).offset(offset)
    )
    return Paginated(items=result.scalars().all(), total=total, limit=limit, offset=offset)


@router.get("/{sub_id}", response_model=SubscriptionResponse)
async def get_subscription(
    sub_id: UUID,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    result = await db.execute(
        select(Subscription)
        .options(selectinload(Subscription.plan))
        .where(Subscription.id == sub_id)
    )
    sub = result.scalar_one_or_none()
    if not sub:
        raise HTTPException(404, "Abonnement introuvable")
    return sub


@router.patch("/{sub_id}", response_model=SubscriptionResponse)
async def update_subscription(
    sub_id: UUID,
    data: SubscriptionAdminUpdate,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    result = await db.execute(
        select(Subscription)
        .options(selectinload(Subscription.plan))
        .where(Subscription.id == sub_id)
    )
    sub = result.scalar_one_or_none()
    if not sub:
        raise HTTPException(404, "Abonnement introuvable")

    # Activation manuelle : calcule les dates depuis le plan
    if data.status == SubscriptionStatus.ACTIVE and sub.status != SubscriptionStatus.ACTIVE:
        now = datetime.utcnow()
        sub.status = SubscriptionStatus.ACTIVE
        sub.start_date = now
        if sub.plan:
            sub.end_date = now + timedelta(days=sub.plan.duration_days)
        if data.end_date:
            sub.end_date = data.end_date
    else:
        for field, value in data.model_dump(exclude_none=True).items():
            setattr(sub, field, value)

    await db.commit()
    await db.refresh(sub)
    return sub
