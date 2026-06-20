from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.core.database import get_db
from app.core.dependencies import require_admin
from app.models.review import Review, ReviewStatus
from app.schemas.review import ReviewAdminResponse, ReviewAdminUpdate

router = APIRouter(prefix="/admin/reviews", tags=["Admin — Avis"])


def _author_name(full_name: str | None) -> str | None:
    if not full_name:
        return None
    parts = full_name.strip().split()
    return f"{parts[0]} {parts[-1][0]}." if len(parts) > 1 else parts[0]


@router.get("", response_model=list[ReviewAdminResponse])
async def list_all_reviews(
    status: ReviewStatus | None = None,
    db: AsyncSession = Depends(get_db),
    _admin=Depends(require_admin),
):
    """Liste tous les avis avec filtre optionnel par statut."""
    q = select(Review).options(selectinload(Review.user)).order_by(Review.created_at.desc())
    if status:
        q = q.where(Review.status == status)
    result = await db.execute(q)
    reviews = result.scalars().all()
    return [
        ReviewAdminResponse(
            id=r.id,
            user_id=r.user_id,
            author_name=_author_name(r.user.full_name if r.user else None),
            author_email=r.user.email if r.user else None,
            rating=r.rating,
            comment=r.comment,
            status=r.status,
            created_at=r.created_at,
        )
        for r in reviews
    ]


@router.patch("/{review_id}", response_model=ReviewAdminResponse)
async def update_review_status(
    review_id: UUID,
    body: ReviewAdminUpdate,
    db: AsyncSession = Depends(get_db),
    _admin=Depends(require_admin),
):
    """Approuver ou rejeter un avis."""
    result = await db.execute(
        select(Review).options(selectinload(Review.user)).where(Review.id == review_id)
    )
    review = result.scalar_one_or_none()
    if not review:
        raise HTTPException(404, "Avis introuvable")

    review.status = body.status
    await db.commit()
    await db.refresh(review)

    return ReviewAdminResponse(
        id=review.id,
        user_id=review.user_id,
        author_name=_author_name(review.user.full_name if review.user else None),
        author_email=review.user.email if review.user else None,
        rating=review.rating,
        comment=review.comment,
        status=review.status,
        created_at=review.created_at,
    )
