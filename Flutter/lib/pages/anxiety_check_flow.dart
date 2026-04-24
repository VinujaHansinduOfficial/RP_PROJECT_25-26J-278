import 'package:flutter/material.dart';
import 'package:health_research/services/AnxietyApiService.dart';
import 'package:health_research/services/StressApiService.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:health_research/config/api_config.dart';

class AnxietyCheckFlow extends StatefulWidget {
  final String userId;

  const AnxietyCheckFlow({
    required this.userId,
    super.key,
  });

  @override
  State<AnxietyCheckFlow> createState() => _AnxietyCheckFlowState();
}

class _AnxietyCheckFlowState extends State<AnxietyCheckFlow> {
  final AnxietyApiService _apiService = AnxietyApiService();
  final StressApiService _stressApiService = StressApiService();

  bool _showingQuestionnaire = false;
  bool _isLoading = false;
  Map<String, dynamic>? _predictionResult;
  String? _errorMessage;

  // User features
  double _screenTime = 0.0;
  double _sleepHours = 5.0;
  double _age = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails(widget.userId);
  }

  Future<void> _fetchUserDetails(String patientId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/patients/$patientId');
      final response = await http.get(url).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _age = (data['age'] as num?)?.toDouble() ?? 0.0;
        });
        _fetchUserFeatures();
      }
    } catch (e) {
      print('Error fetching user details: $e');
      _fetchUserFeatures();
    }
  }

  Future<void> _fetchUserFeatures() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final features = await _stressApiService.getUserFeatures(widget.userId);

      setState(() {
        _screenTime = (features['Screen_Time'] as num?)?.toDouble() ?? 0.0;
        _sleepHours = (features['Sleep_Hours'] as num?)?.toDouble() ?? 5.0;
        if (_age == 0.0) {
          _age = (features['Age'] as num?)?.toDouble() ?? 0.0;
        }
        _showingQuestionnaire = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching user features: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _onQuestionnaireCompleted(
      Map<String, dynamic> answersData) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Build complete payload with user features + questionnaire answers
      final payload = {
        'Tech_Usage_Hours': answersData['Tech_Usage_Hours'] ?? 0,
        'Sensory_Sensitivity': answersData['Sensory_Sensitivity'] ?? 0,
        'Multitasking_Habit': answersData['Multitasking_Habit'] ?? 0,
        'Sleep_Hours': _sleepHours,
        'Screen_Time': _screenTime,
        'Social_Interaction': answersData['Social_Interaction'] ?? 0,
        'Irritability_Score': answersData['Irritability_Score'] ?? 0,
        'Noise_Exposure': answersData['Noise_Exposure'] ?? 0,
        'Exercise_Hours': answersData['Exercise_Hours'] ?? 0,
        'Work_Hours': answersData['Work_Hours'] ?? 0,
        'Age': _age,
      };

      print('Anxiety Questionnaire answers: $answersData');
      print('Sending anxiety prediction payload: $payload');

      final result = await _apiService.predictAnxiety(widget.userId, payload);

      if (mounted) {
        setState(() {
          _predictionResult = result;
          _showingQuestionnaire = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _retry() {
    setState(() {
      _showingQuestionnaire = false;
      _errorMessage = null;
      _predictionResult = null;
    });
    _fetchUserDetails(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Anxiety Check')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Anxiety Check')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _retry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_showingQuestionnaire) {
      return _AnxietyQuestionnaire(
        onCompleted: _onQuestionnaireCompleted,
      );
    }

    return _ResultScreen(
      result: _predictionResult,
      onClose: () => Navigator.of(context).pop(),
    );
  }
}

// Questionnaire Widget
class _AnxietyQuestionnaire extends StatefulWidget {
  final Function(Map<String, dynamic>) onCompleted;

  const _AnxietyQuestionnaire({
    required this.onCompleted,
  });

  @override
  State<_AnxietyQuestionnaire> createState() => _AnxietyQuestionnaireState();
}

class _AnxietyQuestionnaireState extends State<_AnxietyQuestionnaire> {
  int _currentIndex = 0;
  final Map<int, dynamic> _answers = {};

  final List<Map<String, dynamic>> _questions = [
    {
      'title': 'How many hours per day on technology/screens?',
      'image': 'assets/images/question_tech.jpg',
      'type': 'number_hours_day',
      'key': 'Tech_Usage_Hours',
    },
    {
      'title': 'How sensitive are you to sensory stimuli? (0-10)',
      'image': 'assets/images/question_support.png',
      'type': 'rating_scale',
      'max_rating': 10,
      'key': 'Sensory_Sensitivity',
    },
    {
      'title': 'Do you usually multitask?',
      'image': 'assets/images/question_work.png',
      'type': 'frequency_grid',
      'options': ['Never', 'Rarely', 'Sometimes', 'Often', 'Always'],
      'key': 'Multitasking_Habit',
    },
    {
      'title': 'On a scale of 0-10, how irritable have you felt recently?',
      'image': 'assets/images/question_irritability.png',
      'type': 'rating_scale',
      'max_rating': 10,
      'key': 'Irritability_Score',
    },
    {
      'title': 'How many hours per week do you work?',
      'image': 'assets/images/question_work.png',
      'type': 'number_hours_week',
      'key': 'Work_Hours',
    },
    {
      'title': 'How many hours per week do you exercise?',
      'image': 'assets/images/question_exercise.jpg',
      'type': 'number_hours_week',
      'key': 'Exercise_Hours',
    },
    {
      'title': 'On a scale of 1-10, how socially active are you?',
      'image': 'assets/images/question_social.jpg',
      'type': 'number_1_10',
      'key': 'Social_Interaction',
    },
    {
      'title': 'How noisy is your daily environment?',
      'image': 'assets/images/question_noise.png',
      'type': 'frequency_grid',
      'options': ['Very Quiet', 'Low Noise', 'Medium Noise', 'Very Noisy'],
      'key': 'Noise_Exposure',
    },
  ];

  bool get _isNextEnabled {
    final answer = _answers[_currentIndex];
    final q = _questions[_currentIndex];
    final type = q['type'];

    if (type == 'choice' || type == 'frequency_grid') {
      return answer != null;
    }
    if (type == 'rating_scale') {
      return answer is int && answer > 0;
    }
    if (type == 'number_1_10') {
      return answer is int && answer >= 1 && answer <= 10;
    }
    if (type == 'number_hours_day') {
      return answer is int && answer >= 0 && answer <= 24;
    }
    if (type == 'number_hours_week') {
      return answer is int && answer >= 0 && answer <= 168;
    }
    return false;
  }

  Map<String, dynamic> get _answersData {
    return {
      'Tech_Usage_Hours': _answers[0] ?? 0,
      'Sensory_Sensitivity': _answers[1] ?? 0,
      'Multitasking_Habit': _mapGridAnswer(_answers[2], 5) ?? 0,
      'Irritability_Score': _answers[3] ?? 0,
      'Work_Hours': _answers[4] ?? 0,
      'Exercise_Hours': _answers[5] ?? 0,
      'Social_Interaction': _answers[6] ?? 0,
      'Noise_Exposure': _mapGridAnswer(_answers[7], 4) ?? 0,
    };
  }

  int? _mapGridAnswer(dynamic answer, int maxValue) {
    if (answer == null) return null;
    if (maxValue == 5) {
      const options = ['Never', 'Rarely', 'Sometimes', 'Often', 'Always'];
      final index = options.indexOf(answer.toString());
      return index >= 0 ? index : null;
    }
    if (maxValue == 4) {
      const options = ['Very Quiet', 'Low Noise', 'Medium Noise', 'Very Noisy'];
      final index = options.indexOf(answer.toString());
      return index >= 0 ? index : null;
    }
    return null;
  }

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

    if (type == 'rating_scale') {
      final n = int.tryParse(value);
      if (n != null && n > 0 && n <= 10) {
        _answers[_currentIndex] = n;
        setState(() {});
      }
    } else if (type == 'number_1_10') {
      final n = int.tryParse(value);
      if (n != null && n >= 1 && n <= 10) {
        _answers[_currentIndex] = n;
        setState(() {});
      }
    } else if (type == 'number_hours_day') {
      final n = int.tryParse(value);
      if (n != null && n >= 0 && n <= 24) {
        _answers[_currentIndex] = n;
        setState(() {});
      }
    } else if (type == 'number_hours_week') {
      final n = int.tryParse(value);
      if (n != null && n >= 0 && n <= 168) {
        _answers[_currentIndex] = n;
        setState(() {});
      }
    }
  }

  void _next() {
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      print('Anxiety answers: $_answersData');
      widget.onCompleted(_answersData);
    }
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
          'Anxiety Questionnaire',
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
                    '${(progress * 100).toStringAsFixed(0)}% Complete',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image,
                              size: 100,
                              color: Colors.grey),
                        ),
                      ),
                    Text(
                      q['title'],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
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
                    backgroundColor:
                        _isNextEnabled ? Colors.black : Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: _isNextEnabled ? 3 : 0,
                  ),
                  child: Text(
                    _currentIndex < _questions.length - 1
                        ? 'Next'
                        : 'Get Prediction',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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

    if (type == 'frequency_grid') {
      final options = (q['options'] as List? ?? []);
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
        children: options.map((option) {
          final selected = value == option;

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
                option,
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

    if (type == 'rating_scale' || type == 'number_1_10' ||
        type == 'number_hours_day' || type == 'number_hours_week') {
      return Column(
        children: [
          SizedBox(
            width: 220,
            child: TextField(
              key: ValueKey('numeric_input_$_currentIndex'),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.blue,
                    width: 2.5,
                  ),
                ),
              ),
              onChanged: (v) => _onNumberChanged(v, type),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            type == 'rating_scale'
                ? 'Scale: 1-10'
                : type == 'number_1_10'
                    ? 'Scale: 1-10'
                    : type == 'number_hours_day'
                        ? 'Hours: 0-24'
                        : 'Hours: 0-168',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

// Result Screen Widget
class _ResultScreen extends StatelessWidget {
  final Map<String, dynamic>? result;
  final VoidCallback onClose;

  const _ResultScreen({
    this.result,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final hasResult = result != null;
    // Extract from nested data structure
    final prediction = result?['data']?['prediction'] as int? ?? 0;
    final probability = result?['data']?['probability'] as double? ?? 0.0;
    final hasAnxiety = prediction == 1;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Anxiety Assessment Result'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                if (hasResult) ...[
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          hasAnxiety ? Colors.red[100] : Colors.green[100],
                    ),
                    child: Center(
                      child: Icon(
                        hasAnxiety ? Icons.warning : Icons.check_circle,
                        size: 60,
                        color: hasAnxiety ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    hasAnxiety ? 'High Anxiety Detected' : 'No Anxiety Detected',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: hasAnxiety ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Confidence: ${(probability * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assessment Result',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          'Status',
                          hasAnxiety ? 'Anxiety Detected' : 'No Anxiety',
                          hasAnxiety ? Colors.red : Colors.green,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow('Confidence',
                            '${(probability * 100).toStringAsFixed(1)}%'),
                      ],
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Processing Assessment...',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: onClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, [Color? valueColor]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
