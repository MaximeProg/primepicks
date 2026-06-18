from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.core.dependencies import require_admin
from app.models.user import User
from app.models.cms_page import CmsPage
from app.schemas.cms_page import CmsPageCreate, CmsPageUpdate, CmsPageResponse

router = APIRouter(prefix="/admin/pages", tags=["Admin — Pages CMS"])


@router.get("", response_model=list[CmsPageResponse])
async def list_pages(
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    r = await db.execute(select(CmsPage).order_by(CmsPage.slug))
    return r.scalars().all()


@router.post("", response_model=CmsPageResponse, status_code=201)
async def create_page(
    data: CmsPageCreate,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    r = await db.execute(select(CmsPage).where(CmsPage.slug == data.slug))
    if r.scalar_one_or_none():
        raise HTTPException(400, f"Un page avec le slug « {data.slug} » existe déjà")
    page = CmsPage(**data.model_dump())
    db.add(page)
    await db.commit()
    await db.refresh(page)
    return page


@router.get("/{page_id}", response_model=CmsPageResponse)
async def get_page(
    page_id: UUID,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    r = await db.execute(select(CmsPage).where(CmsPage.id == page_id))
    page = r.scalar_one_or_none()
    if not page:
        raise HTTPException(404, "Page introuvable")
    return page


@router.patch("/{page_id}", response_model=CmsPageResponse)
async def update_page(
    page_id: UUID,
    data: CmsPageUpdate,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    r = await db.execute(select(CmsPage).where(CmsPage.id == page_id))
    page = r.scalar_one_or_none()
    if not page:
        raise HTTPException(404, "Page introuvable")
    for field, value in data.model_dump(exclude_none=True).items():
        setattr(page, field, value)
    await db.commit()
    await db.refresh(page)
    return page


@router.delete("/{page_id}", status_code=204)
async def delete_page(
    page_id: UUID,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    r = await db.execute(select(CmsPage).where(CmsPage.id == page_id))
    page = r.scalar_one_or_none()
    if not page:
        raise HTTPException(404, "Page introuvable")
    await db.delete(page)
    await db.commit()
