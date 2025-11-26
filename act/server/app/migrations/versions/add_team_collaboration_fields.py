"""Add team collaboration fields to User model

Revision ID: team_collab_001
Revises: add_is_draft_001
Create Date: 2025-11-06 19:00:00

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = 'team_collab_001'
down_revision = 'add_is_draft_001'
branch_labels = None
depends_on = None


def upgrade():
    # Add team collaboration fields to users table
    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.add_column(sa.Column('last_activity', sa.DateTime(), nullable=True, server_default=sa.func.now()))
        batch_op.add_column(sa.Column('is_online', sa.Boolean(), nullable=True, server_default='false'))


def downgrade():
    # Remove team collaboration fields from users table
    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.drop_column('is_online')
        batch_op.drop_column('last_activity')
