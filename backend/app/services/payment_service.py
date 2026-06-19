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

    # Appel FedaPay — la réponse de création contient déjà payment_url et payment_token
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
    # FedaPay fournit directement payment_url (https://process.fedapay.com/...) dans la réponse
    payment_url = fedapay_transaction.get("payment_url", "")
    payment_token = fedapay_transaction.get("payment_token", "")

    logger.info("FedaPay transaction %s → payment_url: %s", fedapay_id, payment_url)

    transaction.fedapay_id = fedapay_id
    transaction.fedapay_token = payment_token
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
