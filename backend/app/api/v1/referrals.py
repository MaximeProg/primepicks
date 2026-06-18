from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from uuid import UUID
from datetime import datetime

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.config import settings
from app.models.user import User
from app.models.referral import Referral

router = APIRouter(prefix="/referrals", tags=["Parrainage"])


class ReferralInfo(BaseModel):
    referral_code: str
    referral_link: str
    total_referred: int
    total_rewarded: int


class ReferralEntry(BaseModel):
    id: UUID
    referred_id: UUID
    reward_given: bool
    rewarded_at: datetime | None
    created_at: datetime

    model_config = {"from_attributes": True}


@router.get("/me", response_model=ReferralInfo)
async def get_my_referral_info(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    total_result = await db.execute(
        select(func.count()).select_from(Referral).where(Referral.referrer_id == user.id)
    )
    total = total_result.scalar() or 0

    rewarded_result = await db.execute(
        select(func.count()).select_from(Referral).where(
            Referral.referrer_id == user.id,
            Referral.reward_given == True,
        )
    )
    rewarded = rewarded_result.scalar() or 0

    return ReferralInfo(
        referral_code=user.referral_code,
        referral_link=f"{settings.FRONTEND_URL}/register?ref={user.referral_code}",
        total_referred=total,
        total_rewarded=rewarded,
    )


@router.get("/me/stats", response_model=list[ReferralEntry])
async def get_my_referral_stats(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Referral)
        .where(Referral.referrer_id == user.id)
        .order_by(Referral.created_at.desc())
    )
    return result.scalars().all()
