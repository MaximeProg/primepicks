from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from app.models.support_ticket import TicketStatus


class SupportTicketCreate(BaseModel):
    subject: str
    message: str


class SupportTicketAdminUpdate(BaseModel):
    status: TicketStatus | None = None
    admin_reply: str | None = None


class SupportTicketResponse(BaseModel):
    id: UUID
    user_id: UUID
    subject: str
    message: str
    status: TicketStatus
    admin_reply: str | None = None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
