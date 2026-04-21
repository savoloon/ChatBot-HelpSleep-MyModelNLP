from datetime import UTC, datetime, timedelta

from jose import JWTError, jwt
from passlib.context import CryptContext

from app.core.config import get_settings

ALGORITHM = "HS256"
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
settings = get_settings()


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(user_id: int) -> str:
    expires_in_seconds = _parse_expires_in(settings.jwt_expires_in)
    payload = {
        "sub": str(user_id),
        "type": "access",
        "exp": datetime.now(UTC) + timedelta(seconds=expires_in_seconds),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=ALGORITHM)


def create_refresh_token(user_id: int) -> str:
    expires_in_seconds = _parse_expires_in(settings.jwt_refresh_expires_in)
    payload = {
        "sub": str(user_id),
        "type": "refresh",
        "exp": datetime.now(UTC) + timedelta(seconds=expires_in_seconds),
    }
    return jwt.encode(payload, settings.jwt_refresh_secret, algorithm=ALGORITHM)


def decode_refresh_token(token: str) -> int:
    try:
        payload = jwt.decode(
            token,
            settings.jwt_refresh_secret,
            algorithms=[ALGORITHM],
        )
    except JWTError as err:
        raise ValueError("Invalid refresh token.") from err

    if payload.get("type") != "refresh":
        raise ValueError("Invalid token type.")

    subject = payload.get("sub")
    if subject is None:
        raise ValueError("Token subject is missing.")

    try:
        return int(subject)
    except ValueError as err:
        raise ValueError("Invalid token subject.") from err


def decode_access_token(token: str) -> int:
    try:
        payload = jwt.decode(
            token,
            settings.jwt_secret,
            algorithms=[ALGORITHM],
        )
    except JWTError as err:
        raise ValueError("Invalid access token.") from err

    if payload.get("type") != "access":
        raise ValueError("Invalid token type.")

    subject = payload.get("sub")
    if subject is None:
        raise ValueError("Token subject is missing.")

    try:
        return int(subject)
    except ValueError as err:
        raise ValueError("Invalid token subject.") from err


def _parse_expires_in(value: str) -> int:
    cleaned = value.strip().lower()
    if cleaned.isdigit():
        return int(cleaned)

    if cleaned.endswith("m") and cleaned[:-1].isdigit():
        return int(cleaned[:-1]) * 60
    if cleaned.endswith("h") and cleaned[:-1].isdigit():
        return int(cleaned[:-1]) * 3600
    if cleaned.endswith("d") and cleaned[:-1].isdigit():
        return int(cleaned[:-1]) * 86400

    raise ValueError(
        "Invalid JWT expiration format. Use seconds or suffixes: m/h/d (e.g. 900, 15m, 24h)."
    )
