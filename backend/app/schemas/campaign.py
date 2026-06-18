from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from app.models.campaign import CampaignTargetType


class CampaignCreate(BaseModel):
    title: str
    description: str | None = None
    start_date: datetime | None = None
    end_date: datetime | None = None
    target_type: CampaignTargetType = CampaignTargetType.ALL
    is_active: bool = True


class CampaignUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    start_date: datetime | None = None
    end_date: datetime | None = None
    target_type: CampaignTargetType | None = None
    is_active: bool | None = None


class CampaignResponse(BaseModel):
    id: UUID
    title: str
    description: str | None = None
    start_date: datetime | None = None
    end_date: datetime | None = None
    target_type: CampaignTargetType
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}
