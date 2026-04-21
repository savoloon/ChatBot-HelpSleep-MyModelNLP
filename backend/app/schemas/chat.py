from datetime import datetime

from pydantic import BaseModel


class ChatHistoryItem(BaseModel):
    id: int
    role: str
    text: str
    date: datetime


class ChatHistoryResponse(BaseModel):
    items: list[ChatHistoryItem]
