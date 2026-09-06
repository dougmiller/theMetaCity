"""add edo_media

Revision ID: 1788585883
Revises: 1787736765
Create Date: 2026-09-05 05:24:43.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '1788585883'
down_revision: Union[str, Sequence[str], None] = '1787736765'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_table(
        'edo_media',
        sa.Column('id', sa.UUID(), server_default=sa.text('uuidv7()'), nullable=False),
        sa.Column('edo_id', sa.UUID(), nullable=False),
        sa.Column('s3_key', sa.String(), nullable=False),
        sa.Column('content_type', sa.String(), nullable=True),
        sa.Column('kind', sa.String(), server_default='file', nullable=False),
        sa.Column('position', sa.Integer(), server_default='0', nullable=False),
        sa.ForeignKeyConstraint(
            ['edo_id'],
            ['everyday_ordinary.everyday_ordinary.id'],
            onupdate='CASCADE',
            ondelete='CASCADE',
        ),
        sa.PrimaryKeyConstraint('id'),
        schema='everyday_ordinary',
    )
    op.create_index(
        op.f('ix_everyday_ordinary_edo_media_edo_id'),
        'edo_media',
        ['edo_id'],
        unique=False,
        schema='everyday_ordinary',
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index(
        op.f('ix_everyday_ordinary_edo_media_edo_id'),
        table_name='edo_media',
        schema='everyday_ordinary',
    )
    op.drop_table('edo_media', schema='everyday_ordinary')
