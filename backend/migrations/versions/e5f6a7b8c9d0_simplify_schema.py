"""simplify schema: remove financial fields, simplify coupon_matches, drop unused tables

Revision ID: e5f6a7b8c9d0
Revises: d4e5f6a7b8c9
Create Date: 2026-06-18
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID as PGUUID

revision = "e5f6a7b8c9d0"
down_revision = "d4e5f6a7b8c9"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 1. Remove financial fields from coupons
    op.drop_column("coupons", "stake_amount")
    op.drop_column("coupons", "expected_return")
    op.drop_column("coupons", "roi")

    # 2. Rebuild coupon_matches with simplified schema (drop & recreate)
    op.drop_table("coupon_matches")
    op.create_table(
        "coupon_matches",
        sa.Column("id", PGUUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("coupon_id", PGUUID(as_uuid=True), sa.ForeignKey("coupons.id", ondelete="CASCADE"), nullable=False),
        sa.Column("match_name", sa.String(255), nullable=False),
        sa.Column("prediction", sa.String(255), nullable=False),
        sa.Column("odd", sa.Numeric(6, 2), nullable=True),
        sa.Column("created_at", sa.DateTime, server_default=sa.text("now()"), nullable=False),
    )
    op.create_index("ix_coupon_matches_coupon_id", "coupon_matches", ["coupon_id"])

    # 3. Drop unused tables
    op.drop_table("coupon_favorites")
    op.drop_table("coupon_views")
    op.drop_table("campaigns")
    op.drop_table("cms_pages")


def downgrade() -> None:
    # Restore financial columns
    op.add_column("coupons", sa.Column("roi", sa.Numeric(6, 2), nullable=True))
    op.add_column("coupons", sa.Column("expected_return", sa.Numeric(12, 2), nullable=True))
    op.add_column("coupons", sa.Column("stake_amount", sa.Numeric(12, 2), nullable=True))

    # Restore old coupon_matches
    op.drop_index("ix_coupon_matches_coupon_id", "coupon_matches")
    op.drop_table("coupon_matches")
    op.create_table(
        "coupon_matches",
        sa.Column("id", PGUUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("coupon_id", PGUUID(as_uuid=True), sa.ForeignKey("coupons.id", ondelete="CASCADE"), nullable=False),
        sa.Column("home_team", sa.String(100), nullable=False),
        sa.Column("away_team", sa.String(100), nullable=False),
        sa.Column("competition", sa.String(100), nullable=True),
        sa.Column("prediction", sa.String(255), nullable=False),
        sa.Column("odd", sa.Numeric(6, 2), nullable=True),
        sa.Column("match_date", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime, server_default=sa.text("now()"), nullable=False),
    )

    # Restore cms_pages, campaigns, coupon_views, coupon_favorites
    op.create_table(
        "cms_pages",
        sa.Column("id", PGUUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("slug", sa.String(100), nullable=False, unique=True),
        sa.Column("title", sa.String(255), nullable=False),
        sa.Column("content", sa.Text, nullable=True),
        sa.Column("is_published", sa.Boolean, server_default="false", nullable=False),
        sa.Column("created_at", sa.DateTime, server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime, server_default=sa.text("now()"), nullable=False),
    )
    op.create_table(
        "campaigns",
        sa.Column("id", PGUUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("title", sa.String(255), nullable=False),
        sa.Column("description", sa.Text, nullable=True),
        sa.Column("start_date", sa.DateTime(timezone=True), nullable=True),
        sa.Column("end_date", sa.DateTime(timezone=True), nullable=True),
        sa.Column("target_type", sa.String(20), server_default="ALL", nullable=False),
        sa.Column("is_active", sa.Boolean, server_default="true", nullable=False),
        sa.Column("created_at", sa.DateTime, server_default=sa.text("now()"), nullable=False),
    )
    op.create_table(
        "coupon_views",
        sa.Column("id", PGUUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("coupon_id", PGUUID(as_uuid=True), sa.ForeignKey("coupons.id", ondelete="CASCADE"), nullable=False),
        sa.Column("user_id", PGUUID(as_uuid=True), nullable=True),
        sa.Column("viewed_at", sa.DateTime, server_default=sa.text("now()"), nullable=False),
    )
    op.create_table(
        "coupon_favorites",
        sa.Column("id", PGUUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("coupon_id", PGUUID(as_uuid=True), sa.ForeignKey("coupons.id", ondelete="CASCADE"), nullable=False),
        sa.Column("user_id", PGUUID(as_uuid=True), nullable=False),
        sa.Column("created_at", sa.DateTime, server_default=sa.text("now()"), nullable=False),
    )
