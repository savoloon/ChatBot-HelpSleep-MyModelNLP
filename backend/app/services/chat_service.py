from datetime import UTC, datetime, timedelta

from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from app.models.message import Message
from app.models.role import Role

RETENTION_DAYS = 15


def cleanup_old_messages(db: Session) -> None:
    threshold = datetime.now(UTC) - timedelta(days=RETENTION_DAYS)
    db.execute(delete(Message).where(Message.date < threshold))
    db.commit()


def save_message(db: Session, user_id: int, role_name: str, text: str) -> Message:
    role_id = _get_role_id(db, role_name)
    message = Message(user_id=user_id, role_id=role_id, text=text)
    db.add(message)
    db.commit()
    db.refresh(message)
    return message


def get_user_history(
    db: Session,
    user_id: int,
    days: int | None = None,
    limit: int | None = None,
) -> list[tuple[Message, str]]:
    cleanup_old_messages(db)

    stmt = (
        select(Message, Role.name)
        .join(Role, Role.id == Message.role_id)
        .where(Message.user_id == user_id)
        .order_by(Message.date.desc())
    )

    if days is not None:
        cutoff = datetime.now(UTC) - timedelta(days=days)
        stmt = stmt.where(Message.date >= cutoff)

    if limit is not None:
        stmt = stmt.limit(limit)

    return list(db.execute(stmt).all())


def _get_role_id(db: Session, role_name: str) -> int:
    role = db.scalar(select(Role).where(Role.name == role_name))
    if role is None:
        raise ValueError(f"Role '{role_name}' not found.")
    return role.id
