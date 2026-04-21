from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_refresh_token,
    hash_password,
    verify_password,
)
from app.models.user import User
from app.schemas.auth import TokenPairResponse


def register_user(db: Session, email: str, password: str) -> User:
    normalized_email = email.strip().lower()
    existing_user = db.scalar(select(User).where(User.email == normalized_email))
    if existing_user is not None:
        raise ValueError("User with this email already exists.")

    user = User(email=normalized_email, password=hash_password(password))
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def authenticate_user(db: Session, email: str, password: str) -> User:
    normalized_email = email.strip().lower()
    user = db.scalar(select(User).where(User.email == normalized_email))
    if user is None or not verify_password(password, user.password):
        raise ValueError("Invalid email or password.")
    return user


def rotate_refresh_token(db: Session, refresh_token: str) -> User:
    user_id = decode_refresh_token(refresh_token)
    user = db.get(User, user_id)
    if user is None:
        raise ValueError("User not found.")
    return user


def build_token_pair(user_id: int) -> TokenPairResponse:
    return TokenPairResponse(
        access_token=create_access_token(user_id),
        refresh_token=create_refresh_token(user_id),
    )
