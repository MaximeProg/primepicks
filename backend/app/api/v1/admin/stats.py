from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, extract, case
from datetime import datetime

from app.core.database import get_db
from app.core.dependencies import require_admin
from app.models.user import User
from app.models.subscription import Subscription, SubscriptionStatus
from app.models.transaction import Transaction, TransactionStatus
from app.models.coupon import Coupon, CouponStatus
from app.schemas.stats import AdminOverviewResponse, MonthlyStats, RevenueStats

router = APIRouter(prefix="/admin/stats", tags=["Admin — Statistiques"])


async def _count(db, model, *where):
    r = await db.execute(select(func.count()).select_from(model).where(*where))
    return r.scalar() or 0


async def _sum(db, col, *where):
    r = await db.execute(select(func.coalesce(func.sum(col), 0)).where(*where))
    return float(r.scalar() or 0)


@router.get("/overview", response_model=AdminOverviewResponse)
async def overview(
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    now = datetime.utcnow()
    first_of_month = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

    total_users   = await _count(db, User)
    active_subs   = await _count(db, Subscription,
                        Subscription.status == SubscriptionStatus.ACTIVE,
                        Subscription.end_date > now)
    new_users     = await _count(db, User, User.created_at >= first_of_month)
    total_revenue = await _sum(db, Transaction.amount,
                        Transaction.status == TransactionStatus.PAID)
    revenue_month = await _sum(db, Transaction.amount,
                        Transaction.status == TransactionStatus.PAID,
                        Transaction.paid_at >= first_of_month)
    total_coupons = await _count(db, Coupon, Coupon.is_published == True)
    won           = await _count(db, Coupon,
                        Coupon.is_published == True,
                        Coupon.status == CouponStatus.WON)
    lost          = await _count(db, Coupon,
                        Coupon.is_published == True,
                        Coupon.status == CouponStatus.LOST)

    resolved = won + lost
    win_rate = round(won / resolved * 100, 2) if resolved > 0 else 0.0

    return AdminOverviewResponse(
        total_users=total_users,
        active_subscribers=active_subs,
        new_users_this_month=new_users,
        total_revenue=total_revenue,
        revenue_this_month=revenue_month,
        total_coupons=total_coupons,
        win_rate=win_rate,
    )


@router.get("/coupons/monthly", response_model=list[MonthlyStats])
async def coupons_monthly(
    year: int = Query(default=None),
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    if not year:
        year = datetime.utcnow().year

    rows = await db.execute(
        select(
            extract("month", Coupon.published_at).label("month"),
            func.count(Coupon.id).label("total"),
            func.sum(case((Coupon.status == CouponStatus.WON, 1), else_=0)).label("won"),
            func.sum(case((Coupon.status == CouponStatus.LOST, 1), else_=0)).label("lost"),
        )
        .where(
            Coupon.is_published == True,
            extract("year", Coupon.published_at) == year,
        )
        .group_by(extract("month", Coupon.published_at))
        .order_by(extract("month", Coupon.published_at))
    )

    result = []
    for row in rows.fetchall():
        m, total, won, lost = int(row[0]), int(row[1]), int(row[2] or 0), int(row[3] or 0)
        resolved = won + lost
        result.append(MonthlyStats(
            month=f"{year}-{m:02d}",
            total=total,
            won=won,
            lost=lost,
            win_rate=round(won / resolved * 100, 2) if resolved > 0 else 0.0,
        ))
    return result


@router.get("/revenue/monthly", response_model=list[RevenueStats])
async def revenue_monthly(
    year: int = Query(default=None),
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    if not year:
        year = datetime.utcnow().year

    rows = await db.execute(
        select(
            extract("month", Transaction.paid_at).label("month"),
            func.coalesce(func.sum(Transaction.amount), 0).label("amount"),
            func.count(Transaction.id).label("count"),
        )
        .where(
            Transaction.status == TransactionStatus.PAID,
            extract("year", Transaction.paid_at) == year,
        )
        .group_by(extract("month", Transaction.paid_at))
        .order_by(extract("month", Transaction.paid_at))
    )

    return [
        RevenueStats(
            period=f"{year}-{int(row[0]):02d}",
            amount=float(row[1]),
            transactions_count=int(row[2]),
        )
        for row in rows.fetchall()
    ]
