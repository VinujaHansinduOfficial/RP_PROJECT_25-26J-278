"""
Test API Client for Emotion Detection

This script provides simple functions to test the Emotion Detection API
"""

import requests
import base64
import json
from pathlib import Path

API_URL = "http://localhost:8000"

def test_health():
    """Test health endpoint"""
    response = requests.get(f"{API_URL}/health")
    print("Health Check:", response.json())
    return response.json()

def test_model_info():
    """Get model information"""
    response = requests.get(f"{API_URL}/model/info")
    print("Model Info:", json.dumps(response.json(), indent=2))
    return response.json()

def test_predict_file(image_path: str):
    """Test prediction with image file"""
    with open(image_path, 'rb') as f:
        files = {'file': f}
        data = {'detect_face': True}
        response = requests.post(f"{API_URL}/predict", files=files, data=data)
    
    result = response.json()
    print(f"\nPrediction for {image_path}:")
    print(f"  Emotion: {result['emotion']}")
    print(f"  Confidence: {result['confidence']:.4f}")
    print(f"  Face Detected: {result['face_detected']}")
    
    return result

def test_predict_base64(image_path: str):
    """Test prediction with base64 encoded image"""
    with open(image_path, 'rb') as f:
        img_data = base64.b64encode(f.read()).decode()
    
    payload = {
        "image": img_data,
        "detect_face": True
    }
    
    response = requests.post(f"{API_URL}/predict/base64", json=payload)
    result = response.json()
    
    print(f"\nBase64 Prediction:")
    print(f"  Emotion: {result['emotion']}")
    print(f"  Confidence: {result['confidence']:.4f}")
    
    return result

def test_batch_predict(image_paths: list):
    """Test batch prediction"""
    images_b64 = []
    for path in image_paths:
        with open(path, 'rb') as f:
            images_b64.append(base64.b64encode(f.read()).decode())
    
    payload = {
        "images": images_b64,
        "detect_face": True
    }
    
    response = requests.post(f"{API_URL}/predict/batch", json=payload)
    result = response.json()
    
    print(f"\nBatch Prediction ({result['total']} images):")
    for i, pred in enumerate(result['predictions']):
        print(f"  Image {i+1}: {pred['emotion']} ({pred['confidence']:.4f})")
    
    return result

def test_list_emotions():
    """List all supported emotions"""
    response = requests.get(f"{API_URL}/emotions/list")
    result = response.json()
    
    print("\nSupported Emotions:")
    for emotion in result['emotions']:
        desc = result['descriptions'].get(emotion, '')
        print(f"  • {emotion}: {desc}")
    
    return result

def run_all_tests(test_image_path: str = None):
    """Run all tests"""
    print("="*70)
    print(" EMOTION DETECTION API - TEST SUITE")
    print("="*70)
    
    # Test 1: Health check
    print("\n[TEST 1] Health Check")
    print("-"*70)
    test_health()
    
    # Test 2: Model info
    print("\n[TEST 2] Model Information")
    print("-"*70)
    test_model_info()
    
    # Test 3: List emotions
    print("\n[TEST 3] List Emotions")
    print("-"*70)
    test_list_emotions()
    
    if test_image_path and Path(test_image_path).exists():
        # Test 4: File upload prediction
        print("\n[TEST 4] Predict from File")
        print("-"*70)
        test_predict_file(test_image_path)
        
        # Test 5: Base64 prediction
        print("\n[TEST 5] Predict from Base64")
        print("-"*70)
        test_predict_base64(test_image_path)
    else:
        print("\nℹ️  Skipping image tests (no test image provided)")
        print("   Run with: run_all_tests('path/to/test/image.jpg')")
    
    print("\n" + "="*70)
    print(" ALL TESTS COMPLETED ✅")
    print("="*70)

if __name__ == '__main__':
    import sys
    
    if len(sys.argv) > 1:
        test_image = sys.argv[1]
        run_all_tests(test_image)
    else:
        print("Usage: python test_api.py [test_image.jpg]")
        print("\nRunning basic tests without image...")
        run_all_tests()
