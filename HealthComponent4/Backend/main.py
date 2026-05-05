from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel, Field
from model_utils import predict_range
from pymongo import MongoClient
from dotenv import load_dotenv
from datetime import datetime

import os

# -----------------------------
# Load ENV
# -----------------------------
load_dotenv()

MONGO_URL = os.getenv("MONGO_URL")

app = FastAPI(
    title="Student Stress Forecast API",
    description="Serve labeled (human-readable) student forecasts",
    version="1.2.0"
)

# -----------------------------
# Mongo Setup
# -----------------------------
@app.on_event("startup")
def startup_event():
    if not MONGO_URL:
        raise Exception("MONGO_URL not found in environment.")

    client = MongoClient(MONGO_URL)
    db = client.get_default_database()

    app.state.db = db
    app.state.col_forecasts = db["student_forecasts"]

    print("✅ MongoDB connected successfully.")


# -----------------------------
# Schema
# -----------------------------
class PredictionRequest(BaseModel):
    student_id: int = Field(..., example=1)
    start_date: str = Field(..., example="2025-10-01")
    end_date: str = Field(..., example="2025-10-30")


# -----------------------------
# POST: Generate + Save Forecast
# -----------------------------
@app.post("/forecast")
def forecast(req: PredictionRequest, request: Request):

    try:
        df = predict_range(
            student_id=req.student_id,
            start_date=req.start_date,
            end_date=req.end_date
        )

        doc = {
            "student_id": req.student_id,
            "start_date": req.start_date,
            "end_date": req.end_date,
            "prediction_count": len(df),
            "predictions": df.to_dict(orient="records"),
            "created_at": datetime.utcnow()
        }

        col = request.app.state.col_forecasts
        inserted = col.insert_one(doc)

        doc["_id"] = str(inserted.inserted_id)

        return {
            "message": "Forecast saved successfully",
            "data": doc
        }

    except FileNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# -----------------------------
# GET: All Forecasts
# -----------------------------
@app.get("/forecast/{student_id}")
def get_forecasts(student_id: int, request: Request):

    col = request.app.state.col_forecasts

    results = list(
        col.find({"student_id": student_id}).sort("created_at", -1)
    )

    for r in results:
        r["_id"] = str(r["_id"])

    return {
        "student_id": student_id,
        "count": len(results),
        "results": results
    }


# -----------------------------
# GET: Latest Forecast
# -----------------------------
@app.get("/forecast/{student_id}/latest")
def get_latest_forecast(student_id: int, request: Request):

    col = request.app.state.col_forecasts

    result = col.find_one(
        {"student_id": student_id},
        sort=[("created_at", -1)]
    )

    if not result:
        raise HTTPException(status_code=404, detail="No forecast found")

    result["_id"] = str(result["_id"])

    return result


# -----------------------------
# GET: Forecast by Date Range
# -----------------------------
from datetime import datetime

@app.get("/forecast/{student_id}/range")
def get_forecast_by_range(
    student_id: int,
    start_date: str,
    end_date: str,
    request: Request
):

    col = request.app.state.col_forecasts

    # convert query params to datetime
    start_dt = datetime.fromisoformat(start_date)
    end_dt = datetime.fromisoformat(end_date)

    # get latest forecast document
    doc = col.find_one(
        {"student_id": student_id},
        sort=[("generated_at", -1)]
    )

    if not doc:
        raise HTTPException(status_code=404, detail="No forecast found")

    filtered = [
        {
            "date": p["date"],
            "stress_pred_label": p["stress_pred_label"],
            "mental_pred_label": p["mental_pred_label"]
        }
        for p in doc["predictions"]
        if start_dt <= p["date"] <= end_dt
    ]

    if not filtered:
        raise HTTPException(
            status_code=404,
            detail="No predictions available in this date range"
        )

    # convert ObjectId
    doc["_id"] = str(doc["_id"])

    return {
        "student_id": student_id,
        "start_date": start_date,
        "end_date": end_date,
        "count": len(filtered),
        "predictions": filtered
    }


from datetime import datetime

# -----------------------------
# SCRIPT: Generate forecasts for ALL students
# -----------------------------
@app.post("/script")
def run_bulk_forecast(request: Request):

    col = request.app.state.col_forecasts

    students = list(range(1, 11))  # 10 students
    results_summary = []

    for student_id in students:

        try:
            # generate full forecast range (your default 3 months)
            df = predict_range(
                student_id=student_id,
                start_date="2025-08-01",   # adjust if needed
                end_date="2025-12-31"
            )

            doc = {
                "student_id": student_id,
                "forecast_type": "3_month",
                "prediction_count": len(df),
                "predictions": df.to_dict(orient="records"),
                "generated_at": datetime.utcnow()
            }

            #  UPSERT (replace if exists, insert if not)
            col.update_one(
                {
                    "student_id": student_id,
                    "forecast_type": "3_month"
                },
                {"$set": doc},
                upsert=True
            )

            results_summary.append({
                "student_id": student_id,
                "status": "updated"
            })

        except Exception as e:
            results_summary.append({
                "student_id": student_id,
                "status": "failed",
                "error": str(e)
            })

    return {
        "message": "Bulk forecast script executed",
        "total_students": len(students),
        "results": results_summary
    }
