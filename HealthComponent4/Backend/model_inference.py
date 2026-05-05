import os
import numpy as np
import pandas as pd
from datetime import timedelta
import joblib
import tensorflow as tf

# -------------------------
# PATHS (adjust if needed)
# -------------------------
BASE_DIR = "newdata/forecast_outputs/per_student_models"

PER_STUDENT_LOOKBACK = 60
PER_STUDENT_HORIZON = 90

per_student_targets = [
    "Stress_Level_Score",
    "Mental_Health_Status_Score"
]

# -------------------------
# Helper functions
# -------------------------
def build_student_daily_features(df_student):
    df_student["date_only"] = pd.to_datetime(df_student["Timestamp"]).dt.floor("D")

    numeric_cols = df_student.select_dtypes(include=[np.number]).columns.tolist()
    agg = (
        df_student
        .groupby("date_only")[numeric_cols]
        .mean()
        .reset_index()
        .rename(columns={"date_only": "date"})
        .set_index("date")
        .asfreq("D")
        .interpolate("time")
        .ffill()
        .bfill()
    )

    agg["dayofweek"] = agg.index.dayofweek
    agg["month"] = agg.index.month
    agg["is_weekend"] = (agg["dayofweek"] >= 5).astype(int)

    return agg


def inverse_scale_seq2seq(y_flat, scaler, horizon, n_targets):
    y_2d = y_flat.reshape(-1, n_targets)
    y_inv = scaler.inverse_transform(y_2d)
    return y_inv.reshape(horizon, n_targets)

# -------------------------
# MAIN INFERENCE FUNCTION
# -------------------------
def forecast_for_student(student_id, df_raw, horizon=PER_STUDENT_HORIZON):
    """
    Returns a DataFrame indexed by future dates with numeric predictions
    """

    df_s = df_raw[df_raw["StudentID"] == student_id].copy()
    if df_s.empty:
        raise ValueError(f"No data found for student {student_id}")

    df_feat = build_student_daily_features(df_s)

    model_path = os.path.join(BASE_DIR, f"student_{student_id}_model.h5")

    if os.path.exists(model_path):
        # ---- per-student model ----
        model = tf.keras.models.load_model(model_path, compile=False)
        scaler_X = joblib.load(os.path.join(BASE_DIR, f"scaler_X_student_{student_id}.joblib"))
        scaler_y = joblib.load(os.path.join(BASE_DIR, f"scaler_y_student_{student_id}.joblib"))

        feature_cols = [
            c for c in df_feat.columns if c not in per_student_targets
        ]

        X = scaler_X.transform(df_feat[feature_cols].values)

    else:
        raise RuntimeError("Global fallback not wired yet")

    # pad if needed
    if X.shape[0] < PER_STUDENT_LOOKBACK:
        pad = np.repeat(X[:1], PER_STUDENT_LOOKBACK - X.shape[0], axis=0)
        X = np.vstack([pad, X])

    X_input = X[-PER_STUDENT_LOOKBACK:].reshape(
        1, PER_STUDENT_LOOKBACK, X.shape[1]
    )

    y_flat = model.predict(X_input)
    y_pred = inverse_scale_seq2seq(
        y_flat, scaler_y, horizon, len(per_student_targets)
    )

    future_dates = [
        df_feat.index[-1] + timedelta(days=i + 1)
        for i in range(horizon)
    ]

    return pd.DataFrame(
        y_pred,
        index=future_dates,
        columns=per_student_targets
    )
