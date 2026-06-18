from sqlalchemy.ext.asyncio import AsyncSession
from app.models.admin_log import AdminLog
from app.models.user import User


async def log_action(
    db: AsyncSession,
    admin: User,
    action: str,
    entity_type: str | None = None,
    entity_id=None,
    old_data: dict | None = None,
    new_data: dict | None = None,
) -> None:
    """Enregistre une action admin. Appeler avant db.commit()."""
    db.add(AdminLog(
        admin_id=admin.id,
        action=action,
        entity_type=entity_type,
        entity_id=str(entity_id) if entity_id is not None else None,
        old_data=old_data,
        new_data=new_data,
    ))
