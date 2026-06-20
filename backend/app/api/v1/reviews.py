from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.review import Review, ReviewStatus
from app.schemas.review import ReviewSubmit, ReviewPublicResponse

router = APIRouter(prefix="/reviews", tags=["Avis"])


def _masked_name(full_name: str | None) -> str | None:
    """'Jean Dupont' → 'Jean D.'"""
    if not full_name:
        return None
    parts = full_name.strip().split()
    if len(parts) == 1:
        return parts[0]
    return f"{parts[0]} {parts[-1][0]}."


@router.get("", response_model=list[ReviewPublicResponse])
async def list_approved_reviews(
    db: AsyncSession = Depends(get_db),
):
    """Retourne uniquement les avis validés par l'admin (visible sans auth)."""
    result = await db.execute(
        select(Review)
        .options(selectinload(Review.user))
        .where(Review.status == ReviewStatus.APPROVED)
        .order_by(Review.created_at.desc())
    )
    reviews = result.scalars().all()
    return [
        ReviewPublicResponse(
            id=r.id,
            rating=r.rating,
            comment=r.comment,
            author_name=_masked_name(r.user.full_name) if r.user else None,
            created_at=r.created_at,
        )
        for r in reviews
    ]


@router.get("/stats", response_model=dict)
async def review_stats(db: AsyncSession = Depends(get_db)):
    """Note moyenne et nombre total d'avis approuvés."""
    result = await db.execute(
        select(func.avg(Review.rating), func.count(Review.id))
        .where(Review.status == ReviewStatus.APPROVED)
    )
    avg_rating, count = result.one()
    return {
        "average_rating": round(float(avg_rating or 0), 1),
        "total_reviews": count,
    }


@router.post("", status_code=201)
async def submit_review(
    body: ReviewSubmit,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """L'utilisateur soumet un avis (en attente de validation admin)."""
    # Un seul avis par utilisateur
    existing = await db.execute(
        select(Review).where(Review.user_id == user.id)
    )
    if existing.scalar_one_or_none():
        raise HTTPException(400, "Vous avez déjà soumis un avis. Contactez le support pour le modifier.")

    review = Review(
        user_id=user.id,
        rating=body.rating,
        comment=body.comment,
        status=ReviewStatus.PENDING,
    )
    db.add(review)
    await db.commit()
    return {"message": "Avis soumis avec succès. Il sera visible après validation."}
