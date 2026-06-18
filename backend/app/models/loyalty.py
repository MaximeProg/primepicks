import enum
import uuid
from datetime import datetime
from sqlalchemy import Integer, Text, Enum as SAEnum, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from app.models.base import Base


class LoyaltySource(str, enum.Enum):
    SUBSCRIPTION = "SUBSCRIPTION"
    REFERRAL = "REFERRAL"
    CAMPAIGN = "CAMPAIGN"
    REDEMPTION = "REDEMPTION"
    MANUAL = "MANUAL"


class LoyaltyTransaction(Base):
    __tablename__ = "loyalty_transactions"

    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    points: Mapped[int] = mapped_column(Integer, nullable=False)  # positif ou négatif
    source: Mapped[LoyaltySource] = mapped_column(SAEnum(LoyaltySource), nullable=False)
    reference_id: Mapped[uuid.UUID | None] = mapped_column(PGUUID(as_uuid=True), nullable=True)
    description: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(default=func.now(), nullable=False)

    user: Mapped["User"] = relationship("User", back_populates="loyalty_transactions")
