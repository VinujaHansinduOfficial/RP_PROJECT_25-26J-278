# 📊 Implementation Architecture & Flow Diagrams

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter App                              │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐│
│  │   Schedule   │      │  Schedule    │      │   Payment    ││
│  │    Page      │─────▶│   Session    │─────▶│    Page      ││
│  │              │      │    Page      │      │              ││
│  └──────────────┘      └──────────────┘      └──────────────┘│
│                               │                       │       │
│                               │                       │       │
│                               ▼                       ▼       │
│                        ┌──────────────┐      ┌──────────────┐│
│                        │ Load Doctors │      │ Step 1:      ││
│                        │  from API    │      │ Checkout     ││
│                        └──────────────┘      │              ││
│                               │              │ Step 2:      ││
│                               │              │ Card Details ││
│                               │              └──────────────┘│
│                               │                       │       │
│                               └──────────┬────────────┘       │
│                                          │                   │
│                                          ▼                   │
│                        ┌──────────────────────────┐          │
│                        │   Payment Success Page    │          │
│                        │                          │          │
│                        │  ┌────────────────────┐  │          │
│                        │  │ Create Session     │  │          │
│                        │  │ (API Call)         │  │          │
│                        │  └────────────────────┘  │          │
│                        │          │               │          │
│                        │          ▼               │          │
│                        │  Show Success Message   │          │
│                        │          │               │          │
│                        │          ▼               │          │
│                        │  Return to Schedule    │          │
│                        └──────────────────────────┘          │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## Data Flow Diagram

```
┌──────────────────────────────────────────────────────┐
│           SharedPreferences Storage                   │
├──────────────────────────────────────────────────────┤
│  • patientId                                          │
│  • firstName                                          │
│  • email                                              │
│  • hasAssignedDoctors                                 │
└──────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────┐
│      ScheduleSessionPage                             │
│  ┌──────────────────────────────────────────────┐   │
│  │ Load: patientId, patientName                │   │
│  └──────────────────────────────────────────────┘   │
│                   │                                  │
│  ┌────────────────────────────────────────────┐    │
│  │ User selects: Date + Time                  │    │
│  └────────────────────────────────────────────┘    │
│                   │                                  │
│                   ▼                                  │
│  ┌────────────────────────────────────────────┐    │
│  │ API: GET /doctors/available                │    │
│  │ Params: start_datetime, end_datetime       │    │
│  └────────────────────────────────────────────┘    │
│                   │                                  │
│                   ▼                                  │
│  ┌────────────────────────────────────────────┐    │
│  │ Receive: available_doctors list            │    │
│  └────────────────────────────────────────────┘    │
│                   │                                  │
│  ┌────────────────────────────────────────────┐    │
│  │ User selects: Doctor                       │    │
│  └────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────┐
│      PaymentPage (2 Steps)                           │
│                                                      │
│  Step 1: Checkout Review                            │
│  ┌──────────────────────────────────────────────┐  │
│  │ Display: Date, Time, Doctor, Price           │  │
│  └──────────────────────────────────────────────┘  │
│                   │                                 │
│                   ▼                                 │
│  Step 2: Card Details                              │
│  ┌──────────────────────────────────────────────┐  │
│  │ Input: Card Number, Holder, Expiry, CVV      │  │
│  │ Validate: All fields required                 │  │
│  └──────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────┐
│    PaymentSuccessPage                                │
│  ┌──────────────────────────────────────────────┐  │
│  │ API: POST /SessionCreate                     │  │
│  │ Body:                                        │  │
│  │  {                                           │  │
│  │   doctorId, doctorName,                      │  │
│  │   patientId, patientName,                    │  │
│  │   sessionDate, sessionTime                   │  │
│  │  }                                           │  │
│  └──────────────────────────────────────────────┘  │
│                   │                                 │
│                   ▼                                 │
│  ┌──────────────────────────────────────────────┐  │
│  │ Response: Session created with ID             │  │
│  │ Status: pending                               │  │
│  │ is_active: true                               │  │
│  └──────────────────────────────────────────────┘  │
│                   │                                 │
│                   ▼                                 │
│  ┌──────────────────────────────────────────────┐  │
│  │ Show Success Message                         │  │
│  │ Return to Schedule Page                      │  │
│  └──────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────┘
```

