import os
import pandas as pd

# ------------------------------------
# CONFIG (FIXED PATH)
# ------------------------------------
BASE_DIR = "newdata/forecast_outputs"

# ------------------------------------
# CORE FUNCTION
# ------------------------------------
def predict_range(student_id: int, start_date: str, end_date: str) -> pd.DataFrame:
    """
    Returns LABEL-BASED forecasts (Low / Medium / High, etc.)
    for a given student and date range.
    """

    file_path = os.path.join(
        BASE_DIR,
        f"student_{student_id}_labeled_3mo.csv"
    )

    if not os.path.exists(file_path):
        raise FileNotFoundError(
            f"Labeled forecast file not found for student {student_id} "
            f"at {file_path}"
        )

    # Load labeled predictions
    df = pd.read_csv(file_path, parse_dates=["date"])

    # Parse input dates
    start = pd.to_datetime(start_date)
    end = pd.to_datetime(end_date)

    if start > end:
        raise ValueError("start_date must be before end_date")

    # Available range
    available_start = df["date"].min()
    available_end = df["date"].max()

    # Filter by date range
    df_filtered = df[
        (df["date"] >= start) &
        (df["date"] <= end)
    ].copy()

    if df_filtered.empty:
        raise ValueError(
            f"No predictions in range. "
            f"Available range is {available_start.date()} "
            f"to {available_end.date()}"
        )

    # Return ONLY labels (frontend-safe)
    return df_filtered[[
        "date",
        "stress_pred_label",
        "mental_pred_label"
    ]].sort_values("date")
