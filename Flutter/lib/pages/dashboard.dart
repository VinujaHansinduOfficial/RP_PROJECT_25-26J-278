import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_research/pages/login.dart';
import 'package:http/http.dart' as http;
import 'package:health_research/services/ForecastApiService.dart';
import 'package:health_research/config/api_config.dart';
import 'dart:convert';
import 'dart:math';
import 'package:health_research/config/api_config.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String firstName = "User";
  String patientId = "";
  int pendingSessions = 0;
  String memberSince = "";
  bool isLoading = false;
  ForecastData? forecastData;
  List<Prediction> selectedPredictions = [];
  bool isForecastLoading = false;
  int _sleepHours = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    patientId = prefs.getString('patientId') ?? '';
    setState(() {
      firstName = prefs.getString('firstName') ?? 'User';
    });

    if (patientId.isNotEmpty) {
      await _fetchDashboardData();
      await _fetchForecastData();
      await _fetchHealthMetrics();
    }
  }

  Future<void> _fetchDashboardData() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/patients/dashboard/$patientId'),
        // Uri.parse('${ApiConfig.baseUrl}/api/patients/dashboard/$patientId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print("Dashboard Response: $jsonResponse");
        setState(() {
          pendingSessions = jsonResponse['pending_sessions'] ?? 0;
          memberSince = jsonResponse['member_since'] ?? '';
        });
      }
    } catch (e) {
      // Error fetching dashboard data
    }
    setState(() => isLoading = false);
  }

  Future<void> _fetchForecastData() async {
    if (patientId.isEmpty) return;

    setState(() => isForecastLoading = true);
    try {
      final studentId = int.tryParse(patientId) ?? 0;
      final forecastService = ForecastApiService();
      final data = await forecastService.fetchForecast(studentId);

      if (data != null && data.predictions.isNotEmpty) {
        final random = Random();
        final maxPredictions = min(3, data.predictions.length);
        final predictions = <Prediction>[];

        // Shuffle and select random predictions
        final shuffled = List<Prediction>.from(data.predictions)
          ..shuffle(random);
        predictions.addAll(shuffled.take(maxPredictions));

        setState(() {
          forecastData = data;
          selectedPredictions = predictions;
        });
      }
    } catch (e) {
      // Error fetching forecast data
    }
    setState(() => isForecastLoading = false);
  }

  Future<void> _fetchHealthMetrics() async {
    try {

      final url = Uri.parse('${ApiConfig.baseUrl1}/user_features/$patientId');

      final response = await http.get(url).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _sleepHours = data['features']['Sleep_Hours'] ?? 0;
        });
      }
    } catch (e) {
      print('Error fetching health metrics: $e');
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return "Good Morning";
    } else if (hour >= 12 && hour < 17) {
      return "Good Afternoon";
    } else if (hour >= 17 && hour < 21) {
      return "Good Evening";
    } else {
      return "Good Night";
    }
  }

  String _formatMemberSince() {
    if (memberSince.isEmpty) return "Recently";
    try {
      final dateTime = DateTime.parse(memberSince);
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return "Recently";
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String date = DateFormat('dd/MM/yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text("Logout"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerCard(date),
              const SizedBox(height: 16),
              _statusCards(),
              const SizedBox(height: 20),
              const Text(
                "Your Mental Health Insights",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              _mentalHealthInsightsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCard(String date) {
    return Container(
      height: 110,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: AssetImage("assets/images/sunshine.jpg"),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(date, style: const TextStyle(color: Colors.white, fontSize: 14)),
          const Spacer(),
          Text(
            _getGreeting(),
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            firstName,
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _statusCards() {
    return Row(
      children: [
        Expanded(
          child: _infoCard(
            title: "Member Since",
            child: isLoading
                ? const SizedBox(
                    height: 60,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Text(
                    _formatMemberSince(),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _infoCard(
            title: "Sleep Hours",
            child: isLoading
                ? const SizedBox(
                    height: 60,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _sleepHours.toString(),
                        style: const TextStyle(
                            fontSize: 36, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        "hours last night",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _infoCard({required String title, required Widget child}) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const Spacer(),
          Center(child: child),
        ],
      ),
    );
  }

  Widget _mentalHealthInsightsSection() {
    if (isForecastLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
              const SizedBox(height: 16),
              const Text(
                "Loading your insights...",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (selectedPredictions.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.grey.shade50, Colors.grey.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.psychology,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              const Text(
                "No predictions available",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Check back soon for mental health insights",
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Insights",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "Your mental health overview",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.psychology,
                color: Color(0xFF6366F1),
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: selectedPredictions
                .asMap()
                .entries
                .map((entry) => _predictionCard(entry.value, entry.key))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _predictionCard(Prediction prediction, int index) {
    Color stressColor;
    Color mentalColor;
    IconData stressIcon;
    IconData mentalIcon;
    Color cardGradientStart;
    Color cardGradientEnd;

    // Determine stress level colors and icons
    if (prediction.stressPredLabel == "High") {
      stressColor = const Color(0xFFEF4444);
      stressIcon = Icons.trending_up;
    } else if (prediction.stressPredLabel == "Medium") {
      stressColor = const Color(0xFFF97316);
      stressIcon = Icons.trending_flat;
    } else {
      stressColor = const Color(0xFF22C55E);
      stressIcon = Icons.trending_down;
    }

    // Determine mental state colors and icons
    if (prediction.mentalPredLabel == "Depression") {
      mentalColor = const Color(0xFFA855F7);
      mentalIcon = Icons.sentiment_very_dissatisfied;
      cardGradientStart = const Color(0xFFA855F7).withOpacity(0.1);
      cardGradientEnd = const Color(0xFF6366F1).withOpacity(0.1);
    } else if (prediction.mentalPredLabel == "Moderate Stress") {
      mentalColor = const Color(0xFFF97316);
      mentalIcon = Icons.sentiment_dissatisfied;
      cardGradientStart = const Color(0xFFF97316).withOpacity(0.1);
      cardGradientEnd = const Color(0xFFEAB308).withOpacity(0.1);
    } else {
      mentalColor = const Color(0xFF22C55E);
      mentalIcon = Icons.sentiment_satisfied;
      cardGradientStart = const Color(0xFF22C55E).withOpacity(0.1);
      cardGradientEnd = const Color(0xFF10B981).withOpacity(0.1);
    }

    // Parse date
    DateTime predictionDate;
    try {
      predictionDate = DateTime.parse(prediction.date);
    } catch (e) {
      predictionDate = DateTime.now();
    }

    return Container(
      width: 200,
      margin: EdgeInsets.only(
        right: 12,
        top: 4,
        bottom: 4,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [cardGradientStart, cardGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: mentalColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: mentalColor.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative element
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: mentalColor.withOpacity(0.05),
              ),
            ),
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date with badge
                Container(
                  decoration: BoxDecoration(
                    color: mentalColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    DateFormat('MMM dd, yyyy').format(predictionDate),
                    style: TextStyle(
                      fontSize: 11,
                      color: mentalColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Stress section with animated indicator
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: stressColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: stressColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          stressIcon,
                          color: stressColor,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Stress Level",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              prediction.stressPredLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: stressColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Mental state section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: mentalColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: mentalColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          mentalIcon,
                          color: mentalColor,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Mental State",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              prediction.mentalPredLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: mentalColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Index indicator at bottom
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      selectedPredictions.length,
                      (i) => Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              i == index ? mentalColor : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
