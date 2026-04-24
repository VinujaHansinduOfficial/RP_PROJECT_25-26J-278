# 🚀 Quick Reference Guide

## File Locations

```
lib/
├── pages/
│   ├── schedule.dart (UPDATED - now has navigation)
│   ├── schedule_session.dart (NEW)
│   ├── payment.dart (NEW)
│   └── payment_success.dart (NEW)
├── services/
│   ├── SessionApiService.dart
│   ├── ScheduleSessionApiService.dart (NEW)
│   ├── UserApiService.dart
│   └── RegisterApiService.dart
└── models/
    └── User.dart

Documentation/
├── IMPLEMENTATION_SUMMARY.md
├── SCHEDULING_IMPLEMENTATION.md
├── ARCHITECTURE_DIAGRAMS.md
├── TESTING_CHECKLIST.md
└── QUICK_REFERENCE.md (this file)
```

---

## Key Code Snippets

### Navigate to Schedule Session
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ScheduleSessionPage(),
  ),
);
```

### Get Patient Info from SharedPreferences
```dart
final prefs = await SharedPreferences.getInstance();
String patientId = prefs.getString('patientId') ?? '';
String patientName = prefs.getString('firstName') ?? 'User';
```

### Call Get Available Doctors API
```dart
final response = await _apiService.getAvailableDoctors(
  startDateTime: startDateTime.toIso8601String(),
  endDateTime: endDateTime.toIso8601String(),
);
```

### Call Create Session API
```dart
final response = await _apiService.createSession(
  doctorId: doctorId,
  doctorName: doctorName,
  patientId: patientId,
  patientName: patientName,
  sessionDate: sessionDate.toIso8601String(),
  sessionTime: sessionTime,
);
```

---

## Environment Variables

All API endpoints are configured in service files:

```dart
static const String baseUrl = 'http://10.33.135.43:8000/api/sessions';
```

To change API endpoint, update in:
- `ScheduleSessionApiService.dart`
- `SessionApiService.dart`

---

## Important Constants

### Date/Time Formatting
- **Display Date Format:** `dd MMM yyyy` → "25 Mar 2026"
- **Display Time Format:** `h:mma` → "2:30pm"
- **API DateTime Format:** `ISO 8601` → "2026-03-25T14:30:00Z"
- **API Time Format:** `HH.mm A.M/P.M` → "14.30 P.M"

### Pricing
- Subtotal: $19.98
- Tax: $2.00
- Total: $21.98

### Date Range
- Min date: Today
- Max date: Today + 30 days

---

## State Management Pattern

Each page uses local state with setState():

```dart
class _PageState extends State<Page> {
  // Variables
  String someValue = "";
  
  @override
  void initState() {
    super.initState();
    _loadData(); // Load initial data
  }
  
