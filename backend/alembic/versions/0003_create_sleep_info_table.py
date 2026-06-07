"""create sleep_info table

Revision ID: 0003_create_sleep_info_table
Revises: 0002_create_roles_and_messages
Create Date: 2026-04-17 01:10:00.000000

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = "0003_create_sleep_info_table"
down_revision: Union[str, Sequence[str], None] = "0002_create_roles_and_messages"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "sleep_info",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("date", sa.Date(), nullable=False),
        sa.Column("duration", sa.Float(), nullable=True),
        sa.Column("schedule", sa.String(length=32), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_sleep_info_date"), "sleep_info", ["date"], unique=False)
    op.create_index(op.f("ix_sleep_info_id"), "sleep_info", ["id"], unique=False)
    op.create_index(op.f("ix_sleep_info_user_id"), "sleep_info", ["user_id"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_sleep_info_user_id"), table_name="sleep_info")
    op.drop_index(op.f("ix_sleep_info_id"), table_name="sleep_info")
    op.drop_index(op.f("ix_sleep_info_date"), table_name="sleep_info")
    op.drop_table("sleep_info")
