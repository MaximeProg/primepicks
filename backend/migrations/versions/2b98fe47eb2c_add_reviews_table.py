"""add_reviews_table

Revision ID: 2b98fe47eb2c
Revises: i9d0e1f2g3h4
Create Date: 2026-06-20 14:08:27.093601

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = '2b98fe47eb2c'
down_revision: Union[str, None] = 'i9d0e1f2g3h4'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'reviews',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('user_id', sa.UUID(), nullable=False),
        sa.Column('rating', sa.Integer(), nullable=False),
        sa.Column('comment', sa.Text(), nullable=True),
        sa.Column('status', sa.Enum('PENDING', 'APPROVED', 'REJECTED', name='reviewstatus'), nullable=False, server_default='PENDING'),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], name='fk_reviews_user_id_users', ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id', name='pk_reviews'),
    )
    op.create_index('ix_reviews_status', 'reviews', ['status'], unique=False)
    op.create_index('ix_reviews_user_id', 'reviews', ['user_id'], unique=False)


def downgrade() -> None:
    op.drop_index('ix_reviews_user_id', table_name='reviews')
    op.drop_index('ix_reviews_status', table_name='reviews')
    op.drop_table('reviews')
    op.execute("DROP TYPE IF EXISTS reviewstatus")
