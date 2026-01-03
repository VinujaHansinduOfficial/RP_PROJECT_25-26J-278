# ============================================================
# app/model_utils.py  (FULL PATCHED VERSION)
# ============================================================

import joblib
from pathlib import Path
import logging
from typing import Dict, Any, Tuple
import pandas as pd
import numpy as np

logger = logging.getLogger(__name__)


# ============================================================
# FIND MODELS DIRECTORY
# ============================================================
def find_models_dir():
    """Find the folder containing saved model artifacts."""
    import os

    # explicit override if user sets env var
    if os.getenv("MODELS_DIR"):
        p = Path(os.getenv("MODELS_DIR"))
        logger.info("Using MODELS_DIR from environment: %s", p)
        return p

    # search common locations
    base = Path(__file__).resolve().parents[1]  # backend/

    candidates = [
        base / "app" / "models_and_results",
        base / "models_and_results",
        base / "models_and_results",
        Path.cwd() / "models_and_results",
        Path(__file__).resolve().parent / "models_and_results",
    ]

    for p in candidates:
        if p.exists() and any(p.iterdir()):
            logger.info("Using models directory: %s", p)
            return p

    logger.warning("No models directory found. Returning first candidate: %s", candidates[0])
    return candidates[0]


# ============================================================
# LOAD ARTIFACTS (SCALER / STACKING / RF / LGBM / THRESHOLD)
# ============================================================
def load_artifacts():
    MODELS_DIR = find_models_dir()

    expected = {
        "stacking_artifacts": MODELS_DIR / "stacking_artifacts.pkl",
        "scaler": MODELS_DIR / "stacking_standard_scaler.pkl",
        "rf": MODELS_DIR / "RandomForest_tuned.pkl",
        "lgbm": MODELS_DIR / "lgbm_pruned_optuna_final.pkl",
        "best_threshold": MODELS_DIR / "best_threshold.pkl",
    }

    artifacts = {}
    missing = []

    for name, path in expected.items():
        if path.exists():
            try:
                artifacts[name] = joblib.load(path)
                logger.info(f"Loaded {name} from {path}")
            except Exception as e:
                artifacts[name] = None
                logger.error(f"Failed to load {name}: {e}")
        else:
            missing.append(name)
            artifacts[name] = None

    if missing:
        logger.warning(f"Missing artifacts: {missing}")

    artifacts["models_dir"] = MODELS_DIR
    return artifacts


# ============================================================
# NUMERIC CLEANER
# ============================================================
def _safe_numeric(val):
    try:
        if val is None or (isinstance(val, str) and val.strip() == ""):
            return np.nan
        return float(val)
    except:
        return np.nan


