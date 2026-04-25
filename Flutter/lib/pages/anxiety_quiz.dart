import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_research/services/AnxietyApiService.dart';
import 'package:health_research/models/AnxietyResult.dart';

import 'anxiety_check_flow.dart';

class AnxietyQuiz extends StatefulWidget {
  const AnxietyQuiz({super.key});

  @override
  State<AnxietyQuiz> createState() => _AnxietyQuizState();
}

class _AnxietyQuizState extends State<AnxietyQuiz> {
  final AnxietyApiService _apiService = AnxietyApiService();
  List<AnxietyRecord> history = [];
  String patientId = "";
  bool isLoading = false;
  bool isLoadingAnxiety = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchAnxiety();
  }

  Future<void> _loadUserIdAndFetchAnxiety() async {
    final prefs = await SharedPreferences.getInstance();
    patientId = prefs.getString('patientId') ?? '';

    if (patientId.isNotEmpty) {
      await _fetchAnxietyHistory();
    } else {
      setState(() {
        errorMessage = 'User ID not found. Please login again.';
      });
    }
  }

  Future<void> _fetchAnxietyHistory() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _apiService.getAnxietyResults(patientId);
      if (result != null) {
        setState(() {
          history = result.results;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading anxiety history: $e';
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> checkAnxiety() async {
    setState(() {
      isLoadingAnxiety = true;
    });

    try {
      await _fetchAnxietyHistory();
    } finally {
      setState(() {
        isLoadingAnxiety = false;
      });
    }
  }

  Color getColor(String status) {
    if (status == "High Anxiety") return Colors.orange;
    return Colors.green;
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat("dd MMMM yyyy").format(dateTime);
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat("HH:mm:ss").format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Daily Anxiety Quest"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchAnxietyHistory,
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      /// IMAGE
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                            )
                          ],
                        ),
                        child: const CircleAvatar(
                          radius: 60,
                          backgroundImage:
                              AssetImage("assets/images/anxiety_quiz.png"),
                        ),
                      ),
                      const SizedBox(height: 20),

                      /// BUTTON
                      ElevatedButton(
                        onPressed: isLoadingAnxiety
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AnxietyCheckFlow(userId: patientId),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoadingAnxiety
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Check Now",
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                      const SizedBox(height: 25),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Anxiety Records History",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 10),

                      /// HISTORY LIST
                      Expanded(
                        child: history.isEmpty
                            ? const Center(
                                child: Text(
                                  "No anxiety records found",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: history.length,
                                itemBuilder: (context, index) {
                                  var item = history[index];

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 5,
                                        )
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _formatDate(item.createdAt),
                                              style:
                                                  const TextStyle(fontSize: 15),
                                            ),
                                            Text(
                                              _formatTime(item.createdAt),
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          item.status,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: getColor(item.status),
                                          ),
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),
                      )
                    ],
                  ),
                ),
    );
  }
}
