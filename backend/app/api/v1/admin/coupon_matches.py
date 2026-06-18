from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.core.dependencies import require_admin
from app.models.user import User
from app.models.coupon import Coupon
from app.models.coupon_match import CouponMatch
from app.schemas.coupon_match import CouponMatchCreate, CouponMatchUpdate, CouponMatchResponse

router = APIRouter(prefix="/admin/coupons/{coupon_id}/matches", tags=["Admin — Matchs coupon"])


async def _get_coupon(coupon_id: UUID, db: AsyncSession) -> Coupon:
    r = await db.execute(select(Coupon).where(Coupon.id == coupon_id))
    c = r.scalar_one_or_none()
    if not c:
        raise HTTPException(404, "Coupon introuvable")
    return c


@router.get("", response_model=list[CouponMatchResponse])
async def list_matches(
    coupon_id: UUID,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    await _get_coupon(coupon_id, db)
    r = await db.execute(select(CouponMatch).where(CouponMatch.coupon_id == coupon_id))
    return r.scalars().all()


@router.post("", response_model=CouponMatchResponse, status_code=201)
async def create_match(
    coupon_id: UUID,
    data: CouponMatchCreate,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    await _get_coupon(coupon_id, db)
    match = CouponMatch(coupon_id=coupon_id, **data.model_dump())
    db.add(match)
    await db.commit()
    await db.refresh(match)
    return match


@router.patch("/{match_id}", response_model=CouponMatchResponse)
async def update_match(
    coupon_id: UUID,
    match_id: UUID,
    data: CouponMatchUpdate,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    r = await db.execute(select(CouponMatch).where(CouponMatch.id == match_id, CouponMatch.coupon_id == coupon_id))
    match = r.scalar_one_or_none()
    if not match:
        raise HTTPException(404, "Match introuvable")
    for field, value in data.model_dump(exclude_none=True).items():
        setattr(match, field, value)
    await db.commit()
    await db.refresh(match)
    return match


@router.delete("/{match_id}", status_code=204)
async def delete_match(
    coupon_id: UUID,
    match_id: UUID,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    r = await db.execute(select(CouponMatch).where(CouponMatch.id == match_id, CouponMatch.coupon_id == coupon_id))
    match = r.scalar_one_or_none()
    if not match:
        raise HTTPException(404, "Match introuvable")
    await db.delete(match)
    await db.commit()
