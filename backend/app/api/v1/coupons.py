from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from sqlalchemy.orm import selectinload

from app.core.database import get_db
from app.core.dependencies import require_active_subscription
from app.models.coupon import Coupon, CouponStatus
from app.schemas.coupon import CouponResponse, CouponPublicResponse

router = APIRouter(prefix="/coupons", tags=["Coupons"])


@router.get("/public", response_model=list[CouponPublicResponse])
async def list_public_coupons(
    limit: int = Query(10, le=50),
    db: AsyncSession = Depends(get_db),
):
    """Aperçu public sans code bookmaker ni analyse."""
    result = await db.execute(
        select(Coupon)
        .where(Coupon.is_published == True)
        .options(selectinload(Coupon.matches))
        .order_by(desc(Coupon.published_at))
        .limit(limit)
    )
    return result.scalars().all()


@router.get("", response_model=list[CouponResponse])
async def list_coupons(
    status: CouponStatus | None = None,
    limit: int = Query(20, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    _user=Depends(require_active_subscription),
):
    query = (
        select(Coupon)
        .where(Coupon.is_published == True)
        .options(selectinload(Coupon.matches))
    )
    if status:
        query = query.where(Coupon.status == status)
    query = query.order_by(desc(Coupon.published_at)).limit(limit).offset(offset)
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/{coupon_id}", response_model=CouponResponse)
async def get_coupon(
    coupon_id: UUID,
    db: AsyncSession = Depends(get_db),
    _user=Depends(require_active_subscription),
):
    result = await db.execute(
        select(Coupon)
        .where(Coupon.id == coupon_id, Coupon.is_published == True)
        .options(selectinload(Coupon.matches))
    )
    coupon = result.scalar_one_or_none()
    if not coupon:
        raise HTTPException(404, "Coupon introuvable")
    return coupon
