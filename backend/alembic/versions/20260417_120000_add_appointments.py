"""add_appointments

Revision ID: a1b2c3d4e5f6
Revises: f1e2d3c4b5a6
Create Date: 2026-04-17 12:00:00.000000

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "c4d5e6f7a8b9"
down_revision: Union[str, None] = "f1e2d3c4b5a6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "appointments",
        sa.Column(
            "id",
            sa.UUID(),
            server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
        sa.Column("lawyer_profile_id", sa.UUID(), nullable=False),
        sa.Column("client_user_id", sa.UUID(), nullable=True),
        sa.Column("client_name", sa.String(length=255), nullable=False),
        sa.Column("appointment_date", sa.Date(), nullable=False),
        sa.Column("appointment_time", sa.String(length=5), nullable=False),
        sa.Column("appointment_type", sa.String(length=100), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column(
            "status",
            sa.String(length=20),
            server_default="pending",
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
            ["lawyer_profile_id"],
            ["lawyer_profiles.id"],
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["client_user_id"],
            ["users.id"],
            ondelete="SET NULL",
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_appointments_lawyer_profile_id"),
        "appointments",
        ["lawyer_profile_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_appointments_client_user_id"),
        "appointments",
        ["client_user_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_appointments_client_user_id"), table_name="appointments")
    op.drop_index(op.f("ix_appointments_lawyer_profile_id"), table_name="appointments")
    op.drop_table("appointments")
