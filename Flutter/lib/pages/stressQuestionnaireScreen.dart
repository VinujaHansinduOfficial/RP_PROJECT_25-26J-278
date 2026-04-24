import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:health_research/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_research/pages/daily_journal.dart';

class StressQuestionnaireScreen extends StatefulWidget {
  const StressQuestionnaireScreen({super.key});

  @override
  State<StressQuestionnaireScreen> createState() => _StressQuestionnaireScreenState();
}

class _StressQuestionnaireScreenState extends State<StressQuestionnaireScreen> {
  int _currentIndex = 0;
  final Map<int, dynamic> _answers = {};

  void initState() {
    super.initState();
    _loadUserData();
  }

  String patientId = "";

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    patientId = prefs.getString('patientId') ?? '';
  }
  bool get _isNextEnabled {
    final answer = _answers[_currentIndex];
    final q = _questions[_currentIndex];
    final type = q['type'];

    // Choice-based types
    if (type == 'choice' || type == 'frequency_grid' || type == 'yes_no') {
      return answer != null;
    }

    // Rating scale
    if (type == 'rating_scale') {
      return answer is int && answer > 0;
    }

    // Slider (0-100 or custom range)
    if (type == 'slider') {
      return answer != null;
    }

    // Percentage (0-100)
    if (type == 'percentage') {
      return answer is int && answer >= 0 && answer <= 100;
    }

    // Text input
    if (type == 'text_input') {
      return answer is String && answer.isNotEmpty;
    }

    // Time input (HH:MM format)
    if (type == 'time_input') {
      return answer is String && RegExp(r'^\d{1,2}:\d{2}$').hasMatch(answer);
    }

    // Numeric inputs
    if (type == 'number_1_10') {
      return answer is int && answer >= 1 && answer <= 10;
    }
    if (type == 'number_hours') {
      return answer is int && answer >= 0 && answer <= 168;
    }
    if (type == 'number_hours_day') {
      return answer is int && answer >= 0 && answer <= 24;
    }
    if (type == 'gpa') {
      return answer is double && answer >= 0 && answer <= 4.0;
    }

    return false;
  }

  /// Get all answers in a structured format
  Map<String, dynamic> get _answersData {
    return {
      'Noise_Exposure': _mapFrequencyGridAnswer(_answers[0], 4) ?? 0,
      'Social_Interaction': _answers[1] ?? 0,
      'Work_Hours': _answers[2] ?? 0,
      'Exercise_Hours': _answers[3] ?? 0,
      'Caffeine_Intake': _mapFrequencyGridAnswer(_answers[4], 4) ?? 0,
      'Multitasking_Habit': _answers[5] == 'Yes (1)' ? 1 : 0,
      'Sensory_Sensitivity': _answers[6] ?? 0,
      'Meditation_Habit': _answers[7] == 'Yes (1)' ? 1 : 0,
      'Overthinking_Score': _answers[8] ?? 0,
      'Irritability_Score': _answers[9] ?? 0,
      'Headache_Frequency': _mapFrequencyGridAnswer(_answers[10], 6) ?? 0,
      'Sleep_Quality': _mapSleepQuality(_answers[11]) ?? 0,
      'Tech_Usage_Hours': _answers[12] ?? 0,
      'GPA': _answers[13] ?? 0.0,
      'Prev_GPA': _answers[14] ?? 0.0,
      'GPA_trend': (_answers[13] ?? 0.0) - (_answers[14] ?? 0.0),
      'Modules': _answers[15] ?? 0,
      'Assignments_total': _answers[16] ?? 0,
      'Deadlines_next_7_days': _answers[17] ?? 0,
      'Study_hours_per_day': _answers[18] ?? 0,
      'Attendance_pct': _answers[19] ?? 0.0,
    };
  }

  /// Map frequency grid answer to numeric value
  int? _mapFrequencyGridAnswer(dynamic answer, int maxValue) {
    if (answer == null) return null;

    // For Noise_Exposure (4 options -> 0-3)
    if (maxValue == 4) {
      const options = ['Very Quiet', 'Low Noise', 'Medium Noise', 'Very Noisy'];
      final index = options.indexOf(answer.toString());
      return index >= 0 ? index : null;
    }

    // For Headache_Frequency (6 options -> 0-5)
    if (maxValue == 6) {
      const options = ['Never', 'Rarely', 'Sometimes', 'Often', 'Very Often', 'Always'];
      final index = options.indexOf(answer.toString());
      return index >= 0 ? index : null;
    }

    return null;
  }

  /// Map sleep quality answer to numeric value (0-5)
  int? _mapSleepQuality(dynamic answer) {
    if (answer == null) return null;

    const Map<String, int> sleepMap = {
      'Very Poor': 0,
      'Poor': 1,
      'Fair': 2,
      'Good': 3,
      'Very Good': 4,
      'Excellent': 5,
    };

    return sleepMap[answer.toString()];
  }

  final List<Map<String, dynamic>> _questions = [
    // Academic Stress Questions
    {
      'title': 'How noisy is your daily environment?',
      'image': 'assets/images/question_noise.png',
      'type': 'frequency_grid',
      'options': ['Very Quiet', 'Low Noise', 'Medium Noise', 'Very Noisy'],
      'key': 'Noise_Exposure',
      'range': '0-5',
    },
    {
      'title': 'On a scale of 1-10, how socially active are you?',
      'image': 'assets/images/question_social.jpg',
      'type': 'number_1_10',
      'key': 'Social_Interaction',
      'range': '0-10',
    },
    {
      'title': 'How many hours per day do you work at a job?',
      'image': 'assets/images/question_work.png',
      'type': 'number_hours',
      'key': 'Work_Hours',
      'range': '0-24',
    },
    {
      'title': 'How many hours per day do you exercise?',
      'image': 'assets/images/question_exercise.jpg',
      'type': 'number_hours_day',
      'key': 'Exercise_Hours',
      'range': '0-6',
    },
    {
      'title': 'How much caffeine do you take in a day?',
      'image': 'assets/images/question_caffeine.jpg',
      'type': 'frequency_grid',
      'options': [
        'Less than 1 Energy drinks/Coffees',
        'Less than 2 Energy drinks/Coffees',
        'Less than 3 Energy drinks/Coffees',
        'More than 4 Energy drinks/Coffees',
      ],
      'key': 'Caffeine_Intake',
      'range': '0-5',
    },
    {
      'title': 'On a scale of 0-1, do you have a multitasking habit?',
      'image': 'assets/images/question_work.png',
      'type': 'choice',
      'options': ['No', 'Yes'],
      'key': 'Multitasking_Habit',
      'range': '0-1',
    },
    {
      'title': 'On a scale of 1-10, how sensitive are you to sensory stimuli?',
      'image': 'assets/images/question_noise.png',
      'type': 'number_1_10',
      'key': 'Sensory_Sensitivity',
      'range': '0-10',
    },
    {
      'title': 'On a scale of 0-1, do you have a meditation habit?',
      'image': 'assets/images/question_exercise2.jpg',
      'type': 'choice',
      'options': ['No', 'Yes'],
      'key': 'Meditation_Habit',
      'range': '0-1',
    },
    {
      'title': 'On a scale of 1-10, how much do you overthink?',
      'image': 'assets/images/question_stressed.jpg',
      'type': 'number_1_10',
      'key': 'Overthinking_Score',
      'range': '0-10',
    },
    {
      'title': 'How frequently do you experience headaches (0-6 scale)?',
      'image': 'assets/images/question_health.png',
      'type': 'choice',
      'options': ['Never', 'Rarely', 'Sometimes', 'Often', 'Very Often', 'Always'],
      'key': 'Headache_Frequency',
      'range': '0-6',
    },
    {
      'title': 'How would you rate your sleep quality over the past week?',
      'image': 'assets/images/question_sleep.jpg',
      'type': 'choice',
      'options': ['Very Poor', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent'],
      'key': 'Sleep_Quality',
      'range': '0-6',
    },
    {
      'title': 'On a typical day, how many total hours do you spend using technology (excluding academic classes)?',
      'image': 'assets/images/question_tech.jpg',
      'type': 'number_hours_day',
      'key': 'Tech_Usage_Hours',
      'range': '0-24',
    },
    {
      'title': 'Current Grade Point Average (GPA)',
      'image': 'assets/images/question_gpa.jpg',
      'type': 'gpa',
      'key': 'GPA',
      'range': '0.0-4.0',
    },
    {
      'title': 'Previous Grade Point Average (GPA)',
      'image': 'assets/images/question_gpa.jpg',
      'type': 'gpa',
      'key': 'Prev_GPA',
      'range': '0.0-4.0',
    },
    {
      'title': 'How many modules are you currently taking?',
      'image': 'assets/images/academic.png',
      'type': 'number_1_10',
      'key': 'Modules',
      'range': '1-10',
    },
    {
      'title': 'How many total assignments do you have this term?',
      'image': 'assets/images/file_icon.png',
      'type': 'number_1_10',
      'key': 'Assignments_total',
      'range': '0-10',
    },
    {
      'title': 'How many deadlines do you have in the next 7 days?',
      'image': 'assets/images/file_icon.png',
      'type': 'number_1_10',
      'key': 'Deadlines_next_7_days',
      'range': '0-10',
    },
    {
      'title': 'On a typical day, how many total hours do you study?',
      'image': 'assets/images/question_education.jpg',
      'type': 'number_hours_day',
      'key': 'Study_hours_per_day',
      'range': '0-24',
    },
    {
      'title': 'What is your current attendance percentage?',
      'image': 'assets/images/question_parttime.jpeg',
      'type': 'percentage',
      'key': 'Attendance_pct',
      'range': '0-100',
    },
  ];

  void _onChoiceSelected(dynamic value) {
    setState(() {
      _answers[_currentIndex] = value;
    });
  }

  void _onNumberChanged(String value, String type) {
    if (value.isEmpty) {
      _answers.remove(_currentIndex);
      setState(() {});
      return;
    }

    if (type == 'number_1_10' || type == 'number_hours' || type == 'number_hours_day') {
      final n = int.tryParse(value);
      if (n != null) {
        if ((type == 'number_1_10' && n >= 1 && n <= 10) ||
            (type == 'number_hours' && n >= 0 && n <= 168) ||
            (type == 'number_hours_day' && n >= 0 && n <= 24)) {
          _answers[_currentIndex] = n;
        }
      }
    } else if (type == 'gpa') {
      final n = double.tryParse(value);
      if (n != null && n >= 0 && n <= 4.0) {
        _answers[_currentIndex] = n;
      }
    }

    setState(() {});
  }

  void _next() {
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      // Questionnaire completed - call behavior prediction API
      _submitQuestionnaire();
    }
  }

  /// Submit questionnaire to behavior prediction API
  Future<void> _submitQuestionnaire() async {
    try {

      _showLoadingDialog('Submitting responses...');

      // Step 1: Fetch user details
      final userDetails = await _fetchUserDetails(patientId);
      if (!mounted) return;
      Navigator.pop(context);

      if (userDetails == null) {
        _showErrorDialog('Failed to load user details.');
        return;
      }

      print('✅ User details fetched');

      _showLoadingDialog('Fetching assessment results...');

      // Step 2: Fetch stress, anxiety, depression predictions
      final stressData = await _fetchPredictionResult('stress', patientId);
      final anxietyData = await _fetchPredictionResult('anxiety', patientId);
      final depressionData = await _fetchPredictionResult('depression', patientId);

      if (!mounted) return;
      Navigator.pop(context);

      // Extract prediction scores
      final stressScore = stressData != null ? (stressData['results'] as List).isNotEmpty
          ? (stressData['results'][0]['prediction'] ?? 0) : 0 : 0;
      final anxietyScore = anxietyData != null ? (anxietyData['results'] as List).isNotEmpty
          ? (anxietyData['results'][0]['prediction'] ?? 0) : 0 : 0;
      final depressionScore = depressionData != null ? (depressionData['results'] as List).isNotEmpty
          ? (depressionData['results'][0]['prediction'] ?? 0) : 0 : 0;

      print('✅ Stress Score: $stressScore');
      print('✅ Anxiety Score: $anxietyScore');
      print('✅ Depression Score: $depressionScore');

      // Get health metrics from database
      final heartRate = await _fetchHealthMetrics(patientId, 'Heart_Rate');
      final sleepHours = await _fetchHealthMetrics(patientId, 'Sleep_Hours');
      final screenTime = await _fetchHealthMetrics(patientId, 'Screen_Time');

      print('✅ Heart Rate: $heartRate');
      print('✅ Sleep Hours: $sleepHours');
      print('✅ Screen Time: $screenTime');

      // Step 3: Prepare behavior prediction data
      final behaviorData = _prepareBehaviorPredictionData(
        userDetails,
        patientId,
        stressScore,
        anxietyScore,
        depressionScore,
        heartRate,
        sleepHours,
        screenTime,
      );

      _showLoadingDialog('Analyzing behavior...');

      // Step 4: Submit to behavior prediction API
      // Note: _submitBehaviorPrediction will close the loading dialog and show the prediction dialog
      final success = await _submitBehaviorPrediction(behaviorData);

      if (!mounted) return;

      // If prediction failed, show error
      if (!success) {
        _showErrorDialog('Failed to submit assessment.');
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (mounted) {
        _showErrorDialog('An error occurred: $e');
      }
    }
  }

  /// Fetch user details from API
  Future<Map<String, dynamic>?> _fetchUserDetails(String patientId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/patients/$patientId');
      final response = await http.get(url).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching user details: $e');
      return null;
    }
  }

  /// Fetch prediction results (stress, anxiety, depression)
  Future<Map<String, dynamic>?> _fetchPredictionResult(
    String type,
    String userId,
  ) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl1}/results/$type/$userId');
      print('📡 Fetching $type results from: $url');

      final response = await http.get(url).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      print('📥 $type response status: ${response.statusCode}');
      print('📥 $type response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ $type data received: $data');
        return data;
      }

      print('❌ Failed to fetch $type results. Status: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ Error fetching $type results: $e');
      return null;
    }
  }

  /// Fetch health metrics from database
  Future<int> _fetchHealthMetrics(String userId, String metric) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl1}/user_features/$userId');
      print('📡 Fetching $metric from: $url');

      final response = await http.get(url).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      print('📥 Health metrics response status: ${response.statusCode}');
      print('📥 Health metrics response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Features object: ${data['features']}');

        final value = data['features']?[metric] ?? 0;
        print('✅ $metric value: $value');

        return value as int? ?? 0;
      }

      print('❌ Failed to fetch health metrics. Status: ${response.statusCode}');
      return 0;
    } catch (e) {
      print('❌ Error fetching $metric: $e');
      return 0;
    }
  }

  /// Prepare behavior prediction data
  Map<String, dynamic> _prepareBehaviorPredictionData(
    Map<String, dynamic> userDetails,
    String userId,
    int stressScore,
    int anxietyScore,
    int depressionScore,
    int heartRate,
    int sleepHours,
    int screenTime,
  ) {
    // Calculate age from date of birth
    int age = 0;
    if (userDetails['date_of_birth'] != null) {
      try {
        final dob = DateTime.parse(userDetails['date_of_birth']);
        final today = DateTime.now();
        age = today.year - dob.year;
        if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
          age--;
        }
      } catch (e) {
        age = 30;
        print('Error parsing DOB: $e');
      }
    }

    final allAnswers = _answersData;

    // Generate random Irritability_Score (1-10)
    final random = Random();
    final irritabilityScore = random.nextInt(10) + 1;

    // Log the values being sent
    print('═══════════════════════════════════════════════════════════');
    print('BEHAVIOR PREDICTION DATA:');
    print('Age: $age');
    print('Sleep_Hours: $sleepHours');
    print('Screen_Time: $screenTime');
    print('Stress_Level: $stressScore');
    print('Anxiety_Score: $anxietyScore');
    print('Depression_Score: $depressionScore');
    print('Heart_Rate: $heartRate');
    print('Irritability_Score: $irritabilityScore (random 1-10)');
    print('Overstimulated: 1');
    print('Assignment_weight_avg_pct: ${(DateTime.now().millisecond % 101).toDouble()}');
    print('═══════════════════════════════════════════════════════════');

    final assignmentWeightAvg = (DateTime.now().millisecond % 101).toDouble();

    return {
      'user_id': userId,
      'features': {
        'Age': age,
        'Sleep_Hours': sleepHours,
        'Screen_Time': screenTime,
        'Stress_Level': stressScore,
        'Noise_Exposure': allAnswers['Noise_Exposure'] ?? 0,
        'Social_Interaction': allAnswers['Social_Interaction'] ?? 0,
        'Work_Hours': allAnswers['Work_Hours'] ?? 0,
        'Exercise_Hours': allAnswers['Exercise_Hours'] ?? 0,
        'Caffeine_Intake': allAnswers['Caffeine_Intake'] ?? 0,
        'Multitasking_Habit': allAnswers['Multitasking_Habit'] ?? 0,
        'Anxiety_Score': anxietyScore,
        'Depression_Score': depressionScore,
        'Sensory_Sensitivity': allAnswers['Sensory_Sensitivity'] ?? 0,
        'Meditation_Habit': allAnswers['Meditation_Habit'] ?? 0,
        'Overthinking_Score': allAnswers['Overthinking_Score'] ?? 0,
        'Irritability_Score': irritabilityScore,
        'Headache_Frequency': allAnswers['Headache_Frequency'] ?? 0,
        'Sleep_Quality': allAnswers['Sleep_Quality'] ?? 0,
        'Tech_Usage_Hours': allAnswers['Tech_Usage_Hours'] ?? 0,
        'Overstimulated': 1,
        'Heart_Rate': heartRate,
        'GPA': allAnswers['GPA'] ?? 0.0,
        'Prev_GPA': allAnswers['Prev_GPA'] ?? 0.0,
        'GPA_trend': allAnswers['GPA_trend'] ?? 0.0,
        'Modules': allAnswers['Modules'] ?? 0,
        'Assignments_total': allAnswers['Assignments_total'] ?? 0,
        'Deadlines_next_7_days': allAnswers['Deadlines_next_7_days'] ?? 0,
        'Assignment_weight_avg_pct': assignmentWeightAvg,
        'Study_hours_per_day': allAnswers['Study_hours_per_day'] ?? 0,
        'Attendance_pct': allAnswers['Attendance_pct'] ?? 0.0,
      },
    };
  }

  /// Submit behavior prediction data to API
  Future<bool> _submitBehaviorPrediction(Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl2}/predict/behavior');


      final jsonBody = jsonEncode(data);

      print('═══════════════════════════════════════════════════════════');
      print('SUBMITTING TO: $url');
      print('FULL PAYLOAD:');
      print(jsonBody);
      print('═══════════════════════════════════════════════════════════');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonBody,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      print('Behavior Prediction API Response: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = jsonDecode(response.body);
          final prediction = responseData['data']['prediction'];
          final probability = responseData['data']['probability_high_burnout'] ?? responseData['data']['probability'] ?? 0.0;

          // Check if user is stressed (prediction == 1)
          final isStressed = prediction == 1;
          print("User is stressed: $isStressed with probability: $probability");
          final stressMessage = isStressed
              ? '⚠️ You are stressed by academic activities'
              : '✅ You are not stressed by academic activities';

          if (mounted) {
            // Close the loading dialog first
            Navigator.pop(context);

            // Then show the prediction dialog
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                _showAcademicStressDialog(stressMessage, isStressed, probability);
              }
            });
          }

          return true;
        } catch (e) {
          print('Error parsing prediction response: $e');
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          return false;
        }
      }

      print('❌ API returned status: ${response.statusCode}');
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      return false;
    } catch (e) {
      print('Error submitting behavior prediction: $e');
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      return false;
    }
  }

  /// Show academic stress prediction dialog
  void _showAcademicStressDialog(
    String message,
    bool isStressed,
    double probability,
  ) {
    // If stress is high, show confirmation dialog asking to write journal
    if (isStressed) {
      _showHighStressConfirmationDialog(message, probability);
      return;
    }

    // Otherwise show the normal result dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: const Text(
                  'Assessment Result',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Confidence Score',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(probability * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: probability,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.green,
                      ),
                      minHeight: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Great Job! 🎉',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You\'re managing academic stress well. Keep maintaining a healthy balance between work and rest.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Optional: Double Check',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Write a journal entry to verify your current stress level and keep a personal record of your wellness journey.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close the alert
                Navigator.pop(context); // Close the questionnaire
                // Navigate to DailyJournal screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DailyJournal(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Write Journal',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show high stress confirmation dialog with journal navigation
  void _showHighStressConfirmationDialog(
    String message,
    double probability,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber,
                color: Colors.red,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: const Text(
                  '⚠️ High Stress Alert',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Stress Confidence Score',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(probability * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: probability,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.red,
                        ),
                        minHeight: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Please Confirm Your Status',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Write a brief entry in your daily journal to confirm your current stress level and help us understand your situation better.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
              ),
              child: const Text(
                'Skip',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close the alert
                Navigator.pop(context); // Close the questionnaire
                // Navigate to DailyJournal screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DailyJournal(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Write Journal',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show loading dialog
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text(
                'Error',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
              child: const Text(
                'OK',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Questionnaire',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.grey[300],
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% Pending...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (q['image'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 28),
                        child: Image.asset(
                          q['image'],
                          height: 180,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                        ),
                      ),
                    Text(
                      q['title'],
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.3),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    _buildAnswerWidget(q),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isNextEnabled ? _next : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isNextEnabled ? Color(0xff000000) : Colors.grey[400],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: _isNextEnabled ? 3 : 0,
                  ),
                  child: Text(
                    _currentIndex < _questions.length - 1 ? 'Next' : 'Finish',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerWidget(Map<String, dynamic> q) {
    final type = q['type'];
    final value = _answers[_currentIndex];

    // ── YES/NO Choice ──────────────────────────────────────────────
    if (type == 'yes_no') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: ['Yes', 'No'].map((opt) {
          final selected = value == opt;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: () => _onChoiceSelected(opt),
                style: ElevatedButton.styleFrom(
                  backgroundColor: selected ? const Color(0xa3bdbaba) : Colors.grey[100],
                  foregroundColor: selected ? Colors.white : Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(opt, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          );
        }).toList(),
      );
    }

    // ── Frequency Grid (2×2 or custom) ─────────────────────────────
    if (type == 'frequency_grid') {
      final options = q['options'] as List<String>;
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
        children: options.asMap().entries.map((entry) {
          final idx = entry.key;
          final opt = entry.value;
          final selected = value == opt;
          return GestureDetector(
            onTap: () => _onChoiceSelected(opt),
            child: Container(
              decoration: BoxDecoration(
                color: selected ? const Color(0xA3BDBABA) : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? Colors.black! : Colors.grey[300]!,
                  width: selected ? 2 : 1,
                ),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Text(
                opt,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }).toList(),
      );
    }

    // ── Regular Choice (vertical buttons) ───────────────────────────
    if (type == 'choice') {
      return Column(
        children: (q['options'] as List<String>).map((opt) {
          final selected = value == opt;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _onChoiceSelected(opt),
                style: ElevatedButton.styleFrom(
                  backgroundColor: selected ? const Color(0xa3bdbaba) : Colors.grey[100],
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: selected ? Colors.black : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(opt, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          );
        }).toList(),
      );
    }

    // ── Rating Scale (1-5 stars or emoji) ──────────────────────────
    if (type == 'rating_scale') {
      final maxRating = q['max_rating'] ?? 5;
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(maxRating, (index) {
              final isSelected = (value ?? 0) == (index + 1);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () => _answers[_currentIndex] = index + 1,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.amber[400] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.amber[700]! : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      '⭐',
                      style: TextStyle(
                        fontSize: isSelected ? 28 : 20,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Rating: ${value ?? 0}/$maxRating',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      );
    }

    // ── Slider (0-100) ─────────────────────────────────────────────
    if (type == 'slider') {
      final max = (q['max'] ?? 100).toDouble();
      final min = (q['min'] ?? 0).toDouble();
      final currentValue = (value ?? min).toDouble();
      return Column(
        children: [
          Slider(
            value: currentValue.clamp(min, max),
            min: min,
            max: max,
            divisions: ((max - min) ~/ 5).toInt(),
            activeColor: Colors.black,
            inactiveColor: Colors.grey[300],
            onChanged: (v) => setState(() => _answers[_currentIndex] = v.toInt()),
          ),
          const SizedBox(height: 12),
          Text(
            '${currentValue.toInt()}/${max.toInt()}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }

    // ── Percentage Input ───────────────────────────────────────────
    if (type == 'percentage') {
      return Column(
        children: [
          SizedBox(
            width: 200,
            child: TextField(
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              key: ValueKey('percentage_input_$_currentIndex'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                suffixText: '%',
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.black),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 2.5),
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              onChanged: (v) {
                final num = int.tryParse(v);
                if (num != null && num >= 0 && num <= 100) {
                  setState(() {
                    _answers[_currentIndex] = num;
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Enter percentage (0-100)',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      );
    }

    // ── Text Input ─────────────────────────────────────────────────
    if (type == 'text_input') {
      return Column(
        children: [
          TextField(
            key: ValueKey('text_input_$_currentIndex'),
            decoration: InputDecoration(
              hintText: 'Enter your response',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black, width: 2),
              ),
            ),
            maxLines: 3,
            onChanged: (v) {
              setState(() {
                _answers[_currentIndex] = v;
              });
            },
          ),
        ],
      );
    }

    // ── Time Input (HH:MM) ─────────────────────────────────────────
    if (type == 'time_input') {
      return Column(
        children: [
          SizedBox(
            width: 200,
            child: TextField(
              keyboardType: TextInputType.datetime,
              key: ValueKey('time_input_$_currentIndex'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'HH:MM',
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 2.5),
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              onChanged: (v) {
                if (v.length == 4) {
                  final hour = int.tryParse(v.substring(0, 2));
                  final min = int.tryParse(v.substring(2, 4));
                  if (hour != null && min != null && hour >= 0 && hour < 24 && min >= 0 && min < 60) {
                    setState(() {
                      _answers[_currentIndex] = '$hour:${min.toString().padLeft(2, '0')}';
                    });
                  }
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Enter time in HH:MM format',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      );
    }

    // ── Default Numeric inputs ──────────────────────────────────────
    String hint = 'Enter value';
    String label = '';
    int? maxLen = 3;
    List<TextInputFormatter> formatters = [
      FilteringTextInputFormatter.digitsOnly,
    ];

    if (type == 'number_1_10') {
      hint = '1–10';
      label = 'Enter a number between 1 and 10';
      maxLen = 2;
    } else if (type == 'number_hours') {
      hint = '0–168';
      label = 'Hours per week (0–168)';
    } else if (type == 'number_hours_day') {
      hint = '0–24';
      label = 'Hours per day (0–24)';
    } else if (type == 'gpa') {
      hint = '0.0–4.0';
      label = 'GPA (0.0 to 4.0)';
      formatters = [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ];
      maxLen = 4;
    }

    return Column(
      children: [
        SizedBox(
          width: 500,
          child: TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            key: ValueKey('numeric_input_$_currentIndex'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.black),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black, width: 2.5),
              ),
            ),
            inputFormatters: [
              ...formatters,
              LengthLimitingTextInputFormatter(maxLen),
            ],
            controller: null,
            onChanged: (v) => _onNumberChanged(v, type),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }
}