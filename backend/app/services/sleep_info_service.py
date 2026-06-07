from datetime import date, datetime, timedelta, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.sleep_info import SleepInfo
from app.services.response_service import (
    extract_duration_hours,
    extract_schedule,
    format_schedule,
)


def save_sleep_info_from_intent(
    db: Session,
    user_id: int,
    intent_name: str,
    message_text: str,
) -> None:
    today = date.today()

    if intent_name == "sleep_duration_report":
        duration = extract_duration_hours(message_text)
        if duration is None:
            return
        db.add(
            SleepInfo(
                user_id=user_id,
                date=today,
                duration=duration,
                schedule=None,
            )
        )
        db.commit()
        return

    if intent_name == "sleep_schedule_report":
        schedule = extract_schedule(message_text)
        if schedule is None:
            return
        bedtime_minutes = int(schedule["bedtime_minutes"])
        wake_minutes = int(schedule["wake_minutes"])
        duration_hours = float(schedule["duration_hours"])
        db.add(
            SleepInfo(
                user_id=user_id,
                date=today,
                duration=duration_hours,
                schedule=format_schedule(bedtime_minutes, wake_minutes),
            )
        )
        db.commit()


def get_sleep_info_history(
    db: Session,
    user_id: int,
    period: str | None = None,
    custom_days: int | None = None,
    limit: int | None = None,
) -> list[SleepInfo]:
    cutoff = _resolve_cutoff(period=period, custom_days=custom_days)
    stmt = select(SleepInfo).where(SleepInfo.user_id == user_id)
    if cutoff is not None:
        stmt = stmt.where(SleepInfo.date >= cutoff)
    stmt = stmt.order_by(SleepInfo.date.desc(), SleepInfo.id.desc())
    if limit is not None:
        stmt = stmt.limit(limit)
    return list(db.scalars(stmt).all())


def _resolve_cutoff(period: str | None, custom_days: int | None) -> date | None:
    now = datetime.now(timezone.utc).date()
    if custom_days is not None:
        return now - timedelta(days=max(custom_days - 1, 0))

    if period is None:
        return None

    mapping = {
        "week": 7,
        "month": 30,
        "half_year": 182,
        "year": 365,
    }
    days = mapping.get(period)
    if days is None:
        raise ValueError("Invalid period value.")
    return now - timedelta(days=max(days - 1, 0))
