# ✅ Burnout Prediction Implementation - Complete

## What Was Implemented

The PhysStress questionnaire now calls the burnout prediction API and displays a comprehensive result dialog with stress status and recommendations.

---

## 🔄 **Updated Flow**

```
User answers all 11 questions
            ↓
       Click "Finish"
            ↓
    Show "Submitting responses..." dialog
            ↓
    Fetch user details from API
            ↓
    Show "Analyzing results..." dialog
            ↓
Call: POST /predict/burnout
    └─ Submit all features + user data
            ↓
Parse prediction response:
    ├─ prediction == 1? → User is STRESSED
    └─ prediction == 0? → User is NOT STRESSED
            ↓
Show comprehensive result dialog:
    ├─ Stress status message
    ├─ Confidence score
    └─ Recommendations (if stressed)
            ↓
    Click "Done" to close
```

---

## 📡 **API Integration**

### Endpoint
```
POST http://10.160.151.43:8001/predict/burnout
```

### Request Body
```json
{
  "user_id": "300",
  "features": {
    "nwave": 2,
    "longipart": 123,
    "age": 35,
    "sex": "M",
    "year": 7,
    "bmi": 24.5,
    "physact": 300,
    "health": 3,
    "psyt": 2,
    "cop_e": 15,
    "cop_p": 10,
    "cop_h": 20,
    "fmale": 0,
    "part": 1,
    "socsup": 7,
    "educ_par": 3,
    "jobhours": 40,
    "cesd": 25,
    "bdi_su": 2,
    "stai": 50,
    "stress": 5
  }
}
```

### Response
```json
{
  "message": "Saved successfully",
  "data": {
    "_id": "69a9bd78dd27ceea656e0a88",
    "user_id": "string",
    "features": { ... },
    "prediction": 1,
    "probability": 0.5680973133955584,
    "threshold_used": 0.55,
    "created_at": "2026-03-05T17:29:28.295000"
  }
}
```

---

## 🎯 **Prediction Logic**

| Prediction | Message | Icon | Color |
|-----------|---------|------|-------|
| **1** | ⚠️ You are stressed | warning_amber | Orange |
| **0** | ✅ You are not stressed | check_circle | Green |

---

## 🎨 **Result Dialog UI**

The dialog displays:

1. **Header**
   - Status icon (warning or check)
   - "Assessment Result" title

2. **Main Message**
   - Large text showing stress status
   - Color-coded (orange/green)

3. **Confidence Score**
   - Percentage (0-100%)
   - Visual progress bar
   - Color-coded container

4. **Recommendations Section**
   - **If Stressed (prediction == 1):**
     - Take regular breaks
     - Practice mindfulness or meditation
     - Maintain a healthy sleep schedule
     - Consider talking to a healthcare provider
   
   - **If Not Stressed (prediction == 0):**
     - "Keep it up! 🎉"
     - Encouragement message
     - Continue with healthy habits

5. **Done Button**
   - Closes dialog
   - Returns to previous screen

---

## 📝 **Code Changes**

### 1. **_submitPredictionData() Method**
- Updated to call `/predict/burnout` endpoint
- Parses response to extract `prediction` and `probability`
- Determines stress status (prediction == 1)
- Calls `_showPredictionDialog()` with results
- Returns true if successful

### 2. **_showPredictionDialog() Method** (NEW)
- Displays comprehensive result dialog
- Shows different UI based on stress status
- Displays confidence score with progress bar
- Shows recommendations or encouragement
- Done button closes both dialogs

### 3. **_submitQuestionnaire() Method**
- Updated to not show success dialog
- Now only shows error dialog on failure
- Prediction dialog is shown automatically by _submitPredictionData

---

## ✨ **Features**

✅ **Burnout Prediction** - Analyzes all health metrics
✅ **Stress Status** - Clear message (stressed/not stressed)
✅ **Confidence Score** - Shows prediction probability
✅ **Visual Feedback** - Color-coded (orange/green)
✅ **Recommendations** - Personalized advice for stressed users
✅ **Encouragement** - Positive message for non-stressed users
✅ **Error Handling** - Graceful failure with error message
✅ **Loading States** - Shows progress during API calls

---

## 🔧 **Example Flows**

### Flow 1: User is Stressed
```
Prediction: 1
Probability: 0.568

Dialog shows:
- ⚠️ "You are stressed"
- Confidence: 56.8%
- Orange color scheme
- Stress management recommendations
```

### Flow 2: User is Not Stressed
```
Prediction: 0
Probability: 0.92

Dialog shows:
- ✅ "You are not stressed"
- Confidence: 92%
- Green color scheme
- Congratulations message
```

---

## 📊 **Response Parsing**

```dart
final responseData = jsonDecode(response.body);
final prediction = responseData['data']['prediction'];     // 0 or 1
final probability = responseData['data']['probability'];  // 0.0-1.0
```

**Stress Determination:**
```dart
final isStressed = prediction == 1;
```

---

## 🎯 **Dialog Components**

### Header
```dart
Row with:
- Icon (warning_amber or check_circle)
- "Assessment Result" text
```

### Message Box
```dart
Color-coded message:
- Orange for stressed
- Green for not stressed
```

### Confidence Section
```dart
- Percentage text (e.g., "56.8%")
- LinearProgressIndicator
- Color-coded background
```

### Recommendations
```dart
Conditional based on isStressed:
- If yes: 4-point recommendation list
- If no: Congratulations message
```

### Action
```dart
Done button that:
- Closes prediction dialog
- Returns to previous page
```

---

## ✅ **Testing Scenarios**

### ✅ Scenario 1: Stressed User
1. Complete 11 questions
2. Click Finish
3. API returns prediction = 1
4. See: "⚠️ You are stressed" dialog
5. See: Stress management recommendations
6. Click Done

### ✅ Scenario 2: Not Stressed User
1. Complete 11 questions
2. Click Finish
3. API returns prediction = 0
4. See: "✅ You are not stressed" dialog
5. See: Congratulations message
6. Click Done

### ❌ Scenario 3: API Error
1. Complete 11 questions
2. Click Finish
3. API call fails
4. See: "Failed to submit assessment" error
5. Can retry

---

## 📚 **Files Modified**

**File:** `lib/pages/physStress.dart`
- Updated: `_submitPredictionData()` 
- Updated: `_submitQuestionnaire()`
- Added: `_showPredictionDialog()`

---

**Status:** ✅ **COMPLETE & FUNCTIONAL**  
**API:** POST /predict/burnout  
**Prediction Logic:** prediction == 1 means stressed  
**Dialog:** Comprehensive with recommendations  
**Created:** March 5, 2026
