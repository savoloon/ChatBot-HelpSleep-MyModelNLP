from datetime import date

from pydantic import BaseModel


class SleepInfoItem(BaseModel):
    id: int
    user_id: int
    date: date
    duration: float | None
    schedule: str | None


class SleepInfoHistoryResponse(BaseModel):
    items: list[SleepInfoItem]
