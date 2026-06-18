from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from app.models.coupon import CouponStatus, CouponType
from app.schemas.coupon_match import CouponMatchResponse


class CouponBase(BaseModel):
    title: str
    description: str | None = None
    analysis: str | None = None
    odds: float | None = None
    bookmaker_code: str | None = None
    valid_until: datetime | None = None
    coupon_type: CouponType = CouponType.FREE
    confidence_level: int | None = None


class CouponCreate(CouponBase):
    pass


class CouponUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    analysis: str | None = None
    odds: float | None = None
    bookmaker_code: str | None = None
    valid_until: datetime | None = None
    status: CouponStatus | None = None
    coupon_type: CouponType | None = None
    confidence_level: int | None = None


class CouponStatusUpdate(BaseModel):
    status: CouponStatus


# Vue publique : pas de code bookmaker
class CouponPublicResponse(BaseModel):
    id: UUID
    title: str
    description: str | None = None
    odds: float | None = None
    status: CouponStatus
    coupon_type: CouponType
    confidence_level: int | None = None
    is_published: bool
    published_at: datetime | None = None
    created_at: datetime
    matches: list[CouponMatchResponse] = []

    model_config = {"from_attributes": True}


# Vue abonné : avec code bookmaker et analyse
class CouponResponse(CouponPublicResponse):
    analysis: str | None = None
    bookmaker_code: str | None = None
    image_url: str | None = None
    valid_until: datetime | None = None


# Vue admin : tous les champs
class CouponAdminResponse(CouponResponse):
    created_by: UUID | None = None
    updated_at: datetime
