from fastapi import APIRouter, Request, HTTPException
from datetime import datetime

router = APIRouter()


# ----------------------------------
# Landing: Mood Forecast
# ----------------------------------

@router.get("/mood/{user_id}")
def get_user_mood(user_id: str, request: Request):

    col = request.app.state.col_mental_single

    latest = col.find_one(
        {"user_id": user_id},
        sort=[("created_at", -1)]
    )

    if not latest:
        raise HTTPException(status_code=404, detail="No mood prediction found")

    return {
        "user_id": user_id,
        "mood_prediction": latest["prediction"],
        "probability": latest.get("probability")
    }


# ----------------------------------
# Landing: Upcoming Sessions Count
# ----------------------------------

@router.get("/sessions/{user_id}")
def get_pending_sessions(user_id: str, request: Request):

    col = request.app.state.col_sessions

    count = col.count_documents({
        "user_id": user_id,
        "session_date": {"$gte": datetime.utcnow()}
    })

    return {
        "user_id": user_id,
        "upcoming_sessions": count
    }
