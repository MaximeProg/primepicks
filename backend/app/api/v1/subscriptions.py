from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_active_subscription
from app.models.user import User
from app.schemas.subscription import SubscriptionCreate, SubscriptionResponse
from app.schemas.payment import PaymentInitiateResponse
from app.services.subscription_service import get_active_subscription
from app.services.payment_service import initiate_fedapay_payment

router = APIRouter(prefix="/subscriptions", tags=["Abonnements"])


@router.get("/me", response_model=SubscriptionResponse | None)
async def get_my_subscription(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await get_active_subscription(db, user.id)


@router.post("", response_model=PaymentInitiateResponse)
async def subscribe(
    data: SubscriptionCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        transaction = await initiate_fedapay_payment(db, user, data.plan_id)
        await db.commit()
        await db.refresh(transaction)
        return PaymentInitiateResponse(
            transaction_id=transaction.id,
            payment_url=transaction.payment_url,
            amount=float(transaction.amount),
            currency=transaction.currency,
        )
    except ValueError as e:
        raise HTTPException(400, str(e))


@router.post("/me/renew", response_model=PaymentInitiateResponse)
async def renew_subscription(
    user: User = Depends(require_active_subscription),
    db: AsyncSession = Depends(get_db),
):
    sub = await get_active_subscription(db, user.id)
    if not sub:
        raise HTTPException(404, "Aucun abonnement actif à renouveler")

    try:
        transaction = await initiate_fedapay_payment(db, user, sub.plan_id)
        await db.commit()
        await db.refresh(transaction)
        return PaymentInitiateResponse(
            transaction_id=transaction.id,
            payment_url=transaction.payment_url,
            amount=float(transaction.amount),
            currency=transaction.currency,
        )
    except ValueError as e:
        raise HTTPException(400, str(e))
