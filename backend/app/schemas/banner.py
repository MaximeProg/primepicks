from pydantic import BaseModel
from uuid import UUID
from datetime import datetime


class BannerCreate(BaseModel):
    title: str
    image_url: str
    redirect_url: str | None = None
    position: int = 0
    is_active: bool = True
    start_date: datetime | None = None
    end_date: datetime | None = None


class BannerUpdate(BaseModel):
    title: str | None = None
    image_url: str | None = None
    redirect_url: str | None = None
    position: int | None = None
    is_active: bool | None = None
    start_date: datetime | None = None
    end_date: datetime | None = None


class BannerResponse(BaseModel):
    id: UUID
    title: str
    image_url: str
    redirect_url: str | None = None
    position: int
    is_active: bool
    start_date: datetime | None = None
    end_date: datetime | None = None
    created_at: datetime

    model_config = {"from_attributes": True}
