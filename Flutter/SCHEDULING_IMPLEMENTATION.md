## 📅 Session Scheduling & Payment Flow - Complete Implementation

### Overview
This implementation creates a complete session scheduling and payment flow with 4 main pages:
1. Schedule (existing) - Lists all sessions
2. Schedule Session - Select date, time, and doctor
3. Payment - Review and add payment details
4. Payment Success - Confirmation and session creation

---

## 🔧 Files Created

### 1. ScheduleSessionApiService (`lib/services/ScheduleSessionApiService.dart`)
**Purpose:** Handle API calls for doctor availability and session creation

**Methods:**
- `getAvailableDoctors(startDateTime, endDateTime)` 
  - Calls: `GET /api/sessions/doctors/available`
  - Returns list of available doctors for the selected time
  
- `createSession(doctorId, doctorName, patientId, patientName, sessionDate, sessionTime)`
  - Calls: `POST /api/sessions/SessionCreate`
  - Creates the session in the backend

---

### 2. ScheduleSessionPage (`lib/pages/schedule_session.dart`)
**Purpose:** Main page for selecting date, time, and doctor

**Features:**
- ✅ Date picker - Select session date (today to 30 days ahead)
- ✅ Time picker - Select session time
- ✅ Doctor selection - Loads available doctors based on selected date/time
- ✅ Pricing display - Shows subtotal, taxes, and total
- ✅ API integration - Fetches doctors from backend
- ✅ Modal bottom sheet for doctor selection
- ✅ Validation - Ensures all fields are filled before proceeding
- ✅ Navigation - Routes to payment page with all data

**Key Methods:**
- `_selectDate()` - Opens date picker
- `_selectTime()` - Opens time picker
- `_loadAvailableDoctors()` - Fetches doctors from API
- `_proceedToPayment()` - Validates and navigates to payment

---

### 3. PaymentPage (`lib/pages/payment.dart`)
**Purpose:** Handle payment information and processing

**UI Sections:**
1. **Checkout Step** - Displays:
   - Selected date (with checkmark)
   - Selected time (with checkmark)
   - Selected doctor (with checkmark)
   - Payment method (Visa *1234)
   - Pricing breakdown
   - "Pay and Schedule" button

2. **Card Details Step** - Displays:
   - Visa/Mastercard selection buttons
   - Card Number input
   - Card Holder's Name input
   - Expiry (dd/yy) input
   - CVV input
   - "Add" button

**Features:**
- ✅ Multi-step form (Checkout → Card Details)
- ✅ Card type selection (Visa/Mastercard)
- ✅ Form validation before payment
- ✅ Dynamic step indicator in AppBar
- ✅ Smooth transitions between steps

---

### 4. PaymentSuccessPage (`lib/pages/payment_success.dart`)
**Purpose:** Show success confirmation and create the session

**Features:**
- ✅ Automatic session creation via API
- ✅ Shows "Successful!" message with icon
- ✅ Displays confirmation text
- ✅ Shows success animation (coins emoji)
- ✅ "Continue" button routes back to Schedule page
- ✅ Prevents back navigation (WillPopScope)
- ✅ Loading spinner while processing

**Process:**
1. Page loads
2. Automatically calls `createSession()` API
3. Shows loading spinner
4. On success, displays success UI
5. User clicks "Continue" to return to Schedule page

---

## 🔗 Navigation Flow

```
Schedule Page
    ↓
    [Click "Schedule a Session" card]
    ↓
ScheduleSessionPage
    ├─ Select Date
    ├─ Select Time
    ├─ Select Doctor (from available list)
    └─ Click "Pay and Schedule"
    ↓
PaymentPage (Step 1: Checkout)
    ├─ Review selection
    └─ Click "Pay and Schedule"
    ↓
PaymentPage (Step 2: Card Details)
    ├─ Select Visa/Mastercard
    ├─ Fill card details
    └─ Click "Add"
    ↓
PaymentSuccessPage
    ├─ Auto create session via API
    └─ Click "Continue"
    ↓
Schedule Page (with updated session list)
```

