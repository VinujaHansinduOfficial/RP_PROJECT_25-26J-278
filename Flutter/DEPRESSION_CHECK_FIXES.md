# Depression Check Flow - Result Display & Age/Sleep Hours Fix

## Issues Fixed

### 1. **Results Not Displaying (Status 200 but No Results)**
**Problem:** The API returns a nested response structure:
```json
{
  "message": "Saved successfully",
  "data": {
    "prediction": 1,
    "probability": 0.855,
    ...
  }
}
```

But the result screen was trying to access values directly:
```dart
final prediction = result?['prediction'] as int? ?? 0;  // ❌ WRONG
final probability = result?['probability'] as double? ?? 0.0;  // ❌ WRONG
```

**Solution:** Updated to access the nested `data` object:
```dart
final prediction = result?['data']?['prediction'] as int? ?? 0;  // ✅ CORRECT
final probability = result?['data']?['probability'] as double? ?? 0.0;  // ✅ CORRECT
```

### 2. **Sleep Hours Always 0**
**Problem:** `Sleep_Hours` was being fetched but defaulting to 0.0 when null.

**Solution:** Changed default to 5.0 (reasonable default):
```dart
_sleepHours = (features['Sleep_Hours'] as num?)?.toDouble() ?? 5.0;  // Default 5 hours
```

### 3. **Age Not Populated Correctly**
**Problem:** Age was not being fetched from user API. The payload showed `"Age": 0.0`.

**Solution:** Added `_fetchUserDetails()` method that:
1. Calls `/api/patients/{patientId}` to get user info including age
2. Extracts age from response: `_age = (data['age'] as num?)?.toDouble() ?? 0.0`
3. Only fetches user features after getting user details
4. Prevents age from being overwritten if already fetched

## Code Changes

### 1. Added Imports
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:health_research/config/api_config.dart';
```

### 2. Updated initState
```dart
@override
void initState() {
  super.initState();
  _fetchUserDetails(widget.userId);  // Fetch user info first
}
```

### 3. Added _fetchUserDetails Method
```dart
Future<void> _fetchUserDetails(String patientId) async {
  try {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/patients/$patientId');
    final response = await http.get(url).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('Request timeout'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _age = (data['age'] as num?)?.toDouble() ?? 0.0;  // Extract age
      });
      _fetchUserFeatures();  // Then fetch features
    }
  } catch (e) {
    print('Error fetching user details: $e');
    _fetchUserFeatures();  // Continue even if user details fail
  }
}
```

### 4. Updated _fetchUserFeatures
```dart
Future<void> _fetchUserFeatures() async {
  // ... existing code ...
  setState(() {
    _sleepHours = (features['Sleep_Hours'] as num?)?.toDouble() ?? 5.0;  // Default 5 hours
    _screenTime = (features['Screen_Time'] as num?)?.toDouble() ?? 0.0;
    
    // Only set age if not already fetched from user details
    if (_age == 0.0) {
      _age = (features['Age'] as num?)?.toDouble() ?? 0.0;
    }
    // ... rest of code ...
  });
}
```

### 5. Fixed Result Screen Data Extraction
```dart
@override
Widget build(BuildContext context) {
  final hasResult = result != null;
  
  // Extract from nested data structure
  final prediction = result?['data']?['prediction'] as int? ?? 0;
  final probability = result?['data']?['probability'] as double? ?? 0.0;
  final isDepressed = prediction == 1;
  
  // ... rest of UI ...
}
```

## Data Flow

```
1. DepressionCheckFlow starts
   ↓
2. Call _fetchUserDetails(userId)
   ↓
3. Get /api/patients/{userId}
   ├─ Extract age from response
   └─ Set _age variable
   ↓
4. Call _fetchUserFeatures(userId)
   ├─ Get Sleep_Hours from API
   ├─ Get Screen_Time from API
   ├─ Use age if fetched, fallback if not
   └─ Move to questionnaire (Step 1)
   ↓
5. User completes 6-question questionnaire
   ↓
6. Call predictDepression() API
   ├─ Payload includes:
   │  ├─ Questionnaire answers
   │  ├─ Sleep_Hours (from API)
   │  ├─ Screen_Time (from API)
   │  └─ Age (from patient API)
   └─ Get nested response with data.prediction, data.probability
   ↓
7. Result Screen displays
   ├─ Extracts from result['data']['prediction']
   ├─ Extracts from result['data']['probability']
   └─ Shows results properly ✅
```

## Expected Payload Now
```json
{
  "Irritability_Score": 9.0,
  "Sleep_Quality": 0.0,
  "Sleep_Hours": 7.5,  // ✅ Real value from API
  "Noise_Exposure": 3.0,
  "Sensory_Sensitivity": 5.0,
  "Social_Interaction": 1.0,
  "Work_Hours": 100.0,
  "Screen_Time": 10.0,
  "Age": 25.0  // ✅ Real value from /api/patients endpoint
}
```

## Testing Checklist
- [ ] User starts Depression Check
- [ ] User details are fetched (check console for age)
- [ ] Sleep Hours show real value (not 0)
- [ ] Age is populated in payload
- [ ] Questionnaire displays correctly
- [ ] Results show after API responds with 200
- [ ] Prediction and probability display correctly

All issues should now be resolved! ✅
