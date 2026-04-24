import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:health_research/config/api_config.dart';

class PrerequisiteCheckService {
  /// Base URL for prerequisites API (different from main API)
  static const String prerequisiteBaseUrl = ApiConfig.baseUrl1;

  /// Check all prerequisites before allowing access to questionnaire
  /// Returns a map with 'success' and 'message' keys
  static Future<Map<String, dynamic>> checkAllPrerequisites(String userId) async {
    try {
      // Check 1: User Features
      final userFeaturesCheck = await _checkUserFeatures(userId);
      if (!userFeaturesCheck['success']) {
        return userFeaturesCheck;
      }

      // Check 2: Stress Results
      final stressCheck = await _checkStressResults(userId);
      if (!stressCheck['success']) {
        return stressCheck;
      }

      // Check 3: Anxiety Results
      final anxietyCheck = await _checkAnxietyResults(userId);
      if (!anxietyCheck['success']) {
        return anxietyCheck;
      }

      // Check 4: Depression Results
      final depressionCheck = await _checkDepressionResults(userId);
      if (!depressionCheck['success']) {
        return depressionCheck;
      }

      // All checks passed
      return {
        'success': true,
        'message': 'All prerequisites completed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error checking prerequisites: $e',
      };
    }
  }

  /// Check if user has completed user features (Heart_Rate, Sleep_Hours, Screen_Time)
  static Future<Map<String, dynamic>> _checkUserFeatures(String userId) async {
    try {
      final url = Uri.parse('$prerequisiteBaseUrl/user_features/$userId');
      final response = await http.get(url).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'You need to add "Heart Rate", "Sleep Hours", and "Screen Time" before taking this questionnaire',
          'type': 'user_features_missing',
        };
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('User Features: $data');
        return {
          'success': true,
          'message': 'User features check passed',
        };
      }

      return {
        'success': false,
        'message': 'Failed to check user features',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error checking user features: $e',
      };
    }
  }

  /// Check if user has completed stress quiz
  static Future<Map<String, dynamic>> _checkStressResults(String userId) async {
    try {
      final url = Uri.parse('$prerequisiteBaseUrl/results/stress/$userId');
      final response = await http.get(url).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check if results array is empty
        final results = data['results'] as List?;
        if (results == null || results.isEmpty) {
          return {
            'success': false,
            'message': 'Complete daily stress quiz before taking this questionnaire',
            'type': 'stress_quiz_required',
          };
        }

        return {
          'success': true,
          'message': 'Stress quiz check passed',
        };
      }

      return {
        'success': false,
        'message': 'Failed to check stress results',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error checking stress results: $e',
      };
    }
  }

  /// Check if user has completed anxiety quiz
  static Future<Map<String, dynamic>> _checkAnxietyResults(String userId) async {
    try {
      final url = Uri.parse('$prerequisiteBaseUrl/results/anxiety/$userId');
      final response = await http.get(url).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check if results array is empty
        final results = data['results'] as List?;
        if (results == null || results.isEmpty) {
          return {
            'success': false,
            'message': 'Complete daily anxiety quiz before taking this questionnaire',
            'type': 'anxiety_quiz_required',
          };
        }

        return {
          'success': true,
          'message': 'Anxiety quiz check passed',
        };
      }

      return {
        'success': false,
        'message': 'Failed to check anxiety results',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error checking anxiety results: $e',
      };
    }
  }

  /// Check if user has completed depression quiz
  static Future<Map<String, dynamic>> _checkDepressionResults(String userId) async {
    try {
      final url = Uri.parse('$prerequisiteBaseUrl/results/depression/$userId');
      final response = await http.get(url).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check if results array is empty
        final results = data['results'] as List?;
        if (results == null || results.isEmpty) {
          return {
            'success': false,
            'message': 'Complete daily depression quiz before taking this questionnaire',
            'type': 'depression_quiz_required',
          };
        }

        return {
          'success': true,
          'message': 'Depression quiz check passed',
        };
      }

      return {
        'success': false,
        'message': 'Failed to check depression results',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error checking depression results: $e',
      };
    }
  }
}
