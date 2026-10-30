import 'package:flutter/material.dart';

/// Small pure function to calculate sleep duration in hours from [bedtime] to [wakeTime].
/// Handles sleeping across midnight (e.g., 23:30 to 06:45 -> 7.25h).
/// When [bedtime] and [wakeTime] are equal, returns 0.0.
double calculateSleepDuration(TimeOfDay bedtime, TimeOfDay wakeTime) {
  final startMinutes = bedtime.hour * 60 + bedtime.minute;
  final endMinutes = wakeTime.hour * 60 + wakeTime.minute;

  if (startMinutes == endMinutes) {
    return 0.0;
  }

  int diffMinutes = endMinutes - startMinutes;
  if (diffMinutes < 0) {
    diffMinutes += 24 * 60;
  }

  final hours = diffMinutes / 60.0;
  return double.parse(hours.toStringAsFixed(2));
}

/// Helper class for sleep suggestion defaults and formatting.
class SleepTimeUtils {
  /// Suggested default bedtime and wake time based on shift type.
  /// - 'night' (Ca đêm) -> sleep in the daytime (08:30 - 15:30).
  /// - 'day' (Ca ngày) or null -> sleep at night (23:00 - 06:30).
  static ({TimeOfDay bedtime, TimeOfDay wakeTime}) defaultTimesForShift(String? shiftType) {
    if (shiftType == 'night') {
      return (
        bedtime: const TimeOfDay(hour: 8, minute: 30),
        wakeTime: const TimeOfDay(hour: 15, minute: 30),
      );
    }
    return (
      bedtime: const TimeOfDay(hour: 23, minute: 0),
      wakeTime: const TimeOfDay(hour: 6, minute: 30),
    );
  }

  /// Formats TimeOfDay into 24h format (HH:mm).
  static String formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Pure function to format sleep duration from decimal hours into hours and minutes.
  /// - Round to the nearest minute, handle 59.5 -> next hour
  /// - 0 -> "0 phút"
  /// - exact hour -> "7h"
  /// - hours with minutes -> e.g. 7.5 -> "7h30", 8.82 -> "8h49", 7.999 -> "8h"
  static String formatHoursMinutes(double hours) {
    if (hours.isNaN || hours.isInfinite) return '0 phút';
    final totalMinutes = (hours * 60).round();
    if (totalMinutes <= 0) {
      return '0 phút';
    }
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h == 0) {
      return '$m phút';
    }
    if (m == 0) {
      return '${h}h';
    }
    return '${h}h${m.toString().padLeft(2, '0')}';
  }
}

/// Pure function to format sleep duration from decimal hours into hours and minutes.
/// - Round to the nearest minute, handle 59.5 -> next hour
/// - 0 -> "0 phút"
/// - exact hour -> "7h"
/// - hours with minutes -> e.g. 7.5 -> "7h30", 8.82 -> "8h49", 7.999 -> "8h"
String formatHoursMinutes(double hours) => SleepTimeUtils.formatHoursMinutes(hours);
