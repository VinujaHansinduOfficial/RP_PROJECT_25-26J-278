package com.example.health_research_278

import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.*
import kotlin.collections.ArrayList
class MainActivity: FlutterActivity() {
    private val CHANNEL = "app.usage.stats/channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getUsageStats" -> {
                    try {
                        val usageStats = getUsageStats()
                        result.success(usageStats)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get usage stats: ${e.message}", null)
                    }
                }
                "hasUsagePermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "openUsageSettings" -> {
                    openUsageAccessSettings()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * Check if usage stats permission is granted
     */
    private fun hasUsageStatsPermission(): Boolean {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val time = System.currentTimeMillis()
        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            time - 1000 * 60,
            time
        )
        return stats != null && stats.isNotEmpty()
    }

    /**
     * Open usage access settings for the user to grant permission
     */
    private fun openUsageAccessSettings() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        startActivity(intent)
    }

    /**
     * Fetch usage statistics for installed apps
     */
    private fun getUsageStats(): List<Map<String, Any>> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val packageManager = packageManager

        // Get usage stats for the last 24 hours
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.DAY_OF_YEAR, -1)
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()

        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )

        val usageList = ArrayList<Map<String, Any>>()

        stats?.let { statsList ->
            for (usageStats in statsList) {
                try {
                    // Skip system apps and apps with zero usage
                    if (usageStats.totalTimeInForeground <= 0) continue

                    val packageName = usageStats.packageName
                    val appInfo = packageManager.getApplicationInfo(packageName, 0)

                    // Skip system apps (optional)
                    if (appInfo.flags and ApplicationInfo.FLAG_SYSTEM != 0) continue

                    val appName = packageManager.getApplicationLabel(appInfo).toString()
                    val totalTimeInMs = usageStats.totalTimeInForeground
                    val lastTimeUsed = usageStats.lastTimeUsed

                    // Convert milliseconds to readable format
                    val hours = totalTimeInMs / (1000 * 60 * 60)
                    val minutes = (totalTimeInMs % (1000 * 60 * 60)) / (1000 * 60)
                    val seconds = (totalTimeInMs % (1000 * 60)) / 1000

                    val usageMap = mapOf(
                        "packageName" to packageName,
                        "appName" to appName,
                        "totalTimeInForeground" to totalTimeInMs,
                        "lastTimeUsed" to lastTimeUsed,
                        "hours" to hours,
                        "minutes" to minutes,
                        "seconds" to seconds,
                        "formattedTime" to formatTime(hours, minutes, seconds)
                    )

                    usageList.add(usageMap)
                } catch (e: PackageManager.NameNotFoundException) {
                    // App might be uninstalled, skip it
                    continue
                }
            }
        }

        // Sort by usage time (descending)
        return usageList.sortedByDescending { it["totalTimeInForeground"] as Long }
    }

    /**
     * Format time duration into readable string
     */
    private fun formatTime(hours: Long, minutes: Long, seconds: Long): String {
        return when {
            hours > 0 -> "${hours}h ${minutes}m"
            minutes > 0 -> "${minutes}m ${seconds}s"
            else -> "${seconds}s"
        }
    }
}