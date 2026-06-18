from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update

from app.models.user import User
from app.models.loyalty import LoyaltyTransaction, LoyaltySource


POINTS_TABLE = {
    LoyaltySource.SUBSCRIPTION: 100,
    LoyaltySource.REFERRAL: 200,
}

REDEMPTION_TABLE = {
    "discount_10": {"cost": 500, "description": "Réduction 10% sur prochain abonnement"},
    "free_month": {"cost": 1000, "description": "1 mois offert"},
    "free_week": {"cost": 300, "description": "Accès 7 jours offert"},
}


async def credit_points(
    db: AsyncSession,
    user_id: UUID,
    source: LoyaltySource,
    reference_id: UUID | None = None,
    override_points: int | None = None,
) -> int:
    points = override_points or POINTS_TABLE.get(source, 0)
    if points <= 0:
        return 0

    tx = LoyaltyTransaction(
        user_id=user_id,
        points=points,
        source=source,
        reference_id=reference_id,
        description=f"Crédit {source.value}",
    )
    db.add(tx)

    await db.execute(
        update(User).where(User.id == user_id).values(loyalty_points=User.loyalty_points + points)
    )
    await db.flush()
    return points


async def redeem_points(
    db: AsyncSession,
    user: User,
    reward_key: str,
) -> dict:
    reward = REDEMPTION_TABLE.get(reward_key)
    if not reward:
        raise ValueError("Récompense inconnue")

    cost = reward["cost"]
    if user.loyalty_points < cost:
        raise ValueError(f"Points insuffisants (besoin : {cost}, disponible : {user.loyalty_points})")

    tx = LoyaltyTransaction(
        user_id=user.id,
        points=-cost,
        source=LoyaltySource.REDEMPTION,
        description=reward["description"],
    )
    db.add(tx)

    await db.execute(
        update(User).where(User.id == user.id).values(loyalty_points=User.loyalty_points - cost)
    )
    await db.flush()
    return reward
