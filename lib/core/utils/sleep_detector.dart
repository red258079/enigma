enum ScreenEventType {
  screenInteractive,
  screenNonInteractive,
  keyguardShown,
  keyguardHidden,
}

/// Represents a screen state change event from UsageStatsManager.
class ScreenEvent {
  final ScreenEventType type;
  final DateTime timestamp;

  ScreenEvent({required this.type, required this.timestamp});

  bool get isScreenOff =>
      type == ScreenEventType.screenNonInteractive ||
      type == ScreenEventType.keyguardShown;

  bool get isScreenOn =>
      type == ScreenEventType.screenInteractive ||
      type == ScreenEventType.keyguardHidden;

  factory ScreenEvent.fromMap(Map<dynamic, dynamic> map) {
    final typeStr = map['type'] as String? ?? '';
    final ts = map['timestamp'] as int? ?? 0;
    ScreenEventType type;
    switch (typeStr) {
      case 'SCREEN_INTERACTIVE':
        type = ScreenEventType.screenInteractive;
        break;
      case 'SCREEN_NON_INTERACTIVE':
        type = ScreenEventType.screenNonInteractive;
        break;
      case 'KEYGUARD_SHOWN':
        type = ScreenEventType.keyguardShown;
        break;
      case 'KEYGUARD_HIDDEN':
        type = ScreenEventType.keyguardHidden;
        break;
      default:
        type = ScreenEventType.screenInteractive;
    }
    return ScreenEvent(
      type: type,
      timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
    );
  }

  @override
  String toString() => '${type.name} at ${timestamp.toIso8601String()}';
}

/// Represents a continuous screen-off period.
class ScreenGap {
  final DateTime start;
  final DateTime end;

  ScreenGap({required this.start, required this.end});

  Duration get duration => end.difference(start);

  double get durationHours =>
      double.parse((duration.inMinutes / 60.0).toStringAsFixed(2));

  @override
  String toString() => 'ScreenGap($start -> $end, ${durationHours}h)';
}

/// Pure functions to detect sleep duration from screen events.
class SleepDetector {
  /// Extracts continuous screen-off intervals from raw events.
  static List<ScreenGap> extractRawGaps(List<ScreenEvent> events) {
    if (events.isEmpty) return [];

    final sorted = List<ScreenEvent>.from(events)
      ..sort((a, b) {
        final c = a.timestamp.compareTo(b.timestamp);
        if (c != 0) return c;
        if (a.isScreenOn && b.isScreenOff) return -1;
        if (a.isScreenOff && b.isScreenOn) return 1;
        return 0;
      });

    final rawGaps = <ScreenGap>[];
    DateTime? offStartTime;
    bool isOff = false;

    for (final event in sorted) {
      if (event.isScreenOff) {
        if (!isOff) {
          offStartTime = event.timestamp;
          isOff = true;
        }
      } else if (event.isScreenOn) {
        if (isOff && offStartTime != null) {
          if (event.timestamp.isAfter(offStartTime)) {
            rawGaps.add(ScreenGap(start: offStartTime, end: event.timestamp));
          }
          isOff = false;
          offStartTime = null;
        }
      }
    }

    return rawGaps;
  }

  /// Merges two gaps with bounded rules:
  /// 1. Merge gaps with screen-on < [maxInterruption] (10 min) only while the merged gap is shorter than 4h.
  /// 2. Once the merged gap is >= 4h, stop at the next screen-on (wake-up time). Do not continue merging after it.
  /// 3. Never merge across an interruption that contains keyguardHidden (real unlock) when interruption is >= 3 min.
  static List<ScreenGap> mergeGaps(
    List<ScreenGap> gaps, {
    Duration maxInterruption = const Duration(minutes: 10),
    List<ScreenEvent>? events,
  }) {
    if (gaps.isEmpty) return [];

    final sorted = List<ScreenGap>.from(gaps)
      ..sort((a, b) => a.start.compareTo(b.start));

    final merged = <ScreenGap>[];
    var current = sorted.first;

    for (int i = 1; i < sorted.length; i++) {
      final next = sorted[i];
      final screenOnDuration = next.start.difference(current.end);

      // 1. Merge gaps with screen-on < 10 min only while the merged gap is shorter than 4h.
      final isShorterThan4h = current.duration < const Duration(hours: 4);

      final isUnderMaxInterruption = screenOnDuration >= Duration.zero &&
          screenOnDuration < maxInterruption;

      // 3. Never merge across an interruption that contains keyguardHidden (real unlock) when interruption >= 3 min.
      bool isUnlockWithLongInterruption = false;
      if (screenOnDuration >= const Duration(minutes: 3) && events != null) {
        isUnlockWithLongInterruption = events.any((e) =>
            e.type == ScreenEventType.keyguardHidden &&
            !e.timestamp.isBefore(current.end) &&
            !e.timestamp.isAfter(next.start));
      }

      // 2. Once the merged gap is >= 4h, stop at the next screen-on. Do not continue merging.
      final canMerge = isShorterThan4h &&
          isUnderMaxInterruption &&
          !isUnlockWithLongInterruption;

      if (canMerge) {
        current = ScreenGap(
          start: current.start,
          end: next.end.isAfter(current.end) ? next.end : current.end,
        );
      } else {
        merged.add(current);
        current = next;
      }
    }
    merged.add(current);
    return merged;
  }

