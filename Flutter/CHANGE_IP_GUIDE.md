# 🎯 How to Change IP Address - Visual Guide

## The Problem ❌
```
Old Way: Change IP in 4+ places

┌─────────────────────────────────────────┐
│  UserApiService.dart                    │
│  static const baseUrl = '10.33...';  ← Change here
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  RegisterApiService.dart                │
│  static const baseUrl = '10.33...';  ← Change here
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  SessionApiService.dart                 │
│  static const baseUrl = '10.33...';  ← Change here
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  ScheduleSessionApiService.dart         │
│  static const baseUrl = '10.33...';  ← Change here
└─────────────────────────────────────────┘

😫 Error-prone, tedious, easy to miss one!
```

---

## The Solution ✅
```
New Way: Change IP in 1 place

                    ┌──────────────────────────┐
                    │  api_config.dart         │
                    │                          │
                    │  baseUrl = '10.33....' ← Change here
                    │                          │
                    └──────────┬───────────────┘
                               │
                ┌──────────────┼──────────────┐
                │              │              │
                ▼              ▼              ▼
            ┌────────┐   ┌────────┐   ┌────────────┐
            │ User   │   │Register│   │ Session    │
            │Service │   │Service │   │ Service    │
            └────────┘   └────────┘   └────────────┘

😊 One change updates everything!
```

---

## Step-by-Step Guide

### Step 1: Open the File
```
File: lib/config/api_config.dart
```

### Step 2: Locate the Line
```dart
class ApiConfig {
  /// Main API Base URL - Change this to switch servers
  static const String baseUrl = 'http://10.33.135.43:8000';  ← THIS LINE
  //                                    ↑
  //                            Change this IP address
```

### Step 3: Change the IP
```dart
// BEFORE:
static const String baseUrl = 'http://10.33.135.43:8000';

// AFTER:
static const String baseUrl = 'http://YOUR.NEW.IP.ADDRESS:8000';
```

### Step 4: Save File
```
Ctrl + S (or Cmd + S on Mac)
```

### Step 5: Done! 🎉
All API calls will now use the new IP automatically.

---

## Examples of IP Address Changes

### Example 1: Local Development
```dart
static const String baseUrl = 'http://localhost:8000';
```

### Example 2: Network Development
```dart
static const String baseUrl = 'http://192.168.1.100:8000';
```

### Example 3: Different Network
```dart
static const String baseUrl = 'http://10.33.135.43:8000';
```

### Example 4: Staging Server
```dart
static const String baseUrl = 'http://staging-api.example.com:8000';
```

### Example 5: Production Server
```dart
static const String baseUrl = 'https://api.example.com';
```

---

## What Gets Updated Automatically

When you change the `baseUrl`, all these endpoints are automatically updated:

```dart
// Login
ApiConfig.loginUrl
// Now points to: http://YOUR.NEW.IP/api/patients/login

// Register
ApiConfig.registerUrl
// Now points to: http://YOUR.NEW.IP/api/patients/register

// Sessions
ApiConfig.sessionsUrl
// Now points to: http://YOUR.NEW.IP/api/sessions

// Available Doctors
ApiConfig.doctorsAvailableUrl
// Now points to: http://YOUR.NEW.IP/api/sessions/doctors/available

// Create Session
ApiConfig.sessionCreateUrl
// Now points to: http://YOUR.NEW.IP/api/sessions/SessionCreate

// Dashboard
ApiConfig.dashboardUrl
// Now points to: http://YOUR.NEW.IP/api/patients/dashboard
```

---

## Verification

### Option 1: Print Configuration
Add this in your app to see current configuration:

```dart
// In main.dart or any startup screen
ApiConfig.printConfig();
```

Output:
```
╔════════════════════════════════════════════════════╗
║        API CONFIGURATION                           ║
╠════════════════════════════════════════════════════╣
║ Environment: Development                           ║
║ Base URL: http://10.33.135.43:8000                ║
║ API Version: /api                                  ║
║ Connection Timeout: 30s                            ║
║ Receive Timeout: 30s                               ║
╚════════════════════════════════════════════════════╝
```

### Option 2: Check in Services
All services will automatically use the new URL:

```dart
// UserApiService - automatically uses new IP
Uri.parse(ApiConfig.loginUrl)

// RegisterApiService - automatically uses new IP
Uri.parse(ApiConfig.registerUrl)

// SessionApiService - automatically uses new IP
Uri.parse(ApiConfig.sessionsUrl)
```

---

## Common Mistakes to Avoid

### ❌ DON'T: Change baseUrl and then modify individual services
```dart
// WRONG - Don't do this!
static const String baseUrl = 'http://new-ip:8000';

// And then in UserApiService
Uri.parse('http://old-ip/api/patients/login')  // ❌ Wrong!
```

### ✅ DO: Only change baseUrl in api_config.dart
```dart
// CORRECT - Just change this one line
static const String baseUrl = 'http://new-ip:8000';

// All services will automatically use the new IP
Uri.parse(ApiConfig.loginUrl)  // ✅ Uses new IP
Uri.parse(ApiConfig.registerUrl)  // ✅ Uses new IP
```

---

## Quick Reference Card

| Task | File | Line | Change |
|------|------|------|--------|
| Change IP | `api_config.dart` | 11 | `baseUrl` value |
| View Config | Any file | - | `ApiConfig.printConfig()` |
| Get Environment | Any file | - | `ApiConfig.getEnvironment()` |
| Use Login URL | Service | - | `ApiConfig.loginUrl` |
| Use Register URL | Service | - | `ApiConfig.registerUrl` |
| Use Sessions URL | Service | - | `ApiConfig.sessionsUrl` |
| Use Headers | Service | - | `ApiConfig.defaultHeaders` |

---

## Troubleshooting

### Problem: API calls not working after changing IP
**Solution:** 
1. Verify the new IP is correct
2. Make sure port number is included (e.g., `:8000`)
3. Check if the server is running at the new IP
4. Run `ApiConfig.printConfig()` to verify the configuration

### Problem: Not sure if change took effect
**Solution:**
Add this to your main function:
```dart
void main() {
  ApiConfig.printConfig();  // Print config to see current IP
  runApp(const MyApp());
}
```

### Problem: Still seeing old IP
**Solution:**
1. Save the file (Ctrl+S)
2. Hot restart the app (or full restart if hot restart doesn't work)
3. Check that you edited the correct file: `lib/config/api_config.dart`

---

## 📞 Summary

**Old Way:** Edit multiple files with hardcoded IP addresses ❌

**New Way:** Edit ONE line in ONE file ✅

**Result:** Instant IP address change across entire app!

---

**🎉 That's all you need to know!**

Change the IP address in `lib/config/api_config.dart` line 11 and you're done.