---

## Component Interaction Diagram

```
         ┌─────────────────────────────────────┐
         │    ScheduleSessionPage              │
         │  ┌───────────────────────────────┐  │
         │  │ • DatePicker Widget           │  │
         │  │ • TimePicker Widget           │  │
         │  │ • DoctorSelector Modal        │  │
         │  │ • PriceDisplay Widget         │  │
         │  └───────────────────────────────┘  │
         │             │                       │
         └─────────────┼───────────────────────┘
                       │
                       │ Navigates with data:
                       │ - doctorId
                       │ - doctorName
                       │ - patientId
                       │ - patientName
                       │ - sessionDate
                       │ - sessionTime
                       │
                       ▼
         ┌─────────────────────────────────────┐
         │    PaymentPage                      │
         │  ┌───────────────────────────────┐  │
         │  │ Step 1: CheckoutReview        │  │
         │  │ • Date field (read-only)      │  │
         │  │ • Time field (read-only)      │  │
         │  │ • Doctor field (read-only)    │  │
         │  │ • Price section               │  │
         │  └───────────────────────────────┘  │
         │         │                           │
         │         │ User clicks              │
         │         │ "Pay and Schedule"       │
         │         ▼                           │
         │  ┌───────────────────────────────┐  │
         │  │ Step 2: CardDetails           │  │
         │  │ • Card type selector          │  │
         │  │ • CardNumber input            │  │
         │  │ • CardHolder input            │  │
         │  │ • Expiry input                │  │
         │  │ • CVV input                   │  │
         │  │ • Add button                  │  │
         │  └───────────────────────────────┘  │
         │         │                           │
         └─────────┼───────────────────────────┘
                   │ Navigates with all data
                   │
                   ▼
         ┌─────────────────────────────────────┐
         │  PaymentSuccessPage                 │
         │  ┌───────────────────────────────┐  │
         │  │ • Loading spinner (initially) │  │
         │  │ • Success message             │  │
         │  │ • Confirmation text           │  │
         │  │ • Success icon/animation      │  │
         │  │ • Continue button             │  │
         │  └───────────────────────────────┘  │
         │         │                           │
         │         │ Auto API call in          │
         │         │ initState()               │
         │         │                           │
         │         ├─ POST /SessionCreate     │
         │         │                           │
         │         ▼                           │
         │  Session created in backend        │
         │         │                           │
         │         │ User clicks              │
         │         │ "Continue"               │
         │         ▼                           │
         │  Return to Schedule page           │
         │         │                           │
         └─────────┼───────────────────────────┘
                   │
                   ▼
         ┌─────────────────────────────────────┐
         │    Schedule Page (Updated)          │
         │    New session appears in           │
         │    "Upcoming Sessions" list         │
         └─────────────────────────────────────┘
```

---

## State Management Flow

```
┌─────────────────────────────────────────────────────┐
│         ScheduleSessionPage State                    │
├─────────────────────────────────────────────────────┤
│                                                      │
│  patientId: String ─────────────┐                  │
│                                 │ From              │
│  patientName: String ───────────┤ SharedPrefs      │
│                                 │ via _loadData()  │
│  selectedDate: DateTime? ───────┐                  │
│                                 │ User              │
│  selectedTime: TimeOfDay? ──────┤ Input via        │
│                                 │ Pickers          │
│  selectedDoctorId: String? ─────┘                  │
│  selectedDoctorName: String?                       │
│                                 │ From API          │
│  availableDoctors: List ────────┤ /doctors/        │
│  isLoadingDoctors: bool ────────┘ available        │
│                                                      │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│         PaymentPage State                            │
├─────────────────────────────────────────────────────┤
│                                                      │
│  currentStep: int (0 or 1) ────── Tracks            │
│  isVisa: bool ─────────────────── Card type        │
│                                                      │
│  cardNumberController: String                       │
│  cardHolderController: String ─── User input       │
│  expiryController: String                          │
│  cvvController: String                             │
│                                                      │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│      PaymentSuccessPage State                        │
├─────────────────────────────────────────────────────┤
│                                                      │
│  isProcessing: bool ────────── True during API      │
│                               call, False after     │
│                                                      │
│  Received in constructor:                           │
│  • doctorId, doctorName                            │
│  • patientId, patientName                          │
│  • sessionDate, sessionTime                        │
│                                                      │
└─────────────────────────────────────────────────────┘
```

