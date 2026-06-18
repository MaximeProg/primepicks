import uuid
from datetime import datetime
from sqlalchemy import String, Boolean, Numeric, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from app.models.base import Base


class Affiliate(Base):
    __tablename__ = "affiliates"

    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("users.id"), unique=True, nullable=False)
    affiliate_code: Mapped[str] = mapped_column(String(20), unique=True, nullable=False, index=True)
    commission_rate: Mapped[float] = mapped_column(Numeric(5, 2), default=10.00, nullable=False)
    total_earned: Mapped[float] = mapped_column(Numeric(10, 2), default=0.00, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(default=func.now(), nullable=False)

    user: Mapped["User"] = relationship("User")
    conversions: Mapped[list["AffiliateConversion"]] = relationship("AffiliateConversion", back_populates="affiliate", lazy="select")


class AffiliateConversion(Base):
    __tablename__ = "affiliate_conversions"

    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    affiliate_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("affiliates.id"), nullable=False, index=True)
    user_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    transaction_id: Mapped[uuid.UUID | None] = mapped_column(PGUUID(as_uuid=True), ForeignKey("transactions.id"), nullable=True)
    commission: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    paid_out: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime] = mapped_column(default=func.now(), nullable=False)

    affiliate: Mapped["Affiliate"] = relationship("Affiliate", back_populates="conversions")
