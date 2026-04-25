# Physical Stress Questionnaire - Questions & Values

## Complete List of All Questions with Numeric Value Assignments

### Q1: BMI (Body Mass Index)
**Type:** Decimal Number Input  
**Key:** `bmi`  
**Input:** Number (0.0-99.9)  
**Value Range:** 0-100  
**Image:** `question_health.png`

---

### Q2: Physical Activity
**Type:** Numeric Input (Minutes)  
**Key:** `physact`  
**Question:** How many minutes per week do you usually exercise?  
**Input:** Number (0-1440 minutes)  
**Value Range:** 0-1440  
**Image:** `question_exercise2.jpg`

---

### Q3: Overall Health
**Type:** Grid 2x2 Selection  
**Key:** `health`  
**Question:** How would you rate your overall health?  
**Value Range:** 0-4  
**Image:** `question_health.png`

| Option | Value |
|--------|-------|
| Poor | 0 |
| Fair | 1 |
| Good | 2 |
| Very Good | 3 |
| Excellent | 4 |

---

### Q4: Emotional Distress
**Type:** Grid 2x2 Selection  
**Key:** `psyt`  
**Question:** In the past two weeks, how often have you felt emotionally distressed?  
**Value Range:** 0-4  
**Image:** `question_sadness.jpg`

| Option | Value |
|--------|-------|
| Never | 0 |
| Rarely | 1 |
| Sometimes | 2 |
| Often | 3 |
| Always | 4 |

---

### Q5: Emotional Coping Strategy
**Type:** Grid 2x2 Selection  
**Key:** `cop_e`  
**Question:** When stressed, how often do you try to manage your emotions (e.g., venting, distraction)?  
**Value Range:** 0-20  
**Image:** `question_emotions.png`

| Option | Value |
|--------|-------|
| Never | 0 |
| Rarely | 5 |
| Sometimes | 10 |
| Often | 15 |
| Always | 20 |

---

### Q6: Problem-Focused Coping
**Type:** Grid 2x2 Selection  
**Key:** `cop_p`  
**Question:** When stressed, how often do you try to solve the problem directly?  
**Value Range:** 0-20  
**Image:** `question_problem_solving.jpg`

| Option | Value |
|--------|-------|
| Never | 0 |
| Rarely | 5 |
| Sometimes | 10 |
| Often | 15 |
| Always | 20 |

---

### Q7: Healthy Coping Strategies
**Type:** Grid 2x2 Selection  
**Key:** `cop_h`  
**Question:** How often do you use healthy strategies to cope (exercise, meditation, sleep)?  
**Value Range:** 0-20  
**Image:** `question_coping.png`

| Option | Value |
|--------|-------|
| Never | 0 |
| Rarely | 5 |
| Sometimes | 10 |
| Often | 15 |
| Always | 20 |

---

### Q8: Part-Time Employment
**Type:** Binary Choice (Yes/No)  
**Key:** `part`  
**Question:** Do you work part-time?  
**Value Range:** 0-1  
**Image:** `question_parttime.jpeg`

| Option | Value |
|--------|-------|
| No | 0 |
| Yes | 1 |

---

### Q9: Social Support
**Type:** Grid 2x2 Selection  
**Key:** `socsup`  
**Question:** How often do you have someone to talk to when you need support?  
**Value Range:** 0-10  
**Image:** `question_support.png`

| Option | Value |
|--------|-------|
| Never | 0 |
| Rarely | 2 |
| Sometimes | 5 |
| Often | 7 |
| Always | 10 |

---

### Q10: Parent Education Level
**Type:** Grid 2x2 Selection  
**Key:** `educ_par`  
**Question:** What is the highest education level completed by your parent or guardian?  
**Value Range:** 0-5  
**Image:** `question_education.jpg`

| Option | Value |
|--------|-------|
| Less than high school | 0 |
| High school | 1 |
| Diploma | 2 |
| Bachelor's | 3 |
| Postgraduate | 4 |
| Don't know | 5 |

---

### Q11: Job Hours Per Week
**Type:** Numeric Input (Hours)  
**Key:** `jobhours`  
**Question:** How many hours per week do you work at a job?  
**Input:** Number (0-50 hours)  
**Value Range:** 0-50  
**Image:** `question_work.png`

