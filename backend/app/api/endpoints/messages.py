from fastapi import APIRouter, HTTPException
from random import choice

from app.core.constants import INTENT_RESPONSES
from app.schemas.message import MessageRequest, MessageResponse
from app.services.intent_service import intent_service

router = APIRouter(tags=["messages"])


@router.post("/messages", response_model=MessageResponse)
def handle_message(payload: MessageRequest) -> MessageResponse:
    clean_message = payload.message.strip()
    if not clean_message:
        raise HTTPException(status_code=400, detail="Message is empty.")

    try:
        intent_id, intent_name, confidence = intent_service.predict(clean_message)
    except Exception as err:  # noqa: BLE001
        raise HTTPException(status_code=500, detail=str(err)) from err

    response_text = choice(
        INTENT_RESPONSES.get(intent_name, INTENT_RESPONSES["other"])
    )

    return MessageResponse(
        response=response_text,
        intent_id=intent_id,
        intent_name=intent_name,
        confidence=confidence,
    )
