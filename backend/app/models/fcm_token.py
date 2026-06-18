import uuid
from datetime import datetime
from sqlalchemy import String, ForeignKey, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from app.models.base import Base


class FcmToken(Base):
    __tablename__ = "fcm_tokens"
    __table_args__ = (
        UniqueConstraint("user_id", "device_type", name="uq_fcm_tokens_user_device"),
    )

    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    token: Mapped[str] = mapped_column(String(500), nullable=False)
    device_type: Mapped[str] = mapped_column(String(20), nullable=False)  # WEB | IOS | ANDROID
    updated_at: Mapped[datetime] = mapped_column(default=func.now(), onupdate=func.now(), nullable=False)

    user: Mapped["User"] = relationship("User", back_populates="fcm_tokens")
