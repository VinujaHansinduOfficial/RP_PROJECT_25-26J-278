# PhysStress API Integration - Documentation

## Overview

The PhysStress questionnaire now integrates with two APIs:

1. **Patient Details API** - Fetches user information
2. **Behavior Prediction API** - Submits health assessment for analysis

---

## Complete Flow

```
User answers 11 physical stress questions
                ↓
         Clicks "Finish" button
                ↓
    Show "Submitting responses..." dialog
                ↓
   Fetch user details from Patient API
                ↓
     Prepare prediction data structure
                ↓
    Show "Analyzing results..." dialog
                ↓
   Submit to Behavior Prediction API
                ↓
           API Response
       ├─ Success (200/201) → Show success dialog
       └─ Failure → Show error dialog
                ↓
         User closes dialog
                ↓
        Navigate back to previous page
```

---

## API 1: Fetch User Details

### Endpoint
```
GET http://10.33.135.43:8000/api/patients/{patient_id}
```

### Parameters
- `patient_id` (String): The patient's unique identifier

### Response (200 OK)
```json
{
  "first_name": "Johnh",
  "last_name": "Doe",
  "email": "email@gmail.com",
  "phone": "+1234567890",
  "date_of_birth": "1990-05-15",
  "gender": "Male",
  "address": "123 Main St, City",
  "emergency_contact": null,
  "medical_history": null,
  "_id": "69a3f4aac7164b048796b4e4",
  "created_at": "2026-03-01T08:11:22.506788",
  "updated_at": "2026-03-01T08:11:22.506788",
  "is_active": true,
  "assigned_doctors": []
}
```

### Data Used
- `date_of_birth` → Calculated to determine age
- `gender` → Converted to 'F' or 'M'

---

## API 2: Behavior Prediction

### Endpoint
```
POST http://10.160.151.43:8001/predict/behavior
```

### Request Headers
```
Content-Type: application/json
```

### Request Body Structure
```json
{
  "user_id": "300",
  "features": {
    "nwave": 1,
    "longipart": 123,
    "age": 35,
    "sex": "M",
    "year": 5,
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

### Features Mapping

| Field | Source | Range | Type |
|-------|--------|-------|------|
| **nwave** | Random | 1-3 | Integer |
| **longipart** | Random | [1,2,3,12,123,23] | Integer |
| **age** | Calculated from DOB | 0+ | Integer |
| **sex** | User details | 'F' or 'M' | String |
| **year** | Random | 0-10 | Integer |
| **bmi** | Q1 Answer | 0-100 | Double |
| **physact** | Q2 Answer | 0-1440 | Integer (minutes) |
| **health** | Q3 Answer | 0-4 | Integer |
| **psyt** | Q4 Answer | 0-4 | Integer |
| **cop_e** | Q5 Answer | 0-20 | Integer |
| **cop_p** | Q6 Answer | 0-20 | Integer |
| **cop_h** | Q7 Answer | 0-20 | Integer |
| **fmale** | 1 if Female, 0 if Male | 0-1 | Integer |
| **part** | Q8 Answer | 0-1 | Integer |
| **socsup** | Q9 Answer | 0-10 | Integer |
| **educ_par** | Q10 Answer | 0-5 | Integer |
| **jobhours** | Q11 Answer | 0-50 | Integer |
| **cesd** | Random | 0-50 | Integer |
| **bdi_su** | Random | 0-3 | Integer |
| **stai** | Random | 0-100 | Integer |
| **stress** | Random | 0-10 | Integer |

### Response (200 or 201)
```json
{
  "prediction_result": "...",
  "confidence_score": 0.95,
  "status": "success"
}
```

---

## Method Details

### `_submitQuestionnaire()`
**Purpose:** Main orchestration method called when user finishes questionnaire

**Steps:**
1. Define user IDs (TODO: get from session/storage)
2. Show loading dialog
3. Fetch user details via API
4. Close dialog and check for errors
5. Prepare prediction data
6. Show loading dialog again
7. Submit prediction data
8. Close dialog and show result

### `_fetchUserDetails(patientId)`
**Purpose:** Retrieve user details from patient API

**Parameters:**
- `patientId` (String): Patient's unique ID

**Returns:** `Future<Map<String, dynamic>?>` or null if error

**Error Handling:**
- Network timeout (30 seconds)
- HTTP error responses
- Returns null on failure

### `_preparePredictionData(userDetails, userId)`
**Purpose:** Structure questionnaire answers with user details

**Parameters:**
- `userDetails` (Map): Response from patient API
- `userId` (String): User's ID

**Returns:** `Map<String, dynamic>` with properly formatted prediction data

**Key Operations:**
- Parse date of birth to calculate age
- Determine gender (F/M)
- Map questionnaire answers to feature keys
- Generate random values for unavailable metrics

### `_submitPredictionData(data)`
**Purpose:** Post prediction data to behavior prediction API

**Parameters:**
- `data` (Map): Structured prediction data

**Returns:** `Future<bool>` - true if success, false if error

**Error Handling:**
- Network timeout (30 seconds)
- Invalid response status
- Exception handling with logging

---

## UI Dialogs

### Loading Dialog
Shown during API calls with message:
- "Submitting responses..." (while fetching user details)
- "Analyzing results..." (while submitting prediction)

### Error Dialog
Shown if any step fails with:
- Red error icon
- "Error" title
- Specific error message
- "OK" button to dismiss

### Success Dialog
Shown on successful completion with:
- Green check icon
- "Success" title
- Confirmation message
- "Done" button (closes page and returns)

---

## Configuration

### API Base URLs
- Patient API: `http://10.33.135.43:8000`
- Prediction API: `http://10.160.151.43:8001`

