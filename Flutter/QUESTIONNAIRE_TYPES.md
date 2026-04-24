# Questionnaire Input Types Documentation

## Complete List of Input Types Available

### 1. **choice** - Multiple Choice Buttons (Vertical)
Displays options as a vertical list of selectable buttons.

**Configuration:**
```dart
{
  'title': 'Your question here?',
  'type': 'choice',
  'options': ['Option 1', 'Option 2', 'Option 3'],
  'key': 'question_key'
}
```

**Validation:** User must select one option
**Returns:** String (selected option text)

---

### 2. **frequency_grid** - Grid Layout Buttons (2x2)
Displays options in a 2x2 grid for frequency or category selection.

**Configuration:**
```dart
{
  'title': 'How often do you exercise?',
  'type': 'frequency_grid',
  'options': ['Never', 'Rarely', 'Sometimes', 'Often'],
  'key': 'exercise_frequency'
}
```

**Validation:** User must select one option
**Returns:** String (selected option text)

---

### 3. **yes_no** - Binary Yes/No Choice
Shows two large buttons for yes/no questions.

**Configuration:**
```dart
{
  'title': 'Do you meditate regularly?',
  'type': 'yes_no',
  'key': 'meditation_habit'
}
```

**Validation:** User must select Yes or No
**Returns:** String ('Yes' or 'No')

---

### 4. **number_1_10** - Integer Input (1-10)
Text field for numbers between 1 and 10.

**Configuration:**
```dart
{
  'title': 'Rate your stress level (1-10)',
  'type': 'number_1_10',
  'key': 'stress_level'
}
```

**Validation:** Must be integer between 1-10
**Returns:** Integer

---

### 5. **number_hours** - Hours Per Week (0-168)
Text field for hours per week input.

**Configuration:**
```dart
{
  'title': 'How many hours do you work per week?',
  'type': 'number_hours',
  'key': 'work_hours_week'
}
```

**Validation:** Must be integer between 0-168
**Returns:** Integer

---

### 6. **number_hours_day** - Hours Per Day (0-24)
Text field for hours per day input.

**Configuration:**
```dart
{
  'title': 'How many hours do you sleep per day?',
  'type': 'number_hours_day',
  'key': 'sleep_hours'
}
```

**Validation:** Must be integer between 0-24
**Returns:** Integer

---

### 7. **percentage** - Percentage Input (0-100) ⭐ NEW
Text field with % suffix for percentage values.

**Configuration:**
```dart
{
  'title': 'What is your attendance percentage?',
  'type': 'percentage',
  'key': 'attendance_percentage'
}
```

**Validation:** Must be integer between 0-100
**Returns:** Integer

---

### 8. **gpa** - GPA Input (0.0-4.0)
Decimal text field for GPA values.

**Configuration:**
```dart
{
  'title': 'What is your current GPA?',
  'type': 'gpa',
  'key': 'current_gpa'
}
```

**Validation:** Must be decimal between 0.0-4.0
**Returns:** Double

---

### 9. **rating_scale** - Star Rating (1-5 or custom) ⭐ NEW
Interactive star rating system with visual feedback.

**Configuration:**
```dart
{
  'title': 'Rate your overall happiness',
  'type': 'rating_scale',
  'max_rating': 5,  // Optional, default is 5
  'key': 'happiness_rating'
}
```

**Validation:** User must select a rating
**Returns:** Integer (1 to max_rating)

---

### 10. **slider** - Slider Control (0-100 or custom range) ⭐ NEW
Interactive slider for continuous value selection.

**Configuration:**
```dart
{
  'title': 'How stressed are you feeling right now?',
  'type': 'slider',
  'min': 0,         // Optional, default 0
  'max': 100,       // Optional, default 100
  'key': 'stress_slider'
}
```

**Validation:** Value within range
**Returns:** Integer

---

### 11. **text_input** - Free Text Input ⭐ NEW
Multi-line text field for open-ended responses.

**Configuration:**
```dart
{
  'title': 'Describe your main source of stress',
  'type': 'text_input',
  'key': 'stress_description'
}
```

**Validation:** Text must not be empty
**Returns:** String

---

### 12. **time_input** - Time Input (HH:MM format) ⭐ NEW
Text field for time entry in HH:MM format.

**Configuration:**
```dart
{
  'title': 'What time do you usually wake up?',
  'type': 'time_input',
  'key': 'wake_up_time'
}
```

**Validation:** Must be valid time (00:00 - 23:59)
**Returns:** String (e.g., "07:30")