---

## Summary Table

| Q | Key | Type | Range | Input Method |
|---|-----|------|-------|--------------|
| 1 | bmi | Decimal | 0-100 | Numeric Input |
| 2 | physact | Integer | 0-1440 | Numeric Input |
| 3 | health | Grid 2x2 | 0-4 | Selection |
| 4 | psyt | Grid 2x2 | 0-4 | Selection |
| 5 | cop_e | Grid 2x2 | 0-20 | Selection |
| 6 | cop_p | Grid 2x2 | 0-20 | Selection |
| 7 | cop_h | Grid 2x2 | 0-20 | Selection |
| 8 | part | Choice | 0-1 | Yes/No Button |
| 9 | socsup | Grid 2x2 | 0-10 | Selection |
| 10 | educ_par | Grid 2x2 | 0-5 | Selection |
| 11 | jobhours | Integer | 0-50 | Numeric Input |

---

## Data Structure

All options are now structured as objects with `text` and `value` properties:

```dart
'options': [
  {'text': 'Option Name', 'value': numeric_value},
  {'text': 'Option Name', 'value': numeric_value},
  // ...
]
```

This allows:
- ✅ Display text to user
- ✅ Store numeric values in answers
- ✅ Easy calculation of stress scores

---

## Answer Collection

When the questionnaire is completed, all answers are stored with their numeric values:

```dart
_answers = {
  0: 24.5,          // BMI
  1: 180,           // physact (minutes)
  2: 3,             // health (value)
  3: 2,             // psyt (value)
  4: 15,            // cop_e (value)
  5: 10,            // cop_p (value)
  6: 20,            // cop_h (value)
  7: 1,             // part (value)
  8: 7,             // socsup (value)
  9: 3,             // educ_par (value)
  10: 40,           // jobhours (hours)
}
```

---

## Calculation of Stress Metrics

Based on the collected values, stress metrics can be calculated:

```dart
// Emotional Coping Score (0-20)
emotionalCopingScore = answers[4]; // cop_e

// Problem-Solving Score (0-20)
problemSolvingScore = answers[5]; // cop_p

// Healthy Coping Score (0-20)
healthyCopingScore = answers[6]; // cop_h

// Total Coping Score (0-60)
totalCopingScore = answers[4] + answers[5] + answers[6];

// Social Support Score (0-10)
socialSupportScore = answers[8]; // socsup

// Physical Stress Indicators
physicalActivityLevel = answers[1]; // physact (minutes)
bmiValue = answers[0]; // bmi

// Employment Status
hasPartTimeWork = answers[7]; // part (0 or 1)

// Educational Background
parentEducationLevel = answers[9]; // educ_par (0-5)
```

---

## New Input Types Added

### 1. **number_bmi** - Decimal BMI Input
- Accepts decimal numbers (e.g., 24.5, 18.3)
- Range: 0-100
- Displayed with "kg/m²" suffix
- Used for: Question 1 (BMI)

### 2. **number_minutes_week** - Minutes Input
- Accepts whole numbers (0-1440)
- Represents minutes per week
- Maximum 1440 (24 hours × 60)
- Used for: Question 2 (Physical Activity)

### 3. **number_hours_week** - Hours Input
- Accepts whole numbers (0-168)
- Represents hours per week
- Maximum 168 (24 hours × 7 days)
- Used for: Question 11 (Job Hours)

---

## Implementation Details

### Updated Methods

**_isNextEnabled getter:**
- Added validation for `number_bmi` (decimal 0-100)
- Validates minute and hour ranges properly
- Handles map options with value properties

**_onChoiceSelected method:**
- Extracts numeric `value` from option map
- Falls back to string if option is string
- Stores only the numeric value in _answers

**_onNumberChanged method:**
- Handles decimal input for BMI
- Handles integer input for minutes and hours
- Proper type conversion and validation

**_buildAnswerWidget method:**
- Displays option `text` but stores `value`
- Handles both string and map option formats
- Added BMI decimal input support
- Professional styling with visual feedback

---

**Created:** March 3, 2026  
**Status:** ✅ All 11 questions configured with values
**Files Updated:** physStress.dart
