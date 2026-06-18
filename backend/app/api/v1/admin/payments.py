import csv
import io
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc, func

from app.core.database import get_db
from app.core.dependencies import require_admin
from app.core.audit import log_action
from app.models.user import User
from app.models.transaction import Transaction, TransactionStatus
from app.schemas.payment import TransactionResponse
from app.schemas.paginated import Paginated

router = APIRouter(prefix="/admin/payments", tags=["Admin — Paiements"])


@router.get("", response_model=Paginated[TransactionResponse])
async def list_transactions(
    status: TransactionStatus | None = None,
    limit: int = Query(20, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    query = select(Transaction)
    if status:
        query = query.where(Transaction.status == status)

    total_r = await db.execute(select(func.count()).select_from(query.subquery()))
    total = total_r.scalar() or 0

    result = await db.execute(
        query.order_by(desc(Transaction.created_at)).limit(limit).offset(offset)
    )
    return Paginated(items=result.scalars().all(), total=total, limit=limit, offset=offset)


@router.get("/export/csv")
async def export_csv(
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    result = await db.execute(
        select(Transaction).order_by(desc(Transaction.created_at)).limit(5000)
    )
    transactions = result.scalars().all()

    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["ID", "User ID", "Plan ID", "Montant", "Devise", "Statut", "FedaPay ID", "Payé le", "Créé le"])
    for t in transactions:
        writer.writerow([
            str(t.id), str(t.user_id or ""), str(t.plan_id or ""),
            float(t.amount), t.currency, t.status.value,
            t.fedapay_id or "",
            t.paid_at.isoformat() if t.paid_at else "",
            t.created_at.isoformat(),
        ])

    output.seek(0)
    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=transactions.csv"},
    )


@router.delete("/{transaction_id}", status_code=204)
async def delete_transaction(
    transaction_id: UUID,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
):
    result = await db.execute(select(Transaction).where(Transaction.id == transaction_id))
    tx = result.scalar_one_or_none()
    if not tx:
        raise HTTPException(404, "Transaction introuvable")

    await log_action(db, admin, "DELETE_TRANSACTION", "transaction", transaction_id,
                     old_data={"amount": float(tx.amount), "status": tx.status.value,
                               "user_id": str(tx.user_id) if tx.user_id else None})
    await db.delete(tx)
    await db.commit()
