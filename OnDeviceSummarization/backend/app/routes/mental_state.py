# app/routes/mental_state.py
"""
Multi-target mental-state routes.

Routes:
 - GET  /mental_features                      -> return feature names expected by each model
 - POST /predict_mental_state                 -> best-effort: create engineered features or fill missing with 0
 - POST /predict_mental_state_strict          -> strict: error if any required features are missing

Drop/replace this file in app/routes and restart your FastAPI server.
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Dict, Any, List, Optional
from pathlib import Path
import joblib
import numpy as np
import pandas as pd
import logging
import warnings

logger = logging.getLogger(__name__)
router = APIRouter()

# ---------------------------
# Config: where the multi-target models live
# ---------------------------
MODEL_DIR = Path(__file__).resolve().parents[1] / "models_simple_no_leak"
MODEL_MAP = {
    "Stress": MODEL_DIR / "stress_simple_noleak_pipeline.joblib",
    "Anxiety": MODEL_DIR / "anxiety_simple_noleak_pipeline.joblib",
    "Depression": MODEL_DIR / "depression_simple_noleak_pipeline.joblib",
}

# ---------------------------
# Load models (do not crash app if missing; endpoints will report)
# ---------------------------
MODELS: Dict[str, Any] = {}
_missing = []
for name, p in MODEL_MAP.items():
    if not p.exists():
        _missing.append(str(p))
    else:
        try:
            # ignore sklearn InconsistentVersionWarning while loading so logs aren't noisy
            with warnings.catch_warnings():
                warnings.simplefilter("ignore")
                MODELS[name] = joblib.load(p)
            logger.info("Loaded multi-target model %s from %s", name, p)
        except Exception as e:
            logger.exception("Failed to load model %s: %s", name, e)
            _missing.append(f"{p} (error: {e})")

if _missing:
    logger.warning("Some multi-target model files missing/failed to load: %s", _missing)

# ---------------------------
# Request / Response models
# ---------------------------
class MentalStateRequest(BaseModel):
    data: Dict[str, Any]

class SingleTargetOut(BaseModel):
    prediction: Optional[int]
    probability: Optional[float]

# ---------------------------
# Utilities
# ---------------------------
def to_native(x):
    """Convert numpy types to Python builtins."""
    if x is None:
        return None
    try:
        if isinstance(x, np.generic):
            return x.item()
        if isinstance(x, np.ndarray):
            if x.size == 1:
                return x.ravel()[0].item()
            return x.tolist()
    except Exception:
        pass
    return x

def _required_features_for_model(model) -> Optional[List[str]]:
    """
    Best-effort: return required feature names for a model/pipeline.
    Tries several common spots: feature_names_in_, pipeline.named_steps, final_estimator.
    """
    try:
        # direct attribute
        fn = getattr(model, "feature_names_in_", None)
        if fn is not None:
            return list(fn)
    except Exception:
        pass

    # if model is a Pipeline, try named steps and the final estimator
    try:
        if hasattr(model, "named_steps"):
            # 1) try pipeline.feature_names_in_ (some pipeline wrappers expose it)
            fn = getattr(model, "feature_names_in_", None)
            if fn is not None:
                return list(fn)
            # 2) try final_estimator / named steps for feature_names_in_
            final = getattr(model, "named_steps", {}).get(list(model.named_steps.keys())[-1], None)
            if final is not None:
                fn = getattr(final, "feature_names_in_", None)
                if fn is not None:
                    return list(fn)
            # 3) try to find any transformer with feature_names_in_
            for step in model.named_steps.values():
                fn = getattr(step, "feature_names_in_", None)
                if fn is not None:
                    return list(fn)
    except Exception:
        pass

    # As a last resort, some sklearn transformers expose get_feature_names_out
    try:
        if hasattr(model, "get_feature_names_out"):
            out = model.get_feature_names_out()
            return list(out)
    except Exception:
        pass

    return None

def ensure_engineered_features(df: pd.DataFrame, required_features: List[str]) -> List[str]:
    """
    Minimal heuristics to synthesize commonly used engineered features used by notebook.
    Returns list of features created on df.
    """
    eps = 1e-6
    created = []
    for feat in required_features:
        if feat in df.columns:
            continue
        # heuristics (copy from notebook)
        if feat == "screen_per_sleep" and "Screen_Time" in df.columns and "Sleep_Hours" in df.columns:
            df[feat] = df["Screen_Time"] / (df["Sleep_Hours"] + eps); created.append(feat); continue
        if feat == "stress_sleep_inter" and "Stress_Level" in df.columns and "Sleep_Hours" in df.columns:
            df[feat] = df["Stress_Level"] * df["Sleep_Hours"]; created.append(feat); continue
        if feat == "tech_per_work" and "Tech_Usage_Hours" in df.columns and "Work_Hours" in df.columns:
            df[feat] = df["Tech_Usage_Hours"] / (df["Work_Hours"] + eps); created.append(feat); continue
        if feat == "caff_headache" and "Caffeine_Intake" in df.columns and "Headache_Frequency" in df.columns:
            df[feat] = df["Caffeine_Intake"] * df["Headache_Frequency"]; created.append(feat); continue
        if feat == "high_stress_flag" and "Stress_Level" in df.columns:
            df[feat] = (pd.to_numeric(df["Stress_Level"], errors="coerce").fillna(0) >= 8).astype(int); created.append(feat); continue
        if feat == "low_sleep_flag" and "Sleep_Hours" in df.columns:
            df[feat] = (pd.to_numeric(df["Sleep_Hours"], errors="coerce").fillna(0) <= 4).astype(int); created.append(feat); continue
        if feat == "hr_age_ratio" and "Heart_Rate" in df.columns and "Age" in df.columns:
            df[feat] = pd.to_numeric(df["Heart_Rate"], errors="coerce").fillna(0) / (pd.to_numeric(df["Age"], errors="coerce").fillna(1) + eps); created.append(feat); continue
        # last resort: try to copy a similarly named column if it exists
        if feat in df.columns:
            created.append(feat)
    # coerce created feature types to numeric where possible
    for c in created:
        try:
            df[c] = pd.to_numeric(df[c], errors="coerce")
        except Exception:
            pass
    return created

def _predict_for_model(model, df_row: pd.DataFrame):
    """Run model.predict and model.predict_proba safely returning (pred, prob, error)."""
    try:
        pred_arr = model.predict(df_row)
        pred = pred_arr[0] if len(pred_arr) > 0 else None
        prob = None
        try:
            p = model.predict_proba(df_row)
            # handle common shapes:
            # binary: (n,2) -> prob of class 1
            # multiclass: (n,k) -> try to get probability for predicted class
            if p is not None and p.ndim == 2:
                if p.shape[1] == 2:
                    prob = float(p[0, 1])
                else:
                    # try to find index of predicted class in classes_
                    classes = getattr(model, "classes_", None)
                    if classes is not None:
                        # find predicted class index
                        try:
                            idx = list(classes).index(pred)
                            prob = float(p[0, idx])
                        except Exception:
                            # fallback: take max class prob
                            prob = float(p[0].max())
                    else:
                        prob = float(p[0].max())
        except Exception:
            prob = None
        return (int(to_native(pred)) if pred is not None else None), prob, None
    except Exception as e:
        return None, None, str(e)

# ---------------------------
# Endpoints
# ---------------------------

@router.get("/mental_features")
def mental_features():
    """Return required features for each model (best-effort)."""
    if not MODELS:
        return {"models": {}, "note": "no models loaded"}
    resp = {}
    for name, m in MODELS.items():
        try:
            resp[name] = _required_features_for_model(m) or []
        except Exception as e:
            logger.exception("Error discovering features for %s: %s", name, e)
            resp[name] = []
    return {"models": resp}

@router.post("/predict_mental_state", response_model=Dict[str, SingleTargetOut])
def predict_mental_state(req: MentalStateRequest):
    """
    Best-effort prediction:
      - Determine union of features required by all models.
      - Attempt to synthesize commonly used engineered features.
      - Fill any remaining missing features with zeros so prediction can proceed.
    """
    if not MODELS:
        raise HTTPException(status_code=503, detail="Multi-target models not loaded on server. Check logs.")

    # build a one-row DataFrame from provided inputs
    row = dict(req.data)
    df_row = pd.DataFrame([row])

    # union of required features
    required_union = set()
    for m in MODELS.values():
        req_feats = _required_features_for_model(m) or []
        required_union.update(req_feats)

    # attempt to create engineered features used in the notebook
    created = ensure_engineered_features(df_row, list(required_union))

    # fill remaining missing required columns with 0.0 (best-effort)
    missing = [c for c in required_union if c not in df_row.columns]
    for c in missing:
        df_row[c] = 0.0

    # coerce numeric where possible
    for c in df_row.columns:
        try:
            df_row[c] = pd.to_numeric(df_row[c], errors="ignore")
        except Exception:
            pass

    # predict per model
    out = {}
    for name, model in MODELS.items():
        pred, prob, err = _predict_for_model(model, df_row)
        if err:
            logger.error("Prediction error for %s: %s", name, err)
            out[name] = {"prediction": None, "probability": None}
        else:
            out[name] = {"prediction": pred, "probability": to_native(prob)}

    return out

@router.post("/predict_mental_state_strict", response_model=Dict[str, SingleTargetOut])
def predict_mental_state_strict(req: MentalStateRequest):
    """
    Strict prediction: fail if any model's required features are missing.
    """
    if not MODELS:
        raise HTTPException(status_code=503, detail="Multi-target models not loaded on server. Check logs.")

    row = dict(req.data)
    df_row = pd.DataFrame([row])

    missing_per_model = {}
    for name, m in MODELS.items():
        req_feats = _required_features_for_model(m)
        if not req_feats:
            continue
        missing = [f for f in req_feats if f not in df_row.columns]
        if missing:
            missing_per_model[name] = missing

    if missing_per_model:
        msg = "; ".join(f"{nm}: missing {set(cols)}" for nm, cols in missing_per_model.items())
        raise HTTPException(status_code=400, detail=f"Missing required columns per model: {msg}")

    out = {}
    for name, model in MODELS.items():
        pred, prob, err = _predict_for_model(model, df_row)
        if err:
            raise HTTPException(status_code=400, detail=f"Model {name} failed: {err}")
        out[name] = {"prediction": pred, "probability": to_native(prob)}
    return out

