from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc, func

from app.core.database import get_db
from app.core.dependencies import require_admin
from app.models.user import User
from app.models.admin_log import AdminLog
from app.schemas.admin_log import AdminLogResponse
from app.schemas.paginated import Paginated

router = APIRouter(prefix="/admin/logs", tags=["Admin — Historique"])


@router.get("", response_model=Paginated[AdminLogResponse])
async def list_logs(
    action: str | None = None,
    limit: int = Query(30, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    q = select(AdminLog)
    cq = select(AdminLog)
    if action:
        q = q.where(AdminLog.action.ilike(f"%{action}%"))
        cq = cq.where(AdminLog.action.ilike(f"%{action}%"))

    total_r = await db.execute(select(func.count()).select_from(cq.subquery()))
    total = total_r.scalar() or 0

    r = await db.execute(q.order_by(desc(AdminLog.created_at)).limit(limit).offset(offset))
    return Paginated(items=r.scalars().all(), total=total, limit=limit, offset=offset)
