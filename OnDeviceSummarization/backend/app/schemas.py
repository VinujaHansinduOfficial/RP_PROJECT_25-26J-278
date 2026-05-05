from pydantic import BaseModel, Field
from typing import Dict, Any, List, Optional

class SinglePredictRequest(BaseModel):
    # Accepts a dict mapping feature name -> numeric value
    data: Dict[str, float] = Field(..., description="Mapping of feature name to numeric value")

class BatchPredictRequest(BaseModel):
    data: List[Dict[str, float]] = Field(..., description="List of feature dictionaries")

class PredictionResponse(BaseModel):
    prediction: int
    probability: float
    input: Dict[str, Any]
    used_features: Optional[List[str]] = None
