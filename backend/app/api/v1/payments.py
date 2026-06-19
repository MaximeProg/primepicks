import hmac
import hashlib
import json
import logging
from uuid import UUID
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.config import settings
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

logger = logging.getLogger(__name__)

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

    # Vérification ANTI-FRAUDE + activation via logique commune
    try:
        await _activate_transaction(db, transaction)
    except Exception as e:
        raise HTTPException(502, f"Erreur communication FedaPay : {e}")

    await db.refresh(transaction)
    return transaction


def _verify_fedapay_signature(sig_header: str, body: bytes, secret: str) -> bool:
    """
    FedaPay envoie : X-FEDAPAY-SIGNATURE: t=TIMESTAMP,v1=HMAC_HEX
    Le HMAC est calculé sur "timestamp.body" (pas seulement body).
    """
    try:
        parts = dict(item.split("=", 1) for item in sig_header.split(",") if "=" in item)
        timestamp = parts.get("t", "")
        v1_sig = parts.get("v1", "")
        if not timestamp or not v1_sig:
            return False
        signed_payload = f"{timestamp}.".encode() + body
        expected = hmac.new(secret.encode(), signed_payload, hashlib.sha256).hexdigest()
        return hmac.compare_digest(expected, v1_sig)
    except Exception:
        return False


async def _activate_transaction(db: AsyncSession, transaction: Transaction) -> None:
    """Logique commune d'activation après confirmation FedaPay (verify + webhook)."""
    if transaction.status == TransactionStatus.PAID:
        return

    real_status = await fetch_fedapay_status(transaction.fedapay_id)
    if real_status != "approved":
        return

    transaction.status = TransactionStatus.PAID
    transaction.paid_at = datetime.utcnow()
    await db.flush()

    subscription = await activate_subscription(
        db,
        user_id=transaction.user_id,
        plan_id=transaction.plan_id,
        transaction_id=transaction.id,
    )
    await credit_points(db, user_id=transaction.user_id, source=LoyaltySource.SUBSCRIPTION, reference_id=subscription.id)
    await process_referral_reward(db, referred_user_id=transaction.user_id)
    await send_to_user(
        db,
        user_id=transaction.user_id,
        title="Abonnement activé",
        body="Votre abonnement est maintenant actif. Accédez à vos coupons premium.",
        notif_type=NotificationType.SUB_ACTIVATED,
        data={"subscription_id": str(subscription.id)},
    )
    await db.commit()


@router.post("/webhook", include_in_schema=False)
async def fedapay_webhook(request: Request, db: AsyncSession = Depends(get_db)):
    """
    Webhook FedaPay — appelé automatiquement côté serveur dès qu'un paiement est approuvé.
    Vérifie la signature HMAC, puis ré-interroge FedaPay (anti-fraude) avant d'activer.
    """
    body = await request.body()

    # Vérification de signature FedaPay (format : "t=TIMESTAMP,v1=HMAC_HEX")
    if settings.FEDAPAY_WEBHOOK_SECRET:
        sig_header = request.headers.get("X-FEDAPAY-SIGNATURE", "")
        logger.info("Webhook FedaPay signature header: %s", sig_header)
        if not _verify_fedapay_signature(sig_header, body, settings.FEDAPAY_WEBHOOK_SECRET):
            logger.warning(
                "Webhook FedaPay : signature invalide (header=%s, secret_last4=...%s)",
                sig_header,
                settings.FEDAPAY_WEBHOOK_SECRET[-4:],
            )
            raise HTTPException(status_code=401, detail="Signature invalide")

    try:
        event = json.loads(body)
    except Exception:
        raise HTTPException(status_code=400, detail="Corps JSON invalide")

    event_name = event.get("name", "")
    logger.info("Webhook FedaPay reçu : %s", event_name)

    if event_name != "transaction.approved":
        return {"ok": True}

    # Extraire notre transaction_id depuis les métadonnées FedaPay
    txn_data = event.get("data", {})
    fedapay_txn = txn_data.get("v1/transaction", txn_data)
    metadata = fedapay_txn.get("metadata") or {}
    transaction_id = metadata.get("transaction_id")

    if not transaction_id:
        logger.warning("Webhook FedaPay : metadata.transaction_id absent")
        return {"ok": True}

    result = await db.execute(
        select(Transaction).where(Transaction.id == transaction_id)
    )
    transaction = result.scalar_one_or_none()
    if not transaction:
        logger.warning("Webhook FedaPay : transaction %s introuvable", transaction_id)
        return {"ok": True}

    await _activate_transaction(db, transaction)
    return {"ok": True}
