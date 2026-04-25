import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:health_research/config/api_config.dart';
import 'package:health_research/models/AnxietyResult.dart';

class AnxietyApiService {
  Future<AnxietyResult?> getAnxietyResults(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl1}/results/anxiety/$userId'),
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return AnxietyResult.fromJson(jsonResponse);
      } else if (response.statusCode == 404) {
        // No anxiety results found, return empty result
        return AnxietyResult(
          userId: userId,
          type: 'Anxiety',
          count: 0,
          results: [],
        );
      } else {
        throw Exception(
            'Failed to load anxiety results: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching anxiety results: $e');
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

      print("Predict Anxiety Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        print("Predict Anxiety Response body: ${response.body}");
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
