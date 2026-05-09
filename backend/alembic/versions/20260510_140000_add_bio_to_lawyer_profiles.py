"""add bio column to lawyer_profiles

Revision ID: e3f4a5b6c7d8
Revises: d2e3f4a5b6c7
Create Date: 2026-05-10 14:00:00.000000

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "e3f4a5b6c7d8"
down_revision: Union[str, None] = "d2e3f4a5b6c7"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "lawyer_profiles",
        sa.Column("bio", sa.Text, nullable=True),
    )


def downgrade() -> None:
    op.drop_column("lawyer_profiles", "bio")
