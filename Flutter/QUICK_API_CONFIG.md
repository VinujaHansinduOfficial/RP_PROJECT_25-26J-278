# 🚀 API Configuration - Quick Start

## How to Change IP Address

**File to Edit:** `lib/config/api_config.dart`

**Line to Change:** Line 11
```dart
static const String baseUrl = 'http://10.33.135.43:8000';
```

**Change To:**
```dart
static const String baseUrl = 'http://YOUR_NEW_IP:PORT';
```

**Example:**
```dart
// Development
static const String baseUrl = 'http://192.168.1.100:8000';

// Staging
static const String baseUrl = 'http://staging.example.com:8000';

// Production
static const String baseUrl = 'https://api.example.com';
```

**That's it!** Save the file and all API calls will use the new IP automatically.

---

## All Available URLs

```dart
ApiConfig.loginUrl              // POST /api/patients/login
ApiConfig.registerUrl           // POST /api/patients/register
ApiConfig.sessionsUrl           // GET /api/sessions
ApiConfig.doctorsAvailableUrl   // GET /api/sessions/doctors/available
ApiConfig.sessionCreateUrl      // POST /api/sessions/SessionCreate
ApiConfig.dashboardUrl          // GET /api/patients/dashboard/{patient_id}
```

---

## Default Headers (Used in All Services)

```dart
ApiConfig.defaultHeaders
// {
//   'Content-Type': 'application/json',
//   'Accept': 'application/json',
// }
```

---

## Utility Methods

```dart
// Print current configuration
ApiConfig.printConfig();

// Get current environment
String env = ApiConfig.getEnvironment();

// Build custom URL
String url = ApiConfig.buildUrl('/api/custom/endpoint');
```

---

## Updated Services

| Service | Uses |
|---------|------|
| UserApiService | `ApiConfig.loginUrl` |
| RegisterApiService | `ApiConfig.registerUrl` |
| SessionApiService | `ApiConfig.sessionsUrl` |
| ScheduleSessionApiService | `ApiConfig.doctorsAvailableUrl`, `ApiConfig.sessionCreateUrl` |

---

**No More Hardcoded IPs!** ✅
