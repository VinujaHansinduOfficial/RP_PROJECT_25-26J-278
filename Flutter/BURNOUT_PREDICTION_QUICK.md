# ✅ Burnout Prediction - Quick Reference

## What Was Done

Updated PhysStress questionnaire to call burnout prediction API and display stress status with recommendations.

---

## 🔄 **Quick Flow**

```
Complete Questionnaire
         ↓
    Click Finish
         ↓
    Show Loading
         ↓
  Fetch User Details
         ↓
  Submit to /predict/burnout
         ↓
  Parse prediction value
         ↓
  Show Result Dialog:
    ├─ prediction == 1 → "⚠️ You are stressed"
    └─ prediction == 0 → "✅ You are not stressed"
         ↓
  Show Recommendations
         ↓
  Click Done
```

---

## 📡 **API Details**

**Endpoint:** `POST http://10.160.151.43:8001/predict/burnout`

**Key Response Fields:**
- `prediction`: 0 or 1 (0 = not stressed, 1 = stressed)
- `probability`: 0.0-1.0 (confidence score)

---

## 🎨 **Result Dialog**

| Stressed (1) | Not Stressed (0) |
|---|---|
| ⚠️ Orange icon | ✅ Green icon |
| "You are stressed" | "You are not stressed" |
| Stress management tips | Congratulations |
| Break reminder | Keep it up message |

---

## 📊 **Dialog Shows:**

1. ✅ Prediction status (stressed/not stressed)
2. ✅ Confidence score (percentage)
3. ✅ Progress bar for confidence
4. ✅ Color-coded background (orange/green)
5. ✅ Recommendations section
6. ✅ Done button

---

## 🔧 **Code Changes**

**Updated Methods:**
- `_submitPredictionData()` - Calls burnout API
- `_submitQuestionnaire()` - Removed success dialog
- `_showPredictionDialog()` - NEW dialog method

**New Dialog:** Shows prediction results with full formatting

---

## ✨ **Features**

✅ Burnout prediction analysis
✅ Clear stress status message
✅ Confidence score display
✅ Personalized recommendations
✅ Visual feedback (colors)
✅ Professional dialog UI

---

**Status:** ✅ **READY**  
**File:** `lib/pages/physStress.dart`  
**Test:** Complete questionnaire and finish to see prediction