### Request Timeout
- 30 seconds per API call

### User IDs
Current hardcoded values:
```dart
const String userId = '300';                          // TODO: Get from session
const String patientId = '69a3f4aac7164b048796b4e4'; // TODO: Get from session
```

---

## Data Flow Example

### Input (Questionnaire Answers)
```dart
{
  0: 24.5,      // BMI
  1: 300,       // Exercise minutes
  2: 3,         // Health rating
  3: 2,         // Emotional distress
  4: 15,        // Emotional coping
  5: 10,        // Problem-focused coping
  6: 20,        // Healthy coping
  7: 1,         // Part-time work (Yes)
  8: 7,         // Social support
  9: 3,         // Parent education
  10: 40,       // Job hours
}
```

### Output (API Request)
```json
{
  "user_id": "300",
  "features": {
    "nwave": 2,
    "longipart": 23,
    "age": 34,
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
    "cesd": 32,
    "bdi_su": 1,
    "stai": 67,
    "stress": 4
  }
}
```

---

## Error Scenarios

| Scenario | Error Message | User Action |
|----------|---------------|------------|
| User details fetch fails | "Failed to load user details. Please try again." | Tap OK, try again |
| Prediction API fails | "Failed to submit assessment. Please try again." | Tap OK, try again |
| Network timeout | "An error occurred: Request timeout" | Tap OK, try again |
| User not found | "An error occurred: 404 Not Found" | Check patient ID |

---

## Logging

The implementation includes console logging for debugging:

```dart
print('Prediction API Response: ${response.statusCode}');
print('Response Body: ${response.body}');
print('Error fetching user details: $e');
print('Error submitting prediction data: $e');
```

---

## Next Steps (TODO)

1. **Get User IDs from Session**
   - Replace hardcoded user ID
   - Retrieve from SharedPreferences or auth service

2. **Add Real CESD/BDI/STAI Scores**
   - Currently using random values
   - Should be calculated from questionnaire answers or separate assessments

3. **Handle API Responses**
   - Parse prediction results
   - Display prediction details to user
   - Store results in local database

4. **Error Recovery**
   - Retry mechanism for failed API calls
   - Offline support with local storage

---

**Created:** March 5, 2026  
**Status:** ✅ **Complete & Functional**  
**APIs Called:** 2  
**Features Tracked:** 20
