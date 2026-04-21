from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api.dependencies.auth import get_current_user
from app.core.database import get_db
from app.models.user import User
from app.schemas.message import MessageRequest, MessageResponse
from app.services.chat_service import cleanup_old_messages, save_message
from app.services.intent_service import intent_service
from app.services.response_service import build_response

router = APIRouter(tags=["messages"])


@router.post("/messages", response_model=MessageResponse)
def handle_message(
    payload: MessageRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    clean_message = payload.message.strip()
    if not clean_message:
        raise HTTPException(status_code=400, detail="Message is empty.")

    cleanup_old_messages(db)

    try:
        intent_id, intent_name, confidence = intent_service.predict(clean_message)
    except Exception as err:  # noqa: BLE001
        raise HTTPException(status_code=500, detail=str(err)) from err

    response_text = build_response(intent_name=intent_name, message=clean_message)
    save_message(db=db, user_id=current_user.id, role_name="user", text=clean_message)
    save_message(db=db, user_id=current_user.id, role_name="assistant", text=response_text)

    return MessageResponse(
        response=response_text,
        intent_id=intent_id,
        intent_name=intent_name,
        confidence=confidence,
    )
