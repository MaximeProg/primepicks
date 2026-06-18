import uuid
from datetime import datetime
from sqlalchemy import String, Numeric, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from app.models.base import Base


class CouponMatch(Base):
    __tablename__ = "coupon_matches"

    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    coupon_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("coupons.id", ondelete="CASCADE"), nullable=False, index=True)
    match_name: Mapped[str] = mapped_column(String(255), nullable=False)
    prediction: Mapped[str] = mapped_column(String(255), nullable=False)
    odd: Mapped[float | None] = mapped_column(Numeric(6, 2))
    created_at: Mapped[datetime] = mapped_column(default=func.now(), nullable=False)

    coupon: Mapped["Coupon"] = relationship("Coupon", back_populates="matches")  # type: ignore[name-defined]
