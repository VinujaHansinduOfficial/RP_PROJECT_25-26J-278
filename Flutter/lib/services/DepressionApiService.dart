import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:health_research/config/api_config.dart';
import 'package:health_research/models/DepressionResult.dart';

class DepressionApiService {
  Future<DepressionResult?> getDepressionResults(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl1}/results/depression/$userId'),
        headers: ApiConfig.defaultHeaders,
      );

      print("Response status: ${response.statusCode}");
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print("dataaaaaa , $jsonResponse");
        return DepressionResult.fromJson(jsonResponse);
      } else if (response.statusCode == 404) {
        // No depression results found, return empty result
        print("data3333, $response.body");
        return DepressionResult(
          userId: userId,
          type: 'Depression',
          count: 0,
          results: [],
        );
      } else {
        throw Exception(
            'Failed to load depression results: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching depression results: $e');
    }
  }

  /// Submit depression prediction with questionnaire data
  Future<Map<String, dynamic>> predictDepression(
    String userId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/predict/depression'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'user_id': userId,
          ...payload,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse as Map<String, dynamic>;
      } else {
        throw Exception('Failed to predict depression: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error predicting depression: $e');
    }
  }
}
