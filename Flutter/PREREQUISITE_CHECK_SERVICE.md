# Prerequisite Check Service - Documentation

## Overview

The `PrerequisiteCheckService` validates that users have completed all required tasks before accessing the OverStimulated questionnaire. It checks 4 different prerequisites via API calls.

---

## Prerequisites Checked

### 1. **User Features Check**
**Endpoint:** `GET http://10.160.151.43:8002/user_features/{user_id}`

**Purpose:** Verify user has added health tracking data
- Heart Rate
- Sleep Hours
- Screen Time

**Error Response (404):**
```json
{
  "detail": "User features not found"
}
```

**Error Message Shown:**
```
"You need to add "Heart Rate", "Sleep Hours", and "Screen Time" 
before taking this questionnaire"
```

**Success Response (200):**
```json
{
  "user_id": "300",
  "heart_rate": 72,
  "sleep_hours": 7.5,
  "screen_time": 4.2
}
```

---

### 2. **Stress Quiz Check**
**Endpoint:** `GET http://10.160.151.43:8002/results/stress/{user_id}`

**Purpose:** Verify user has completed daily stress assessment

**Check Condition:** Results array must NOT be empty

**Response Format:**
```json
{
  "user_id": "user300",
  "type": "Stress",
  "count": 0,
  "results": []
}
```

**Error Message Shown (if empty results):**
```
"Complete daily stress quiz before taking this questionnaire"
```

---

### 3. **Anxiety Quiz Check**
**Endpoint:** `GET http://10.160.151.43:8002/results/anxiety/{user_id}`

**Purpose:** Verify user has completed daily anxiety assessment

**Check Condition:** Results array must NOT be empty

**Response Format:**
```json
{
  "user_id": "300",
  "type": "Anxiety",
  "count": 0,
  "results": []
}
```

**Error Message Shown (if empty results):**
```
"Complete daily anxiety quiz before taking this questionnaire"
```

---

### 4. **Depression Quiz Check**
**Endpoint:** `GET http://10.160.151.43:8002/results/depression/{user_id}`

**Purpose:** Verify user has completed daily depression assessment

**Check Condition:** Results array must NOT be empty

**Response Format:**
```json
{
  "user_id": "300",
  "type": "Depression",
  "count": 0,
  "results": []
}
```

**Error Message Shown (if empty results):**
```
"Complete daily depression quiz before taking this questionnaire"
```

---

## API Flow

```
User clicks "Start Questionnaire"
            ↓
    Show Loading Dialog
            ↓
Check 1: User Features (404?)
    ├─ NO 404? Continue
    └─ 404? Show Error & Stop
            ↓
Check 2: Stress Results (Empty?)
    ├─ Not Empty? Continue
    └─ Empty? Show Error & Stop
            ↓
Check 3: Anxiety Results (Empty?)
    ├─ Not Empty? Continue
    └─ Empty? Show Error & Stop
            ↓
Check 4: Depression Results (Empty?)
    ├─ Not Empty? Continue
    └─ Empty? Show Error & Stop
            ↓
All Passed? ✅
    └─ Navigate to OverStimulatedQuestionnaire
```

---

## Service Methods

### `checkAllPrerequisites(userId)`
**Purpose:** Master method that checks all 4 prerequisites sequentially

**Parameters:**
- `userId` (String): The user's unique identifier

**Returns:** 
```dart
Future<Map<String, dynamic>>
{
  'success': bool,      // All checks passed?
  'message': String,    // Error/success message
  'type': String?       // Optional: Error type identifier
}
```

**Example:**
```dart
final result = await PrerequisiteCheckService.checkAllPrerequisites('300');

if (result['success']) {
  // All prerequisites met - proceed
} else {
  // Show error message
  print(result['message']);
}
```

---

### Individual Check Methods (Private)

#### `_checkUserFeatures(userId)`
- Checks if user features exist (404 check)
- Returns success only if status 200

#### `_checkStressResults(userId)`
- Checks if stress results exist (not empty)
- Returns error if results array is empty

#### `_checkAnxietyResults(userId)`
- Checks if anxiety results exist (not empty)
- Returns error if results array is empty

#### `_checkDepressionResults(userId)`
- Checks if depression results exist (not empty)
- Returns error if results array is empty

---

## Error Handling

### Network Errors
- Request timeout (30 seconds)
- Connection failures
- Returns error message with exception details

### API Errors
- 404 responses
- Empty results arrays
- Returns specific error messages for each case

### Exception Handling
All methods wrapped in try-catch to prevent crashes

---

## Integration with UI

### Overstimulated Page
The `Overstimulated` page integrates the service:

1. **User clicks quest button**
2. **Loading dialog shown**
3. **Service checks all prerequisites**
4. **Loading dialog closed**
5. **If success → Navigate to questionnaire**
6. **If error → Show error dialog**

### UI Components

**Loading Dialog:**
```
┌─────────────────────┐
│ Loading Indicator   │
│ Checking            │
│ prerequisites...    │
└─────────────────────┘
```

**Error Dialog:**
```
┌──────────────────────────┐
│ ❌ Unable to Continue    │
│                          │
│ [Error message here]     │
│                          │
│              [OK Button] │
└──────────────────────────┘
```

---

## Usage Example

```dart
// In Overstimulated page
Future<void> _checkAndNavigate() async {
  const String userId = '300';
  
  _showLoadingDialog();
  
  final result = await PrerequisiteCheckService.checkAllPrerequisites(userId);
  
  Navigator.pop(context); // Close loading
  
  if (result['success']) {
    // Navigate to questionnaire
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OverStimulatedQuestionnaire(),
      ),
    );
  } else {
    // Show error
    _showErrorDialog(result['message']);
  }
}
```

---

## Configuration

### Base URL
The service uses a hardcoded base URL:
```dart
static const String prerequisiteBaseUrl = 'http://10.160.151.43:8002';
```

To change this, update the constant in the service file.

### Request Timeout
Currently set to 30 seconds:
```dart
.timeout(
  const Duration(seconds: 30),
  onTimeout: () => throw Exception('Request timeout'),
)
```

---

## Response Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 404 | Not Found (User Features) |
| 500 | Server Error |
| Timeout | Connection timeout |

---

## Success Criteria

✅ **User Features:** Status 200 (file exists)
✅ **Stress Quiz:** Status 200 AND results not empty
✅ **Anxiety Quiz:** Status 200 AND results not empty
✅ **Depression Quiz:** Status 200 AND results not empty

---

## Testing

### Test Case 1: All Checks Pass
```
Expected: Navigate to questionnaire
```

### Test Case 2: Missing User Features
```
Expected: Show error "You need to add..."
```

### Test Case 3: Empty Stress Results
```
Expected: Show error "Complete daily stress quiz..."
```

### Test Case 4: Empty Anxiety Results
```
Expected: Show error "Complete daily anxiety quiz..."
```

### Test Case 5: Empty Depression Results
```
Expected: Show error "Complete daily depression quiz..."
```

### Test Case 6: Network Error
```
Expected: Show error "Error checking prerequisites..."
```

---

**Created:** March 5, 2026  
**Status:** ✅ **COMPLETE**
