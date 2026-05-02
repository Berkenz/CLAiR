"""extend lawyer profile and user name fields

Revision ID: e6f7a8b9c0d1
Revises: d5e6f7a8b9c0
Create Date: 2026-05-02 12:00:00.000000

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "e6f7a8b9c0d1"
down_revision: Union[str, None] = "d5e6f7a8b9c0"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("users", sa.Column("middle_name", sa.String(length=100), nullable=True))
    op.add_column("users", sa.Column("name_suffix", sa.String(length=30), nullable=True))

    op.add_column(
        "lawyer_profiles",
        sa.Column("ibp_roll_number", sa.String(length=64), nullable=True),
    )
    op.add_column(
        "lawyer_profiles",
        sa.Column("year_admitted", sa.String(length=8), nullable=True),
    )
    op.add_column(
        "lawyer_profiles",
        sa.Column("ibp_chapter", sa.String(length=255), nullable=True),
    )
    op.add_column(
        "lawyer_profiles",
        sa.Column("ptr_number", sa.String(length=128), nullable=True),
    )
    op.add_column(
        "lawyer_profiles",
        sa.Column("mcle_compliance_number", sa.String(length=128), nullable=True),
    )
    op.add_column(
        "lawyer_profiles",
        sa.Column("law_school", sa.String(length=255), nullable=True),
    )
    op.add_column(
        "lawyer_profiles",
        sa.Column("firm_name", sa.String(length=255), nullable=True),
    )
    op.add_column(
        "lawyer_profiles",
        sa.Column("office_phone", sa.String(length=64), nullable=True),
    )
    op.add_column(
        "lawyer_profiles",
        sa.Column("mobile_phone", sa.String(length=64), nullable=True),
    )
    op.add_column(
        "lawyer_profiles",
        sa.Column("office_email", sa.String(length=255), nullable=True),
    )
    op.add_column(
        "lawyer_profiles",
        sa.Column("office_address", sa.Text(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("lawyer_profiles", "office_address")
    op.drop_column("lawyer_profiles", "office_email")
    op.drop_column("lawyer_profiles", "mobile_phone")
    op.drop_column("lawyer_profiles", "office_phone")
    op.drop_column("lawyer_profiles", "firm_name")
    op.drop_column("lawyer_profiles", "law_school")
    op.drop_column("lawyer_profiles", "mcle_compliance_number")
    op.drop_column("lawyer_profiles", "ptr_number")
    op.drop_column("lawyer_profiles", "ibp_chapter")
    op.drop_column("lawyer_profiles", "year_admitted")
    op.drop_column("lawyer_profiles", "ibp_roll_number")
    op.drop_column("users", "name_suffix")
    op.drop_column("users", "middle_name")
