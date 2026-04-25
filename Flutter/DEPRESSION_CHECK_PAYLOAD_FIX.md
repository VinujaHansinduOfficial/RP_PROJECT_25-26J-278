# Depression Check Flow - Payload Fix Summary

## Issue Found
The values were not being assigned to the payload because:

1. **Missing setState() calls** in `_onNumberChanged()` - When numeric values were entered, they were stored in the `_answers` map but `setState()` wasn't being called every time, causing the UI not to update and button state not to refresh.

2. **Incorrect payload construction** - The payload had unnecessary/incorrect fields like:
   - `Social_Interaction_div_Exercise_Hours`
   - `Tech_Usage_Hours`
   - `num_missing`
   - `Overthinking_Score`
   - `Heart_Rate` (hardcoded 78.0)

## Fixes Applied

### 1. Fixed `_onNumberChanged()` Method
**Before:**
```dart
void _onNumberChanged(String value, String type) {
  // ... validation logic ...
  _answers[_currentIndex] = n;
  // Missing setState() calls in conditions!
  
  setState(() {}); // Called only once at the end
}
```

**After:**
```dart
void _onNumberChanged(String value, String type) {
  if (value.isEmpty) {
    _answers.remove(_currentIndex);
    setState(() {});
    return;
  }

  if (type == 'number_0_10' || type == 'number_1_10') {
    final n = int.tryParse(value);
    if (type == 'number_0_10' && n != null && n >= 0 && n <= 10) {
      _answers[_currentIndex] = n;
      setState(() {}); // ✅ Call setState immediately
    } else if (type == 'number_1_10' && n != null && n >= 1 && n <= 10) {
      _answers[_currentIndex] = n;
      setState(() {}); // ✅ Call setState immediately
    }
  } else if (type == 'number_hours_week') {
    final n = int.tryParse(value);
    if (n != null && n >= 0 && n <= 168) {
      _answers[_currentIndex] = n;
      setState(() {}); // ✅ Call setState immediately
    }
  }
}
```

### 2. Fixed Payload Construction
**Before:**
```dart
final payload = {
  'Irritability_Score': ...,
  'Sleep_Quality': ...,
  'Sleep_Hours': _sleepHours ?? 0.0,
  'Noise_Exposure': ...,
  'Sensory_Sensitivity': ...,
  'Social_Interaction_div_Exercise_Hours': 0.0, // ❌ Wrong key
  'Tech_Usage_Hours': 0.0, // ❌ Not in questionnaire
  'num_missing': 0.0, // ❌ Not needed
  'Overthinking_Score': 0, // ❌ Not in questionnaire
  'Screen_Time': _screenTime ?? 0.0,
  'Heart_Rate': 78.0, // ❌ Hardcoded
};
```

**After:**
```dart
final payload = {
  'Irritability_Score': (_depressionAnswersData!['Irritability_Score'] as num?)?.toDouble() ?? 0.0,
  'Sleep_Quality': (_depressionAnswersData!['Sleep_Quality'] as num?)?.toDouble() ?? 0.0,
  'Sleep_Hours': _sleepHours ?? 0.0,
  'Noise_Exposure': (_depressionAnswersData!['Noise_Exposure'] as num?)?.toDouble() ?? 0.0,
  'Sensory_Sensitivity': (_depressionAnswersData!['Sensory_Sensitivity'] as num?)?.toDouble() ?? 0.0,
  'Social_Interaction': (_depressionAnswersData!['Social_Interaction'] as num?)?.toDouble() ?? 0.0,
  'Work_Hours': (_depressionAnswersData!['Work_Hours'] as num?)?.toDouble() ?? 0.0,
  'Screen_Time': _screenTime ?? 0.0,
  'Age': _age ?? 0.0,
};
```

### 3. Added Debugging Statements
- Print in `_next()`: Logs all collected answers when quiz completes
- Print in `_onDepressionQuestionnaireCompleted()`: Logs answers received from questionnaire
- Print in `_submitDepressionAssessment()`: Logs final payload being sent to API

## Questions & Answer Keys
The questionnaire collects 6 questions mapped to these keys:

| Question | Answer Key | Type | Values |
|----------|-----------|------|--------|
| Irritability | `Irritability_Score` | 0-10 | Integer |
| Sleep Quality | `Sleep_Quality` | Grid | 0-4 (indices) |
| Work Hours | `Work_Hours` | 0-168 | Integer |
| Social Interaction | `Social_Interaction` | 1-10 | Integer |
| Noise Exposure | `Noise_Exposure` | Grid | 0-3 (indices) |
| Sensory Sensitivity | `Sensory_Sensitivity` | 0-10 | Integer |

## API Payload Structure
```json
{
  "user_id": "user301",
  "data": {
    "Irritability_Score": 7.0,
    "Sleep_Quality": 2.0,
    "Sleep_Hours": 7.5,
    "Noise_Exposure": 1.0,
    "Sensory_Sensitivity": 6.0,
    "Social_Interaction": 5.0,
    "Work_Hours": 40.0,
    "Screen_Time": 3.5,
    "Age": 25.0
  }
}
```

## Data Flow
```
1. User starts Depression Check
   ↓
2. Fetch user features (Sleep_Hours, Screen_Time, Age)
   ↓
3. Display 6-question questionnaire
   ↓
4. User answers each question
   ↓
5. Values stored in _answers map with setState() called immediately
   ↓
6. User completes quiz → _next() prints answers
   ↓
7. _answersData getter maps answers to keys
   ↓
8. _onDepressionQuestionnaireCompleted() receives mapped answers
   ↓
9. _submitDepressionAssessment() builds payload with:
   - Questionnaire answers (mapped)
   - Fetched user features
   ↓
10. predictDepression() API called with complete payload
   ↓
11. Results displayed
```

## How to Verify
Check the Dart console logs:
1. Look for `"Depression answers: {..."` - Confirms answers are collected
2. Look for `"Questionnaire completed with answers: {...}"` - Confirms answers mapped correctly
3. Look for `"Submitting depression assessment with payload: {...}"` - Confirms all values in payload
4. Look for `"Answers data: {...}"` - Confirms stored answers

All values should now be properly assigned to the payload! ✅