---

## API Call Sequence Diagram

```
Client                               Backend
  │                                   │
  │──────────────────────────────────▶│
  │ GET /doctors/available?           │
  │   start=2026-03-10T10:00:00Z      │
  │   end=2026-03-10T11:00:00Z        │
  │                                   │
  │                        ┌─────────┐│
  │                        │ Process ││
  │                        └─────────┘│
  │                                   │
  │◀──────────────────────────────────│
  │ {                                 │
  │   "total": 3,                     │
  │   "available_doctors": [          │
  │     {                             │
  │       "doctor_id": "...",         │
  │       "doctor_name": "Dr. Smith"  │
  │     },                            │
  │     ...                           │
  │   ]                               │
  │ }                                 │
  │                                   │
  │                                   │ [User fills form]
  │                                   │
  │──────────────────────────────────▶│
  │ POST /SessionCreate               │
  │ {                                 │
  │   "doctor_id": "...",             │
  │   "doctor_name": "Dr. Smith",     │
  │   "patient_id": "...",            │
  │   "patient_name": "John",         │
  │   "session_date":                 │
  │     "2026-03-10T10:30:00",        │
  │   "session_time": "10.30 A.M"     │
  │ }                                 │
  │                                   │
  │                        ┌─────────┐│
  │                        │ Process ││
  │                        │  Create ││
  │                        │ Session ││
  │                        └─────────┘│
  │                                   │
  │◀──────────────────────────────────│
  │ {                                 │
  │   "doctor_id": "...",             │
  │   "doctor_name": "Dr. Smith",     │
  │   "patient_id": "...",            │
  │   "patient_name": "John",         │
  │   "session_date":                 │
  │     "2026-03-10T10:30:00",        │
  │   "session_time": "10.30 A.M",    │
  │   "_id": "session_id",            │
  │   "status": "pending",            │
  │   "is_active": true,              │
  │   "created_at": "..."             │
  │ }                                 │
  │                                   │
  ▼                                   ▼
[Show Success & Return to Home]    [Session Created]
```

---

## Error Handling Flow

```
              User Action
                  │
                  ▼
        ┌─────────────────┐
        │ Validate Input  │
        └─────────────────┘
                  │
         ┌────────┴────────┐
         │                 │
        NO                YES
         │                 │
         ▼                 ▼
    ┌─────────┐      ┌──────────────┐
    │Show     │      │Call API      │
    │SnackBar │      └──────────────┘
    │Error    │            │
    └─────────┘     ┌──────┴──────┐
                    │             │
                  200/201        ERROR
                    │             │
                    ▼             ▼
              ┌──────────┐    ┌─────────┐
              │Show      │    │Show     │
              │Success   │    │SnackBar │
              │Navigate  │    │Error    │
              │Next Page │    │Message  │
              └──────────┘    └─────────┘
```

---

## File Dependency Graph

```
schedule.dart
    │
    ├──▶ schedule_session.dart
    │         │
    │         ├──▶ ScheduleSessionApiService.dart
    │         │         │
    │         │         └──▶ http package
    │         │
    │         └──▶ payment.dart
    │                 │
    │                 ├──▶ payment_success.dart
    │                 │         │
    │                 │         ├──▶ ScheduleSessionApiService.dart
    │                 │         │
    │                 │         └──▶ schedule.dart (navigation back)
    │                 │
    │                 └──▶ intl package (date formatting)
    │
    └──▶ SessionApiService.dart (for listing sessions)

Shared Dependencies:
    • shared_preferences (patientId, patientName)
    • intl (date/time formatting)
    • http (API calls)
```

---

**Created on**: March 2, 2026  
**Document Type**: Architecture & Flow Diagrams  
**Version**: 1.0
