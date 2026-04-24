// import 'package:flutter/material.dart';
// import 'package:health/health.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:usage_stats/usage_stats.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// class TimeSeriesDashboard extends StatefulWidget {
//   const TimeSeriesDashboard({super.key});
//
//   @override
//   State<TimeSeriesDashboard> createState() => _TimeSeriesDashboardState();
// }
//
// class _TimeSeriesDashboardState extends State<TimeSeriesDashboard> {
//   final Health health = Health();
//
//   // Health data
//   int heartRateBpm = 0;
//   double sleepHoursToday = 0.0;
//   List<FlSpot> sleepSpotsLast7Days = [];
//
//   // Screen Time data
//   String _currentApp = "Unknown";
//   int _currentAppTimeMs = 0;
//   int _dailyScreenTimeMs = 0;
//
//   String _status = "Initializing...";
//   bool _isLoading = true;
//   String _errorMessage = "";
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeAll();
//   }
//
//   Future<void> _initializeAll() async {
//     await _loadHealthData();
//     await _loadScreenTime();
//   }
//
//   // ───────── HEALTH CONNECT ─────────
//
//   Future<void> _loadHealthData() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = "";
//     });
//
//     try {
//       await Permission.activityRecognition.request();
//
//       bool authorized = await _requestHealthPermissions();
//       if (!authorized) {
//         setState(() {
//           _errorMessage = "Health permissions denied";
//           _isLoading = false;
//         });
//         return;
//       }
//
//       final now = DateTime.now();
//       final startOfDay = DateTime(now.year, now.month, now.day);
//
//       // Heart Rate (last 24h)
//       final heartData = await health.getHealthDataFromTypes(
//         startTime: now.subtract(const Duration(hours: 24)),
//         endTime: now,
//         types: [HealthDataType.HEART_RATE],
//       );
//
//       if (heartData.isNotEmpty) {
//         heartRateBpm =
//             (heartData.last.value as NumericHealthValue).numericValue.toInt();
//       }
//
//       // Sleep Today (FIXED calculation)
//       final sleepToday = await health.getHealthDataFromTypes(
//         startTime: startOfDay,
//         endTime: now,
//         types: [HealthDataType.SLEEP_ASLEEP],
//       );
//
//       double totalMinutes = 0;
//       for (var d in sleepToday) {
//         totalMinutes += d.dateTo.difference(d.dateFrom).inMinutes;
//       }
//       sleepHoursToday = totalMinutes / 60;
//
//       // Sleep last 7 days
//       sleepSpotsLast7Days = [];
//
//       for (int i = 6; i >= 0; i--) {
//         final dayStart = startOfDay.subtract(Duration(days: i));
//         final dayEnd = dayStart.add(const Duration(days: 1));
//
//         final daySleep = await health.getHealthDataFromTypes(
//           startTime: dayStart,
//           endTime: dayEnd,
//           types: [HealthDataType.SLEEP_ASLEEP],
//         );
//
//         double dayMinutes = 0;
//         for (var d in daySleep) {
//           dayMinutes += d.dateTo.difference(d.dateFrom).inMinutes;
//         }
//
//         sleepSpotsLast7Days
//             .add(FlSpot((6 - i).toDouble(), dayMinutes / 60));
//       }
//
//       setState(() {});
//     } catch (e) {
//       _errorMessage = "Health error: $e";
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   Future<bool> _requestHealthPermissions() async {
//     final types = [
//       HealthDataType.HEART_RATE,
//       HealthDataType.SLEEP_ASLEEP,
//       HealthDataType.STEPS,
//     ];
//
//     try {
//       return await health.requestAuthorization(types);
//     } catch (e) {
//       return false;
//     }
//   }
//
//   // ───────── SCREEN TIME (usage_stats) ─────────
//
//   Future<void> _loadScreenTime() async {
//     setState(() {
//       _status = "Requesting usage permission...";
//       _isLoading = true;
//     });
//
//     try {
//       print("Fetching screen time data...");
//       // Opens Usage Access settings screen
//       await UsageStats.grantUsagePermission();
//
//
//       DateTime endDate = DateTime.now();
//       DateTime startDate =
//       DateTime(endDate.year, endDate.month, endDate.day);
//
//       List<UsageInfo> usageStats =
//       await UsageStats.queryUsageStats(startDate, endDate);
//
//       if (usageStats.isEmpty) {
//         setState(() {
//           _status = "No usage data found.";
//           _isLoading = false;
//         });
//         return;
//       }
//
//       int totalTimeMs = 0;
//
//       for (var stat in usageStats) {
//         int time = int.tryParse(
//             stat.totalTimeInForeground ?? "0") ??
//             0;
//         totalTimeMs += time;
//
//         print("App: ${stat.packageName} Time: ${stat.totalTimeInForeground}");      }
//
//       // Sort by usage time
//       usageStats.sort((a, b) {
//         int aTime =
//             int.tryParse(a.totalTimeInForeground ?? "0") ??
//                 0;
//         int bTime =
//             int.tryParse(b.totalTimeInForeground ?? "0") ??
//                 0;
//         return bTime.compareTo(aTime);
//       });
//
//       var topApp = usageStats.first;
//
//       int topAppTime =
//           int.tryParse(topApp.totalTimeInForeground ?? "0") ??
//               0;
//
//       setState(() {
//         _dailyScreenTimeMs = totalTimeMs;
//         _currentApp =
//             topApp.packageName ?? "Unknown App";
//         _currentAppTimeMs = topAppTime;
//         _status = "Screen time loaded";
//       });
//     } catch (e) {
//       setState(() {
//         _status = "Screen time error: $e";
//       });
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   // ───────── UI ─────────
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Time Series"),
//       ),
//       body: RefreshIndicator(
//         onRefresh: _initializeAll,
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment:
//             CrossAxisAlignment.start,
//             children: [
//               Text(_status,
//                   style: const TextStyle(
//                       fontWeight: FontWeight.bold)),
//               const SizedBox(height: 20),
//
//               Text("Heart Rate: $heartRateBpm BPM"),
//               Text(
//                   "Sleep Today: ${sleepHoursToday.toStringAsFixed(1)} hrs"),
//
//               const SizedBox(height: 20),
//
//               const Text(
//                 "Sleep (Last 7 Days)",
//                 style: TextStyle(
//                     fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 10),
//               SizedBox(
//                 height: 200,
//                 child: sleepSpotsLast7Days.isEmpty
//                     ? const Center(
//                     child: Text(
//                         "No sleep data yet"))
//                     : LineChart(
//                   LineChartData(
//                     gridData:
//                     FlGridData(show: false),
//                     titlesData:
//                     FlTitlesData(show: false),
//                     borderData:
//                     FlBorderData(show: false),
//                     lineBarsData: [
//                       LineChartBarData(
//                         spots:
//                         sleepSpotsLast7Days,
//                         isCurved: true,
//                         dotData:
//                         FlDotData(show: true),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//
//               const SizedBox(height: 30),
//
//               const Text(
//                 "Screen Time Today",
//                 style: TextStyle(
//                     fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 10),
//
//               Text(
//                   "Total: ${(_dailyScreenTimeMs / 1000 / 60).toStringAsFixed(1)} minutes"),
//               Text("Most Used App: $_currentApp"),
//               Text(
//                   "Time: ${(_currentAppTimeMs / 1000 / 60).toStringAsFixed(1)} minutes"),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
