import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:health_research/config/api_config.dart';

class ScheduleSessionApiService {

  Future<Map<String, dynamic>> getAvailableDoctors({
    required String startDateTime,
    required String endDateTime,
  }) async {
    try {
      final queryParams = {
        'start_datetime': startDateTime,
        'end_datetime': endDateTime,
      };

      final uri = Uri.parse(ApiConfig.doctorsAvailableUrl)
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load available doctors');
      }
    } catch (e) {
      throw Exception('Error fetching doctors: $e');
    }
  }

  Future<Map<String, dynamic>> createSession({
    required String doctorId,
    required String doctorName,
    required String patientId,
    required String patientName,
    required String sessionDate,
    required String sessionTime,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.sessionCreateUrl),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'doctor_id': doctorId,
          'doctor_name': doctorName,
          'patient_id': patientId,
          'patient_name': patientName,
          'session_date': sessionDate,
          'session_time': sessionTime,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create session');
      }
    } catch (e) {
      throw Exception('Error creating session: $e');
    }
  }
}
