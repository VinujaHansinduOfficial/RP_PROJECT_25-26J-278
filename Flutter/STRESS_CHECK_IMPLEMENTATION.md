# Stress Check Flow - Complete Implementation

## Flow Overview

```
1. App Starts
   ↓
2. Fetch User Features (Heart_Rate, Screen_Time)
   ↓
3. Display 3-Question Questionnaire
   ↓
4. User Completes Questionnaire
   ↓
5. Call API: predictStress() with complete payload
   ↓
6. Display Results (Stressed/Not Stressed + Confidence %)
```

## API Implementation Details

### Step 1: Fetch User Features
**When:** On initialization (`initState`)
**Method:** `StressApiService.getUserFeatures(userId)`
**Data Retrieved:**
- `Heart_Rate` (stored in `_heartRate`)
- `Screen_Time` (stored in `_screenTime`)

### Step 2: Display Questionnaire
**Questions (3 total):**

1. **Noise Exposure** - Grid selection
   - Options: "Very Quiet", "Low Noise", "Medium Noise", "Very Noisy"
   - Returns: Index 0-3

2. **Social Interaction** - Number input (1-10)
   - Range: 1-10 scale
   - Returns: Integer value

3. **Work Hours** - Number input (0-24)
   - Range: 0-24 hours
   - Returns: Integer value

### Step 3: Complete Questionnaire & Call API
**When:** User completes all questions and clicks "Get Prediction"

**API Call:** `StressApiService.predictStress(userId, payload)`

**Payload Structure:**
```dart
{
  'Age': 0,  // Not collected (set to 0, can be updated if needed)
  'Heart_Rate': _heartRate,  // Fetched from API
  'Work_Hours': answersData['Work_Hours'],  // From questionnaire
  'Screen_Time': _screenTime,  // Fetched from API
  'Social_Interaction': answersData['Social_Interaction'],  // From questionnaire
  'Noise_Exposure': answersData['Noise_Exposure'],  // From questionnaire
}
```

### Step 4: Display Results
**Response Data Used:**
- `prediction` (0 or 1): 0 = Not Stressed, 1 = Stressed
- `probability` (0-1): Confidence score

**Result Display:**
- **Status**: "You Are Stressed" or "You Are Not Stressed"
- **Confidence**: Shows percentage (e.g., 71.5%)
- **Color Coding**:
  - Red: Stressed
  - Green: Not Stressed

## Code Structure

### State Variables
```dart
bool _showingQuestionnaire = false;  // Toggle between questionnaire/results
bool _isLoading = false;             // Loading indicator
Map<String, dynamic>? _predictionResult;  // API response
String? _errorMessage;               // Error handling
double _heartRate = 0.0;             // Fetched from API
double _screenTime = 0.0;            // Fetched from API
```

### Key Methods

1. **_fetchUserFeatures()** - Runs on init
   - Fetches user data from backend
   - Sets _heartRate and _screenTime
   - Shows questionnaire when complete

2. **_onQuestionnaireCompleted()** - Runs when quiz finishes
   - Builds payload with all required data
   - Calls predictStress() API
   - Shows results screen when complete

3. **build()** - Main widget
   - Shows loading → questionnaire → results flow

## Error Handling

- Shows error message if feature fetch fails
- Shows error message if prediction API fails
- Provides "Retry" button on error

## User Journey

```
┌─────────────────────────────────────┐
│  StressCheckFlow                    │
│  (Receives userId)                  │
└────────────┬────────────────────────┘
             │
             ▼
    ┌─────────────────────┐
    │ Loading...          │
    │ Fetching features   │
    └────────┬────────────┘
             │
             ▼
    ┌─────────────────────────────────┐
    │ Question 1: Noise Exposure      │
    │ (Grid selection)                │
    │ [Next] button                   │
    └────────┬────────────────────────┘
             │
             ▼
    ┌─────────────────────────────────┐
    │ Question 2: Social Interaction  │
    │ (Number input 1-10)             │
    │ [Next] button                   │
    └────────┬────────────────────────┘
             │
             ▼
    ┌─────────────────────────────────┐
    │ Question 3: Work Hours          │
    │ (Number input 0-24)             │
    │ [Get Prediction] button         │
    └────────┬────────────────────────┘
             │
             ▼
    ┌─────────────────────┐
    │ Loading...          │
    │ Calling API         │
    └────────┬────────────┘
             │
             ▼
    ┌──────────────────────────────────┐
    │ Result Screen                    │
    │ "You Are [Stressed|Not Stressed]"│
    │ Confidence: XX.X%               │
    │ [Close] button                   │
    └──────────────────────────────────┘
```

## Dependencies

- `StressApiService.getUserFeatures(userId)` - Get Heart_Rate, Screen_Time
- `StressApiService.predictStress(userId, payload)` - Get prediction result

## Notes

- Age is currently hardcoded as 0 in payload (can be updated if collected from user)
- All questionnaire answers are validated before enabling "Get Prediction" button
- App remains responsive during API calls with loading indicators
- Results display prediction status and confidence percentage
