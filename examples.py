"""
Example usage scripts for the Emotion Detection System
"""

# Example 1: Simple image prediction
def example_single_image():
    from emotion_system import EmotionDetector
    
    detector = EmotionDetector(model_path='best_new_emotion_model.pt')
    result = detector.predict('test_image.jpg', detect_face=True)
    
    print(f"Emotion: {result['emotion']}")
    print(f"Confidence: {result['confidence']:.2f}")
    print(f"Face detected: {result['face_detected']}")

# Example 2: Batch processing
def example_batch():
    from emotion_system import EmotionDetector
    
    detector = EmotionDetector(model_path='best_new_emotion_model.pt')
    
    images = ['img1.jpg', 'img2.jpg', 'img3.jpg']
    results = detector.predict_batch(images, detect_face=True)
    
    for i, result in enumerate(results):
        print(f"Image {i+1}: {result['emotion']} ({result['confidence']:.2f})")

# Example 3: Webcam detection
def example_webcam():
    from emotion_system import EmotionDetector
    
    detector = EmotionDetector(model_path='best_new_emotion_model.pt')
    detector.run_webcam(show_probabilities=True, save_results=True)

# Example 4: Video processing
def example_video():
    from emotion_system import EmotionDetector, process_video_file
    
    detector = EmotionDetector(model_path='best_new_emotion_model.pt')
    results = process_video_file(
        detector,
        'input.mp4',
        output_path='output_annotated.mp4',
        save_json=True
    )
    
    print(f"Processed {len(results)} frames")

# Example 5: Analysis
def example_analysis():
    from emotion_system import EmotionDetector, analyze_emotion_distribution, calculate_emotional_score
    
    detector = EmotionDetector(model_path='best_new_emotion_model.pt')
    
    # Get predictions
    images = ['img1.jpg', 'img2.jpg', 'img3.jpg']
    results = detector.predict_batch(images)
    
    # Analyze
    analysis = analyze_emotion_distribution(results)
    print(f"Dominant emotion: {analysis['dominant_emotion']}")
    print(f"Distribution: {analysis['emotion_percentages']}")
    
    score = calculate_emotional_score(results)
    print(f"Emotional score: {score:.2f}")

# Example 6: Base64 image
def example_base64():
    from emotion_system import EmotionDetector
    import base64
    
    detector = EmotionDetector(model_path='best_new_emotion_model.pt')
    
    with open('image.jpg', 'rb') as f:
        img_base64 = base64.b64encode(f.read()).decode()
    
    result = detector.predict_from_base64(img_base64)
    print(f"Emotion: {result['emotion']}")

# Example 7: MongoDB integration
def example_mongodb():
    from emotion_system import EmotionDetector, EmotionDatabase
    
    detector = EmotionDetector(model_path='best_new_emotion_model.pt')
    db = EmotionDatabase(
        mongo_uri="mongodb://localhost:27017",
        db_name="emotion_db"
    )
    
    # Predict and store
    result = detector.predict('image.jpg')
    doc_id = db.insert_detection(result, session_id="test_session")
    
    # Get session results
    session_results = db.get_session_results("test_session")
    print(f"Session has {len(session_results)} detections")
    
    db.close()

# Example 8: FastAPI testing
def example_api_test():
    import requests
    
    # Test health
    response = requests.get('http://localhost:8000/health')
    print(response.json())
    
    # Test prediction
    with open('test.jpg', 'rb') as f:
        files = {'file': f}
        response = requests.post('http://localhost:8000/predict', files=files)
        print(response.json())

if __name__ == '__main__':
    print("Emotion Detection System - Examples")
    print("Run individual example functions to test different features")
