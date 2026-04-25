from fastapi import APIRouter, Request, HTTPException
from pydantic import BaseModel, Field
from typing import Dict, Any, List, Optional
from app.model_utils import prepare_row, load_artifacts
import logging
from datetime import datetime

logger = logging.getLogger(__name__)
router = APIRouter()


class PredictIn(BaseModel):
    user_id: str
    data: Dict[str, Any]



class PredictOut(BaseModel):
    predicted: int
    probability: float
    used_model: str
    threshold: float
    details: Dict[str, Any] = Field(default_factory=dict)


class BatchIn(BaseModel):
    data: List[Dict[str, Any]]


class BatchItem(BaseModel):
    prediction: int
    probability: float
    input: Dict[str, Any]
    used_features: Optional[List[str]] = None


class BatchOut(BaseModel):
    results: List[BatchItem]


def _to_native(x):
    """Convert numpy types to Python builtins."""
    if x is None:
        return None
    try:
        import numpy as _np
        if isinstance(x, _np.generic):
            return x.item()
        if isinstance(x, _np.ndarray) and x.size == 1:
            return x.ravel()[0].item()
    except Exception:
        pass
    return x


from datetime import datetime
from fastapi import Request

@router.post("/predict")
def predict(payload: PredictIn, request: Request):

    artifacts = getattr(request.app.state, "ART", None)
    if not artifacts:
        try:
            artifacts = load_artifacts()
            request.app.state.ART = artifacts
        except Exception as e:
            raise HTTPException(status_code=503, detail="Model artifacts not loaded.")

    try:
        X_proba_df, meta = prepare_row(payload.data, artifacts)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to prepare input row: {e}")

    try:
        proba = float(_to_native(X_proba_df.iloc[0, 0]))
    except Exception:
        proba = 0.0

    threshold = float(_to_native(meta.get("threshold", 0.5)))
    predicted = int(_to_native(meta.get("pred", int(proba >= threshold))))
    used_model = meta.get("used", "unknown")

    details_raw = meta.get("details", {}) or {}
    details = {k: _to_native(v) for k, v in details_raw.items()}

    # --------------------------
    # SAVE TO MONGO
    # --------------------------
    doc = {
        "user_id": payload.user_id,
        "input": payload.data,
        "predicted": predicted,
        "probability": proba,
        "used_model": used_model,
        "threshold": threshold,
        "details": details,
        "created_at": datetime.utcnow()
    }

    col = request.app.state.col_overstim
    inserted = col.insert_one(doc)

    doc["_id"] = str(inserted.inserted_id)

    return {
        "message": "Saved successfully",
        "data": doc
    }



@router.get("/results/{user_id}")
def get_results(user_id: str, request: Request):

    col = request.app.state.col_overstim

    results = list(
        col.find({"user_id": user_id}).sort("created_at", -1)
    )

    for r in results:
        r["_id"] = str(r["_id"])

    return {
        "count": len(results),
        "results": results
    }



@router.post("/predict_batch", response_model=BatchOut)
def predict_batch(payload: BatchIn, request: Request):
    artifacts = getattr(request.app.state, "ART", None)
    if not artifacts:
        try:
            artifacts = load_artifacts()
            request.app.state.ART = artifacts
        except Exception as e:
            logger.exception("Failed to load artifacts on-demand (batch): %s", e)
            raise HTTPException(status_code=503, detail="Model artifacts not loaded.")

    results = []
    for row in payload.data:
        try:
            X_proba_df, meta = prepare_row(row, artifacts)
            proba = float(_to_native(X_proba_df.iloc[0, 0]))
            thr = float(_to_native(meta.get("threshold", 0.5)))
            pred = int(_to_native(meta.get("pred", int(proba >= thr))))
        except Exception as e:
            logger.exception("Batch prediction error: %s", e)
            proba = 0.0
            thr = 0.5
            pred = 0

        results.append({
            "prediction": pred,
            "probability": proba,
            "input": row,
            "used_features": list(row.keys())
        })
    return {"results": results}


@router.get("/features")
def get_features(request: Request):
    art = getattr(request.app.state, "ART", None)
    if not art:
        try:
            art = load_artifacts()
            request.app.state.ART = art
        except Exception:
            return {"features": "unknown"}

    scaler = art.get("scaler")
    if scaler is not None:
        try:
            if hasattr(scaler, "feature_names_in_"):
                return {"features": list(scaler.feature_names_in_)}
        except Exception:
            pass

    # fallback: try stacking artifact
    stacking = art.get("stacking_artifacts", {})
    if stacking and isinstance(stacking, dict):
        feat = stacking.get("feature_list") or stacking.get("input_feature_names")
        if feat:
            return {"features": feat}

    return {"features": "unknown"}
