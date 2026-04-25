# app/routes/user_features.py

from fastapi import APIRouter, Request, HTTPException
from pydantic import BaseModel
from typing import Dict, Any
from datetime import datetime
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/user_features", tags=["User Features"])


class FeatureIn(BaseModel):
    user_id: str
    features: Dict[str, Any]


# ----------------------------
# SAVE OR UPDATE FEATURES
# ----------------------------
@router.post("/save")
def save_features(payload: FeatureIn, request: Request):

    col = request.app.state.col_user_features

    # ✅ remove age if present
    clean_features = {
        k: v for k, v in payload.features.items()
        if k.lower() != "age"
    }

    doc = {
        "user_id": payload.user_id,
        "features": clean_features,
        "updated_at": datetime.utcnow()
    }

    col.update_one(
        {"user_id": payload.user_id},
        {"$set": doc},
        upsert=True
    )

    saved = col.find_one({"user_id": payload.user_id})
    saved["_id"] = str(saved["_id"])

    return {
        "message": "Features saved successfully",
        "data": saved
    }


# ----------------------------
# GET FEATURES
# ----------------------------
@router.get("/{user_id}")
def get_features(user_id: str, request: Request):

    col = request.app.state.col_user_features

    doc = col.find_one({"user_id": user_id})

    if not doc:
        raise HTTPException(status_code=404, detail="User features not found")

    doc["_id"] = str(doc["_id"])

    return doc