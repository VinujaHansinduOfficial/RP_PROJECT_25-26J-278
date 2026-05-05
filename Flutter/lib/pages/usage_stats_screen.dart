import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/usage_stats_service.dart';
import 'package:health_research/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsageStatsScreen extends StatefulWidget {
  const UsageStatsScreen({Key? key}) : super(key: key);
  @override
  State<UsageStatsScreen> createState() => _UsageStatsScreenState();
}
class _UsageStatsScreenState extends State<UsageStatsScreen> {
  List<AppUsageInfo> _usageStats = [];
  bool _isLoading = true;
  bool _hasPermission = false;
  String _errorMessage = '';

  // Health metrics
  int _heartRate = 0;
  int _sleepHours = 0;
  int _screenTime = 0;
  bool _isLoadingHealthMetrics = false;
  String patientId = "";

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    patientId = prefs.getString('patientId') ?? '';

if (patientId.isNotEmpty) {
      await _fetchHealthMetrics();
    }
  }

  // Controllers for input (only for Heart Rate and Sleep Hours)
  late TextEditingController _heartRateController;
  late TextEditingController _sleepHoursController;
  @override
  void initState() {
    super.initState();
    _heartRateController = TextEditingController();
    _sleepHoursController = TextEditingController();
    _checkPermissionAndLoadData();
    _loadUserData();
  }

  @override
  void dispose() {
    _heartRateController.dispose();
    _sleepHoursController.dispose();
    super.dispose();
  }
  /// Fetch health metrics from API
  Future<void> _fetchHealthMetrics() async {
    try {
      print("featch data, patientId: $patientId");
      final url = Uri.parse('${ApiConfig.baseUrl1}/user_features/$patientId');

      final response = await http.get(url).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _heartRate = data['features']['Heart_Rate'] ?? 0;
          _sleepHours = data['features']['Sleep_Hours'] ?? 0;

          // Update controllers
          _heartRateController.text = _heartRate.toString();
          _sleepHoursController.text = _sleepHours.toString();
        });
      }
    } catch (e) {
      print('Error fetching health metrics: $e');
    }
  }

  /// Save health metrics to API
  Future<void> _saveHealthMetrics() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl1}/user_features/save');

      final heartRate = int.tryParse(_heartRateController.text) ?? 0;
      final sleepHours = int.tryParse(_sleepHoursController.text) ?? 0;
      // Calculate screen time from total usage time (convert milliseconds to hours)
      final totalUsageTime = _getTotalUsageTime();
      final screenTimeHours = (totalUsageTime / (1000 * 60 * 60)).toInt();

      setState(() {
        _isLoadingHealthMetrics = true;
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': patientId,
          'features': {
            'Heart_Rate': heartRate,
            'Sleep_Hours': sleepHours,
            'Screen_Time': screenTimeHours,
          },
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      setState(() {
        _isLoadingHealthMetrics = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _heartRate = heartRate;
          _sleepHours = sleepHours;
          _screenTime = screenTimeHours;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Health metrics saved successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save health metrics'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingHealthMetrics = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
  Future<void> _checkPermissionAndLoadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      final hasPermission = await UsageStatsService.hasUsagePermission();

      if (hasPermission) {
        final stats = await UsageStatsService.getUsageStats();
        setState(() {
          _hasPermission = true;
          _usageStats = stats;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasPermission = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }
  /// Request usage access permission
  Future<void> _requestPermission() async {
    await UsageStatsService.openUsageSettings();

    // Show dialog explaining what to do
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Usage Access'),
        content: const Text(
          'Please find this app in the list and toggle the switch to grant usage access permission. Then return to the app.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Recheck permission after user returns
              Future.delayed(const Duration(seconds: 1), () {
                _checkPermissionAndLoadData();
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  /// Calculate total usage time across all apps
  int _getTotalUsageTime() {
    return _usageStats.fold(0, (sum, app) => sum + app.totalTimeInForeground);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'App Usage Stats',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkPermissionAndLoadData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading usage statistics...'),
          ],
        ),
      );
    }
    if (!_hasPermission) {
      return _buildPermissionRequest();
    }
    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }
    if (_usageStats.isEmpty) {
      return _buildEmptyState();
    }
    return _buildUsageStatsList();
  }
  Widget _buildPermissionRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'Usage Access Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'To show app usage statistics, this app needs usage access permission. This permission allows us to read how long you\'ve used other apps.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _requestPermission,
              icon: const Icon(Icons.settings),
              label: const Text('Grant Permission'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'Error Loading Data',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _checkPermissionAndLoadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'No Usage Data',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No app usage data found for the last 24 hours. Use some apps and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildUsageStatsList() {
    final totalUsageTime = _getTotalUsageTime();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Summary Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.purple.shade300],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Total Apps',
                  _usageStats.length.toString(),
                  Icons.apps,
                ),
                _buildSummaryItem(
                  'Total Time',
                  _formatTotalTime(totalUsageTime),
                  Icons.timer,
                ),
                _buildSummaryItem(
                  'Social Media',
                  _usageStats.where((app) => app.isSocialMediaApp()).length.toString(),
                  Icons.people,
                ),
              ],
            ),
          ),

          // Health Metrics Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display current values
                const Text(
                  'Current Health Metrics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Heart Rate Display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.favorite, color: Colors.red.shade700, size: 24),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Heart Rate',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '$_heartRate BPM',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Sleep Hours Display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.nights_stay, color: Colors.blue.shade700, size: 24),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sleep Hours',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '$_sleepHours hours',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),


                const SizedBox(height: 24),

                // Input Section
                const Text(
                  'Update Health Metrics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Heart Rate Input
                TextField(
                  controller: _heartRateController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Heart Rate (BPM)',
                    prefixIcon: Icon(Icons.favorite, color: Colors.red.shade700),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.red.shade700, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Sleep Hours Input
                TextField(
                  controller: _sleepHoursController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Sleep Hours',
                    prefixIcon: Icon(Icons.nights_stay, color: Colors.blue.shade700),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoadingHealthMetrics ? null : _saveHealthMetrics,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoadingHealthMetrics
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Saving...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'Save Health Metrics',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatTotalTime(int totalTimeMs) {
    final hours = totalTimeMs ~/ (1000 * 60 * 60);
    final minutes = (totalTimeMs % (1000 * 60 * 60)) ~/ (1000 * 60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
