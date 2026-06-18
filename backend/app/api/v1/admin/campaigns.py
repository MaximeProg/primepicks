from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc

from app.core.database import get_db
from app.core.dependencies import require_admin
from app.models.user import User
from app.models.campaign import Campaign
from app.schemas.campaign import CampaignCreate, CampaignUpdate, CampaignResponse

router = APIRouter(prefix="/admin/campaigns", tags=["Admin — Campagnes"])


@router.get("", response_model=list[CampaignResponse])
async def list_campaigns(
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    r = await db.execute(select(Campaign).order_by(desc(Campaign.created_at)))
    return r.scalars().all()


@router.post("", response_model=CampaignResponse, status_code=201)
async def create_campaign(
    data: CampaignCreate,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    campaign = Campaign(**data.model_dump())
    db.add(campaign)
    await db.commit()
    await db.refresh(campaign)
    return campaign


@router.patch("/{campaign_id}", response_model=CampaignResponse)
async def update_campaign(
    campaign_id: UUID,
    data: CampaignUpdate,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    r = await db.execute(select(Campaign).where(Campaign.id == campaign_id))
    campaign = r.scalar_one_or_none()
    if not campaign:
        raise HTTPException(404, "Campagne introuvable")
    for field, value in data.model_dump(exclude_none=True).items():
        setattr(campaign, field, value)
    await db.commit()
    await db.refresh(campaign)
    return campaign


@router.delete("/{campaign_id}", status_code=204)
async def delete_campaign(
    campaign_id: UUID,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    r = await db.execute(select(Campaign).where(Campaign.id == campaign_id))
    campaign = r.scalar_one_or_none()
    if not campaign:
        raise HTTPException(404, "Campagne introuvable")
    await db.delete(campaign)
    await db.commit()
