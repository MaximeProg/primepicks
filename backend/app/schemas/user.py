from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from app.models.user import UserRole


class UserBase(BaseModel):
    email: str | None = None
    full_name: str | None = None
    phone: str | None = None


class UserCreate(UserBase):
    firebase_uid: str
    referred_by_code: str | None = None


class UserUpdate(BaseModel):
    full_name: str | None = None
    phone: str | None = None


class UserResponse(UserBase):
    id: UUID
    role: UserRole
    referral_code: str
    loyalty_points: int
    avatar_url: str | None = None
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class UserAdminResponse(UserResponse):
    firebase_uid: str
    referred_by: UUID | None = None
    updated_at: datetime
