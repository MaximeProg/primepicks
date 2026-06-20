from pydantic import BaseModel, Field
from uuid import UUID
from datetime import datetime
from app.models.review import ReviewStatus


class ReviewSubmit(BaseModel):
    rating: int = Field(..., ge=1, le=5)
    comment: str | None = Field(None, max_length=1000)


class ReviewPublicResponse(BaseModel):
    id: UUID
    rating: int
    comment: str | None
    author_name: str | None   # prénom masqué ex : "Jean D."
    created_at: datetime

    model_config = {"from_attributes": True}


class ReviewAdminResponse(BaseModel):
    id: UUID
    user_id: UUID
    author_name: str | None
    author_email: str | None
    rating: int
    comment: str | None
    status: ReviewStatus
    created_at: datetime

    model_config = {"from_attributes": True}


class ReviewAdminUpdate(BaseModel):
    status: ReviewStatus
