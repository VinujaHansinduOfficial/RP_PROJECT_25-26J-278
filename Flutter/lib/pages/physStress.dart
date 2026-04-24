import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:health_research/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhysStress extends StatefulWidget {
  const PhysStress({super.key});

  @override
  State<PhysStress> createState() => _PhysStressState();
}

class _PhysStressState extends State<PhysStress> {
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

    if (type == 'choice' || type == 'grid_2x2') {
      return answer != null;
    }
    if (type == 'number_minutes_week') {
      return answer is int && answer >= 0 && answer <= 1440; // max 24*60 minutes
    }
    if (type == 'number_hours_week') {
      return answer is int && answer >= 0 && answer <= 168;
    }
    if (type == 'number_bmi') {
      return answer is double && answer > 0 && answer < 100;
    }
    return false;
  }

  final List<Map<String, dynamic>> _questions = [
    // Q1: BMI
    {
      'title': 'What is your BMI?',
      'image': 'assets/images/question_health.png',
      'type': 'number_bmi',
      'key': 'bmi',
    },
    // Q2: Physical Activity
    {
      'title': 'How many minutes per week do you usually exercise?',
      'image': 'assets/images/question_exercise2.jpg',
      'type': 'number_minutes_week',
      'key': 'physact',
      'range': '0-20',
    },
    // Q3: Overall Health
    {
      'title': 'How would you rate your overall health?',
      'image': 'assets/images/question_health.png',
      'type': 'grid_2x2',
      'key': 'health',
      'range': '0-5',
      'options': [
        {'text': 'Poor', 'value': 0},
        {'text': 'Fair', 'value': 1},
        {'text': 'Good', 'value': 2},
        {'text': 'Very Good', 'value': 3},
        {'text': 'Excellent', 'value': 4},
      ],
    },
    // Q4: Emotional Distress
    {
      'title': 'In the past two weeks, how often have you felt emotionally distressed?',
      'image': 'assets/images/question_sadness.jpg',
      'type': 'grid_2x2',
      'key': 'psyt',
      'range': '0-4',
      'options': [
        {'text': 'Never', 'value': 0},
        {'text': 'Rarely', 'value': 1},
        {'text': 'Sometimes', 'value': 2},
        {'text': 'Often', 'value': 3},
        {'text': 'Always', 'value': 4},
      ],
    },
    // Q5: Emotional Coping
    {
      'title': 'When stressed, how often do you try to manage your emotions (e.g., venting, distraction)?',
      'image': 'assets/images/question_emotions.png',
      'type': 'grid_2x2',
      'key': 'cop_e',
      'range': '0-20',
      'options': [
        {'text': 'Never', 'value': 0},
        {'text': 'Rarely', 'value': 5},
        {'text': 'Sometimes', 'value': 10},
        {'text': 'Often', 'value': 15},
        {'text': 'Always', 'value': 20},
      ],
    },
    // Q6: Problem-Focused Coping
    {
      'title': 'When stressed, how often do you try to solve the problem directly?',
      'image': 'assets/images/question_problem_solving.jpg',
      'type': 'grid_2x2',
      'key': 'cop_p',
      'range': '0-20',
      'options': [
        {'text': 'Never', 'value': 0},
        {'text': 'Rarely', 'value': 5},
        {'text': 'Sometimes', 'value': 10},
        {'text': 'Often', 'value': 15},
        {'text': 'Always', 'value': 20},
      ],
    },
    // Q7: Healthy Coping Strategies
    {
      'title': 'How often do you use healthy strategies to cope (exercise, meditation, sleep)?',
      'image': 'assets/images/question_coping.png',
      'type': 'grid_2x2',
      'key': 'cop_h',
      'range': '0-20',
      'options': [
        {'text': 'Never', 'value': 0},
        {'text': 'Rarely', 'value': 5},
        {'text': 'Sometimes', 'value': 10},
        {'text': 'Often', 'value': 15},
        {'text': 'Always', 'value': 20},
      ],
    },
    // Q8: Part-Time Work
    {
      'title': 'Do you work part-time?',
      'image': 'assets/images/question_parttime.jpeg',
      'type': 'choice',
      'key': 'part',
      'range': '0-1',
      'options': [
        {'text': 'No', 'value': 0},
        {'text': 'Yes', 'value': 1},
      ],
    },
    // Q9: Social Support
    {
      'title': 'How often do you have someone to talk to when you need support?',
      'image': 'assets/images/question_support.png',
      'type': 'grid_2x2',
      'key': 'socsup',
      'range': '0-10',
      'options': [
        {'text': 'Never', 'value': 0},
        {'text': 'Rarely', 'value': 2},
        {'text': 'Sometimes', 'value': 5},
        {'text': 'Often', 'value': 7},
        {'text': 'Always', 'value': 10},
      ],
    },
    // Q10: Parent Education Level
    {
      'title': 'What is the highest education level completed by your parent or guardian?',
      'image': 'assets/images/question_education.jpg',
      'type': 'grid_2x2',
      'key': 'educ_par',
      'range': '0-5',
      'options': [
        {'text': 'Less than high school', 'value': 0},
        {'text': 'High school', 'value': 1},
        {'text': 'Diploma', 'value': 2},
        {'text': "Bachelor's", 'value': 3},
        {'text': 'Postgraduate', 'value': 4},
        {'text': "Don't know", 'value': 5},
      ],
    },
    // Q11: Job Hours
    {
      'title': 'How many hours per week do you work at a job?',
      'image': 'assets/images/question_work.png',
      'type': 'number_hours_week',
      'key': 'jobhours',
      'range': '0-50',
    },
  ];

  void _onChoiceSelected(dynamic value) {
    setState(() {
      // Handle both string and map options
      if (value is Map) {
        _answers[_currentIndex] = value['value'];
      } else {
        _answers[_currentIndex] = value;
      }
    });
  }

  void _onNumberChanged(String value, String type) {
    if (value.isEmpty) {
      _answers.remove(_currentIndex);
      setState(() {});
      return;
    }

    if (type == 'number_bmi') {
      final n = double.tryParse(value);
      if (n != null && n > 0 && n < 100) {
        _answers[_currentIndex] = n;
      }
    } else {
      final n = int.tryParse(value);
      if (n != null) {
        if ((type == 'number_minutes_week' && n >= 0 && n <= 1440) ||
            (type == 'number_hours_week' && n >= 0 && n <= 168)) {
          _answers[_currentIndex] = n;
        }
      }
    }
    setState(() {});
  }

  void _next() {
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      // Questionnaire completed - collect answers and call API
      _submitQuestionnaire();
    }
  }

  /// Submit questionnaire answers to prediction API
  Future<void> _submitQuestionnaire() async {
    try {
      // Show loading dialog
      _showLoadingDialog('Submitting responses...');

      // Step 1: Fetch user details
      final userDetails = await _fetchUserDetails(patientId);

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      if (userDetails == null) {
        _showErrorDialog('Failed to load user details. Please try again.');
        return;
      }

      // Step 2: Prepare prediction data
      final predictionData = _preparePredictionData(userDetails, patientId);

      // Show loading dialog again
      _showLoadingDialog('Analyzing results...');

      // Step 3: Submit to prediction API
      // Note: _submitPredictionData will close the loading dialog and show the prediction dialog
      final success = await _submitPredictionData(predictionData);

      // If prediction failed, close any remaining dialogs and show error
      if (!success) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context); // Close loading dialog if still open
        }
        if (mounted) {
          _showErrorDialog('Failed to submit assessment. Please try again.');
        }
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

  /// Prepare prediction data from answers and user details
  Map<String, dynamic> _preparePredictionData(
    Map<String, dynamic> userDetails,
    String userId,
  ) {
    final random = Random();

    // Parse date of birth to calculate age
    int age = 0;
    if (userDetails['date_of_birth'] != null) {
      try {
        final dob = DateTime.parse(userDetails['date_of_birth']);
        final today = DateTime.now();
        age = today.year - dob.year;
        if (today.month < dob.month ||
            (today.month == dob.month && today.day < dob.day)) {
          age--;
        }
      } catch (e) {
        age = 30; // Default age if parsing fails
      }
    }

    // Determine gender (1 for Female, 0 for Male)
    final gender = userDetails['gender']?.toString().toLowerCase() ?? 'male';
    final isFemale = gender.contains('female') ? 1 : 0;

    return {
      'user_id': userId,
      'features': {
        'nwave': random.nextInt(3) + 1, // 1, 2, or 3
        'longipart': [1, 2, 3, 12, 123, 23][random.nextInt(6)],
        'age': age,
        'sex': gender == 'female' ? 'Female' : 'Male',
        'year': random.nextInt(11), // 0-10
        'bmi': _answers[0] ?? 0, // Q1: BMI
        'physact': _answers[1] ?? 0, // Q2: Physical Activity (minutes)
        'health': _answers[2] ?? 0, // Q3: Overall Health (0-4)
        'psyt': _answers[3] ?? 0, // Q4: Emotional Distress (0-4)
        'cop_e': _answers[4] ?? 0, // Q5: Emotional Coping (0-20)
        'cop_p': _answers[5] ?? 0, // Q6: Problem-Focused Coping (0-20)
        'cop_h': _answers[6] ?? 0, // Q7: Healthy Coping (0-20)
        'fmale': isFemale, // Female (1) or Male (0)
        'part': _answers[7] ?? 0, // Q8: Part-Time Work (0-1)
        'socsup': _answers[8] ?? 0, // Q9: Social Support (0-10)
        'educ_par': _answers[9] ?? 0, // Q10: Parent Education (0-5)
        'jobhours': _answers[10] ?? 0, // Q11: Job Hours (0-50)
        'cesd': random.nextInt(51), // 0-50 (random for now)
        'bdi_su': random.nextInt(4), // 0-3 (random for now)
        'stai': random.nextInt(101), // 0-100 (random for now)
        'stress': random.nextInt(11), // 0-10 (random for now)
      },
    };
  }

  /// Submit prediction data to API
  Future<bool> _submitPredictionData(Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl2}/predict/burnout');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(data),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timeout'),
          );

      print('Burnout Prediction API Response: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = jsonDecode(response.body);
          final prediction = responseData['data']['prediction'];
          final probability = responseData['data']['probability'];

          // Check if user is stressed (prediction == 1)
          final isStressed = prediction == 1;
          print("User is stressed: $isStressed with probability: $probability");
          final stressMessage = isStressed
              ? '⚠️ You are stressed'
              : '✅ You are not stressed';

          if (mounted) {
            // Close the loading dialog first
            Navigator.pop(context);

            // Then show the prediction dialog
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                _showPredictionDialog(stressMessage, isStressed, probability);
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

      // Close loading dialog on failure
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      return false;
    } catch (e) {
      print('Error submitting prediction data: $e');
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      return false;
    }
  }

  /// Show prediction result dialog
  void _showPredictionDialog(
    String message,
    bool isStressed,
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
                isStressed ? Icons.warning_amber : Icons.check_circle,
                color: isStressed ? Colors.orange : Colors.green,
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isStressed ? Colors.orange : Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isStressed ? Colors.orange.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isStressed ? Colors.orange.shade200 : Colors.green.shade200,
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
                        color: isStressed ? Colors.orange[700] : Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: probability,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isStressed ? Colors.orange : Colors.green,
                      ),
                      minHeight: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (isStressed)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recommendations:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Take regular breaks\n'
                        '• Practice mindfulness or meditation\n'
                        '• Maintain a healthy sleep schedule\n'
                        '• Consider talking to a healthcare provider',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                )
              else
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
                        'Keep it up! 🎉',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You\'re managing stress well. Continue with your healthy habits and routines.',
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

  /// Show success dialog
  void _showSuccessDialog(String message) {
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
              Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text(
                'Success',
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
            // Progress Bar
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
                    // Illustration Image
                    if (q['image'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Image.asset(
                          q['image'],
                          height: 200,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                        ),
                      ),

                    // Question Title
                    Text(
                      q['title'],
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.3),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    // Answer Widget
                    _buildAnswerWidget(q),
                  ],
                ),
              ),
            ),

            // Next / Finish Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isNextEnabled ? _next : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isNextEnabled ? Colors.black : Colors.grey[400],
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

    // ── 2x2 Grid (most questions) ───────────────────────────────────
    if (type == 'grid_2x2' || type == 'frequency_grid') {
      final options = (q['options'] as List? ?? []);
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
        children: options.map((option) {
          // Handle both string options and map options with value property
          final optText = option is Map ? option['text'] : option;
          final optValue = option is Map ? option['value'] : option;
          final selected = value == optValue;

          return GestureDetector(
            onTap: () => _onChoiceSelected(option),
            child: Container(
              decoration: BoxDecoration(
                color: selected ? const Color(0xA3BDBABA) : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? Colors.black : Colors.grey[300]!,
                  width: selected ? 2.5 : 1.5,
                ),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              child: Text(
                optText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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
      final options = (q['options'] as List? ?? []);
      return Column(
        children: options.map((option) {
          // Handle both string options and map options with value property
          final optText = option is Map ? option['text'] : option;
          final optValue = option is Map ? option['value'] : option;
          final selected = value == optValue;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _onChoiceSelected(option),
                style: ElevatedButton.styleFrom(
                  backgroundColor: selected ? const Color(0xa3bdbaba) : Colors.grey[100],
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: selected ? Colors.black : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                ),
                child: Text(optText, style: const TextStyle(fontSize: 16)),
              ),
            ),
          );
        }).toList(),
      );
    }

    // ── BMI Input (decimal number) ──────────────────────────────────
    if (type == 'number_bmi') {
      return Column(
        children: [
          SizedBox(
            width: 220,
            child: TextField(
              key: ValueKey('bmi_input_$_currentIndex'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '0.0',
                suffixText: 'kg/m²',
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
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: (v) => _onNumberChanged(v, type),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Body Mass Index',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      );
    }

    // ── Numeric Input (minutes or hours) ────────────────────────────
    String hint = 'Enter value';
    String label = '';
    int? maxLen = 4;
    List<TextInputFormatter> formatters = [
      FilteringTextInputFormatter.digitsOnly,
    ];

    if (type == 'number_minutes_week') {
      hint = '0–1440';
      label = 'Minutes per week';
    } else if (type == 'number_hours_week') {
      hint = '0–168';
      label = 'Hours per week';
    }

    return Column(
      children: [
        SizedBox(
          width: 220,
          child: TextField(
            key: ValueKey('numeric_input_$_currentIndex'),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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