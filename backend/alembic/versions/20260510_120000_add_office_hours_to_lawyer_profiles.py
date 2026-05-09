"""add office_hours JSONB column to lawyer_profiles

Revision ID: c1d2e3f4a5b6
Revises: b0c1d2e3f4a5
Create Date: 2026-05-10 12:00:00.000000

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import JSONB

revision: str = "c1d2e3f4a5b6"
down_revision: Union[str, None] = "b0c1d2e3f4a5"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "lawyer_profiles",
        sa.Column("office_hours", JSONB, nullable=True),
    )


def downgrade() -> None:
    op.drop_column("lawyer_profiles", "office_hours")
