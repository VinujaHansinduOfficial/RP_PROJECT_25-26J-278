import 'package:flutter/material.dart';
import 'package:health_research/services/StressApiService.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:health_research/config/api_config.dart';

class StressCheckFlow extends StatefulWidget {
  final String userId;

  const StressCheckFlow({
    required this.userId,
    super.key,
  });

  @override
  State<StressCheckFlow> createState() => _StressCheckFlowState();
}

class _StressCheckFlowState extends State<StressCheckFlow> {
  final StressApiService _apiService = StressApiService();

  bool _showingQuestionnaire = false;
  bool _isLoading = false;
  Map<String, dynamic>? _predictionResult;
  String? _errorMessage;

  // Fetched from APIs
  double _age = 0.0;
  double _heartRate = 0.0;
  double _workHours = 0.0;
  double _screenTime = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch user details (Age)
      final userUrl = Uri.parse('${ApiConfig.baseUrl}/api/patients/${widget.userId}');
      final userResponse = await http.get(userUrl, headers: ApiConfig.defaultHeaders);

      if (userResponse.statusCode == 200) {
        final userData = jsonDecode(userResponse.body);
        _age = (userData['age'] as num?)?.toDouble() ?? 0.0;
        print('Fetched age: $_age');
      }

      // Fetch user features
      final featuresResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl1}/user_features/${widget.userId}'),
        headers: ApiConfig.defaultHeaders,
      );

      if (featuresResponse.statusCode == 200) {
        final featuresData = jsonDecode(featuresResponse.body);
        final features = featuresData['features'] ?? {};

        _heartRate = (features['Heart_Rate'] as num?)?.toDouble() ?? 0.0;
        _workHours = (features['Work_Hours'] as num?)?.toDouble() ?? 0.0;
        _screenTime = (features['Screen_Time'] as num?)?.toDouble() ?? 0.0;

        print('Fetched features - Heart_Rate: $_heartRate, Work_Hours: $_workHours, Screen_Time: $_screenTime');
      }

      setState(() {
        _showingQuestionnaire = true;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        _errorMessage = 'Error fetching user data: $e';
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
      // Build complete payload with fetched data + questionnaire answers
      final payload = {
        'Age': _age,
        'Heart_Rate': _heartRate,
        'Work_Hours': _workHours,
        'Screen_Time': _screenTime,
        'Social_Interaction': answersData['Social_Interaction'] ?? 0,
        'Noise_Exposure': answersData['Noise_Exposure'] ?? 0,
      };

      print('Stress Questionnaire answers: $answersData');
      print('Sending stress prediction payload: $payload');

      final result = await _apiService.predictStress(widget.userId, payload);

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
    _fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Stress Check')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Stress Check')),
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
      return _StressQuestionnaire(
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
class _StressQuestionnaire extends StatefulWidget {
  final Function(Map<String, dynamic>) onCompleted;

  const _StressQuestionnaire({
    required this.onCompleted,
  });

  @override
  State<_StressQuestionnaire> createState() => _StressQuestionnaireState();
}

class _StressQuestionnaireState extends State<_StressQuestionnaire> {
  int _currentIndex = 0;
  final Map<int, dynamic> _answers = {};

  final List<Map<String, dynamic>> _questions = [
    {
      'title': 'How noisy is your daily environment?',
      'image': 'assets/images/question_noise.png',
      'type': 'frequency_grid',
      'options': ['Very Quiet', 'Low Noise', 'Medium Noise', 'Very Noisy'],
      'key': 'Noise_Exposure',
    },
    {
      'title': 'On a scale of 1-10, how socially active are you?',
      'image': 'assets/images/question_social.jpg',
      'type': 'number_1_10',
      'key': 'Social_Interaction',
    },
  ];

  bool get _isNextEnabled {
    final answer = _answers[_currentIndex];
    final q = _questions[_currentIndex];
    final type = q['type'];

    if (type == 'frequency_grid') {
      return answer != null;
    }
    if (type == 'number_1_10') {
      return answer is int && answer >= 1 && answer <= 10;
    }
    return false;
  }

  Map<String, dynamic> get _answersData {
    return {
      'Noise_Exposure': _mapGridAnswer(_answers[0]) ?? 0,
      'Social_Interaction': _answers[1] ?? 0,
    };
  }

  int? _mapGridAnswer(dynamic answer) {
    if (answer == null) return null;
    const options = ['Very Quiet', 'Low Noise', 'Medium Noise', 'Very Noisy'];
    final index = options.indexOf(answer.toString());
    return index >= 0 ? index : null;
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

    if (type == 'number_1_10') {
      final n = int.tryParse(value);
      if (n != null && n >= 1 && n <= 10) {
        _answers[_currentIndex] = n;
        setState(() {});
      }
    }
  }

  void _next() {
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      print('Stress answers: $_answersData');
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
          'Stress Questionnaire',
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

    if (type == 'number_1_10') {
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
            'Scale: 1-10',
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
    final isStressed = prediction == 1;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Stress Assessment Result'),
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
                      color: isStressed ? Colors.red[100] : Colors.green[100],
                    ),
                    child: Center(
                      child: Icon(
                        isStressed ? Icons.warning : Icons.check_circle,
                        size: 60,
                        color: isStressed ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isStressed ? 'You Are Stressed' : 'You Are Not Stressed',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isStressed ? Colors.red : Colors.green,
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
                          isStressed ? 'Stressed' : 'Not Stressed',
                          isStressed ? Colors.red : Colors.green,
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
