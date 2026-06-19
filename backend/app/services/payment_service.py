import hmac
import hashlib
import httpx
import logging
from uuid import UUID
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

logger = logging.getLogger(__name__)

from app.core.config import settings
from app.models.transaction import Transaction, TransactionStatus
from app.models.plan import Plan
from app.models.user import User


async def initiate_fedapay_payment(
    db: AsyncSession,
    user: User,
    plan_id: UUID,
) -> Transaction:
    result = await db.execute(select(Plan).where(Plan.id == plan_id, Plan.is_active == True))
    plan = result.scalar_one_or_none()
    if not plan:
        raise ValueError("Plan introuvable ou inactif")

    # Créer la transaction locale en PENDING
    transaction = Transaction(
        user_id=user.id,
        plan_id=plan.id,
        amount=plan.price,
        currency="XOF",
        status=TransactionStatus.PENDING,
    )
    db.add(transaction)
    await db.flush()

    # Appel FedaPay API
    payload = {
        "description": f"Abonnement {plan.name}",
        "amount": int(plan.price),
        "currency": {"iso": "XOF"},
        "customer": {
            "email": user.email,
            "firstname": (user.full_name or "").split(" ")[0] or "Client",
            "lastname": " ".join((user.full_name or "Client").split(" ")[1:]) or "Client",
        },
        "callback_url": f"{settings.FRONTEND_URL}/payment/callback",
        "metadata": {"transaction_id": str(transaction.id)},
    }

    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.FEDAPAY_BASE_URL}/transactions",
            json=payload,
            headers={
                "Authorization": f"Bearer {settings.FEDAPAY_API_KEY}",
                "Content-Type": "application/json",
            },
            timeout=30,
        )
        response.raise_for_status()
        data = response.json()

    fedapay_transaction = data.get("v1/transaction", data)
    fedapay_id = str(fedapay_transaction.get("id", ""))

    # Générer le token de paiement FedaPay
    async with httpx.AsyncClient() as client:
        token_response = await client.post(
            f"{settings.FEDAPAY_BASE_URL}/transactions/{fedapay_id}/token",
            headers={"Authorization": f"Bearer {settings.FEDAPAY_API_KEY}"},
            timeout=30,
        )
        token_response.raise_for_status()
        token_data = token_response.json()

    logger.info("FedaPay token raw response: %s", token_data)
    # FedaPay wraps token response under "v1/token" key (same pattern as "v1/transaction")
    token_obj = token_data.get("v1/token", token_data)
    token = token_obj.get("token", "")
    checkout_host = (
        "sandbox-checkout.fedapay.com"
        if "sandbox" in settings.FEDAPAY_BASE_URL
        else "checkout.fedapay.com"
    )
    # Prefer the payment_url returned by FedaPay directly; fall back to manual construction
    payment_url = token_obj.get("payment_url") or f"https://{checkout_host}/{token}"
    logger.info("FedaPay payment_url generated: %s", payment_url)

    transaction.fedapay_id = fedapay_id
    transaction.fedapay_token = token
    transaction.payment_url = payment_url

    await db.flush()
    return transaction


async def fetch_fedapay_status(fedapay_id: str) -> str:
    """Récupère le vrai statut d'une transaction depuis FedaPay (anti-fraude)."""
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.FEDAPAY_BASE_URL}/transactions/{fedapay_id}",
            headers={"Authorization": f"Bearer {settings.FEDAPAY_API_KEY}"},
            timeout=30,
        )
        response.raise_for_status()
        data = response.json()
    txn = data.get("v1/transaction", data)
    return txn.get("status", "pending")
