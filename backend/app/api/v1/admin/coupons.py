from uuid import UUID
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc, func
from sqlalchemy.orm import selectinload

from app.core.database import get_db
from app.core.dependencies import require_admin
from app.core.audit import log_action
from app.models.user import User
from app.models.coupon import Coupon, CouponStatus
from app.models.coupon_match import CouponMatch
from app.schemas.coupon import CouponCreate, CouponUpdate, CouponStatusUpdate, CouponAdminResponse
from app.schemas.paginated import Paginated
from app.services.cloudinary_service import upload_coupon_image
from app.services.notification_service import broadcast_to_subscribers, NotificationType

router = APIRouter(prefix="/admin/coupons", tags=["Admin — Coupons"])


async def _reload(db: AsyncSession, coupon_id) -> Coupon:
    r = await db.execute(
        select(Coupon).options(selectinload(Coupon.matches)).where(Coupon.id == coupon_id)
    )
    return r.scalar_one()


@router.get("", response_model=Paginated[CouponAdminResponse])
async def list_all_coupons(
    search: str | None = None,
    status: CouponStatus | None = None,
    is_published: bool | None = None,
    limit: int = Query(20, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    query = select(Coupon)
    if search:
        query = query.where(Coupon.title.ilike(f"%{search}%"))
    if status is not None:
        query = query.where(Coupon.status == status)
    if is_published is not None:
        query = query.where(Coupon.is_published == is_published)

    total_r = await db.execute(select(func.count()).select_from(query.subquery()))
    total = total_r.scalar() or 0

    result = await db.execute(
        query.options(selectinload(Coupon.matches)).order_by(desc(Coupon.created_at)).limit(limit).offset(offset)
    )
    return Paginated(items=result.scalars().all(), total=total, limit=limit, offset=offset)


@router.post("", response_model=CouponAdminResponse, status_code=201)
async def create_coupon(
    data: CouponCreate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    coupon = Coupon(**data.model_dump(), created_by=admin.id)
    db.add(coupon)
    await db.flush()
    await log_action(db, admin, "CREATE_COUPON", "coupon", coupon.id,
                     new_data={"title": coupon.title, "coupon_type": coupon.coupon_type.value})
    await db.commit()
    return await _reload(db, coupon.id)


@router.patch("/{coupon_id}", response_model=CouponAdminResponse)
async def update_coupon(
    coupon_id: UUID,
    data: CouponUpdate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    result = await db.execute(select(Coupon).where(Coupon.id == coupon_id))
    coupon = result.scalar_one_or_none()
    if not coupon:
        raise HTTPException(404, "Coupon introuvable")

    old = {"title": coupon.title, "status": coupon.status.value}
    for field, value in data.model_dump(exclude_none=True).items():
        setattr(coupon, field, value)

    await log_action(db, admin, "UPDATE_COUPON", "coupon", coupon_id,
                     old_data=old, new_data=data.model_dump(exclude_none=True))
    await db.commit()
    return await _reload(db, coupon_id)


@router.delete("/{coupon_id}", status_code=204)
async def delete_coupon(
    coupon_id: UUID,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    result = await db.execute(select(Coupon).where(Coupon.id == coupon_id))
    coupon = result.scalar_one_or_none()
    if not coupon:
        raise HTTPException(404, "Coupon introuvable")

    await log_action(db, admin, "DELETE_COUPON", "coupon", coupon_id,
                     old_data={"title": coupon.title})
    await db.delete(coupon)
    await db.commit()


@router.post("/{coupon_id}/publish", response_model=CouponAdminResponse)
async def publish_coupon(
    coupon_id: UUID,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    result = await db.execute(select(Coupon).where(Coupon.id == coupon_id))
    coupon = result.scalar_one_or_none()
    if not coupon:
        raise HTTPException(404, "Coupon introuvable")
    if coupon.is_published:
        raise HTTPException(400, "Coupon déjà publié")

    coupon.is_published = True
    coupon.published_at = datetime.utcnow()

    await broadcast_to_subscribers(
        db,
        title=f"Nouveau coupon : {coupon.title}",
        body=f"Cote : {coupon.odds} — Connectez-vous pour voir l'analyse complète.",
        notif_type=NotificationType.NEW_COUPON,
        data={"coupon_id": str(coupon.id)},
    )
    await log_action(db, admin, "PUBLISH_COUPON", "coupon", coupon_id,
                     new_data={"title": coupon.title})
    await db.commit()
    return await _reload(db, coupon_id)


@router.patch("/{coupon_id}/status", response_model=CouponAdminResponse)
async def update_coupon_status(
    coupon_id: UUID,
    data: CouponStatusUpdate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    result = await db.execute(select(Coupon).where(Coupon.id == coupon_id))
    coupon = result.scalar_one_or_none()
    if not coupon:
        raise HTTPException(404, "Coupon introuvable")

    old_status = coupon.status.value
    coupon.status = data.status

    notif_map = {
        "WON":       (NotificationType.COUPON_WON,       "Coupon gagnant !",  f"{coupon.title} est un gagnant !"),
        "LOST":      (NotificationType.COUPON_LOST,      "Résultat coupon",   f"{coupon.title} — Perdu cette fois."),
        "CANCELLED": (NotificationType.COUPON_CANCELLED, "Coupon annulé",     f"{coupon.title} a été annulé."),
    }
    if data.status.value in notif_map and coupon.is_published:
        notif_type, title, body = notif_map[data.status.value]
        await broadcast_to_subscribers(db, title=title, body=body, notif_type=notif_type,
                                       data={"coupon_id": str(coupon.id)})

    await log_action(db, admin, "UPDATE_COUPON_STATUS", "coupon", coupon_id,
                     old_data={"status": old_status}, new_data={"status": data.status.value})
    await db.commit()
    return await _reload(db, coupon_id)


@router.post("/{coupon_id}/image", response_model=CouponAdminResponse)
async def upload_image(
    coupon_id: UUID,
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    result = await db.execute(select(Coupon).where(Coupon.id == coupon_id))
    coupon = result.scalar_one_or_none()
    if not coupon:
        raise HTTPException(404, "Coupon introuvable")

    coupon.image_url = await upload_coupon_image(file)
    await log_action(db, admin, "UPLOAD_COUPON_IMAGE", "coupon", coupon_id)
    await db.commit()
    return await _reload(db, coupon_id)
