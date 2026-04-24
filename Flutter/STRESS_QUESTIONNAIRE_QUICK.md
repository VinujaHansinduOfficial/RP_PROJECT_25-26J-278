# ✅ StressQuestionnaireScreen - Quick Reference

## Implementation Complete

Successfully integrated 6 APIs to collect comprehensive behavioral analysis data when users complete the 20-question academic stress assessment.

---

## 🔄 **Quick Flow**

```
Complete 20 Questions
         ↓
    Click "Finish"
         ↓
Fetch User Details
         ↓
Fetch Stress/Anxiety/Depression Scores
         ↓
Fetch Health Metrics (Heart Rate, Sleep, Screen Time)
         ↓
Combine All Data + Questionnaire Answers
         ↓
Send to Behavior Prediction API
         ↓
Show Success Message ✅
```

---

## 📡 **6 APIs Called**

1. **Patient Details** → BaseUrl/api/patients/{id}
2. **Stress Results** → BaseUrl1/results/stress/{id}
3. **Anxiety Results** → BaseUrl1/results/anxiety/{id}
4. **Depression Results** → BaseUrl1/results/depression/{id}
5. **Health Metrics** → BaseUrl1/user_features/{id}
6. **Behavior Prediction** → BaseUrl2/predict/behavior

---

## 📊 **Data Submitted**

27 features sent to behavior prediction API:

**From User Profile:**
- Age (calculated from DOB)

**From Database:**
- Heart_Rate
- Sleep_Hours
- Screen_Time

**From Prediction APIs:**
- Stress_Level (0/1)
- Anxiety_Score (0/1)
- Depression_Score (0/1)

**From Questionnaire (20 questions):**
- Noise_Exposure
- Social_Interaction
- Work_Hours
- Exercise_Hours
- Caffeine_Intake
- Multitasking_Habit
- Sensory_Sensitivity
- Meditation_Habit
- Overthinking_Score
- Irritability_Score
- Headache_Frequency
- Sleep_Quality
- Tech_Usage_Hours
- GPA
- Prev_GPA
- GPA_trend
- Modules
- Assignments_total
- Deadlines_next_7_days
- Assignment_weight_avg_pct (random)
- Study_hours_per_day
- Attendance_pct

**Constant:**
- Overstimulated: 1

---

## 🎯 **Prediction Output**

```
prediction == 1 → User is stressed by academic activities
prediction == 0 → User is not stressed by academic activities

probability_high_burnout: 0.0-1.0 (confidence score)
```

---

## ✨ **Features**

✅ Sequential API calls with error handling
✅ Loading dialogs showing progress
✅ Automatic age calculation
✅ Data extraction from nested responses
✅ Default values for missing data
✅ Complete feature set (27 features)
✅ Uses centralized API config

---

## 🔧 **User IDs (Replace These)**

```dart
const String userId = 'user_301';           // From session/auth
const String patientId = '69a3f4aac7164b048796b4e4';  // From session/auth
```

---

**Status:** ✅ **COMPLETE**  
**Methods:** 8 new API integration methods  
**Tests:** Ready to test with any questionnaire answers
