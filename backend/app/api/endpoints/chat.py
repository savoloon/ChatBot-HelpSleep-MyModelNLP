from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.dependencies.auth import get_current_user
from app.core.database import get_db
from app.models.user import User
from app.schemas.chat import ChatHistoryItem, ChatHistoryResponse
from app.services.chat_service import get_user_history

router = APIRouter(prefix="/chat", tags=["chat"])


@router.get("/history", response_model=ChatHistoryResponse)
def get_chat_history(
    days: int | None = Query(default=None, ge=1, le=15),
    limit: int | None = Query(default=None, ge=1, le=500),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> ChatHistoryResponse:
    rows = get_user_history(
        db=db,
        user_id=current_user.id,
        days=days,
        limit=limit,
    )
    items = [
        ChatHistoryItem(
            id=message.id,
            role=role_name,
            text=message.text,
            date=message.date,
        )
        for message, role_name in rows
    ]
    return ChatHistoryResponse(items=items)
