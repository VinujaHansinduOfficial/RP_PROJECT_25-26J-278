import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_research/services/DepressionApiService.dart';
import 'package:health_research/models/DepressionResult.dart';

import 'depression_check_flow.dart';

class DepressionQuiz extends StatefulWidget {
  const DepressionQuiz({super.key});

  @override
  State<DepressionQuiz> createState() => _DepressionQuizState();
}

class _DepressionQuizState extends State<DepressionQuiz> {
  final DepressionApiService _apiService = DepressionApiService();
  List<DepressionRecord> history = [];
  String patientId = "";
  bool isLoading = false;
  bool isLoadingDepression = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchDepression();
  }

  Future<void> _loadUserIdAndFetchDepression() async {
    final prefs = await SharedPreferences.getInstance();
    patientId = prefs.getString('patientId') ?? '';

    if (patientId.isNotEmpty) {
      await _fetchDepressionHistory();
    } else {
      setState(() {
        errorMessage = 'User ID not found. Please login again.';
      });
    }
  }

  Future<void> _fetchDepressionHistory() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _apiService.getDepressionResults(patientId);
      if (result != null) {
        setState(() {
          history = result.results;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading depression history: $e';
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> checkDepression() async {
    setState(() {
      isLoadingDepression = true;
    });

    try {
      await _fetchDepressionHistory();
    } finally {
      setState(() {
        isLoadingDepression = false;
      });
    }
  }

  Color getColor(String status) {
    if (status == "Depressed") return Colors.red;
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
        title: const Text("Daily Depression Quest"),
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
                          onPressed: _fetchDepressionHistory,
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
                              AssetImage("assets/images/depression-quiz.png"),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: isLoadingDepression
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DepressionCheckFlow(
                                      userId: patientId,
                                    ),
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
                        child: isLoadingDepression
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
                          "Depression Records History",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: history.isEmpty
                            ? const Center(
                                child: Text(
                                  "No depression records found",
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