---

## Usage Examples

### Example 1: Complete Question with Multiple Input Types

```dart
final List<Map<String, dynamic>> _questions = [
  {
    'title': 'Do you exercise regularly?',
    'type': 'yes_no',
    'image': 'assets/images/exercise.png',
    'key': 'Exercise_Habit',
  },
  {
    'title': 'How many hours per week?',
    'type': 'number_hours',
    'image': 'assets/images/clock.png',
    'key': 'Exercise_Hours_Week',
  },
  {
    'title': 'Rate your fitness level',
    'type': 'rating_scale',
    'max_rating': 5,
    'image': 'assets/images/fitness.png',
    'key': 'Fitness_Rating',
  },
  {
    'title': 'How satisfied are you with your routine?',
    'type': 'slider',
    'min': 0,
    'max': 100,
    'image': 'assets/images/satisfaction.png',
    'key': 'Routine_Satisfaction',
  },
];
```

### Example 2: Converting All Answer Types

```dart
Map<String, dynamic> get _answersData {
  return {
    'Exercise_Habit': _answers[0] == 'Yes' ? 1 : 0,
    'Exercise_Hours_Week': _answers[1] ?? 0,
    'Fitness_Rating': _answers[2] ?? 0,
    'Routine_Satisfaction': _answers[3] ?? 0,
  };
}
```

---

## Visual Comparison

| Type | Display | Input Method | Return Type |
|------|---------|--------------|-------------|
| choice | Vertical Buttons | Tap Button | String |
| frequency_grid | 2x2 Grid | Tap Grid Item | String |
| yes_no | 2 Large Buttons | Tap Button | String |
| number_1_10 | Text Field | Type Numbers | Integer |
| number_hours | Text Field | Type Numbers | Integer |
| number_hours_day | Text Field | Type Numbers | Integer |
| percentage | Text Field + % | Type Numbers | Integer |
| gpa | Text Field (decimal) | Type Numbers | Double |
| rating_scale | Star Display | Tap Star | Integer |
| slider | Interactive Slider | Drag Slider | Integer |
| text_input | Text Area | Type Text | String |
| time_input | Time Field (HH:MM) | Type Time | String |

---

## Best Practices

### ✅ DO:
- Use **choice** for categorical data (small number of options)
- Use **frequency_grid** for 4-6 frequency options
- Use **rating_scale** for satisfaction/happiness metrics
- Use **slider** for continuous scales (0-100)
- Use **percentage** for attendance, accuracy, etc.
- Use **text_input** for open-ended questions
- Use **time_input** for specific time values
- Always include descriptive titles and images

### ❌ DON'T:
- Don't use **choice** for more than 6 options (use frequency_grid or custom)
- Don't use **slider** for discrete values that should be buttons
- Don't use **text_input** for questions needing structured answers
- Don't mix types without clear reason

---

## Example: Full Questionnaire with All Types

```dart
final List<Map<String, dynamic>> _questions = [
  // Choice type
  {
    'title': 'How would you describe your stress level?',
    'type': 'choice',
    'options': ['Very Low', 'Low', 'Moderate', 'High', 'Very High'],
    'key': 'stress_description'
  },
  
  // Yes/No type
  {
    'title': 'Do you practice meditation?',
    'type': 'yes_no',
    'key': 'meditation_practice'
  },
  
  // Number input
  {
    'title': 'Rate your anxiety (1-10)',
    'type': 'number_1_10',
    'key': 'anxiety_score'
  },
  
  // Percentage type
  {
    'title': 'What is your class attendance?',
    'type': 'percentage',
    'key': 'attendance_percentage'
  },
  
  // Rating scale
  {
    'title': 'How happy are you?',
    'type': 'rating_scale',
    'max_rating': 5,
    'key': 'happiness_score'
  },
  
  // Slider type
  {
    'title': 'Your overall wellbeing (0-100)',
    'type': 'slider',
    'min': 0,
    'max': 100,
    'key': 'wellbeing_score'
  },
  
  // Text input
  {
    'title': 'What helps you manage stress?',
    'type': 'text_input',
    'key': 'stress_management'
  },
  
  // Time input
  {
    'title': 'When do you usually study?',
    'type': 'time_input',
    'key': 'study_time'
  },
];
```

---

**Total Input Types:** 12  
**Most Recent Additions:** percentage, rating_scale, slider, text_input, time_input, yes_no  
**Last Updated:** March 3, 2026
