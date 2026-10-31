package com.enigma.enigmateam.enigma

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.enigma.enigmateam.enigma/sleep_sensor"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isUsagePermissionGranted" -> {
                    result.success(isUsagePermissionGranted())
                }
                "requestUsagePermission" -> {
                    requestUsagePermission()
                    result.success(true)
                }
                "getScreenEvents" -> {
                    val hours = call.argument<Int>("hours") ?: 24
                    result.success(getScreenEvents(hours))
                }
                "getChargingState" -> {
                    result.success(getChargingState())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun isUsagePermissionGranted(): Boolean {
        return try {
            val appOps = getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager ?: return false
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOps.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
            } else {
                appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
            }
            mode == AppOpsManager.MODE_ALLOWED
        } catch (e: Exception) {
            false
        }
    }

    private fun requestUsagePermission() {
        try {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
        } catch (e: Exception) {
            try {
                val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(intent)
            } catch (ignored: Exception) {
            }
        }
    }

    private fun getScreenEvents(hours: Int): List<Map<String, Any>> {
        val endTime = System.currentTimeMillis()
        val startTime = endTime - (hours.toLong() * 60 * 60 * 1000L)
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return emptyList()

        val events = usageStatsManager.queryEvents(startTime, endTime) ?: return emptyList()
        val eventList = mutableListOf<Map<String, Any>>()
        val event = UsageEvents.Event()

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val typeStr = when (event.eventType) {
                UsageEvents.Event.SCREEN_INTERACTIVE -> "SCREEN_INTERACTIVE"
                UsageEvents.Event.SCREEN_NON_INTERACTIVE -> "SCREEN_NON_INTERACTIVE"
                UsageEvents.Event.KEYGUARD_SHOWN -> "KEYGUARD_SHOWN"
                UsageEvents.Event.KEYGUARD_HIDDEN -> "KEYGUARD_HIDDEN"
                else -> null
            }
            if (typeStr != null) {
                eventList.add(
                    mapOf(
                        "type" to typeStr,
                        "timestamp" to event.timeStamp
                    )
                )
            }
        }
        return eventList
    }

    private fun getChargingState(): Map<String, Any> {
        val batteryStatus: Intent? = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val status = batteryStatus?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL
        val chargePlug = batteryStatus?.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1) ?: -1
        val isPlugged = chargePlug == BatteryManager.BATTERY_PLUGGED_USB ||
                        chargePlug == BatteryManager.BATTERY_PLUGGED_AC ||
                        chargePlug == BatteryManager.BATTERY_PLUGGED_WIRELESS
        return mapOf(
            "isCharging" to (isCharging || isPlugged),
            "status" to status,
            "plugged" to chargePlug
        )
    }
}
