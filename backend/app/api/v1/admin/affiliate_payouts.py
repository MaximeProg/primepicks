from uuid import UUID
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc, func

from app.core.database import get_db
from app.core.dependencies import require_admin
from app.core.audit import log_action
from app.models.user import User
from app.models.affiliate_payout import AffiliatePayout, PayoutStatus
from app.models.affiliate import Affiliate
from app.schemas.affiliate_payout import AffiliatePayoutAdminUpdate, AffiliatePayoutResponse
from app.schemas.paginated import Paginated
from app.services.notification_service import send_to_user, NotificationType

router = APIRouter(prefix="/admin/affiliate-payouts", tags=["Admin — Retraits affiliés"])


@router.get("", response_model=Paginated[AffiliatePayoutResponse])
async def list_payouts(
    status: PayoutStatus | None = None,
    limit: int = Query(20, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    q = select(AffiliatePayout)
    cq = select(AffiliatePayout)
    if status:
        q = q.where(AffiliatePayout.status == status)
        cq = cq.where(AffiliatePayout.status == status)

    total_r = await db.execute(select(func.count()).select_from(cq.subquery()))
    total = total_r.scalar() or 0

    r = await db.execute(q.order_by(desc(AffiliatePayout.requested_at)).limit(limit).offset(offset))
    return Paginated(items=r.scalars().all(), total=total, limit=limit, offset=offset)


@router.patch("/{payout_id}", response_model=AffiliatePayoutResponse)
async def update_payout(
    payout_id: UUID,
    data: AffiliatePayoutAdminUpdate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    r = await db.execute(select(AffiliatePayout).where(AffiliatePayout.id == payout_id))
    payout = r.scalar_one_or_none()
    if not payout:
        raise HTTPException(404, "Retrait introuvable")

    old_status = payout.status
    payout.status = data.status
    if data.status == PayoutStatus.PAID and not payout.paid_at:
        payout.paid_at = data.paid_at or datetime.now(timezone.utc)

    await log_action(db, admin, "UPDATE_PAYOUT", "affiliate_payout", payout_id,
                     old_data={"status": old_status.value},
                     new_data={"status": data.status.value})

    # Notifier l'affilié quand son retrait est approuvé/payé
    if data.status in (PayoutStatus.PAID, PayoutStatus.APPROVED):
        # Récupérer l'user_id de l'affilié
        aff_r = await db.execute(
            select(Affiliate.user_id).where(Affiliate.id == payout.affiliate_id)
        )
        affiliate_user_id = aff_r.scalar_one_or_none()
        if affiliate_user_id:
            label = "payé" if data.status == PayoutStatus.PAID else "approuvé"
            await send_to_user(
                db, user_id=affiliate_user_id,
                title="Retrait affilié mis à jour",
                body=f"Votre retrait de {float(payout.amount):,.0f} XOF a été {label}.",
                notif_type=NotificationType.PAYOUT_APPROVED,
                data={"payout_id": str(payout_id), "status": data.status.value},
            )

    await db.commit()
    await db.refresh(payout)
    return payout
