import asyncio
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
import cloudinary.uploader
from app.services import cloudinary_service as _cs  # ensures cloudinary is configured

from app.core.database import get_db
from app.core.dependencies import require_admin
from app.core.audit import log_action
from app.models.user import User
from app.models.banner import Banner
from app.schemas.banner import BannerCreate, BannerUpdate, BannerResponse

router = APIRouter(prefix="/admin/banners", tags=["Admin — Bannières"])


def _upload_banner_sync(content: bytes, banner_id: str) -> str:
    result = cloudinary.uploader.upload(
        content,
        folder="banners",
        public_id=f"banner_{banner_id}",
        overwrite=True,
        transformation=[
            {"width": 1200, "crop": "limit"},
            {"quality": "auto", "fetch_format": "auto"},
        ],
    )
    return result["secure_url"]


@router.get("", response_model=list[BannerResponse])
async def list_banners(
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    r = await db.execute(select(Banner).order_by(Banner.position))
    return r.scalars().all()


@router.post("", response_model=BannerResponse, status_code=201)
async def create_banner(
    data: BannerCreate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    banner = Banner(**data.model_dump())
    db.add(banner)
    await db.flush()
    await log_action(db, admin, "CREATE_BANNER", "banner", banner.id,
                     new_data={"title": banner.title})
    await db.commit()
    await db.refresh(banner)
    return banner


@router.patch("/{banner_id}", response_model=BannerResponse)
async def update_banner(
    banner_id: UUID,
    data: BannerUpdate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    r = await db.execute(select(Banner).where(Banner.id == banner_id))
    banner = r.scalar_one_or_none()
    if not banner:
        raise HTTPException(404, "Bannière introuvable")

    old = {"title": banner.title, "is_active": banner.is_active}
    for field, value in data.model_dump(exclude_none=True).items():
        setattr(banner, field, value)

    await log_action(db, admin, "UPDATE_BANNER", "banner", banner_id,
                     old_data=old, new_data=data.model_dump(exclude_none=True))
    await db.commit()
    await db.refresh(banner)
    return banner


@router.post("/{banner_id}/image", response_model=BannerResponse)
async def upload_banner_image(
    banner_id: UUID,
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    r = await db.execute(select(Banner).where(Banner.id == banner_id))
    banner = r.scalar_one_or_none()
    if not banner:
        raise HTTPException(404, "Bannière introuvable")

    content = await file.read()
    loop = asyncio.get_event_loop()
    url = await loop.run_in_executor(None, lambda: _upload_banner_sync(content, str(banner_id)))

    banner.image_url = url
    await log_action(db, admin, "UPLOAD_BANNER_IMAGE", "banner", banner_id)
    await db.commit()
    await db.refresh(banner)
    return banner


@router.delete("/{banner_id}", status_code=204)
async def delete_banner(
    banner_id: UUID,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    r = await db.execute(select(Banner).where(Banner.id == banner_id))
    banner = r.scalar_one_or_none()
    if not banner:
        raise HTTPException(404, "Bannière introuvable")

    await log_action(db, admin, "DELETE_BANNER", "banner", banner_id,
                     old_data={"title": banner.title})
    await db.delete(banner)
    await db.commit()
