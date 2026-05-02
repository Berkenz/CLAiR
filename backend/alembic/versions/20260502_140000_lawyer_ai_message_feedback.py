"""lawyer_ai_message_feedback table

Revision ID: f7a8b9c0d1e2
Revises: e6f7a8b9c0d1
Create Date: 2026-05-02 14:00:00.000000

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "f7a8b9c0d1e2"
down_revision: Union[str, None] = "e6f7a8b9c0d1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "lawyer_ai_message_feedback",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
        sa.Column("lawyer_user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("message_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("feedback_type", sa.String(length=20), nullable=False),
        sa.Column("issue_codes", postgresql.ARRAY(sa.String()), nullable=True),
        sa.Column("comment", sa.Text(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["lawyer_user_id"],
            ["users.id"],
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["message_id"],
            ["messages.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "lawyer_user_id",
            "message_id",
            name="uq_lawyer_ai_feedback_lawyer_message",
        ),
    )
    op.create_index(
        op.f("ix_lawyer_ai_message_feedback_lawyer_user_id"),
        "lawyer_ai_message_feedback",
        ["lawyer_user_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_lawyer_ai_message_feedback_message_id"),
        "lawyer_ai_message_feedback",
        ["message_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(
        op.f("ix_lawyer_ai_message_feedback_message_id"),
        table_name="lawyer_ai_message_feedback",
    )
    op.drop_index(
        op.f("ix_lawyer_ai_message_feedback_lawyer_user_id"),
        table_name="lawyer_ai_message_feedback",
    )
    op.drop_table("lawyer_ai_message_feedback")
