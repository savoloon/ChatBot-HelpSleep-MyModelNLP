from pydantic import BaseModel, Field


class MessageRequest(BaseModel):
    message: str = Field(..., min_length=1, description="User chat message")


class MessageResponse(BaseModel):
    response: str
    intent_id: int
    intent_name: str
    confidence: float
