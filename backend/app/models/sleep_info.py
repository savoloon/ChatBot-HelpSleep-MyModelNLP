from datetime import date

from sqlalchemy import Date, Float, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class SleepInfo(Base):
    __tablename__ = "sleep_info"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    duration: Mapped[float | None] = mapped_column(Float, nullable=True)
    schedule: Mapped[str | None] = mapped_column(String(32), nullable=True)
