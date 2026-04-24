import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:health_research/models/User.dart';
import 'package:health_research/config/api_config.dart';

class UserApiService {
  Future<User?> loginUser(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('Login successful: $jsonResponse');

        // Parse the API response directly
        User user = User.fromJson({
          'patient_id': jsonResponse['patient_id'],
          'first_name': jsonResponse['first_name'],
          'email': jsonResponse['email'],
          'has_assigned_doctors': jsonResponse['has_assigned_doctors'],
          'age': jsonResponse['age'],
        });

        return user;
      } else if (response.statusCode == 401) {
        throw Exception('Invalid email or password');
      } else {
        throw Exception(
            'Login failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }
}
