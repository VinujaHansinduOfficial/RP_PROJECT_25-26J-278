import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health_research/services/AnxietyApiService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnxietyQuestionnaireScreen extends StatefulWidget {
  final String? userId;
  const AnxietyQuestionnaireScreen({super.key, this.userId});

  @override
  State<AnxietyQuestionnaireScreen> createState() =>
      _AnxietyQuestionnaireScreenState();
}

class _AnxietyQuestionnaireScreenState
    extends State<AnxietyQuestionnaireScreen> {
  int _currentIndex = 0;
  final Map<int, dynamic> _answers = {};
  bool _isSubmitting = false;
  final AnxietyApiService _apiService = AnxietyApiService();
  int _age = 0; // Store age from session

  @override
  void initState() {
    super.initState();
    _loadAgeFromSession();
  }

  Future<void> _loadAgeFromSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _age = prefs.getInt('age') ?? 0;
    });
    print('✅ Age loaded from session: $_age');
  }

  bool get _isNextEnabled {
    final answer = _answers[_currentIndex];
    final q = _questions[_currentIndex];
    final type = q['type'];

    if (type == 'choice' || type == 'yes_no') {
      return answer != null;
    }
    if (type == 'rating_scale') {
      return answer is int && answer > 0;
    }
    if (type == 'number_1_10') {
      return answer is int && answer >= 0 && answer <= 10;
    }
    if (type == 'number_hours_day') {
      return answer is int && answer >= 0 && answer <= 24;
    }
    return false;
  }

  /// Map anxiety questionnaire answers to API payload
  Map<String, dynamic> get _answersData {
    return {
      'Tech_Usage_Hours': _answers[0]?.toDouble() ?? 0.0,
      'Sensory_Sensitivity': _answers[1] ?? 0,
      'num_missing': 0.0,
      'Multitasking_Habit': _answers[2] == 'Yes' ? 1.0 : 0.0,
      'Sleep_Hours_div_Screen_Time':
          _calculateRatio(_answers[3], _answers[4]) ?? 0.0,
      'Social_Interaction': _answers[5] ?? 0,
      'Irritability_Score': _answers[6] ?? 0,
      'Noise_Exposure_div_Exercise_Hours':
          _calculateRatio(_answers[7], _answers[8]) ?? 0.0,
      'Social_Interaction_div_Work_Hours':
          _calculateRatio(_answers[5], _answers[9]) ?? 0.0,
      'Sleep_Hours': _answers[3]?.toDouble() ?? 0.0,
      'Age': _age.toDouble(), // Use age from session
    };
  }

  double? _calculateRatio(dynamic a, dynamic b) {
    if (a == null || b == null) return null;
    if (b is int && b == 0) return 0.0;
    if (a is int && b is int) return a / b;
    if (a is double && b is int && b != 0) return a / b;
    return 0.0;
  }

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
      'type': 'yes_no',
      'key': 'Multitasking_Habit',
    },
    {
      'title': 'How many hours of sleep per night?',
      'image': 'assets/images/question_sleep.jpg',
      'type': 'number_hours_day',
      'key': 'Sleep_Hours',
    },
    {
      'title': 'Your screen time daily (hours)?',
      'image': 'assets/images/question_tech.jpg',
      'type': 'number_hours_day',
      'key': 'Screen_Time',
    },
    {
      'title': 'How often do you interact socially? (0-10)',
      'image': 'assets/images/question_social.jpg',
      'type': 'rating_scale',
      'max_rating': 10,
      'key': 'Social_Interaction',
    },
    {
      'title': 'How irritable do you feel? (0-10)',
      'image': 'assets/images/question_emotions.png',
      'type': 'rating_scale',
      'max_rating': 10,
      'key': 'Irritability_Score',
    },
    {
      'title': 'How often exposed to noise?',
      'image': 'assets/images/question_noise.png',
      'type': 'choice',
      'options': ['Never', 'Rarely', 'Sometimes', 'Often', 'Very Often'],
      'key': 'Noise_Exposure',
    },
    {
      'title': 'How many hours per week do you exercise?',
      'image': 'assets/images/physical_activities.png',
      'type': 'number_1_10',
      'key': 'Exercise_Hours',
    },
    {
      'title': 'How many work/study hours per day?',
      'image': 'assets/images/question_work.png',
      'type': 'number_hours_day',
      'key': 'Work_Hours',
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

    if (type == 'number_1_10') {
      final n = int.tryParse(value);
      if (n != null && n >= 0 && n <= 10) {
        _answers[_currentIndex] = n;
      }
    } else if (type == 'number_hours_day') {
      final n = int.tryParse(value);
      if (n != null && n >= 0 && n <= 24) {
        _answers[_currentIndex] = n;
      }
    } else if (type == 'number_age') {
      final n = int.tryParse(value);
      if (n != null && n >= 10 && n <= 100) {
        _answers[_currentIndex] = n;
      }
    }

    setState(() {});
  }

  void _next() {
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _showSubmitDialog();
    }
  }

  void _showSubmitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Anxiety Assessment Complete'),
          content: const Text('Would you like to submit your responses?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Review Later'),
            ),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitQuestionnaire,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[700],
              ),
              child: _isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitQuestionnaire() async {
    setState(() => _isSubmitting = true);

    try {
      final allAnswers = _answersData;

      print('=== ANXIETY QUESTIONNAIRE COMPLETED ===');
      print('All Answers:');
      allAnswers.forEach((key, value) {
        print('  $key: $value');
      });
      print('========================================');

      String userId = widget.userId ?? 'unknown_user';
      final response = await _apiService.predictAnxiety(userId, allAnswers);

      if (mounted) {
        setState(() => _isSubmitting = false);

        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Anxiety assessment submitted successfully!'),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 3),
          ),
        );

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });

        print('=== API RESPONSE ===');
        print(response);
        print('====================');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 3),
          ),
        );

        print('=== ERROR SUBMITTING ANXIETY QUESTIONNAIRE ===');
        print('Error: $e');
        print('=============================================');
      }
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
          'Anxiety Assessment',
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
                      color: Colors.purple[700],
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
                          height: 1.3),
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
                  onPressed: (_isNextEnabled && !_isSubmitting) ? _next : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_isNextEnabled && !_isSubmitting)
                        ? Colors.purple[700]
                        : Colors.grey[400],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: (_isNextEnabled && !_isSubmitting) ? 3 : 0,
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _currentIndex < _questions.length - 1
                              ? 'Next'
                              : 'Submit',
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
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
                  backgroundColor:
                      selected ? Colors.purple[100] : Colors.grey[100],
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color:
                          selected ? Colors.purple[700]! : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(opt,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          );
        }).toList(),
      );
    }

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
                  onTap: () =>
                      setState(() => _answers[_currentIndex] = index + 1),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.purple[700] : Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Low',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              Text('High',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ],
      );
    }

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
                  backgroundColor:
                      selected ? Colors.purple[700] : Colors.grey[200],
                  foregroundColor: selected ? Colors.white : Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(opt,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          );
        }).toList(),
      );
    }

    String hint = 'Enter value';
    String label = '';
    if (type == 'number_1_10') {
      hint = '0–10';
      label = 'Enter a number between 0 and 10';
    } else if (type == 'number_hours_day') {
      hint = '0–24';
      label = 'Hours (0–24)';
    } else if (type == 'number_age') {
      hint = '10–100';
      label = 'Age (10–100)';
    }

    return Column(
      children: [
        SizedBox(
          width: 200,
          child: TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            key: ValueKey('numeric_input_$_currentIndex'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.purple, width: 2.5),
              ),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            onChanged: (v) => _onNumberChanged(v, type),
          ),
        ),
        const SizedBox(height: 16),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
      ],
    );
  }
}
