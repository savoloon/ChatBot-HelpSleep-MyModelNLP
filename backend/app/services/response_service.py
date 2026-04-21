import re
from random import choice

from app.core.constants import (
    INTENT_RESPONSES,
    SLEEP_DURATION_RESPONSES,
    SLEEP_SCHEDULE_RESPONSES,
)


def build_response(intent_name: str, message: str) -> str:
    if intent_name == "sleep_duration_report":
        hours = _extract_duration_hours(message)
        if hours is None:
            return choice(INTENT_RESPONSES["sleep_duration_report"])
        duration_text = _format_duration(hours)
        if hours < 6:
            return (
                f"По твоим данным ты спал {duration_text}. "
                f"{choice(SLEEP_DURATION_RESPONSES['short'])} "
                f"{_duration_tip('short')}"
            )
        if hours <= 9:
            return (
                f"По твоим данным ты спал {duration_text}. "
                f"{choice(SLEEP_DURATION_RESPONSES['normal'])}"
            )
        return (
            f"По твоим данным ты спал {duration_text}. "
            f"{choice(SLEEP_DURATION_RESPONSES['long'])} "
            f"{_duration_tip('long')}"
        )

    if intent_name == "sleep_schedule_report":
        schedule = _extract_schedule(message)
        if schedule is None:
            return choice(INTENT_RESPONSES["sleep_schedule_report"])
        category = _classify_schedule(
            bedtime_minutes=schedule["bedtime_minutes"],
            wake_minutes=schedule["wake_minutes"],
            duration_hours=schedule["duration_hours"],
        )
        bedtime_text = _format_clock(int(schedule["bedtime_minutes"]))
        wake_text = _format_clock(int(schedule["wake_minutes"]))
        duration_text = _format_duration(float(schedule["duration_hours"]))
        advice = _schedule_tip(
            category=category,
            bedtime_minutes=int(schedule["bedtime_minutes"]),
            wake_minutes=int(schedule["wake_minutes"]),
        )
        advice_text = f" {advice}" if advice else ""
        return (
            f"Судя по сообщению, ты лег в {bedtime_text}, встал в {wake_text} "
            f"и спал примерно {duration_text}. "
            f"{choice(SLEEP_SCHEDULE_RESPONSES[category])}"
            f"{advice_text}"
        )

    return choice(INTENT_RESPONSES.get(intent_name, INTENT_RESPONSES["other"]))


def _extract_duration_hours(text: str) -> float | None:
    normalized = text.lower().replace(",", ".")

    hour_minute_pattern = re.search(
        r"(\d{1,2}(?:\.\d+)?)\s*час(?:а|ов)?\s*(\d{1,2})\s*мин",
        normalized,
    )
    if hour_minute_pattern:
        hours = float(hour_minute_pattern.group(1))
        minutes = int(hour_minute_pattern.group(2))
        return hours + minutes / 60

    hours_pattern = re.search(
        r"(\d{1,2}(?:\.\d+)?)\s*час(?:а|ов)?",
        normalized,
    )
    if hours_pattern:
        return float(hours_pattern.group(1))

    return None


