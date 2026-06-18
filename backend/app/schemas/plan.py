from pydantic import BaseModel
from uuid import UUID
from datetime import datetime


class PlanBase(BaseModel):
    name: str
    slug: str
    price: float
    duration_days: int
    description: str | None = None
    features: dict | None = None
    loyalty_points_reward: int = 0


class PlanCreate(PlanBase):
    pass


class PlanUpdate(BaseModel):
    name: str | None = None
    price: float | None = None
    duration_days: int | None = None
    description: str | None = None
    features: dict | None = None
    loyalty_points_reward: int | None = None
    is_active: bool | None = None


class PlanResponse(PlanBase):
    id: UUID
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}
