import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:health_research/config/api_config.dart';

class SessionApiService {

  Future<Map<String, dynamic>> getSessions({
    String? patientId,
    String? doctorId,
    String? status,
    int skip = 0,
    int limit = 100,
    bool activeOnly = true,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (patientId != null && patientId.isNotEmpty) {
        queryParams['patient_id'] = patientId;
      }
      print('Patient ID: $patientId');

      if (doctorId != null && doctorId.isNotEmpty) {
        queryParams['doctor_id'] = doctorId;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      queryParams['skip'] = skip.toString();
      queryParams['limit'] = limit.toString();
      queryParams['active_only'] = activeOnly.toString();

      final uri = Uri.parse(ApiConfig.sessionsUrl).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse;
      } else {
        throw Exception('Failed to load sessions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Session error: $e');
    }
  }
}
