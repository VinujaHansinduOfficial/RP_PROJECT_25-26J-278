import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:health_research/config/api_config.dart';

class Prediction {
  final String date;
  final String stressPredLabel;
  final String mentalPredLabel;

  Prediction({
    required this.date,
    required this.stressPredLabel,
    required this.mentalPredLabel,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      date: json['date'] ?? '',
      stressPredLabel: json['stress_pred_label'] ?? 'Unknown',
      mentalPredLabel: json['mental_pred_label'] ?? 'Unknown',
    );
  }
}

class ForecastData {
  final int studentId;
  final int count;
  final List<Prediction> predictions;

  ForecastData({
    required this.studentId,
    required this.count,
    required this.predictions,
  });

  factory ForecastData.fromJson(Map<String, dynamic> json) {
    var predictionsList = (json['results'] as List)
        .expand((result) => (result['predictions'] as List? ?? []))
        .map((p) => Prediction.fromJson(p as Map<String, dynamic>))
        .toList();

    return ForecastData(
      studentId: json['student_id'] ?? 0,
      count: json['count'] ?? 0,
      predictions: predictionsList,
    );
  }
}

class ForecastApiService {
  Future<ForecastData?> fetchForecast(int studentId) async {
    try {
      // Generate random student ID between 1-10
      final randomStudentId = Random().nextInt(10) + 1;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl3}/forecast/$randomStudentId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return ForecastData.fromJson(jsonResponse);
      } else {
        // Error fetching forecast
        return null;
      }
    } catch (e) {
      // Error fetching forecast data
      return null;
    }
  }
}
