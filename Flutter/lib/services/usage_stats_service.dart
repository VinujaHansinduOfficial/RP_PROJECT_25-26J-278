import 'package:flutter/services.dart';

class UsageStatsService {
  static const platform = MethodChannel('app.usage.stats/channel');

  /// Check if usage stats permission is granted
  static Future<bool> hasUsagePermission() async {
    try {
      final bool hasPermission = await platform.invokeMethod('hasUsagePermission');
      return hasPermission;
    } on PlatformException catch (e) {
      print("Error checking permission: ${e.message}");
      return false;
    }
  }

  /// Open usage access settings for user to grant permission
  static Future<void> openUsageSettings() async {
    try {
      await platform.invokeMethod('openUsageSettings');
    } on PlatformException catch (e) {
      print("Error opening settings: ${e.message}");
    }
  }

  /// Fetch app usage statistics
  static Future<List<AppUsageInfo>> getUsageStats() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getUsageStats');
      return result.map((data) => AppUsageInfo.fromMap(data)).toList();
    } on PlatformException catch (e) {
      print("Error getting usage stats: ${e.message}");
      return [];
    }
  }
}
/// Data model for app usage information
class AppUsageInfo {
  final String packageName;
  final String appName;
  final int totalTimeInForeground;
  final int lastTimeUsed;
  final int hours;
  final int minutes;
  final int seconds;
  final String formattedTime;

  AppUsageInfo({
    required this.packageName,
    required this.appName,
    required this.totalTimeInForeground,
    required this.lastTimeUsed,
    required this.hours,
    required this.minutes,
    required this.seconds,
    required this.formattedTime,
  });

  factory AppUsageInfo.fromMap(Map<dynamic, dynamic> map) {
    return AppUsageInfo(
      packageName: map['packageName']?.toString() ?? '',
      appName: map['appName']?.toString() ?? '',
      totalTimeInForeground: map['totalTimeInForeground']?.toInt() ?? 0,
      lastTimeUsed: map['lastTimeUsed']?.toInt() ?? 0,
      hours: map['hours']?.toInt() ?? 0,
      minutes: map['minutes']?.toInt() ?? 0,
      seconds: map['seconds']?.toInt() ?? 0,
      formattedTime: map['formattedTime']?.toString() ?? '0s',
    );
  }

  /// Get usage percentage relative to total time
  double getUsagePercentage(int totalUsageTime) {
    if (totalUsageTime == 0) return 0.0;
    return (totalTimeInForeground / totalUsageTime * 100).clamp(0.0, 100.0);
  }

  /// Check if this is a social media app
  bool isSocialMediaApp() {
    final socialMediaKeywords = [
      'facebook', 'instagram', 'whatsapp', 'telegram',
      'snapchat', 'tiktok', 'twitter', 'linkedin'
    ];
    return socialMediaKeywords.any(
            (keyword) => packageName.toLowerCase().contains(keyword)
    );
  }
}