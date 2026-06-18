from pydantic import BaseModel
from uuid import UUID
from datetime import datetime


class AppSettingUpdate(BaseModel):
    platform_name: str | None = None
    logo_url: str | None = None
    favicon_url: str | None = None
    support_email: str | None = None
    support_phone: str | None = None
    telegram_url: str | None = None
    whatsapp_url: str | None = None
    facebook_url: str | None = None
    instagram_url: str | None = None
    maintenance_mode: bool | None = None


class AppSettingResponse(BaseModel):
    id: UUID
    platform_name: str
    logo_url: str | None = None
    favicon_url: str | None = None
    support_email: str | None = None
    support_phone: str | None = None
    telegram_url: str | None = None
    whatsapp_url: str | None = None
    facebook_url: str | None = None
    instagram_url: str | None = None
    maintenance_mode: bool
    updated_at: datetime

    model_config = {"from_attributes": True}