  /// Checks if a gap start time falls within the sleep window:
  /// - 'day' shift: 20:00 - 04:00 (sleep at night)
  /// - 'night' shift: 08:00 - 14:00 (sleep in daytime)
  /// - null / other: 20:00 - 12:00 (wide window)
  static bool isStartInSleepWindow(DateTime start, {String? shiftType}) {
    final local = start.toLocal();
    final h = local.hour;
    final m = local.minute;

    if (shiftType == 'day') {
      return (h >= 20) || (h < 4) || (h == 4 && m == 0);
    } else if (shiftType == 'night') {
      return (h >= 8 && h < 14) || (h == 14 && m == 0);
    } else {
      return (h >= 20) || (h < 12) || (h == 12 && m == 0);
    }
  }

  /// Infers shift type ('day', 'night', or null) from a sleep gap start time:
  /// - gap start 20:00 - 04:00 -> 'day'
  /// - gap start 08:00 - 14:00 -> 'night'
  /// - otherwise -> null
  static String? inferShiftTypeFromGapStart(DateTime start) {
    final local = start.toLocal();
    final h = local.hour;
    final m = local.minute;

    if ((h >= 20) || (h < 4) || (h == 4 && m == 0)) {
      return 'day';
    } else if ((h >= 8 && h < 14) || (h == 14 && m == 0)) {
      return 'night';
    } else {
      return null;
    }
  }

  /// Finds the longest screen-off gap for the given [shiftType].
  /// Ignores gaps under [minSleepDuration] (default 2 hours).
  /// When [shiftType] is null, requires duration <= 11 hours (raised from 10h).
  /// When [shiftType] is set, keeps [maxSleepDuration] (default 12 hours) cap. If null, no cap is enforced.
  /// When [ignoreSleepWindow] is true, sleep window check is skipped (used in debug test mode).
  /// Bounded merge: merges screen-on < 10m only while gap < 4h, stops when gap >= 4h, and ignores interruptions with unlock >= 3m.
  static ScreenGap? findLongestSleepGap(
    List<ScreenEvent> events, {
    String? shiftType,
    Duration minSleepDuration = const Duration(hours: 2),
    Duration? maxSleepDuration = const Duration(hours: 12),
    Duration maxInterruption = const Duration(minutes: 10),
    bool ignoreSleepWindow = false,
  }) {
    final rawGaps = extractRawGaps(events);
    if (rawGaps.isEmpty) return null;

    final mergedGaps = mergeGaps(
      rawGaps,
      maxInterruption: maxInterruption,
      events: events,
    );

    // If maxSleepDuration is null, no cap is enforced.
    // If shiftType is null, cap at 11 hours; if shift is set, keep maxSleepDuration cap.
    final effectiveMaxDuration = maxSleepDuration == null
        ? null
        : (shiftType == null
            ? (maxSleepDuration < const Duration(hours: 11)
                ? maxSleepDuration
                : const Duration(hours: 11))
            : maxSleepDuration);

    // Filter gaps:
    // 1. duration >= minSleepDuration (2h default)
    // 2. duration <= effectiveMaxDuration (if not null)
    // 3. starts within shift-appropriate sleep window (unless ignoreSleepWindow is true)
    final validGaps = mergedGaps.where((g) {
      if (g.duration < minSleepDuration) return false;
      if (effectiveMaxDuration != null && g.duration > effectiveMaxDuration) {
        return false;
      }
      if (!ignoreSleepWindow && !isStartInSleepWindow(g.start, shiftType: shiftType)) {
        return false;
      }
      return true;
    }).toList();

    if (validGaps.isEmpty) return null;

    // Return the longest gap
    validGaps.sort((a, b) => b.duration.compareTo(a.duration));
    return validGaps.first;
  }
}