def _extract_schedule(text: str) -> dict[str, float | int] | None:
    normalized = text.lower()

    range_match = re.search(
        r"(?:с|спал\s+с)\s*(\d{1,2})(?::(\d{2}))?\s*(утра|ночи|вечера|дня)?\s*"
        r"(?:до)\s*(\d{1,2})(?::(\d{2}))?\s*(утра|ночи|вечера|дня)?",
        normalized,
    )
    if range_match:
        bedtime_minutes = _to_minutes(
            hour_text=range_match.group(1),
            minute_text=range_match.group(2),
            period_text=range_match.group(3),
        )
        wake_minutes = _to_minutes(
            hour_text=range_match.group(4),
            minute_text=range_match.group(5),
            period_text=range_match.group(6),
        )
        duration_hours = _calc_duration_hours(bedtime_minutes, wake_minutes)
        return {
            "bedtime_minutes": bedtime_minutes,
            "wake_minutes": wake_minutes,
            "duration_hours": duration_hours,
        }

    verbose_match = re.search(
        r"(?:уснул|лег(?:\s+спать)?)\s*(?:в)?\s*(\d{1,2})(?::(\d{2}))?\s*(утра|ночи|вечера|дня)?"
        r".{0,30}"
        r"(?:проснулся|встал)\s*(?:в)?\s*(\d{1,2})(?::(\d{2}))?\s*(утра|ночи|вечера|дня)?",
        normalized,
    )
    if verbose_match:
        bedtime_minutes = _to_minutes(
            hour_text=verbose_match.group(1),
            minute_text=verbose_match.group(2),
            period_text=verbose_match.group(3),
        )
        wake_minutes = _to_minutes(
            hour_text=verbose_match.group(4),
            minute_text=verbose_match.group(5),
            period_text=verbose_match.group(6),
        )
        duration_hours = _calc_duration_hours(bedtime_minutes, wake_minutes)
        return {
            "bedtime_minutes": bedtime_minutes,
            "wake_minutes": wake_minutes,
            "duration_hours": duration_hours,
        }

    return None


def _to_minutes(hour_text: str, minute_text: str | None, period_text: str | None) -> int:
    hour = int(hour_text) % 24
    minute = int(minute_text) if minute_text else 0

    if period_text == "вечера" and hour < 12:
        hour += 12
    elif period_text == "дня" and hour < 12:
        hour += 12
    elif period_text in {"утра", "ночи"} and hour == 12:
        hour = 0

    return hour * 60 + minute


def _calc_duration_hours(bedtime_minutes: int, wake_minutes: int) -> float:
    delta = wake_minutes - bedtime_minutes
    if delta <= 0:
        delta += 24 * 60
    return delta / 60


def _classify_schedule(
    bedtime_minutes: int,
    wake_minutes: int,
    duration_hours: float,
) -> str:
    bedtime_is_healthy = 21 * 60 <= bedtime_minutes <= 23 * 60 + 59
    wake_is_healthy = 5 * 60 <= wake_minutes <= 8 * 60 + 30

    if duration_hours < 6:
        if bedtime_minutes >= 1 * 60:
            return "late"
        return "short"

    if duration_hours > 9:
        return "long"

    if bedtime_is_healthy and wake_is_healthy and 7 <= duration_hours <= 9:
        return "healthy"

    if bedtime_minutes >= 1 * 60:
        return "late"

    return "mixed"


def _format_duration(hours: float) -> str:
    total_minutes = max(0, int(round(hours * 60)))
    hrs = total_minutes // 60
    mins = total_minutes % 60

    if mins == 0:
        return f"{hrs} ч"
    return f"{hrs} ч {mins} мин"


def _format_clock(total_minutes: int) -> str:
    minutes_in_day = total_minutes % (24 * 60)
    hours = minutes_in_day // 60
    mins = minutes_in_day % 60
    return f"{hours:02d}:{mins:02d}"


def _duration_tip(category: str) -> str:
    if category == "short":
        return "Короткая рекомендация: сегодня постарайся лечь хотя бы на 30-60 минут раньше обычного."
    if category == "long":
        return "Короткая рекомендация: завтра поставь подъем на одно и то же время, чтобы стабилизировать ритм."
    return ""


def _schedule_tip(category: str, bedtime_minutes: int, wake_minutes: int) -> str:
    if category == "short":
        return "Короткая рекомендация: увеличь сон хотя бы до 6.5-7 часов уже в ближайшую ночь."
    if category == "late":
        new_bedtime = _format_clock(max(0, bedtime_minutes - 20))
        return (
            "Короткая рекомендация: сдвинь отбой на 15-20 минут раньше, "
            f"например к {new_bedtime}."
        )
    if category == "long":
        stable_wake = _format_clock(wake_minutes)
        return (
            "Короткая рекомендация: зафиксируй стабильный подъем, "
            f"например в {stable_wake}, и выравнивай время сна."
        )
    if category == "mixed":
        return "Короткая рекомендация: начни со стабильного времени подъема 5-7 дней подряд."
    return ""
