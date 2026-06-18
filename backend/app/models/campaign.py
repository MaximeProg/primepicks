import enum
import uuid
from datetime import datetime
from sqlalchemy import String, Text, Boolean, func
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import TIMESTAMP
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from app.models.base import Base


class CampaignTargetType(str, enum.Enum):
    ALL = "ALL"
    PREMIUM = "PREMIUM"
    FREE = "FREE"
    INACTIVE = "INACTIVE"


class Campaign(Base):
    __tablename__ = "campaigns"

    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    start_date: Mapped[datetime | None] = mapped_column(TIMESTAMP(timezone=True), nullable=True)
    end_date: Mapped[datetime | None] = mapped_column(TIMESTAMP(timezone=True), nullable=True)
    target_type: Mapped[CampaignTargetType] = mapped_column(String(20), default=CampaignTargetType.ALL.value, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(default=func.now(), nullable=False)
