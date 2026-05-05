"""
FastAPI mental state prediction using models_simple_no_leak pipelines.
"""

import datetime
from pydantic import BaseModel
from typing import Dict, Any, List, Optional
from pathlib import Path
import joblib
import numpy as np
import pandas as pd
import logging
import warnings
from fastapi import APIRouter, HTTPException, Request
from datetime import datetime
router = APIRouter()
logger = logging.getLogger(__name__)

# ============================================
# Model directory 
# ============================================
MODEL_DIR = Path(__file__).resolve().parents[1] / "models_simple_no_leak"

MODEL_MAP = {
    "Stress": MODEL_DIR / "stress_simple_noleak_pipeline.joblib",
    "Anxiety": MODEL_DIR / "anxiety_simple_noleak_pipeline.joblib",
    "Depression": MODEL_DIR / "depression_simple_noleak_pipeline.joblib",
}

# ============================================
# HARD-CODED FEATURE LISTS 
# ============================================
FEATURES = {
    "Stress": [
        "Age", "Heart_Rate", "Work_Hours", "Screen_Time",
        "Social_Interaction", "Noise_Exposure"
    ],

    "Anxiety": [
        "Tech_Usage_Hours", "Sensory_Sensitivity", "num_missing",
        "Multitasking_Habit", "Sleep_Hours_div_Screen_Time",
        "Social_Interaction", "Irritability_Score",
        "Noise_Exposure_div_Exercise_Hours",
        "Social_Interaction_div_Work_Hours",
        "Sleep_Hours", "Age"
    ],

    "Depression": [
        "Irritability_Score", "Sleep_Quality", "Sleep_Hours",
        "Noise_Exposure", "Sensory_Sensitivity",
        "Social_Interaction_div_Exercise_Hours",
        "Tech_Usage_Hours", "num_missing", "Overthinking_Score",
        "Screen_Time", "Heart_Rate"
    ]
}

DEFAULT_THRESHOLD = 0.5

# ============================================
# Load sklearn models
# ============================================
MODELS = {}
_missing = []

for name, p in MODEL_MAP.items():
    if not p.exists():
        _missing.append(str(p))
        continue
    try:
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            MODELS[name] = joblib.load(p)
        print(f"Loaded {name} model → {p}")
    except Exception as e:
        logger.exception(f"Error loading {name}: {e}")
        _missing.append(str(p))

if _missing:
    print("WARNING: Missing models:", _missing)


# ============================================
# Request/Response schemas
# ============================================
class MentalStateRequest(BaseModel):
    user_id: str
    data: Dict[str, Any]


class SingleTargetOut(BaseModel):
    prediction: Optional[int]
    probability: Optional[float]


# ============================================
# Engineered Feature Builder
# ============================================
def add_engineered_features(df):
    eps = 1e-6

    # num_missing
    df["num_missing"] = df.isna().sum(axis=1)

    # ratio features (general pattern)
    def make_ratio(df, feat):
        if "_div_" in feat:
            a, b = feat.split("_div_")
            if a in df.columns and b in df.columns:
                df[feat] = df[a] / (df[b] + eps)

    # build ratio features
    for feat_list in FEATURES.values():
        for f in feat_list:
            make_ratio(df, f)

    return df


# ============================================
# Universal prediction function
# ============================================
def _predict_single(target_name: str, input_dict: Dict[str, Any]) -> SingleTargetOut:

    if target_name not in MODELS:
        raise HTTPException(status_code=503, detail=f"{target_name} model is not loaded.")

    model = MODELS[target_name]
    feats = FEATURES[target_name]
    threshold = DEFAULT_THRESHOLD

    # Build row
    df_row = pd.DataFrame([input_dict])

    # Add engineered features
    df_row = add_engineered_features(df_row)

    # Fill missing features with 0
    for f in feats:
        if f not in df_row.columns:
            df_row[f] = 0.0

    df_row = df_row[feats].apply(pd.to_numeric, errors="coerce").fillna(0)

    # Predict
    try:
        prob = float(model.predict_proba(df_row)[0][1])
        pred = int(prob >= threshold)
        return SingleTargetOut(prediction=pred, probability=prob)
    except:
        pred = int(model.predict(df_row)[0])
        return SingleTargetOut(prediction=pred, probability=None)


