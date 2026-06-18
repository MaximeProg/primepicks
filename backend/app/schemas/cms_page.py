from pydantic import BaseModel
from uuid import UUID
from datetime import datetime


class CmsPageCreate(BaseModel):
    slug: str
    title: str
    content: str | None = None
    is_published: bool = False


class CmsPageUpdate(BaseModel):
    title: str | None = None
    content: str | None = None
    is_published: bool | None = None


class CmsPageResponse(BaseModel):
    id: UUID
    slug: str
    title: str
    content: str | None = None
    is_published: bool
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
