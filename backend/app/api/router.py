from fastapi import APIRouter

from app.api.endpoints.auth import router as auth_router
from app.api.endpoints.chat import router as chat_router
from app.api.endpoints.health import router as health_router
from app.api.endpoints.messages import router as messages_router

api_router = APIRouter()
api_router.include_router(health_router)
api_router.include_router(messages_router)
api_router.include_router(auth_router)
api_router.include_router(chat_router)
