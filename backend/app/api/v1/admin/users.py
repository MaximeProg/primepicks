from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc, func, or_

from app.core.database import get_db
from app.core.dependencies import require_admin
from app.core.audit import log_action
from app.models.user import User, UserRole
from app.schemas.user import UserAdminResponse
from app.schemas.paginated import Paginated
from app.services.notification_service import send_to_user, NotificationType

router = APIRouter(prefix="/admin/users", tags=["Admin — Utilisateurs"])


class UserAdminUpdate(BaseModel):
    role: UserRole | None = None
    is_active: bool | None = None


@router.get("", response_model=Paginated[UserAdminResponse])
async def list_users(
    search: str | None = None,
    role: UserRole | None = None,
    is_active: bool | None = None,
    limit: int = Query(20, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    query = select(User)
    if search:
        q = f"%{search}%"
        query = query.where(
            or_(User.email.ilike(q), User.full_name.ilike(q), User.phone.ilike(q))
        )
    if role is not None:
        query = query.where(User.role == role)
    if is_active is not None:
        query = query.where(User.is_active == is_active)

    total_r = await db.execute(select(func.count()).select_from(query.subquery()))
    total = total_r.scalar() or 0

    result = await db.execute(
        query.order_by(desc(User.created_at)).limit(limit).offset(offset)
    )
    return Paginated(items=result.scalars().all(), total=total, limit=limit, offset=offset)


@router.get("/{user_id}", response_model=UserAdminResponse)
async def get_user(
    user_id: UUID,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(404, "Utilisateur introuvable")
    return user


@router.patch("/{user_id}", response_model=UserAdminResponse)
async def update_user(
    user_id: UUID,
    data: UserAdminUpdate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(404, "Utilisateur introuvable")

    # Seul un SUPER_ADMIN peut attribuer ou retirer le rôle SUPER_ADMIN
    if data.role == UserRole.SUPER_ADMIN and admin.role != UserRole.SUPER_ADMIN:
        raise HTTPException(403, "Seul un Super Admin peut attribuer ce rôle")
    if user.role == UserRole.SUPER_ADMIN and admin.role != UserRole.SUPER_ADMIN:
        raise HTTPException(403, "Impossible de modifier un Super Admin")

    old = {"role": user.role.value, "is_active": user.is_active}

    role_changed = data.role is not None and data.role != user.role
    active_changed = data.is_active is not None and data.is_active != user.is_active

    if data.role is not None:
        user.role = data.role
    if data.is_active is not None:
        user.is_active = data.is_active

    new = {"role": user.role.value, "is_active": user.is_active}
    await log_action(db, admin, "UPDATE_USER", "user", user_id, old, new)

    # Push notification à l'utilisateur si son rôle a changé
    if role_changed:
        role_labels = {
            "ADMIN": "Administrateur",
            "SUPER_ADMIN": "Super Administrateur",
            "AFFILIATE": "Affilié",
            "USER": "Utilisateur",
        }
        label = role_labels.get(user.role.value, user.role.value)
        await send_to_user(
            db, user_id=user.id,
            title="Votre rôle a été mis à jour",
            body=f"Votre compte a été promu : {label}.",
            notif_type=NotificationType.ROLE_CHANGED,
            data={"new_role": user.role.value},
        )

    if active_changed and not user.is_active:
        await send_to_user(
            db, user_id=user.id,
            title="Compte suspendu",
            body="Votre compte a été temporairement suspendu. Contactez le support.",
            notif_type=NotificationType.PROMO,
        )

    await db.commit()
    await db.refresh(user)
    return user


@router.delete("/{user_id}", status_code=204)
async def delete_user(
    user_id: UUID,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    if str(user_id) == str(admin.id):
        raise HTTPException(400, "Impossible de supprimer votre propre compte")

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(404, "Utilisateur introuvable")

    if user.role == UserRole.SUPER_ADMIN and admin.role != UserRole.SUPER_ADMIN:
        raise HTTPException(403, "Impossible de supprimer un Super Admin")

    await log_action(db, admin, "DELETE_USER", "user", user_id,
                     old_data={"email": user.email, "role": user.role.value})
    await db.commit()  # commit le log avant la suppression (CASCADE supprime l'utilisateur)

    # Re-fetch après commit du log
    result2 = await db.execute(select(User).where(User.id == user_id))
    user2 = result2.scalar_one_or_none()
    if user2:
        await db.delete(user2)
        await db.commit()
