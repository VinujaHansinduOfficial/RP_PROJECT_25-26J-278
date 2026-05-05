# ✅ Questionnaire Button Enable Issue - FIXED

## Problem
The "Finish" button was not becoming enabled when users entered values for percentage, text_input, and time_input types, even though the values were being entered correctly.

## Root Cause
The `onChanged` callbacks for these input types were saving the values to the `_answers` map but were **not calling `setState()`** to notify the Flutter widget that the state had changed. This meant the `_isNextEnabled` getter was never being re-evaluated.

## Solution
Added `setState()` calls to all three problematic input types:

### 1. **Percentage Input** (Line 631-635)
```dart
onChanged: (v) {
  final num = int.tryParse(v);
  if (num != null && num >= 0 && num <= 100) {
    setState(() {
      _answers[_currentIndex] = num;
    });
  }
}
```

### 2. **Text Input** (Line 667-671)
```dart
onChanged: (v) {
  setState(() {
    _answers[_currentIndex] = v;
  });
}
```

### 3. **Time Input** (Line 703-710)
```dart
onChanged: (v) {
  if (v.length == 4) {
    final hour = int.tryParse(v.substring(0, 2));
    final min = int.tryParse(v.substring(2, 4));
    if (hour != null && min != null && hour >= 0 && hour < 24 && min >= 0 && min < 60) {
      setState(() {
        _answers[_currentIndex] = '$hour:${min.toString().padLeft(2, '0')}';
      });
    }
  }
}
```

## Files Updated
✅ `/lib/pages/stressQuestionnaireScreen.dart`

## Testing
Now when users:
- ✅ Enter a percentage (e.g., 50) → Finish button becomes enabled
- ✅ Enter text in the text field → Finish button becomes enabled
- ✅ Enter a valid time (e.g., 0730) → Finish button becomes enabled

## Result
✅ All input types now properly enable the Next/Finish button when valid values are entered
✅ UI updates immediately upon input
✅ Validation is working correctly

**Status:** 🎉 **FIXED**
