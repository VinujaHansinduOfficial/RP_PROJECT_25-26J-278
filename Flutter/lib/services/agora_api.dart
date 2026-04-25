import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:health_research/config/api_config.dart';

class AgoraApi {
  /// Backend base URL - dynamically retrieved from ApiConfig
  /// This allows easy switching between dev, staging, and production servers
  /// Change the baseUrl in lib/config/api_config.dart to switch servers
  static String get backendBase => ApiConfig.baseUrl;

  // Fallback URLs to try if primary fails (useful for debugging network issues)
  static const List<String> fallbackUrls = [
    // Fallback URLs can be added here if needed
    // The primary URL will be used from ApiConfig.baseUrl
  ];

  /// Fetch token from backend with timeout and better error handling
  static Future<Map<String, dynamic>> getToken({
    required String sessionId,
    required String role, // doctor or patient
    int?
        uid, // Optional: specific UID (1000=doctor web, 1001=doctor flutter, 1002=patient)
  }) async {
    try {
      // Determine UID based on role if not explicitly provided
      int assignedUid = uid ?? (role == "doctor" ? 1001 : 1002);

      final url =
          Uri.parse("$backendBase/token?channel=$sessionId&uid=$assignedUid");

      // Add timeout to prevent hanging forever (e.g. backend offline)
      final res = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception(
              "Request timed out – check your internet or backend server");
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        // Validate required fields - only token is required
        if (data["token"] == null) {
          throw Exception("Invalid token response – missing token field");
        }

        return {
          "token": data["token"] as String,
          "uid": data["uid"] != null ? int.parse(data["uid"].toString()) : 0,
          "channel": data["channel"] ?? sessionId, // fallback
          "role": data["role"] ?? role,
        };
      } else {
        // Server returned error (400, 500, etc.)
        throw Exception("Failed to fetch token\n"
            "Status: ${res.statusCode}\n"
            "Body: ${res.body.substring(0, res.body.length.clamp(0, 200))}");
      }
    } on http.ClientException catch (e) {
      // Network-level errors (no connection, DNS failure, etc.)
      final errorMsg = "Network error: $e\n"
          "⚠️ Unable to connect to backend at: $backendBase\n"
          "💡 TROUBLESHOOTING:\n"
          "  1. Check if backend is running: python start_api.py\n"
          "  2. Verify backend IP address matches your machine\n"
          "  3. Check if device is on same network as backend\n"
          "  4. Update AgoraApi.backendBase in agora_api.dart if IP changed\n"
          "  5. For physical device, use machine IP (not localhost)";
      throw Exception(errorMsg);
    } on FormatException catch (e) {
      // JSON parsing failed
      throw Exception("Invalid JSON response from server: $e");
    } on TimeoutException {
      throw Exception(
          "Backend took too long to respond (timeout after 10 seconds)\n"
          "💡 Backend might be offline or network is slow.\n"
          "   Check if running: python start_api.py");
    } catch (e, stack) {
      // Any other unexpected error
      if (kDebugMode) {
        print("Unexpected error in getToken: $e");
        print("Stack trace: $stack");
      }
      throw Exception("Unexpected error while fetching token: $e");
    }
  }
}
