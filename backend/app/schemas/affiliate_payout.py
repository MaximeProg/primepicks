from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from app.models.affiliate_payout import PayoutStatus


class AffiliatePayoutCreate(BaseModel):
    amount: float


class AffiliatePayoutAdminUpdate(BaseModel):
    status: PayoutStatus
    paid_at: datetime | None = None


class AffiliatePayoutResponse(BaseModel):
    id: UUID
    affiliate_id: UUID
    amount: float
    status: PayoutStatus
    requested_at: datetime
    paid_at: datetime | None = None

    model_config = {"from_attributes": True}
