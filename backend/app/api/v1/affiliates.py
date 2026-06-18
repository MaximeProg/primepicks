import shortuuid
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from uuid import UUID
from datetime import datetime

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User, UserRole
from app.models.affiliate import Affiliate, AffiliateConversion

router = APIRouter(prefix="/affiliates", tags=["Affiliation"])


class AffiliateResponse(BaseModel):
    id: UUID
    affiliate_code: str
    commission_rate: float
    total_earned: float
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class ConversionResponse(BaseModel):
    id: UUID
    user_id: UUID
    transaction_id: UUID | None
    commission: float
    paid_out: bool
    created_at: datetime

    model_config = {"from_attributes": True}


@router.post("/apply", response_model=AffiliateResponse)
async def apply_affiliate(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    existing = await db.execute(select(Affiliate).where(Affiliate.user_id == user.id))
    if existing.scalar_one_or_none():
        raise HTTPException(400, "Vous êtes déjà affilié")

    affiliate = Affiliate(
        user_id=user.id,
        affiliate_code=shortuuid.ShortUUID().random(length=10).upper(),
    )
    db.add(affiliate)

    # Élever le rôle en AFFILIATE
    if user.role == UserRole.USER:
        user.role = UserRole.AFFILIATE

    await db.commit()
    await db.refresh(affiliate)
    return affiliate


@router.get("/me", response_model=AffiliateResponse)
async def get_my_affiliate(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Affiliate).where(Affiliate.user_id == user.id))
    affiliate = result.scalar_one_or_none()
    if not affiliate:
        raise HTTPException(404, "Compte affilié introuvable. Faites une demande via POST /affiliates/apply")
    return affiliate


@router.get("/me/conversions", response_model=list[ConversionResponse])
async def get_my_conversions(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Affiliate).where(Affiliate.user_id == user.id))
    affiliate = result.scalar_one_or_none()
    if not affiliate:
        raise HTTPException(404, "Compte affilié introuvable")

    convs = await db.execute(
        select(AffiliateConversion)
        .where(AffiliateConversion.affiliate_id == affiliate.id)
        .order_by(AffiliateConversion.created_at.desc())
    )
    return convs.scalars().all()


@router.get("/me/earnings")
async def get_my_earnings(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Affiliate).where(Affiliate.user_id == user.id))
    affiliate = result.scalar_one_or_none()
    if not affiliate:
        raise HTTPException(404, "Compte affilié introuvable")

    unpaid = await db.execute(
        select(func.sum(AffiliateConversion.commission)).where(
            AffiliateConversion.affiliate_id == affiliate.id,
            AffiliateConversion.paid_out == False,
        )
    )

    return {
        "total_earned": float(affiliate.total_earned),
        "pending_payout": float(unpaid.scalar() or 0),
        "commission_rate": float(affiliate.commission_rate),
    }
