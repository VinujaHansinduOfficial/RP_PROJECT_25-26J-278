import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_research/services/StressApiService.dart';
import 'package:health_research/models/StressResult.dart';
import 'package:health_research/pages/stress_check_flow.dart';

class StressQuiz extends StatefulWidget {
  const StressQuiz({super.key});

  @override
  State<StressQuiz> createState() => _StressQuizState();
}

class _StressQuizState extends State<StressQuiz> {
  final StressApiService _apiService = StressApiService();
  List<StressRecord> history = [];
  String patientId = "";
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchStress();
  }

  Future<void> _loadUserIdAndFetchStress() async {
    final prefs = await SharedPreferences.getInstance();
    patientId = prefs.getString('patientId') ?? '';

    if (patientId.isNotEmpty) {
      await _fetchStressHistory();
    } else {
      setState(() {
        errorMessage = 'User ID not found. Please login again.';
      });
    }
  }

  Future<void> _fetchStressHistory() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _apiService.getStressResults(patientId);
      if (result != null) {
        setState(() {
          history = result.results;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading stress history: $e';
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> checkStress() async {
    if (patientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID not found. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to stress check flow
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => StressCheckFlow(userId: patientId),
      ),
    )
        .then((_) {
      // Refresh the stress history when returning from the flow
      _fetchStressHistory();
    });
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
        title: const Text("Daily Stress Quest"),
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
                          onPressed: _fetchStressHistory,
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
                      CircleAvatar(
                        radius: 60,
                        backgroundImage:
                            const AssetImage("assets/images/stressed-quiz.png"),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: checkStress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("Check Now"),
                      ),
                      const SizedBox(height: 20),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Stress Records History",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: history.isEmpty
                            ? const Center(
                                child: Text(
                                  "No stress records found",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: history.length,
                                itemBuilder: (_, index) {
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
                                            blurRadius: 4)
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
                                            Text(_formatDate(item.createdAt)),
                                            Text(_formatTime(item.createdAt),
                                                style: const TextStyle(
                                                    color: Colors.grey)),
                                          ],
                                        ),
                                        Text(
                                          item.status,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: item.status == "Stressed"
                                                ? Colors.red
                                                : Colors.green,
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
