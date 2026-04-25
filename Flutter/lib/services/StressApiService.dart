import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:health_research/config/api_config.dart';
import 'package:health_research/models/StressResult.dart';

class StressApiService {
  Future<StressResult?> getStressResults(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl1}/results/stress/$userId'),
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return StressResult.fromJson(jsonResponse);
      } else if (response.statusCode == 404) {
        // No stress results found, return empty result
        return StressResult(
          userId: userId,
          type: 'Stress',
          count: 0,
          results: [],
        );
      } else {
        throw Exception(
            'Failed to load stress results: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching stress results: $e');
    }
  }

  /// Fetch user features (Heart_Rate, Sleep_Hours, Screen_Time, Age, etc.)
  Future<Map<String, dynamic>> getUserFeatures(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl1}/user_features/$userId'),
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['features'] as Map<String, dynamic>? ?? {};
      } else {
        throw Exception('Failed to load user features: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user features: $e');
    }
  }

  /// Submit stress prediction with questionnaire data
  Future<Map<String, dynamic>> predictStress(
    String userId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl1}/predict/stress'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'user_id': userId,
          'data': payload,
        }),
      );

      print("Predict Stress Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        print("Predict Stress Response body: ${response.body}");
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse as Map<String, dynamic>;
      } else {
        throw Exception('Failed to predict stress: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error predicting stress: $e');
    }
  }

  /// Submit depression prediction with questionnaire data
  Future<Map<String, dynamic>> predictDepression(
    String userId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl1}/predict/depression'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'user_id': userId,
          'data': payload,
        }),
      );

      print("Predict Depression Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        print("Predict Depression Response body: ${response.body}");
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse as Map<String, dynamic>;
      } else {
        throw Exception('Failed to predict depression: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error predicting depression: $e');
    }
  }

  /// Submit anxiety prediction with questionnaire data
  Future<Map<String, dynamic>> predictAnxiety(
    String userId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl1}/predict/anxiety'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'user_id': userId,
          'data': payload,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse as Map<String, dynamic>;
      } else {
        throw Exception('Failed to predict anxiety: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error predicting anxiety: $e');
    }
  }
}
