import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_research/config/api_config.dart';

class DailyJournal extends StatefulWidget {
  const DailyJournal({super.key});

  @override
  State<DailyJournal> createState() => _DailyJournalState();
}

class _DailyJournalState extends State<DailyJournal> {
  TextEditingController controller = TextEditingController();
  bool _isLoading = false;
  String? _userId;
  List<dynamic> _journalHistory = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('patientId') ?? '';
    });
    // Load history after user ID is set
    _fetchJournalHistory();
  }

  Future<void> _fetchJournalHistory() async {
    if (_userId == null || _userId!.isEmpty) return;

    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl2}/results/text/$_userId'),
        headers: ApiConfig.defaultHeaders,
      );

      print("Journal History Response status: ${response.statusCode}");
      print("Journal History Response body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        setState(() {
          _journalHistory = jsonResponse['results'] ?? [];
        });
      } else {
        print("Error fetching history: ${response.statusCode}");
      }
    } catch (e) {
      print('Error fetching journal history: $e');
    } finally {
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> saveJournal() async {
    if (controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please write something in your journal"),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl2}/predict/text'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'user_id': _userId ?? '',
          'text': controller.text,
        }),
      );

      print("Text Prediction Response status: ${response.statusCode}");
      print("Text Prediction Response body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final data = jsonResponse['data'];
        final predictionLabel = data['prediction_label'] as int? ?? 0;
        final probability = (data['probabilities'] as List?)?.cast<double>() ?? [0.0, 0.0];

        final isStressed = predictionLabel == 1;
        final confidence = isStressed ? probability[1] : probability[0];

        // Clear the text field
        controller.clear();

        // Refresh history
        await _fetchJournalHistory();

        // Show result
        _showResultDialog(isStressed, confidence);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${response.statusCode}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error saving journal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showResultDialog(bool isStressed, double confidence) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Journal Analysis Result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isStressed ? Colors.red[100] : Colors.green[100],
              ),
              child: Center(
                child: Icon(
                  isStressed ? Icons.warning : Icons.check_circle,
                  size: 50,
                  color: isStressed ? Colors.red : Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isStressed ? 'You Appear Stressed' : 'You Appear Calm',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isStressed ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Daily Journal"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: const AssetImage("assets/images/academic-quiz.png"),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Write your journal here",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: controller,
                      maxLines: 6,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: "Write here...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : saveJournal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text("Save"),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Journal History Section
                    const Text(
                      "Journal History",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _isLoadingHistory
                        ? const Center(child: CircularProgressIndicator())
                        : _journalHistory.isEmpty
                            ? Center(
                                child: Text(
                                  'No journal entries yet',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              )
                            : ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: _journalHistory.length,
                                itemBuilder: (context, index) {
                                  final entry = _journalHistory[index];
                                  final predictionLabel =
                                      entry['prediction_label'] as int? ?? 0;
                                  final isStressed = predictionLabel == 1;
                                  final inputText = entry['input_text'] ?? '';
                                  final createdAt = entry['created_at'] ?? '';
                                  final probabilities =
                                      (entry['probabilities'] as List?)?.cast<double>() ?? [0.0, 0.0];
                                  final confidence =
                                      isStressed ? probabilities[1] : probabilities[0];

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 12,
                                                height: 12,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: isStressed
                                                      ? Colors.red
                                                      : Colors.green,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                isStressed
                                                    ? 'Burnout'
                                                    : 'Calm',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: isStressed
                                                      ? Colors.red
                                                      : Colors.green,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                '${(confidence * 100).toStringAsFixed(1)}%',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            inputText,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            _formatDateTime(createdAt),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final date = dateTime.toString().split(' ')[0];
      final time = '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      return '$date at $time';
    } catch (e) {
      return dateTimeString;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
