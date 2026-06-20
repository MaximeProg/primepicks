import enum
import uuid
from datetime import datetime, timezone
from sqlalchemy import String, Boolean, Integer, Enum as SAEnum, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from app.models.base import Base


class UserRole(str, enum.Enum):
    SUPER_ADMIN = "SUPER_ADMIN"
    ADMIN = "ADMIN"
    AFFILIATE = "AFFILIATE"
    USER = "USER"


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    firebase_uid: Mapped[str] = mapped_column(String(128), unique=True, nullable=False, index=True)
    email: Mapped[str | None] = mapped_column(String(255), unique=True, nullable=True, index=True)
    phone: Mapped[str | None] = mapped_column(String(20))
    full_name: Mapped[str | None] = mapped_column(String(255))
    avatar_url: Mapped[str | None] = mapped_column(String(500))
    role: Mapped[UserRole] = mapped_column(SAEnum(UserRole), default=UserRole.USER, nullable=False)
    referral_code: Mapped[str] = mapped_column(String(12), unique=True, nullable=False, index=True)
    referred_by: Mapped[uuid.UUID | None] = mapped_column(PGUUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    loyalty_points: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(default=func.now(), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(default=func.now(), onupdate=func.now(), nullable=False)

    # Relations — passive_deletes=True laisse PostgreSQL gérer ON DELETE CASCADE/SET NULL
    subscriptions: Mapped[list["Subscription"]] = relationship("Subscription", back_populates="user", lazy="select", passive_deletes=True)
    transactions: Mapped[list["Transaction"]] = relationship("Transaction", back_populates="user", lazy="select", passive_deletes=True)
    fcm_tokens: Mapped[list["FcmToken"]] = relationship("FcmToken", back_populates="user", lazy="select", passive_deletes=True)
    loyalty_transactions: Mapped[list["LoyaltyTransaction"]] = relationship("LoyaltyTransaction", back_populates="user", lazy="select", passive_deletes=True)
    reviews: Mapped[list["Review"]] = relationship("Review", back_populates="user", lazy="select", passive_deletes=True)
