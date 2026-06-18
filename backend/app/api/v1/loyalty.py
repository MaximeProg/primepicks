from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from uuid import UUID
from datetime import datetime

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.loyalty import LoyaltyTransaction, LoyaltySource
from app.services.loyalty_service import redeem_points, REDEMPTION_TABLE

router = APIRouter(prefix="/loyalty", tags=["Fidélité"])


class LoyaltyTxResponse(BaseModel):
    id: UUID
    points: int
    source: LoyaltySource
    description: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class RedeemRequest(BaseModel):
    reward_key: str


@router.get("/me")
async def get_loyalty(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(LoyaltyTransaction)
        .where(LoyaltyTransaction.user_id == user.id)
        .order_by(LoyaltyTransaction.created_at.desc())
        .limit(50)
    )
    history = result.scalars().all()

    return {
        "current_points": user.loyalty_points,
        "history": [LoyaltyTxResponse.model_validate(tx) for tx in history],
        "available_rewards": [
            {"key": k, "cost": v["cost"], "description": v["description"]}
            for k, v in REDEMPTION_TABLE.items()
            if v["cost"] <= user.loyalty_points
        ],
    }


@router.post("/redeem")
async def redeem(
    data: RedeemRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        reward = await redeem_points(db, user, data.reward_key)
        await db.commit()
        await db.refresh(user)
        return {
            "message": f"Récompense obtenue : {reward['description']}",
            "remaining_points": user.loyalty_points,
        }
    except ValueError as e:
        raise HTTPException(400, str(e))
