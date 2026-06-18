"""cascade user fks: ON DELETE CASCADE for NOT NULL, SET NULL for nullable

Revision ID: f6a7b8c9d0e1
Revises: e5f6a7b8c9d0
Create Date: 2026-06-18
"""
from alembic import op

revision = "f6a7b8c9d0e1"
down_revision = "e5f6a7b8c9d0"
branch_labels = None
depends_on = None

# (constraint_name, table, column, ref_table, ref_col, ondelete)
CASCADE_FKS = [
    ("fk_fcm_tokens_user_id_users",              "fcm_tokens",            "user_id",   "CASCADE"),
    ("fk_subscriptions_user_id_users",           "subscriptions",         "user_id",   "CASCADE"),
    ("fk_transactions_user_id_users",            "transactions",          "user_id",   "CASCADE"),
    ("fk_loyalty_transactions_user_id_users",    "loyalty_transactions",  "user_id",   "CASCADE"),
    ("fk_affiliates_user_id_users",              "affiliates",            "user_id",   "CASCADE"),
    ("fk_affiliate_conversions_user_id_users",   "affiliate_conversions", "user_id",   "CASCADE"),
    ("fk_referrals_referred_id_users",           "referrals",             "referred_id", "CASCADE"),
    # Nullable — SET NULL
    ("fk_referrals_referrer_id_users",           "referrals",             "referrer_id", "SET NULL"),
    ("fk_notification_logs_user_id_users",       "notification_logs",     "user_id",   "SET NULL"),
    ("fk_coupons_created_by_users",              "coupons",               "created_by", "SET NULL"),
    ("fk_users_referred_by_users",               "users",                 "referred_by", "SET NULL"),
]


def upgrade() -> None:
    for constraint, table, column, ondelete in CASCADE_FKS:
        op.drop_constraint(constraint, table, type_="foreignkey")
        op.create_foreign_key(
            constraint, table, "users",
            [column], ["id"],
            ondelete=ondelete,
        )


def downgrade() -> None:
    for constraint, table, column, _ in CASCADE_FKS:
        op.drop_constraint(constraint, table, type_="foreignkey")
        op.create_foreign_key(
            constraint, table, "users",
            [column], ["id"],
        )
