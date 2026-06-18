from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.referral import Referral
from app.models.loyalty import LoyaltySource
from app.services.loyalty_service import credit_points
from datetime import datetime, timezone


async def process_referral_reward(db: AsyncSession, referred_user_id: UUID) -> bool:
    result = await db.execute(
        select(Referral).where(
            Referral.referred_id == referred_user_id,
            Referral.reward_given == False,
        )
    )
    referral = result.scalar_one_or_none()
    if not referral:
        return False

    await credit_points(
        db,
        user_id=referral.referrer_id,
        source=LoyaltySource.REFERRAL,
        reference_id=referral.id,
    )

    referral.reward_given = True
    referral.rewarded_at = datetime.utcnow()
    await db.flush()
    return True


async def create_referral(
    db: AsyncSession, referrer_id: UUID, referred_id: UUID
) -> Referral:
    existing = await db.execute(
        select(Referral).where(Referral.referred_id == referred_id)
    )
    if existing.scalar_one_or_none():
        return None

    referral = Referral(
        referrer_id=referrer_id,
        referred_id=referred_id,
        reward_type="POINTS",
        reward_value=200,
    )
    db.add(referral)
    await db.flush()
    return referral
