import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../utils/sleep_detector.dart';

/// Service interfacing with native Android UsageStatsManager & BatteryManager
/// via Kotlin MethodChannel. No background services, no new packages.
class SleepSensorService {
  static const MethodChannel _channel =
      MethodChannel('com.enigma.enigmateam.enigma/sleep_sensor');

  static final SleepSensorService instance = SleepSensorService._();
  SleepSensorService._();

  /// Check if PACKAGE_USAGE_STATS is granted in Android settings.
  Future<bool> isUsagePermissionGranted() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      final granted =
          await _channel.invokeMethod<bool>('isUsagePermissionGranted');
      return granted ?? false;
    } catch (e) {
      debugPrint('[SleepSensorService] isUsagePermissionGranted error: $e');
      return false;
    }
  }

  /// Open Android Usage Access settings page so the user can grant permission.
  Future<bool> requestUsagePermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      final ok = await _channel.invokeMethod<bool>('requestUsagePermission');
      return ok ?? false;
    } catch (e) {
      debugPrint('[SleepSensorService] requestUsagePermission error: $e');
      return false;
    }
  }

  /// Query raw screen events for the last [hours] (default 24h).
  Future<List<ScreenEvent>> getScreenEvents({int hours = 24}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return [];
    }
    try {
      final rawList = await _channel.invokeListMethod<dynamic>(
        'getScreenEvents',
        {'hours': hours},
      );
      if (rawList == null) return [];
      return rawList
          .whereType<Map<dynamic, dynamic>>()
          .map((m) => ScreenEvent.fromMap(m))
          .toList();
    } catch (e) {
      debugPrint('[SleepSensorService] getScreenEvents error: $e');
      return [];
    }
  }

  /// Get current battery charging state (one-shot, foreground).
  Future<Map<String, dynamic>> getChargingState() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return {'isCharging': false};
    }
    try {
      final state =
          await _channel.invokeMapMethod<String, dynamic>('getChargingState');
      return state ?? {'isCharging': false};
    } catch (e) {
      debugPrint('[SleepSensorService] getChargingState error: $e');
      return {'isCharging': false};
    }
  }
}
