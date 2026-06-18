from uuid import UUID
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.transaction import Transaction, TransactionStatus
from app.schemas.payment import TransactionResponse
from app.services.payment_service import fetch_fedapay_status
from app.services.subscription_service import activate_subscription
from app.services.notification_service import send_to_user, NotificationType
from app.services.loyalty_service import credit_points, LoyaltySource
from app.services.referral_service import process_referral_reward

router = APIRouter(prefix="/payments", tags=["Paiements"])


@router.get("/history", response_model=list[TransactionResponse])
async def payment_history(
    limit: int = 50,
    offset: int = 0,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Transaction)
        .where(Transaction.user_id == user.id)
        .order_by(Transaction.created_at.desc())
        .limit(limit)
        .offset(offset)
    )
    return result.scalars().all()


@router.post(
    "/verify/{transaction_id}",
    response_model=TransactionResponse,
    summary="Vérifier le paiement en fetchant le vrai statut chez FedaPay",
)
async def verify_and_activate(
    transaction_id: UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Appelée par le frontend après redirection depuis la page de paiement FedaPay.
    Va chercher le statut RÉEL de la transaction chez FedaPay (évite toute fraude côté client).
    Si le statut est 'approved', active l'abonnement et crédite les points.
    Idempotente : si déjà traitée, renvoie simplement la transaction.
    """
    result = await db.execute(
        select(Transaction).where(
            Transaction.id == transaction_id,
            Transaction.user_id == user.id,
        )
    )
    transaction = result.scalar_one_or_none()
    if not transaction:
        raise HTTPException(404, "Transaction introuvable")

    # Déjà traitée → retour immédiat sans appel FedaPay
    if transaction.status == TransactionStatus.PAID:
        return transaction

    if not transaction.fedapay_id:
        raise HTTPException(400, "Transaction non initialisée (pas encore de fedapay_id)")

    # Vérification ANTI-FRAUDE : on interroge directement FedaPay
    try:
        real_status = await fetch_fedapay_status(transaction.fedapay_id)
    except Exception as e:
        raise HTTPException(502, f"Erreur communication FedaPay : {e}")

    if real_status != "approved":
        # Pas encore payé ou refusé — on retourne le statut actuel sans modifier la DB
        return transaction

    # — Paiement confirmé par FedaPay —

    transaction.status = TransactionStatus.PAID
    transaction.paid_at = datetime.utcnow()
    await db.flush()

    # Activer l'abonnement
    subscription = await activate_subscription(
        db,
        user_id=transaction.user_id,
        plan_id=transaction.plan_id,
        transaction_id=transaction.id,
    )

    # Créditer les points de fidélité
    await credit_points(
        db,
        user_id=transaction.user_id,
        source=LoyaltySource.SUBSCRIPTION,
        reference_id=subscription.id,
    )

    # Récompense parrainage (premier abonnement du filleul)
    await process_referral_reward(db, referred_user_id=transaction.user_id)

    # Notification push
    await send_to_user(
        db,
        user_id=transaction.user_id,
        title="Abonnement activé",
        body="Votre abonnement est maintenant actif. Accédez à vos coupons premium.",
        notif_type=NotificationType.SUB_ACTIVATED,
        data={"subscription_id": str(subscription.id)},
    )

    await db.commit()
    await db.refresh(transaction)
    return transaction
