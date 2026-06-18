import enum
import uuid
from datetime import datetime
from sqlalchemy import String, Numeric, Text, Boolean, Integer, Enum as SAEnum, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from app.models.base import Base


class CouponStatus(str, enum.Enum):
    PENDING = "PENDING"
    WON = "WON"
    LOST = "LOST"
    CANCELLED = "CANCELLED"


class CouponType(str, enum.Enum):
    FREE = "FREE"
    PREMIUM = "PREMIUM"
    VIP = "VIP"


class Coupon(Base):
    __tablename__ = "coupons"

    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    analysis: Mapped[str | None] = mapped_column(Text)
    odds: Mapped[float | None] = mapped_column(Numeric(6, 2))
    bookmaker_code: Mapped[str | None] = mapped_column(String(100))
    image_url: Mapped[str | None] = mapped_column(String(500))
    valid_until: Mapped[datetime | None] = mapped_column(nullable=True)
    status: Mapped[CouponStatus] = mapped_column(SAEnum(CouponStatus), default=CouponStatus.PENDING, nullable=False)
    coupon_type: Mapped[CouponType] = mapped_column(SAEnum(CouponType), default=CouponType.FREE, nullable=False)
    confidence_level: Mapped[int | None] = mapped_column(Integer, nullable=True)
    is_published: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    published_at: Mapped[datetime | None] = mapped_column(nullable=True)
    created_by: Mapped[uuid.UUID | None] = mapped_column(PGUUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    created_at: Mapped[datetime] = mapped_column(default=func.now(), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(default=func.now(), onupdate=func.now(), nullable=False)

    matches: Mapped[list["CouponMatch"]] = relationship("CouponMatch", back_populates="coupon", cascade="all, delete-orphan", lazy="select")  # type: ignore[name-defined]
