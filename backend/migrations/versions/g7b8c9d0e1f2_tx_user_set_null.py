"""transactions.user_id nullable + SET NULL on user delete

Revision ID: g7b8c9d0e1f2
Revises: f6a7b8c9d0e1
Create Date: 2026-06-18
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID as PGUUID

revision = "g7b8c9d0e1f2"
down_revision = "f6a7b8c9d0e1"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Rendre user_id nullable dans transactions
    op.alter_column("transactions", "user_id", nullable=True)
    # Changer FK CASCADE → SET NULL
    op.drop_constraint("fk_transactions_user_id_users", "transactions", type_="foreignkey")
    op.create_foreign_key(
        "fk_transactions_user_id_users",
        "transactions", "users",
        ["user_id"], ["id"],
        ondelete="SET NULL",
    )
    # Faire pareil pour subscriptions (garder l'historique d'abonnement)
    op.alter_column("subscriptions", "user_id", nullable=True)
    op.drop_constraint("fk_subscriptions_user_id_users", "subscriptions", type_="foreignkey")
    op.create_foreign_key(
        "fk_subscriptions_user_id_users",
        "subscriptions", "users",
        ["user_id"], ["id"],
        ondelete="SET NULL",
    )


def downgrade() -> None:
    op.drop_constraint("fk_subscriptions_user_id_users", "subscriptions", type_="foreignkey")
    op.create_foreign_key(
        "fk_subscriptions_user_id_users",
        "subscriptions", "users",
        ["user_id"], ["id"],
        ondelete="CASCADE",
    )
    op.alter_column("subscriptions", "user_id", nullable=False)

    op.drop_constraint("fk_transactions_user_id_users", "transactions", type_="foreignkey")
    op.create_foreign_key(
        "fk_transactions_user_id_users",
        "transactions", "users",
        ["user_id"], ["id"],
        ondelete="CASCADE",
    )
    op.alter_column("transactions", "user_id", nullable=False)
