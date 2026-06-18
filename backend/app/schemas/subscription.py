from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from app.models.subscription import SubscriptionStatus
from app.schemas.plan import PlanResponse


class SubscriptionCreate(BaseModel):
    plan_id: UUID


class SubscriptionResponse(BaseModel):
    id: UUID
    user_id: UUID
    plan_id: UUID
    status: SubscriptionStatus
    start_date: datetime | None = None
    end_date: datetime | None = None
    auto_renew: bool
    created_at: datetime
    plan: PlanResponse | None = None

    model_config = {"from_attributes": True}


class SubscriptionAdminUpdate(BaseModel):
    status: SubscriptionStatus | None = None
    end_date: datetime | None = None
    start_date: datetime | None = None
    auto_renew: bool | None = None
