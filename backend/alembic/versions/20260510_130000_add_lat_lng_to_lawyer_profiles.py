"""add latitude and longitude columns to lawyer_profiles

Revision ID: d2e3f4a5b6c7
Revises: c1d2e3f4a5b6
Create Date: 2026-05-10 13:00:00.000000

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "d2e3f4a5b6c7"
down_revision: Union[str, None] = "c1d2e3f4a5b6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "lawyer_profiles",
        sa.Column("latitude", sa.Float, nullable=True),
    )
    op.add_column(
        "lawyer_profiles",
        sa.Column("longitude", sa.Float, nullable=True),
    )


def downgrade() -> None:
    op.drop_column("lawyer_profiles", "longitude")
    op.drop_column("lawyer_profiles", "latitude")
