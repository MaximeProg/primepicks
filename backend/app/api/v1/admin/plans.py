from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.core.dependencies import require_admin
from app.core.audit import log_action
from app.models.user import User
from app.models.plan import Plan
from app.schemas.plan import PlanCreate, PlanUpdate, PlanResponse

router = APIRouter(prefix="/admin/plans", tags=["Admin — Plans"])


@router.get("", response_model=list[PlanResponse])
async def list_all_plans(
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    result = await db.execute(select(Plan).order_by(Plan.price))
    return result.scalars().all()


@router.post("", response_model=PlanResponse, status_code=201)
async def create_plan(
    data: PlanCreate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    existing = await db.execute(select(Plan).where(Plan.slug == data.slug))
    if existing.scalar_one_or_none():
        raise HTTPException(400, f"Un plan avec le slug '{data.slug}' existe déjà")

    plan = Plan(**data.model_dump())
    db.add(plan)
    await db.flush()
    await log_action(db, admin, "CREATE_PLAN", "plan", plan.id,
                     new_data={"name": plan.name, "price": float(plan.price)})
    await db.commit()
    await db.refresh(plan)
    return plan


@router.patch("/{plan_id}", response_model=PlanResponse)
async def update_plan(
    plan_id: UUID,
    data: PlanUpdate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    result = await db.execute(select(Plan).where(Plan.id == plan_id))
    plan = result.scalar_one_or_none()
    if not plan:
        raise HTTPException(404, "Plan introuvable")

    old = {"name": plan.name, "price": float(plan.price), "is_active": plan.is_active}
    for field, value in data.model_dump(exclude_none=True).items():
        setattr(plan, field, value)

    await log_action(db, admin, "UPDATE_PLAN", "plan", plan_id,
                     old_data=old, new_data=data.model_dump(exclude_none=True))
    await db.commit()
    await db.refresh(plan)
    return plan


@router.delete("/{plan_id}", status_code=204)
async def deactivate_plan(
    plan_id: UUID,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    result = await db.execute(select(Plan).where(Plan.id == plan_id))
    plan = result.scalar_one_or_none()
    if not plan:
        raise HTTPException(404, "Plan introuvable")

    plan.is_active = False
    await log_action(db, admin, "DEACTIVATE_PLAN", "plan", plan_id,
                     old_data={"name": plan.name, "is_active": True})
    await db.commit()
