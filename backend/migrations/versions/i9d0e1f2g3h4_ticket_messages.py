"""ticket_messages table

Revision ID: i9d0e1f2g3h4
Revises: h8c9d0e1f2g3
Create Date: 2026-06-18
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = 'i9d0e1f2g3h4'
down_revision = 'h8c9d0e1f2g3'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        'ticket_messages',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('ticket_id', postgresql.UUID(as_uuid=True),
                  sa.ForeignKey('support_tickets.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('sender_type', sa.String(10), nullable=False),   # USER | ADMIN
        sa.Column('sender_id', postgresql.UUID(as_uuid=True),
                  sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('content', sa.Text, nullable=True),
        sa.Column('media_url', sa.String(500), nullable=True),
        sa.Column('media_type', sa.String(10), nullable=True),     # IMAGE | VIDEO | FILE
        sa.Column('is_read', sa.Boolean, nullable=False, server_default='false'),
        sa.Column('created_at', sa.DateTime(timezone=True),
                  nullable=False, server_default=sa.text('now()')),
    )


def downgrade() -> None:
    op.drop_table('ticket_messages')
