from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.core.dependencies import require_admin
from app.models.user import User
from app.models.referral import Referral

router = APIRouter(prefix="/admin/referrals", tags=["Admin — Parrainage"])


class ManualReferralBody(BaseModel):
    referrer_email: str
    referred_email: str


@router.post("/manual", summary="Créer manuellement un lien de parrainage entre deux utilisateurs")
async def create_manual_referral(
    body: ManualReferralBody,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(require_admin),
):
    referrer_res = await db.execute(select(User).where(User.email == body.referrer_email))
    referrer = referrer_res.scalar_one_or_none()
    if not referrer:
        raise HTTPException(status_code=404, detail=f"Parrain introuvable: {body.referrer_email}")

    referred_res = await db.execute(select(User).where(User.email == body.referred_email))
    referred = referred_res.scalar_one_or_none()
    if not referred:
        raise HTTPException(status_code=404, detail=f"Filleul introuvable: {body.referred_email}")

    if referrer.id == referred.id:
        raise HTTPException(status_code=400, detail="Un utilisateur ne peut pas se parrainer lui-même")

    existing = await db.execute(
        select(Referral).where(
            Referral.referrer_id == referrer.id,
            Referral.referred_id == referred.id,
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Ce lien de parrainage existe déjà")

    referral = Referral(referrer_id=referrer.id, referred_id=referred.id)
    referred.referred_by = referrer.id
    db.add(referral)
    await db.commit()

    return {
        "message": "Lien de parrainage créé avec succès",
        "referrer": body.referrer_email,
        "referred": body.referred_email,
    }