# ============================================
# Endpoints
# ============================================

@router.post("/predict/stress")
def predict_stress(req: MentalStateRequest, request: Request):

    result = _predict_single("Stress", req.data)

    doc = {
        "user_id": req.user_id,
        "target": "Stress",
        "input": req.data,
        "prediction": result.prediction,
        "probability": result.probability,
        "created_at": datetime.utcnow()
    }

    col = request.app.state.col_mental_single
    inserted = col.insert_one(doc)

    doc["_id"] = str(inserted.inserted_id)

    return {
        "message": "Saved successfully",
        "data": doc
    }


@router.post("/predict/anxiety")
def predict_anxiety(req: MentalStateRequest, request: Request):

    result = _predict_single("Anxiety", req.data)

    doc = {
        "user_id": req.user_id,
        "target": "Anxiety",
        "input": req.data,
        "prediction": result.prediction,
        "probability": result.probability,
        "created_at": datetime.utcnow()
    }

    col = request.app.state.col_mental_single
    inserted = col.insert_one(doc)

    doc["_id"] = str(inserted.inserted_id)

    return {
        "message": "Saved successfully",
        "data": doc
    }



@router.post("/predict/depression")
def predict_depression(req: MentalStateRequest, request: Request):

    result = _predict_single("Depression", req.data)

    doc = {
        "user_id": req.user_id,
        "target": "Depression",
        "input": req.data,
        "prediction": result.prediction,
        "probability": result.probability,
        "created_at": datetime.utcnow()
    }

    col = request.app.state.col_mental_single
    inserted = col.insert_one(doc)

    doc["_id"] = str(inserted.inserted_id)

    return {
        "message": "Saved successfully",
        "data": doc
    }


@router.get("/results/mental/{user_id}")
def get_mental_results(user_id: str, request: Request):

    col = request.app.state.col_mental_single

    results = list(
        col.find({"user_id": user_id}).sort("created_at", -1)
    )

    for r in results:
        r["_id"] = str(r["_id"])

    return {
        "count": len(results),
        "results": results
    }


@router.get("/results/overstim/{user_id}")
def get_overstim_results(user_id: str, request: Request):

    col = request.app.state.col_overstim

    results = list(
        col.find({"user_id": user_id}).sort("created_at", -1)
    )

    for r in results:
        r["_id"] = str(r["_id"])

    return {
        "user_id": user_id,
        "type": "Overstimulated",
        "count": len(results),
        "results": results
    }

@router.get("/results/stress/{user_id}")
def get_stress_results(user_id: str, request: Request):

    col = request.app.state.col_mental_single

    results = list(
        col.find({
            "user_id": user_id,
            "target": "Stress"
        }).sort("created_at", -1)
    )

    for r in results:
        r["_id"] = str(r["_id"])

    return {
        "user_id": user_id,
        "type": "Stress",
        "count": len(results),
        "results": results
    }


@router.get("/results/anxiety/{user_id}")
def get_anxiety_results(user_id: str, request: Request):

    col = request.app.state.col_mental_single

    results = list(
        col.find({
            "user_id": user_id,
            "target": "Anxiety"
        }).sort("created_at", -1)
    )

    for r in results:
        r["_id"] = str(r["_id"])

    return {
        "user_id": user_id,
        "type": "Anxiety",
        "count": len(results),
        "results": results
    }

@router.get("/results/depression/{user_id}")
def get_depression_results(user_id: str, request: Request):

    col = request.app.state.col_mental_single

    results = list(
        col.find({
            "user_id": user_id,
            "target": "Depression"
        }).sort("created_at", -1)
    )

    for r in results:
        r["_id"] = str(r["_id"])

    return {
        "user_id": user_id,
        "type": "Depression",
        "count": len(results),
        "results": results
    }