---

## 📡 API Integration

### 1. Get Available Doctors
**Endpoint:** `GET /api/sessions/doctors/available`

**Query Parameters:**
- `start_datetime` (ISO format) - Session start time
- `end_datetime` (ISO format) - Session end time

**Response:**
```json
{
  "total": 3,
  "available_doctors": [
    {
      "doctor_id": "507f1f77bcf86cd799439010",
      "doctor_name": "Dr. Sarah Johnson"
    },
    ...
  ]
}
```

### 2. Create Session
**Endpoint:** `POST /api/sessions/SessionCreate`

**Request Body:**
```json
{
  "doctor_id": "69a50eb413a5f2502ad8e9c8",
  "doctor_name": "Janindu Udana",
  "patient_id": "69a3f545c7164b048796b4e5",
  "patient_name": "John",
  "session_date": "2026-03-16T14:30:00",
  "session_time": "14.30 P.M"
}
```

**Response:**
```json
{
  "doctor_id": "69a50eb413a5f2502ad8e9c8",
  "doctor_name": "Janindu Udana",
  "patient_id": "69a3f545c7164b048796b4e5",
  "patient_name": "John",
  "session_date": "2026-03-16T14:30:00",
  "session_time": "14.30 P.M",
  "_id": "69a549081411b3b0e231d29b",
  "status": "pending",
  "created_at": "2026-03-02T08:23:36.643903",
  "is_active": true
}
```

---

## 🎨 UI Components

### Schedule Session Page
- Date/Time/Doctor selection fields with icons
- Pricing breakdown section
- Full-width action buttons

### Payment Page
- Step indicator in AppBar
- Checkout view with review section
- Card details form with field labels
- Card type selection with border indicators
- Pricing summary

### Payment Success Page
- Centered success message
- Large "Successful!" text in blue
- Confirmation description
- Success icon/animation
- Continue button

---

## 📋 Data Flow

### SharedPreferences Usage
The app uses SharedPreferences to retrieve:
- `patientId` - For creating sessions
- `firstName` - For displaying patient name

### State Management
- **ScheduleSessionPage**: Local state for date, time, doctor selection
- **PaymentPage**: Step tracking state
- **PaymentSuccessPage**: Loading state during API call

---

## ✨ Key Features

1. **Smart Doctor Loading**
   - Only fetches doctors when date AND time are selected
   - Clears doctor selection when date/time changes
   - Shows loading indicator during fetch

2. **Form Validation**
   - Validates all required fields before proceeding
   - Shows error messages in SnackBars
   - Prevents invalid submissions

3. **Multi-Step Payment**
   - Separated into logical steps
   - Clear visual indication of current step
   - Easy navigation between steps

4. **Automatic Session Creation**
   - Creates session immediately after payment
   - Shows loading state during creation
   - Handles errors gracefully

5. **User Experience**
   - Back buttons on all pages
   - Prevents back navigation on success page
   - Auto-formatting of times and dates
   - Clear visual feedback on selections

---

## 🚀 How to Use

1. **User navigates to Schedule page** and clicks "Schedule a Session" card
2. **Selects date** from date picker
3. **Selects time** from time picker
4. **Selects doctor** from available list (auto-loaded)
5. **Reviews pricing** and clicks "Pay and Schedule"
6. **Enters card details** (Visa/Mastercard)
7. **Clicks "Add"** to process payment
8. **Sees success message** and session is created in backend
9. **Clicks "Continue"** to return to Schedule page
10. **New session appears** in the upcoming sessions list

---

## 📸 UI References

The implementation follows the exact UI design provided:
- ✅ Schedule Session page layout with date/time/doctor fields
- ✅ Payment page with checkout and card details steps
- ✅ Success page with success animation
- ✅ Pricing display with subtotal, taxes, and total
- ✅ Professional card type selection (Visa/Mastercard)

