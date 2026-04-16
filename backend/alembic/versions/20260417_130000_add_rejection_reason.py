"""add_rejection_reason_to_appointments

Revision ID: d5e6f7a8b9c0
Revises: c4d5e6f7a8b9
Create Date: 2026-04-17 13:00:00.000000

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "d5e6f7a8b9c0"
down_revision: Union[str, None] = "c4d5e6f7a8b9"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "appointments",
        sa.Column("rejection_reason", sa.Text(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("appointments", "rejection_reason")
