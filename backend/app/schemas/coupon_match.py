from pydantic import BaseModel
from uuid import UUID
from datetime import datetime


class CouponMatchCreate(BaseModel):
    match_name: str
    prediction: str
    odd: float | None = None


class CouponMatchUpdate(BaseModel):
    match_name: str | None = None
    prediction: str | None = None
    odd: float | None = None


class CouponMatchResponse(BaseModel):
    id: UUID
    coupon_id: UUID
    match_name: str
    prediction: str
    odd: float | None = None
    created_at: datetime

    model_config = {"from_attributes": True}
