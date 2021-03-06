"""CoTags have better definition

Revision ID: 0893e5f2954f
Revises: 3577e4c322c6
Create Date: 2018-10-24 21:29:37.055252

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '0893e5f2954f'
down_revision = '3577e4c322c6'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.drop_constraint('tags_id_key', 'tags', type_='unique')
    op.drop_constraint('tags_tag_key', 'tags', type_='unique')
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.create_unique_constraint('tags_tag_key', 'tags', ['tag'])
    op.create_unique_constraint('tags_id_key', 'tags', ['id'])
    # ### end Alembic commands ###
