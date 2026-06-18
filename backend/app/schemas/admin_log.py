from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from typing import Any


class AdminLogResponse(BaseModel):
    id: UUID
    admin_id: UUID | None = None
    action: str
    entity_type: str | None = None
    entity_id: str | None = None
    old_data: dict[str, Any] | None = None
    new_data: dict[str, Any] | None = None
    created_at: datetime

    model_config = {"from_attributes": True}
