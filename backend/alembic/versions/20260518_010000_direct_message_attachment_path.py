"""add attachment_path to direct_messages for signed URL support

Revision ID: 20260518_010000
Revises: b4c5d6e7f8a9
Create Date: 2026-05-18

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "c5d6e7f8a9b0"
down_revision: Union[str, None] = "b4c5d6e7f8a9"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "direct_messages",
        sa.Column("attachment_path", sa.String(512), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("direct_messages", "attachment_path")
