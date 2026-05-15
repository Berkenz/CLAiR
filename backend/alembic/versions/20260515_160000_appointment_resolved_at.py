"""appointment resolved_at for messaging grace window

Revision ID: f2a3b4c5d6e7
Revises: e5f6a7b8c9d0
Create Date: 2026-05-15 16:00:00.000000

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy import text

revision: str = "f2a3b4c5d6e7"
down_revision: Union[str, None] = "e5f6a7b8c9d0"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "appointments",
        sa.Column("resolved_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.execute(
        text(
            "UPDATE appointments SET resolved_at = updated_at "
            "WHERE status = 'resolved' AND resolved_at IS NULL"
        )
    )


def downgrade() -> None:
    op.drop_column("appointments", "resolved_at")
