from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.api.dependencies.auth import get_current_user
from app.core.database import get_db
from app.models.user import User
from app.schemas.sleep_info import SleepInfoHistoryResponse, SleepInfoItem
from app.services.sleep_info_service import get_sleep_info_history

router = APIRouter(prefix="/sleep-info", tags=["sleep-info"])


@router.get("/history", response_model=SleepInfoHistoryResponse)
def sleep_info_history(
    period: Literal["week", "month", "half_year", "year"] | None = Query(default=None),
    custom_days: int | None = Query(default=None, ge=1, le=3650),
    limit: int | None = Query(default=180, ge=1, le=1000),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> SleepInfoHistoryResponse:
    if period is not None and custom_days is not None:
        raise HTTPException(
            status_code=400,
            detail="Use either period or custom_days, not both.",
        )
    try:
        items = get_sleep_info_history(
            db=db,
            user_id=current_user.id,
            period=period,
            custom_days=custom_days,
            limit=limit,
        )
    except ValueError as err:
        raise HTTPException(status_code=400, detail=str(err)) from err

    return SleepInfoHistoryResponse(
        items=[
            SleepInfoItem(
                id=item.id,
                user_id=item.user_id,
                date=item.date,
                duration=item.duration,
                schedule=item.schedule,
            )
            for item in items
        ]
    )
