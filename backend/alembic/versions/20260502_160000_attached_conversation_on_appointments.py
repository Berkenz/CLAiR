"""attached conversation id on appointments

Revision ID: a8b9c0d1e2f3
Revises: f7a8b9c0d1e2
Create Date: 2026-05-02 16:00:00.000000

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "a8b9c0d1e2f3"
down_revision: Union[str, None] = "f7a8b9c0d1e2"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "appointments",
        sa.Column(
            "attached_conversation_id",
            postgresql.UUID(as_uuid=True),
            nullable=True,
        ),
    )
    op.create_foreign_key(
        "fk_appointments_attached_conversation_id_conversations",
        "appointments",
        "conversations",
        ["attached_conversation_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_index(
        op.f("ix_appointments_attached_conversation_id"),
        "appointments",
        ["attached_conversation_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(
        op.f("ix_appointments_attached_conversation_id"),
        table_name="appointments",
    )
    op.drop_constraint(
        "fk_appointments_attached_conversation_id_conversations",
        "appointments",
        type_="foreignkey",
    )
    op.drop_column("appointments", "attached_conversation_id")
