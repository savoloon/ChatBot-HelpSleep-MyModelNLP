from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.auth import (
    AuthRequest,
    RefreshRequest,
    RegisterRequest,
    RegisterResponse,
    TokenPairResponse,
    UserResponse,
)
from app.services.auth_service import (
    authenticate_user,
    build_token_pair,
    register_user,
    rotate_refresh_token,
)

router = APIRouter(tags=["auth"])


@router.post("/register", response_model=RegisterResponse, status_code=status.HTTP_201_CREATED)
def register(payload: RegisterRequest, db: Session = Depends(get_db)) -> RegisterResponse:
    try:
        user = register_user(db=db, email=payload.email, password=payload.password)
    except ValueError as err:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(err)) from err

    return RegisterResponse(user=UserResponse.model_validate(user), tokens=build_token_pair(user.id))


@router.post("/auth", response_model=TokenPairResponse)
def auth(payload: AuthRequest, db: Session = Depends(get_db)) -> TokenPairResponse:
    try:
        user = authenticate_user(db=db, email=payload.email, password=payload.password)
    except ValueError as err:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(err)) from err

    return build_token_pair(user.id)


@router.post("/refresh", response_model=TokenPairResponse)
def refresh(payload: RefreshRequest, db: Session = Depends(get_db)) -> TokenPairResponse:
    try:
        user = rotate_refresh_token(db=db, refresh_token=payload.refresh_token)
    except ValueError as err:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(err)) from err

    return build_token_pair(user.id)
