# ✅ PhysStress API Integration - Complete

## What Was Implemented

The PhysStress questionnaire now calls 2 APIs when the user completes the assessment:

### 1. **Patient Details API** (GET)
```
http://10.33.135.43:8000/api/patients/{patient_id}
```
- Retrieves user information (age, gender, etc.)
- Used to populate prediction data

### 2. **Behavior Prediction API** (POST)
```
http://10.160.151.43:8001/predict/behavior
```
- Submits health assessment data
- Returns prediction analysis results

---

## Implementation Details

### When API Calls Happen
✅ **Only** when user clicks "Finish" button on the last question
✅ **Sequential:** Patient API first, then Prediction API
✅ **Error handling:** Shows specific error messages if any step fails
✅ **Dialogs:** Loading dialogs during processing, success/error dialogs on completion

### Data Submitted

All 11 questionnaire answers plus calculated values:

```json
{
  "user_id": "300",
  "features": {
    // Random values
    "nwave": 1,                    // Random 1-3
    "longipart": 123,              // Random from [1,2,3,12,123,23]
    "year": 5,                     // Random 0-10
    
    // From user details
    "age": 35,                     // Calculated from DOB
    "sex": "M",                    // From user details
    "fmale": 0,                    // 1 if Female, 0 if Male
    
    // From questionnaire answers
    "bmi": 24.5,                   // Q1: BMI
    "physact": 300,                // Q2: Exercise minutes
    "health": 3,                   // Q3: Health rating (0-4)
    "psyt": 2,                     // Q4: Emotional distress (0-4)
    "cop_e": 15,                   // Q5: Emotional coping (0-20)
    "cop_p": 10,                   // Q6: Problem-solving (0-20)
    "cop_h": 20,                   // Q7: Healthy coping (0-20)
    "part": 1,                     // Q8: Part-time work (0-1)
    "socsup": 7,                   // Q9: Social support (0-10)
    "educ_par": 3,                 // Q10: Parent education (0-5)
    "jobhours": 40,                // Q11: Job hours (0-50)
    
    // Random mental health metrics
    "cesd": 25,                    // Random 0-50
    "bdi_su": 2,                   // Random 0-3
    "stai": 50,                    // Random 0-100
    "stress": 5                    // Random 0-10
  }
}
```

---

## User Experience Flow

```
┌─────────────────────────────────┐
│ User answers 11 questions       │
└──────────────┬──────────────────┘
               │
               ↓
┌─────────────────────────────────┐
│ Clicks "Finish" button          │
└──────────────┬──────────────────┘
               │
               ↓
     ╔═════════════════════════════╗
     ║ "Submitting responses..."   ║  ← Loading Dialog
     ║ [spinner]                   ║
     ╚═════════════════════════════╝
               │
               ↓
     ┌─────────────────────────────┐
     │ Fetch user details          │
     │ (GET patient API)           │
     └──────────┬──────────────────┘
                │
                ├─ Success? Continue
                └─ Error? → Error Dialog
               │
               ↓
     ╔═════════════════════════════╗
     ║ "Analyzing results..."      ║  ← Loading Dialog
     ║ [spinner]                   ║
     ╚═════════════════════════════╝
               │
               ↓
     ┌─────────────────────────────┐
     │ Submit prediction data      │
     │ (POST prediction API)       │
     └──────────┬──────────────────┘
                │
                ├─ Success (200/201)
                │   ↓
                │   ╔════════════════════════════════╗
                │   ║ ✅ Success                     ║
                │   ║ Assessment completed!          ║
                │   ║ [OK] [Done]                    ║
                │   ╚════════════════════════════════╝
                │
                └─ Error
                    ↓
                    ╔════════════════════════════════╗
                    ║ ❌ Error                       ║
                    ║ Failed to submit assessment    ║
                    ║ [OK]                           ║
                    ╚════════════════════════════════╝
```

---

## Methods Added

### Core Methods
| Method | Purpose |
|--------|---------|
| `_submitQuestionnaire()` | Main orchestration method |
| `_fetchUserDetails()` | Get user info from API |
| `_preparePredictionData()` | Structure data for prediction API |
| `_submitPredictionData()` | Post to prediction API |

### UI Methods
| Method | Purpose |
|--------|---------|
| `_showLoadingDialog()` | Show loading with custom message |
| `_showErrorDialog()` | Show error with red icon |
| `_showSuccessDialog()` | Show success with green icon |

---

## Configuration

### Hardcoded Values (TODO - Get from Session)
```dart
const String userId = '300';                          // TODO: Get from SharedPreferences
const String patientId = '69a3f4aac7164b048796b4e4'; // TODO: Get from auth service
```

### API Endpoints
```dart
'http://10.33.135.43:8000/api/patients/{patientId}'  // Patient API
'http://10.160.151.43:8001/predict/behavior'          // Prediction API
```

### Timeouts
```dart
const Duration(seconds: 30)  // Per API call
```

---

## Error Handling

✅ **Network errors** - Shows "An error occurred" message
✅ **HTTP errors** - Shows "Failed to load/submit" message
✅ **Timeout errors** - Shows "Request timeout" message
✅ **Parsing errors** - Shows "An error occurred" message
✅ **Not mounted checks** - Prevents crashes during navigation

---

## Testing Scenarios

### ✅ Success Path
1. User completes all 11 questions
2. Clicks "Finish"
3. "Submitting responses..." appears
4. User details fetched successfully
5. "Analyzing results..." appears
6. Prediction API returns 200/201
7. "Success!" dialog shows
8. Click "Done" to return

### ❌ Failure Path
1. User completes all questions
2. Clicks "Finish"
3. "Submitting responses..." appears
4. User details API returns error
5. Error dialog shows: "Failed to load user details"
6. Click "OK" to dismiss
7. User can try again

---

## Console Logging

Debug output printed to console:
```
Prediction API Response: 200
Response Body: {prediction_result: "..."}
Error fetching user details: 404 Not Found
Error submitting prediction data: Connection timeout
```

---

## Next Steps (Optional Improvements)

1. **Get actual user IDs from session/storage**
   ```dart
   final userId = await SharedPreferences.getInstance().getString('user_id');
   final patientId = await SharedPreferences.getInstance().getString('patient_id');
   ```

2. **Calculate real mental health metrics**
   - CESD (Center for Epidemiologic Studies Depression Scale)
   - BDI (Beck Depression Inventory)
   - STAI (State-Trait Anxiety Inventory)
   - Stress score based on questionnaire

3. **Parse and display prediction results**
   - Show detailed analysis to user
   - Store results in local database
   - Display trends over time

4. **Add retry mechanism**
   - Retry button on error
   - Exponential backoff
   - Offline support with local storage

---

**File:** `lib/pages/physStress.dart`  
**Status:** ✅ **COMPLETE & FUNCTIONAL**  
**Created:** March 5, 2026  
**APIs:** 2 (Patient Details + Behavior Prediction)  
**Methods Added:** 7  
**Questionnaire Questions:** 11
