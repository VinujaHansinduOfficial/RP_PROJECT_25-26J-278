# Anxiety Check Flow - Refactoring Summary

## Overview
The `anxiety_check_flow.dart` and `anxiety_quiz.dart` files have been refactored to follow the same clean design pattern as `DepressionCheckFlow`. The new implementation provides a streamlined user experience with proper data fetching, questionnaire display, API calls, and result presentation.

## Architecture

### Flow Diagram
```
┌─────────────────────────────────────┐
│  AnxietyCheckFlow                   │
│  (Receives userId from AnxietyQuiz) │
└────────────────┬────────────────────┘
                 │
                 ▼
    ┌─────────────────────────┐
    │ Fetch User Details      │
    │ (Age from /api/patients)│
    └────────┬────────────────┘
             │
             ▼
    ┌─────────────────────────┐
    │ Fetch User Features     │
    │ (Sleep, Screen Time)    │
    └────────┬────────────────┘
             │
             ▼
    ┌─────────────────────────────────┐
    │ Display Questionnaire (8 Qs)    │
    │ - Tech Usage Hours              │
    │ - Sensory Sensitivity           │
    │ - Multitasking Habit            │
    │ - Irritability Score            │
    │ - Work Hours                    │
    │ - Exercise Hours                │
    │ - Social Interaction            │
    │ - Noise Exposure                │
    └────────┬────────────────────────┘
             │
             ▼
    ┌──────────────────────────────────┐
    │ Call API: predictAnxiety()       │
    │ Payload includes:                │
    │ - Questionnaire answers          │
    │ - Sleep_Hours (fetched)          │
    │ - Screen_Time (fetched)          │
    │ - Age (fetched)                  │
    └────────┬─────────────────────────┘
             │
             ▼
    ┌──────────────────────────────────┐
    │ Display Results Screen           │
    │ - Status (Anxiety/No Anxiety)    │
    │ - Confidence %                   │
    │ - Close Button                   │
    └──────────────────────────────────┘
```

## Key Components

### 1. _AnxietyCheckFlowState
- **_fetchUserDetails()** - Gets user age from `/api/patients/{userId}`
- **_fetchUserFeatures()** - Gets Sleep_Hours and Screen_Time
- **_onQuestionnaireCompleted()** - Builds payload and calls predictAnxiety API
- **_retry()** - Resets state and starts over

### 2. _AnxietyQuestionnaire (8 Questions)
Questions asked in sequence:

| # | Question | Type | Range |
|---|----------|------|-------|
| 1 | Tech Usage Hours | number_hours_day | 0-24 |
| 2 | Sensory Sensitivity | rating_scale | 1-10 |
| 3 | Multitasking Habit | frequency_grid | 5 options |
| 4 | Irritability Score | rating_scale | 1-10 |
| 5 | Work Hours | number_hours_week | 0-168 |
| 6 | Exercise Hours | number_hours_week | 0-168 |
| 7 | Social Interaction | number_1_10 | 1-10 |
| 8 | Noise Exposure | frequency_grid | 4 options |

### 3. _ResultScreen
Displays prediction results with:
- ✅ Status (High Anxiety Detected / No Anxiety Detected)
- ✅ Confidence percentage
- ✅ Visual indicator (icon + color)
- ✅ Close button

## Data Flow

### Imports Added
```dart
import 'package:health_research/services/AnxietyApiService.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:health_research/config/api_config.dart';
```

### State Variables
```dart
bool _showingQuestionnaire = false;   // Toggle between questionnaire/results
bool _isLoading = false;              // Loading indicator
Map<String, dynamic>? _predictionResult;  // API response
String? _errorMessage;                // Error handling
double _screenTime = 0.0;             // Fetched from API
double _sleepHours = 5.0;             // Fetched from API (default 5)
double _age = 0.0;                    // Fetched from /api/patients endpoint
```

## API Integration

### 1. Fetch User Details (Patient Age)
**Endpoint:** `GET /api/patients/{userId}`
**Extracts:** `age` field

### 2. Fetch User Features
**Endpoint:** `GET /api/users/{userId}/features`
**Extracts:** `Sleep_Hours`, `Screen_Time`

### 3. Predict Anxiety
**Endpoint:** `POST /api/predictions/anxiety`
**Payload:**
```json
{
  "user_id": "user_id",
  "data": {
    "Tech_Usage_Hours": 5,
    "Sensory_Sensitivity": 7,
    "Multitasking_Habit": 2,
    "Irritability_Score": 6,
    "Work_Hours": 40,
    "Exercise_Hours": 5,
    "Social_Interaction": 8,
    "Noise_Exposure": 1,
    "Sleep_Hours": 7.5,
    "Screen_Time": 4.0,
    "Age": 25
  }
}
```

**Response:**
```json
{
  "data": {
    "prediction": 0,  // 0 = No Anxiety, 1 = Anxiety
    "probability": 0.65
  }
}
```

## Changes from Previous Implementation

### ✅ Improvements
1. **Cleaner UI** - Single questionnaire flow instead of multiple screens
2. **User Data** - Automatically fetches age from patient API
3. **Better Defaults** - Sleep hours defaults to 5 instead of 0
4. **Proper Error Handling** - Loading states, error messages, retry button
5. **Consistent Design** - Matches DepressionCheckFlow pattern
6. **StateCell Management** - Simple boolean flags instead of step numbers
7. **Direct API Calls** - User answers directly contribute to payload
8. **Result Display** - Shows prediction immediately with proper nested data extraction

### ❌ Removed
- Complex step management (0, 1, 2)
- Unnecessary wrapper classes
- Redundant data transformation
- Multiple intermediate screens

## Testing Checklist
- [ ] User navigates from AnxietyQuiz to AnxietyCheckFlow
- [ ] User age is fetched from /api/patients endpoint
- [ ] Sleep hours and screen time are fetched correctly
- [ ] Questionnaire displays 8 questions
- [ ] All questions have proper validation
- [ ] API is called when questionnaire completes
- [ ] Results screen displays prediction
- [ ] Confidence percentage shows correctly
- [ ] Icons and colors match status (red for anxiety, green for no anxiety)
- [ ] Close button returns to previous screen

## API Payload Example

**Request:**
```json
{
  "Tech_Usage_Hours": 6,
  "Sensory_Sensitivity": 8,
  "Multitasking_Habit": 3,
  "Irritability_Score": 5,
  "Work_Hours": 45,
  "Exercise_Hours": 3,
  "Social_Interaction": 7,
  "Noise_Exposure": 2,
  "Sleep_Hours": 6.5,
  "Screen_Time": 5.0,
  "Age": 28
}
```

**Response:**
```json
{
  "message": "Saved successfully",
  "data": {
    "prediction": 1,
    "probability": 0.78,
    "created_at": "2026-03-10T10:30:00",
    "_id": "12345..."
  }
}
```

Everything is now aligned with the DepressionCheckFlow design pattern! 🎯
