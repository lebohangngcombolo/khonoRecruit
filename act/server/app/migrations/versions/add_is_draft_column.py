"""Add is_draft column to applications

Revision ID: add_is_draft_001
Revises: 9467f4e67954
Create Date: 2025-11-06 16:50:00

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = 'add_is_draft_001'
down_revision = '9467f4e67954'
branch_labels = None
depends_on = None


def upgrade():
    # Add is_draft and draft_data columns to applications table
    with op.batch_alter_table('applications', schema=None) as batch_op:
        batch_op.add_column(sa.Column('is_draft', sa.Boolean(), nullable=True, server_default='false'))
        batch_op.add_column(sa.Column('draft_data', sa.JSON(), nullable=True))


def downgrade():
    # Remove is_draft and draft_data columns from applications table
    with op.batch_alter_table('applications', schema=None) as batch_op:
        batch_op.drop_column('draft_data')
        batch_op.drop_column('is_draft')
