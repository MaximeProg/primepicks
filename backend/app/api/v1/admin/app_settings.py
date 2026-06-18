import uuid
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.core.dependencies import require_admin
from app.core.audit import log_action
from app.models.user import User
from app.models.app_setting import AppSetting
from app.schemas.app_setting import AppSettingUpdate, AppSettingResponse

router = APIRouter(prefix="/admin/settings", tags=["Admin — Paramètres"])


async def _get_or_create(db: AsyncSession) -> AppSetting:
    r = await db.execute(select(AppSetting).limit(1))
    setting = r.scalar_one_or_none()
    if not setting:
        setting = AppSetting(id=uuid.uuid4())
        db.add(setting)
        await db.commit()
        await db.refresh(setting)
    return setting


@router.get("", response_model=AppSettingResponse)
async def get_settings(
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    return await _get_or_create(db)


@router.patch("", response_model=AppSettingResponse)
async def update_settings(
    data: AppSettingUpdate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    setting = await _get_or_create(db)
    changes = data.model_dump(exclude_none=True)
    for field, value in changes.items():
        setattr(setting, field, value)

    await log_action(db, admin, "UPDATE_SETTINGS", "app_setting", setting.id,
                     new_data=changes)
    await db.commit()
    await db.refresh(setting)
    return setting
