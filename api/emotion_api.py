"""
FastAPI Emotion Detection API

Provides RESTful endpoints for emotion detection using the trained EfficientNet-B0 model.

Endpoints:
- POST /predict - Predict emotion from image
- POST /predict/batch - Predict emotions for multiple images
- POST /predict/base64 - Predict emotion from base64 encoded image
- GET /model/info - Get model information
- GET /health - Health check
- POST /webcam/start - Start webcam session
- POST /video/process - Process video file

Run with: uvicorn emotion_api:app --reload --host 0.0.0.0 --port 8000
"""

from fastapi import FastAPI, File, UploadFile, HTTPException, BackgroundTasks
from fastapi.responses import JSONResponse, FileResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List, Optional, Dict
import base64
import io
import os
import sys
from datetime import datetime
import tempfile
import shutil
import uuid

# Add parent directory to path for imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from models.emotion_system import (
    EmotionDetector, 
    get_model_info, 
    analyze_emotion_distribution,
    calculate_emotional_score,
    process_video_file,
    EmotionDatabase
)

import numpy as np
from PIL import Image
import cv2

# -----------------------
# FastAPI App Setup
# -----------------------
app = FastAPI(
    title="Emotion Detection API",
    description="API for detecting emotions from images and videos using EfficientNet-B0",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# -----------------------
# Global Variables
# -----------------------
MODEL_PATH = os.path.join(os.path.dirname(__file__), "..", "models", "best_new_emotion_model.pt")
detector = None

# -----------------------
# Pydantic Models
# -----------------------
class EmotionPredictionResponse(BaseModel):
    emotion: str
    confidence: float
    probabilities: Dict[str, float]
    face_detected: bool
    timestamp: str

class Base64ImageRequest(BaseModel):
    image: str = Field(..., description="Base64 encoded image")
    detect_face: bool = Field(True, description="Whether to detect and crop face")

class BatchPredictionRequest(BaseModel):
    images: List[str] = Field(..., description="List of base64 encoded images")
    detect_face: bool = Field(True, description="Whether to detect faces")

class VideoProcessRequest(BaseModel):
    video_path: str = Field(..., description="Path to video file")
    save_output: bool = Field(False, description="Whether to save annotated video")
    output_path: Optional[str] = Field(None, description="Output path for annotated video")

class AnalysisRequest(BaseModel):
    session_id: Optional[str] = None
    start_time: Optional[str] = None
    end_time: Optional[str] = None

class HealthResponse(BaseModel):
    status: str
    model_loaded: bool
    model_path: str
    device: str
    timestamp: str

# -----------------------
# Startup & Shutdown
# -----------------------
@app.on_event("startup")
async def startup_event():
    """Initialize the emotion detector on startup"""
    global detector
    
    if not os.path.exists(MODEL_PATH):
        print(f"Warning: Model not found at {MODEL_PATH}")
        print("Please train the model first or update MODEL_PATH")
        return
    
    try:
        detector = EmotionDetector(model_path=MODEL_PATH, device='auto')
        print(f" Model loaded successfully from {MODEL_PATH}")
        print(f"   Device: {detector.device}")
    except Exception as e:
        print(f" Error loading model: {e}")
        detector = None

@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    print("Shutting down API...")

# -----------------------
# Helper Functions
# -----------------------
def decode_base64_image(base64_string: str) -> Image.Image:
    """Decode base64 string to PIL Image"""
    try:
        # Remove data URI prefix if present
        if ',' in base64_string:
            base64_string = base64_string.split(',')[1]
        
        image_data = base64.b64decode(base64_string)
        image = Image.open(io.BytesIO(image_data))
        return image
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid base64 image: {str(e)}")

def save_upload_file(upload_file: UploadFile) -> str:
    """Save uploaded file to temporary location"""
    try:
        suffix = os.path.splitext(upload_file.filename)[1]
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            shutil.copyfileobj(upload_file.file, tmp)
            return tmp.name
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error saving file: {str(e)}")

def cleanup_file(file_path: str):
    """Delete temporary file"""
    try:
        if os.path.exists(file_path):
            os.remove(file_path)
    except Exception as e:
        print(f"Warning: Could not delete {file_path}: {e}")

# -----------------------
# API Endpoints
# -----------------------

@app.get("/", tags=["General"])
async def root():
    """Root endpoint"""
    return {
        "message": "Emotion Detection API",
        "version": "1.0.0",
        "endpoints": {
            "predict": "/predict",
            "predict_batch": "/predict/batch",
            "predict_base64": "/predict/base64",
            "model_info": "/model/info",
            "health": "/health",
            "docs": "/docs"
        }
    }

@app.get("/health", response_model=HealthResponse, tags=["General"])
async def health_check():
    """Health check endpoint"""
    return HealthResponse(
        status="healthy" if detector is not None else "model_not_loaded",
        model_loaded=detector is not None,
        model_path=MODEL_PATH,
        device=str(detector.device) if detector else "N/A",
        timestamp=datetime.utcnow().isoformat()
    )

@app.get("/model/info", tags=["Model"])
async def get_model_information():
    """Get information about the loaded model"""
    if detector is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    info = get_model_info(MODEL_PATH)
    return JSONResponse(content=info)

@app.post("/predict", response_model=EmotionPredictionResponse, tags=["Prediction"])
async def predict_emotion(
    file: UploadFile = File(...),
    detect_face: bool = True,
    background_tasks: BackgroundTasks = None
):
    """
    Predict emotion from an uploaded image
    
    Args:
        file: Image file (jpg, jpeg, png)
        detect_face: Whether to detect and crop face first
    
    Returns:
        Emotion prediction with probabilities
    """
    if detector is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    # Validate file type
    if not file.content_type.startswith('image/'):
        raise HTTPException(status_code=400, detail="File must be an image")
    
    # Save uploaded file temporarily
    temp_path = save_upload_file(file)
    
    try:
        # Make prediction
        result = detector.predict(temp_path, detect_face=detect_face)
        
        # Schedule cleanup
        if background_tasks:
            background_tasks.add_task(cleanup_file, temp_path)
        else:
            cleanup_file(temp_path)
        
        return EmotionPredictionResponse(**result)
    
    except Exception as e:
        cleanup_file(temp_path)
        raise HTTPException(status_code=500, detail=f"Prediction error: {str(e)}")

@app.post("/predict/base64", response_model=EmotionPredictionResponse, tags=["Prediction"])
async def predict_emotion_base64(request: Base64ImageRequest):
    """
    Predict emotion from a base64 encoded image
    
    Args:
        request: Base64ImageRequest with image data
    
    Returns:
        Emotion prediction with probabilities
    """
    if detector is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    try:
        # Decode image
        image = decode_base64_image(request.image)
        
        # Make prediction
        result = detector.predict(image, detect_face=request.detect_face)
        
        return EmotionPredictionResponse(**result)
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction error: {str(e)}")

@app.post("/predict/batch", tags=["Prediction"])
async def predict_emotion_batch(request: BatchPredictionRequest):
    """
    Predict emotions for multiple base64 encoded images
    
    Args:
        request: BatchPredictionRequest with list of images
    
    Returns:
        List of emotion predictions
    """
    if detector is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    if len(request.images) > 50:
        raise HTTPException(status_code=400, detail="Maximum 50 images per batch")
    
    try:
        images = [decode_base64_image(img) for img in request.images]
        results = detector.predict_batch(images, detect_face=request.detect_face)
        
        return JSONResponse(content={
            "total": len(results),
            "predictions": results
        })
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Batch prediction error: {str(e)}")

@app.post("/predict/url", response_model=EmotionPredictionResponse, tags=["Prediction"])
async def predict_emotion_from_url(
    image_url: str,
    detect_face: bool = True
):
    """
    Predict emotion from an image URL
    
    Args:
        image_url: URL of the image
        detect_face: Whether to detect face
    
    Returns:
        Emotion prediction
    """
    if detector is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    try:
        import requests
        
        # Download image
        response = requests.get(image_url, timeout=10)
        response.raise_for_status()
        
        image = Image.open(io.BytesIO(response.content))
        
        # Make prediction
        result = detector.predict(image, detect_face=detect_face)
        
        return EmotionPredictionResponse(**result)
    
    except requests.exceptions.RequestException as e:
        raise HTTPException(status_code=400, detail=f"Failed to download image: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction error: {str(e)}")

@app.post("/video/process", tags=["Video"])
async def process_video(
    file: UploadFile = File(...),
    save_output: bool = False,
    background_tasks: BackgroundTasks = None
):
    """
    Process a video file and detect emotions frame by frame
    
    Args:
        file: Video file
        save_output: Whether to save annotated video
    
    Returns:
        Analysis results
    """
    if detector is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    # Validate file type
    if not file.content_type.startswith('video/'):
        raise HTTPException(status_code=400, detail="File must be a video")
    
    # Save uploaded file
    temp_input = save_upload_file(file)
    temp_output = None
    
    try:
        if save_output:
            temp_output = temp_input.replace(os.path.splitext(temp_input)[1], '_annotated.mp4')
        
        # Process video
        results = process_video_file(detector, temp_input, output_path=temp_output, save_json=False)
        
        # Analyze results
        analysis = analyze_emotion_distribution(results)
        emotional_score = calculate_emotional_score(results)
        
        response_data = {
            "total_frames": len(results),
            "analysis": analysis,
            "emotional_score": emotional_score,
            "has_output_video": save_output,
            "frame_sample": results[:10] if len(results) > 10 else results
        }
        
        # Schedule cleanup
        if background_tasks:
            background_tasks.add_task(cleanup_file, temp_input)
            if temp_output:
                background_tasks.add_task(cleanup_file, temp_output)
        else:
            cleanup_file(temp_input)
            if temp_output:
                cleanup_file(temp_output)
        
        return JSONResponse(content=response_data)
    
    except Exception as e:
        cleanup_file(temp_input)
        if temp_output:
            cleanup_file(temp_output)
        raise HTTPException(status_code=500, detail=f"Video processing error: {str(e)}")

@app.post("/analyze/results", tags=["Analysis"])
async def analyze_results(results: List[Dict]):
    """
    Analyze a list of emotion detection results
    
    Args:
        results: List of prediction results
    
    Returns:
        Statistical analysis
    """
    try:
        analysis = analyze_emotion_distribution(results)
        emotional_score = calculate_emotional_score(results)
        
        return JSONResponse(content={
            "analysis": analysis,
            "emotional_score": emotional_score
        })
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Analysis error: {str(e)}")

@app.get("/emotions/list", tags=["Reference"])
async def list_emotions():
    """Get list of supported emotions"""
    from models.emotion_system import EMOTION_CLASSES
    
    return JSONResponse(content={
        "emotions": EMOTION_CLASSES,
        "count": len(EMOTION_CLASSES),
        "descriptions": {
            "Anger": "Angry, irritated, or frustrated expression",
            "Confused": "Puzzled or uncertain expression",
            "Excited": "Enthusiastic or energetic expression",
            "Fear": "Scared or anxious expression",
            "Happy": "Joyful or pleased expression",
            "Sadness": "Sad or sorrowful expression",
            "Surprised": "Shocked or amazed expression",
            "Thaughtful": "Contemplative or pensive expression"
        }
    })

# -----------------------
# Error Handlers
# -----------------------
@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": exc.detail,
            "status_code": exc.status_code,
            "timestamp": datetime.utcnow().isoformat()
        }
    )

@app.exception_handler(Exception)
async def general_exception_handler(request, exc):
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal server error",
            "detail": str(exc),
            "timestamp": datetime.utcnow().isoformat()
        }
    )

# -----------------------
# Router for modular usage
# -----------------------
from fastapi import APIRouter

router = APIRouter()

# Register all routes with router for flexibility
for route in app.routes:
    if hasattr(route, 'path') and not route.path.startswith('/openapi') and not route.path.startswith('/docs'):
        router.routes.append(route)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
