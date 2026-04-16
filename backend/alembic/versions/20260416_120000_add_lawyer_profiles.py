"""add_lawyer_profiles

Revision ID: f1e2d3c4b5a6
Revises: ada5fce63fd7
Create Date: 2026-04-16 12:00:00.000000

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "f1e2d3c4b5a6"
down_revision: Union[str, None] = "ada5fce63fd7"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "lawyer_profiles",
        sa.Column(
            "id",
            sa.UUID(),
            server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
        sa.Column("user_id", sa.UUID(), nullable=False),
        sa.Column("display_name", sa.String(length=255), nullable=True),
        sa.Column("designation", sa.String(length=255), nullable=True),
        sa.Column(
            "practice_areas",
            postgresql.ARRAY(sa.String()),
            nullable=True,
        ),
        sa.Column(
            "must_change_password",
            sa.Boolean(),
            server_default="true",
            nullable=False,
        ),
        sa.Column(
            "is_profile_complete",
            sa.Boolean(),
            server_default="false",
            nullable=False,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=True,
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id"),
    )
    op.create_index(
        op.f("ix_lawyer_profiles_user_id"),
        "lawyer_profiles",
        ["user_id"],
        unique=True,
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_lawyer_profiles_user_id"), table_name="lawyer_profiles")
    op.drop_table("lawyer_profiles")