  Future<void> _loadData() async {
    setState(() {
      // Update state
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(...);
  }
}
```

---

## Common Patterns

### Form Validation
```dart
if (field.isEmpty) {
  _showError("Field is required");
  return;
}
```

### API Call with Error Handling
```dart
setState(() => isLoading = true);
try {
  final response = await _apiService.getData();
  setState(() {
    // Update UI with response
  });
} catch (e) {
  _showError(e.toString());
}
setState(() => isLoading = false);
```

### Show Error SnackBar
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Error message'),
    backgroundColor: Colors.red,
  ),
);
```

### Show Success SnackBar
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Success message'),
    backgroundColor: Colors.green,
  ),
);
```

---

## Debugging Tips

### Check Patient Data
```dart
final prefs = await SharedPreferences.getInstance();
print('PatientId: ${prefs.getString('patientId')}');
print('PatientName: ${prefs.getString('firstName')}');
```

### Check API Response
```dart
print('Response: $response');
print('Status: ${response.statusCode}');
```

### Check Selected Values
```dart
print('Selected Date: $selectedDate');
print('Selected Time: $selectedTime');
print('Selected Doctor: $selectedDoctorId');
```

### Enable Verbose Logging
Add to main.dart:
```dart
void main() {
  // Enable verbose logging
  debugPrintBeginFrameBanner = true;
  runApp(const MyApp());
}
```

---

## Common Issues & Fixes

### Issue: "Cannot find ScheduleSessionPage"
**Fix:** Add import to schedule.dart:
```dart
import 'package:health_research/pages/schedule_session.dart';
```

### Issue: "SharedPreferences returns null"
**Fix:** Check that patientId was saved during login:
```dart
// In login.dart, verify this is called:
await prefs.setString('patientId', user.patientId);
```

### Issue: "Date picker doesn't open"
**Fix:** Ensure you're calling `_selectDate()` on tap:
```dart
onTap: () => _selectDate(context),
```

### Issue: "Doctors list is empty"
**Fix:** Check:
1. Both date and time are selected
2. API endpoint is correct
3. Internet connection is available
4. No API errors in console

### Issue: "Payment doesn't navigate"
**Fix:** Ensure all fields are filled:
```dart
if (_cardNumberController.text.isEmpty || ...) {
  _showError("Please fill all fields");
  return;
}
```

---

## Testing with Mock Data

### Test Date/Time
```
Date: 2026-03-10
Time: 14:30 (2:30 PM)
Doctor: Select any from list
```

### Test Patient Data
```
patientId: 69a3f4aac7164b048796b4e4
firstName: John
```

### Test Doctor Data
```
doctor_id: 507f1f77bcf86cd799439010
doctor_name: Dr. Sarah Johnson
```

### Test Session Creation
```
session_date: 2026-03-10T14:30:00
session_time: 14.30 P.M
```

---

## Performance Optimization Tips

1. **Lazy Load Doctors**
   - Only load when both date and time selected
   - Don't load on every rebuild

2. **Minimize API Calls**
   - Cache doctor list if same date/time
   - Don't call API on every keystroke

3. **Optimize UI Rendering**
   - Use const constructors where possible
   - Avoid unnecessary rebuilds
   - Use SingleChildScrollView for long forms

4. **Image Optimization**
   - Keep image sizes reasonable
   - Use appropriate formats (PNG/JPG)
   - Compress before adding to assets

---

## Deployment Checklist

Before deploying to production:

- [ ] Remove all debug print statements
- [ ] Update API endpoint to production URL
- [ ] Test all flows thoroughly
- [ ] Test on real devices
- [ ] Check for memory leaks
- [ ] Verify error handling
- [ ] Test with slow internet
- [ ] Test offline scenarios
- [ ] Update version number
- [ ] Create release build

---

## Useful Commands

### Run app
```bash
flutter run
```

### Run app on specific device
```bash
flutter devices  # List devices
flutter run -d <device-id>
```

### Build for production
```bash
flutter build apk       # Android
flutter build ipa       # iOS
flutter build web       # Web
```

### Clean build
```bash
flutter clean
flutter pub get
flutter run
```

### Check dependencies
```bash
flutter pub outdated
flutter pub upgrade
```

---

## Documentation Links

- [Flutter Official Docs](https://flutter.dev/docs)
- [Dart Language Docs](https://dart.dev/guides)
- [HTTP Package](https://pub.dev/packages/http)
- [Intl Package](https://pub.dev/packages/intl)
- [SharedPreferences](https://pub.dev/packages/shared_preferences)

---

## Support Resources

1. **Check Existing Documentation**
   - IMPLEMENTATION_SUMMARY.md
   - SCHEDULING_IMPLEMENTATION.md
   - ARCHITECTURE_DIAGRAMS.md
   - TESTING_CHECKLIST.md

2. **Debug the Issue**
   - Check console for errors
   - Verify API endpoints
   - Test with Postman
   - Check SharedPreferences values

3. **Test the Flow**
   - Manually test each page
   - Test with mock data
   - Test error scenarios
   - Test navigation

---

## Version Information

- **Flutter Version:** 3.5.4
- **Dart Version:** 3.x
- **Implementation Date:** March 2, 2026
- **Status:** ✅ Complete and Ready

---

**Quick Reference Version:** 1.0  
**Last Updated:** March 2, 2026  
**Maintained by:** Development Team
