from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, extract
from datetime import datetime, timezone

from app.core.database import get_db
from app.models.coupon import Coupon, CouponStatus
from app.schemas.stats import PublicStatsResponse

router = APIRouter(prefix="/stats", tags=["Statistiques"])


@router.get("/public", response_model=PublicStatsResponse)
async def public_stats(db: AsyncSession = Depends(get_db)):
    async def count(where_clauses):
        result = await db.execute(
            select(func.count()).select_from(Coupon).where(*where_clauses)
        )
        return result.scalar() or 0

    total     = await count([Coupon.is_published == True])
    won       = await count([Coupon.is_published == True, Coupon.status == CouponStatus.WON])
    lost      = await count([Coupon.is_published == True, Coupon.status == CouponStatus.LOST])
    cancelled = await count([Coupon.is_published == True, Coupon.status == CouponStatus.CANCELLED])
    pending   = total - won - lost - cancelled

    resolved  = won + lost
    win_rate  = round(won / resolved * 100, 2) if resolved > 0 else 0.0

    return PublicStatsResponse(
        total_coupons=total,
        won=won,
        lost=lost,
        cancelled=cancelled,
        pending=pending,
        win_rate=win_rate,
    )
