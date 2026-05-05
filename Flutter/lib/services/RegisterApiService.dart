import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:health_research/config/api_config.dart';

class RegisterApiService {
  Future<Map<String, dynamic>> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
    required String phone,
    required String dateOfBirth,
    required String gender,
    required String address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.registerUrl),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
          'confirm_password': confirmPassword,
          'phone': phone,
          'date_of_birth': dateOfBirth,
          'gender': gender,
          'address': address,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          return jsonResponse;
        } else {
          throw Exception(jsonResponse['message'] ?? 'Registration failed');
        }
      } else if (response.statusCode == 400) {
        final jsonResponse = jsonDecode(response.body);
        throw Exception(jsonResponse['message'] ?? 'Invalid registration data');
      } else if (response.statusCode == 409) {
        throw Exception('Email already registered');
      } else {
        throw Exception(
            'Registration failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }
}
