import 'package:flutter/material.dart';
import 'package:health_research/pages/physStress.dart';
import 'package:health_research/pages/stressQuestionnaireScreen.dart';
import 'package:health_research/services/PrerequisiteCheckService.dart';
import 'overStimulatedQuestionnaire.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Overstimulated extends StatefulWidget {
  const Overstimulated({super.key});

  @override
  State<Overstimulated> createState() => _OverstimulatedState();
}

class _OverstimulatedState extends State<Overstimulated> {
  bool _isCheckingPrerequisites = false;

  void initState() {
    super.initState();
    _loadUserData();
  }

  String patientId = "";

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    patientId = prefs.getString('patientId') ?? '';
  }

  /// Check all prerequisites before navigating to questionnaire
  Future<void> _checkAndNavigate() async {
    // Get user ID (you may need to get this from shared preferences or auth service)
    // For now, using a placeholder - replace with actual user ID retrieval

    setState(() {
      _isCheckingPrerequisites = true;
    });

    try {
      // Show loading dialog
      _showLoadingDialog();

      // Check all prerequisites
      final result = await PrerequisiteCheckService.checkAllPrerequisites(patientId);

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      if (result['success']) {
        // All prerequisites passed - navigate to questionnaire
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OverStimulatedQuestionnaire(),
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          _showErrorDialog(result['message'] ?? 'Failed to check prerequisites');
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
        _showErrorDialog('An error occurred: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingPrerequisites = false;
        });
      }
    }
  }

  /// Show loading dialog
  void _showLoadingDialog() {
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
                const Text(
                  'Checking prerequisites...',
                  style: TextStyle(
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

  /// Show error dialog with message
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
                'Unable to Continue',
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Burnout',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🖼️ Illustration Image
              Image.asset(
                'assets/images/burnout.jpg',
                height: 270,
              ),

              const SizedBox(height: 20),

              // 📄 Description Text
              Text(
                "Burnout is a state of emotional, mental, and physical exhaustion caused by prolonged stress, often related to school, work, or personal responsibilities. It can make you feel drained, unmotivated, irritable, and disconnected from things you usually care about. Taking burnout seriously is important for mental health because ignoring it can lead to anxiety, depression, and ongoing stress. Prioritizing rest, setting boundaries, and making time for activities you enjoy helps protect your well-being and keeps your mind healthier and more balanced over time.",
                textAlign: TextAlign.justify,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 25),

              // 🔥 Section Title
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Try the quest to check you’s",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              GestureDetector(
                onTap: _isCheckingPrerequisites ? null : _checkAndNavigate,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xfff2f2f2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _isCheckingPrerequisites
                              ? const CircularProgressIndicator(
                                  strokeWidth: 2,
                                )
                              : Image.asset(
                                  'assets/images/file_icon.png',
                                  fit: BoxFit.contain,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Burnout Quest ",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "Check for signs of emotional and physical exhaustion to find out if you may be experiencing burnout.",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
