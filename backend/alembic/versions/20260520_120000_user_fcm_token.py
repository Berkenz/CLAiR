"""Add FCM device token on users for mobile push notifications."""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260520_120000"
down_revision: Union[str, None] = "c5d6e7f8a9b0"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column("fcm_token", sa.String(length=512), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("users", "fcm_token")
