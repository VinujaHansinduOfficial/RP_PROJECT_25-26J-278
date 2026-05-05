# 🎯 Centralized API Configuration Guide

## Overview
A centralized API configuration system has been created to manage all API endpoints and settings in one place. This makes it extremely easy to change the server IP address or other configuration without modifying multiple service files.

---

## 📁 File Structure

```
lib/
├── config/
│   └── api_config.dart ..................... NEW - Centralized API Config
├── services/
│   ├── UserApiService.dart ................ UPDATED
│   ├── RegisterApiService.dart ............ UPDATED
│   ├── SessionApiService.dart ............. UPDATED
│   └── ScheduleSessionApiService.dart ..... UPDATED
└── ...other files
```

---

## 🔧 How to Use

### Step 1: Change the IP Address
Edit `/lib/config/api_config.dart` and update the `baseUrl`:

```dart
// Development
static const String baseUrl = 'http://10.33.135.43:8000';

// Staging
static const String baseUrl = 'http://staging-api.example.com:8000';

// Production
static const String baseUrl = 'https://api.example.com';
```

**That's it!** All API calls will automatically use the new IP address.

---

## 📋 ApiConfig File Details

### Main Configuration Section

```dart
class ApiConfig {
  /// Change this to switch servers
  static const String baseUrl = 'http://10.33.135.43:8000';
  
  /// API version prefix
  static const String apiVersion = '/api';
```

### Available Endpoints

#### Authentication
```dart
static String get loginUrl => '$baseUrl/api/patients/login';
static String get registerUrl => '$baseUrl/api/patients/register';
```

#### Sessions
```dart
static String get sessionsUrl => '$baseUrl/api/sessions';
static String get doctorsAvailableUrl => '$baseUrl/api/sessions/doctors/available';
static String get sessionCreateUrl => '$baseUrl/api/sessions/SessionCreate';
```

#### Dashboard
```dart
static String get dashboardUrl => '$baseUrl/api/patients/dashboard';
```

### HTTP Headers
```dart
static const Map<String, String> defaultHeaders = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
};
```

### Timeouts
```dart
static const int connectionTimeout = 30;  // seconds
static const int receiveTimeout = 30;     // seconds
```

---

## 📝 Quick Reference

### Complete List of Available URLs

| Service | Endpoint | Full URL |
|---------|----------|----------|
| Login | loginUrl | `{baseUrl}/api/patients/login` |
| Register | registerUrl | `{baseUrl}/api/patients/register` |
| Sessions | sessionsUrl | `{baseUrl}/api/sessions` |
| Doctors Available | doctorsAvailableUrl | `{baseUrl}/api/sessions/doctors/available` |
| Create Session | sessionCreateUrl | `{baseUrl}/api/sessions/SessionCreate` |
| Dashboard | dashboardUrl | `{baseUrl}/api/patients/dashboard` |

---

## 🛠️ Using ApiConfig in Services

### Before (Hardcoded)
```dart
class UserApiService {
  static const String baseUrl = 'http://10.33.135.43:8000/api/patients';
  
  Future<User?> loginUser(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      ...
    );
  }
}
```

### After (Centralized)
```dart
import 'package:health_research/config/api_config.dart';

class UserApiService {
  Future<User?> loginUser(String email, String password) async {
    final response = await http.post(
      Uri.parse(ApiConfig.loginUrl),
      headers: ApiConfig.defaultHeaders,
      ...
    );
  }
}
```

---

## ✅ Services Updated

All the following services now use `ApiConfig`:

1. ✅ **UserApiService.dart**
   - Uses `ApiConfig.loginUrl`
   - Uses `ApiConfig.defaultHeaders`

2. ✅ **RegisterApiService.dart**
   - Uses `ApiConfig.registerUrl`
   - Uses `ApiConfig.defaultHeaders`

3. ✅ **SessionApiService.dart**
   - Uses `ApiConfig.sessionsUrl`
   - Uses `ApiConfig.defaultHeaders`

4. ✅ **ScheduleSessionApiService.dart**
   - Uses `ApiConfig.doctorsAvailableUrl`
   - Uses `ApiConfig.sessionCreateUrl`
   - Uses `ApiConfig.defaultHeaders`

---

## 🎛️ Utility Functions

### Get Current Environment
```dart
String environment = ApiConfig.getEnvironment();
// Returns: 'Development', 'Staging', or 'Production'
```

### Build Custom URL
```dart
String customUrl = ApiConfig.buildUrl('/api/custom/endpoint');
```

### Print Configuration (Debugging)
```dart
ApiConfig.printConfig();
// Output:
// ╔════════════════════════════════════════════════════╗
// ║        API CONFIGURATION                           ║
// ╠════════════════════════════════════════════════════╣
// ║ Environment: Development                           ║
// ║ Base URL: http://10.33.135.43:8000                ║
// ║ API Version: /api                                  ║
// ║ Connection Timeout: 30s                            ║
// ║ Receive Timeout: 30s                               ║
// ╚════════════════════════════════════════════════════╝
```

---

## 🔄 Switching Environments

### Easy Environment Switching

**Option 1: Manual Change**
```dart
// In api_config.dart
static const String baseUrl = 'http://10.33.135.43:8000';  // Development
// static const String baseUrl = 'http://staging-api.example.com:8000';  // Staging
// static const String baseUrl = 'https://api.example.com';  // Production
```

**Option 2: Using Flavors (Advanced)**
Create different configuration files for each environment and import based on build flavor.

---

## 📊 Quick Checklist

- ✅ ApiConfig created at `/lib/config/api_config.dart`
- ✅ UserApiService updated
- ✅ RegisterApiService updated
- ✅ SessionApiService updated
- ✅ ScheduleSessionApiService updated
- ✅ All services use centralized headers
- ✅ All services use centralized URLs
- ✅ No hardcoded IP addresses in services

---

## 🚀 Adding New Endpoints

### To add a new endpoint:

```dart
// In ApiConfig class
static const String newEndpointPath = '$apiVersion/new/endpoint';
static String get newEndpointUrl => '$baseUrl$newEndpointPath';

// In ApiEndpoints class
static const String NEW_ENDPOINT = ApiConfig.newEndpointPath;
```

### Then use in your service:
```dart
final response = await http.get(
  Uri.parse(ApiConfig.newEndpointUrl),
  headers: ApiConfig.defaultHeaders,
);
```

---

## 📞 Support

### To Change IP Address:
1. Open `/lib/config/api_config.dart`
2. Find line: `static const String baseUrl = '...'`
3. Replace with your new IP
4. Save file
5. All API calls will automatically use the new IP ✅

### To Add New Endpoint:
1. Open `/lib/config/api_config.dart`
2. Add new constant in `ApiConfig` class
3. Add shortcut in `ApiEndpoints` class
4. Import and use in your service

---

## 🎉 Benefits

✨ **Single Source of Truth** - All API configuration in one place
✨ **Easy IP Changes** - Change once, affects all services
✨ **Consistency** - All services use same headers and format
✨ **Maintainability** - Easy to find and update endpoints
✨ **Scalability** - Simple to add new endpoints
✨ **Debugging** - Print configuration to verify settings
✨ **Environment Support** - Auto-detect development/staging/production

---

**Created:** March 3, 2026
**Version:** 1.0
**Status:** ✅ Complete & Ready to Use
