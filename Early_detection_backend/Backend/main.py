from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from model_utils import predict_range

app = FastAPI(
    title="Student Stress Forecast API",
    description="Serve labeled (human-readable) student forecasts",
    version="1.1.0"
)

class PredictionRequest(BaseModel):
    student_id: int = Field(..., example=1)
    start_date: str = Field(..., example="2025-10-01")
    end_date: str = Field(..., example="2025-10-30")

@app.post("/predict")
def predict(req: PredictionRequest):
    try:
        df = predict_range(
            student_id=req.student_id,
            start_date=req.start_date,
            end_date=req.end_date
        )

        return {
            "student_id": req.student_id,
            "start_date": req.start_date,
            "end_date": req.end_date,
            "count": len(df),
            "predictions": df.to_dict(orient="records")
        }

    except FileNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Unexpected error: {str(e)}"
        )

@app.get("/health")
def health():
    return {"status": "ok"}
