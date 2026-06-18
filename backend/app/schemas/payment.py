from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from app.models.transaction import TransactionStatus


class PaymentInitiate(BaseModel):
    plan_id: UUID


class PaymentInitiateResponse(BaseModel):
    transaction_id: UUID
    payment_url: str
    amount: float
    currency: str


class TransactionResponse(BaseModel):
    id: UUID
    user_id: UUID
    plan_id: UUID | None = None
    amount: float
    currency: str
    status: TransactionStatus
    fedapay_id: str | None = None
    payment_url: str | None = None
    paid_at: datetime | None = None
    created_at: datetime

    model_config = {"from_attributes": True}


class FedapayWebhookPayload(BaseModel):
    id: int
    status: str
    amount: float | None = None
    currency: dict | None = None
    customer: dict | None = None

    model_config = {"extra": "allow"}