# ============================================================
# PREPARE ROW FOR PREDICTION (FULL STACKING FIXED)
# ============================================================
def prepare_row(input_data: Dict[str, Any], artifacts: Dict[str, Any]) -> Tuple[pd.DataFrame, Dict[str, Any]]:
    """
    Returns:
        (DataFrame probability, {pred, used, threshold, oof_probas})
    """

    stack_art = artifacts.get("stacking_artifacts")
    scaler = artifacts.get("scaler")
    best_threshold = artifacts.get("best_threshold")

    # -------------------------------------------------------
    # Resolve feature names
    # -------------------------------------------------------
    feature_names = None

    # 1) stacking feature list (preferred)
    if stack_art and isinstance(stack_art, dict):
        feature_names = (
            stack_art.get("feature_list")
            or stack_art.get("input_feature_names")
        )

    # 2) scaler feature list
    if feature_names is None and scaler is not None:
        try:
            feature_names = list(scaler.feature_names_in_)
        except:
            feature_names = None

    # 3) fallback → use keys given by user
    if feature_names is None:
        feature_names = list(input_data.keys())

    # -------------------------------------------------------
    # Build input row
    # -------------------------------------------------------
    row_vals = []
    for fn in feature_names:
        row_vals.append(_safe_numeric(input_data.get(fn)))

    X_row = pd.DataFrame([row_vals], columns=feature_names).fillna(0)

    # =======================================================
    # CASE 1: STACKING META MODEL AVAILABLE
    # =======================================================
    if stack_art and "base_models" in stack_art and "meta_model" in stack_art:
        base_models = stack_art["base_models"]
        meta_model = stack_art["meta_model"]
        base_names = stack_art.get("base_model_names")  # OPTIONAL list saved earlier

        # ---------------------------------------------------
        # Scaling
        # ---------------------------------------------------
        if scaler is not None:
            try:
                X_scaled = pd.DataFrame(scaler.transform(X_row), columns=X_row.columns)
            except:
                X_scaled = X_row.copy()
        else:
            X_scaled = X_row.copy()

        # ---------------------------------------------------
        # Get base model probabilities
        # ---------------------------------------------------
        computed_probs = []
        friendly_tokens = []

        for i, model in enumerate(base_models):

            # Determine a readable / stable name
            if base_names and len(base_names) > i:
                token = base_names[i]
            else:
                token = getattr(model, "name", None) or model.__class__.__name__

            # normalize token
            token = "".join(ch for ch in str(token) if ch.isalnum()).lower()
            friendly_tokens.append(token)

            # compute probability
            try:
                if hasattr(model, "predict_proba"):
                    p = float(model.predict_proba(X_scaled)[:, 1][0])
                else:
                    p = float(model.predict(X_scaled)[0])
            except:
                # fallback try raw row
                try:
                    if hasattr(model, "predict_proba"):
                        p = float(model.predict_proba(X_row)[:, 1][0])
                    else:
                        p = float(model.predict(X_row)[0])
                except:
                    p = 0.0

            computed_probs.append(p)

        # ---------------------------------------------------
        # Map to meta_model.feature_names_in_
        # ---------------------------------------------------
        if hasattr(meta_model, "feature_names_in_") and meta_model.feature_names_in_ is not None:
            meta_cols = list(meta_model.feature_names_in_)
        else:
            # fallback guess
            meta_cols = [f"{t}_proba" for t in friendly_tokens]

        # candidate mapping
        proba_map = {}
        for i, token in enumerate(friendly_tokens):
            p = computed_probs[i]
            # several naming patterns
            candidates = [
                f"{token}_proba",
                f"{token}__proba",
                f"{token}",
                f"m{i}_proba",
                f"m{i}",
            ]
            for c in candidates:
                proba_map[c] = p

        # ---------------------------------------------------
        # Build meta-row in exact order meta model expects
        # ---------------------------------------------------
        meta_values = [proba_map.get(col, 0.0) for col in meta_cols]
        meta_row = pd.DataFrame([meta_values], columns=meta_cols)

        logger.info("Meta columns expected → %s", meta_cols)
        logger.info("Meta row passed → %s", meta_row.to_dict(orient='records'))

        # ---------------------------------------------------
        # Get final meta probability
        # ---------------------------------------------------
        try:
            final_proba = float(meta_model.predict_proba(meta_row)[:, 1][0])
            used_model = "stacking_meta"
        except Exception as e:
            logger.exception("Meta prediction failed, falling back to average: %s", e)
            final_proba = float(np.mean(computed_probs)) if computed_probs else 0.0
            used_model = "stacking_avg_fallback"

        # ---------------------------------------------------
        # Threshold
        # ---------------------------------------------------
        thr = 0.5
        if isinstance(best_threshold, dict) and "threshold" in best_threshold:
            thr = float(best_threshold["threshold"])
        else:
            try:
                thr = float(best_threshold)
            except:
                thr = 0.5

        pred_label = int(final_proba >= thr)

        return (
            pd.DataFrame([final_proba], columns=["proba"]),
            {
                "pred": pred_label,
                "used": used_model,
                "threshold": thr,
                "oof_probas": {f"m{i}_proba": computed_probs[i] for i in range(len(computed_probs))}
            }
        )

    # =======================================================
    # CASE 2: FALLBACK → single model (LGBM or RF)
    # =======================================================
    model = artifacts.get("lgbm") or artifacts.get("rf")

    if model:
        if scaler is not None:
            try:
                X_scaled = scaler.transform(X_row)
            except:
                X_scaled = X_row.copy()
        else:
            X_scaled = X_row.copy()

        try:
            if hasattr(model, "predict_proba"):
                prob = float(model.predict_proba(X_scaled)[:, 1][0])
            else:
                prob = float(model.predict(X_scaled)[0])
        except:
            prob = 0.0

        thr = 0.5
        if isinstance(best_threshold, dict) and "threshold" in best_threshold:
            thr = float(best_threshold["threshold"])

        pred = int(prob >= thr)

        return pd.DataFrame([prob], columns=["proba"]), {
            "pred": pred,
            "used": model.__class__.__name__,
            "threshold": thr
        }

    # =======================================================
    # CASE 3: No model exists
    # =======================================================
    return pd.DataFrame([0.0], columns=["proba"]), {
        "pred": 0,
        "used": "none",
        "threshold": 0.5
    }
