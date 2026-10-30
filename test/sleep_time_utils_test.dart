import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enigma/core/utils/sleep_time_utils.dart';

void main() {
  group('calculateSleepDuration', () {
    test('normal daytime sleep duration calculation', () {
      // 08:30 -> 15:30 is exactly 7 hours
      const bedtime = TimeOfDay(hour: 8, minute: 30);
      const wakeTime = TimeOfDay(hour: 15, minute: 30);

      final duration = calculateSleepDuration(bedtime, wakeTime);
      expect(duration, 7.0);
    });

    test('crossing midnight sleep duration calculation', () {
      // 23:30 -> 06:45 is 7 hours and 15 minutes = 7.25 hours
      const bedtime = TimeOfDay(hour: 23, minute: 30);
      const wakeTime = TimeOfDay(hour: 6, minute: 45);

      final duration = calculateSleepDuration(bedtime, wakeTime);
      expect(duration, 7.25);
    });

    test('equal bedtime and wake time returns 0.0 hours', () {
      const bedtime = TimeOfDay(hour: 8, minute: 0);
      const wakeTime = TimeOfDay(hour: 8, minute: 0);

      final duration = calculateSleepDuration(bedtime, wakeTime);
      expect(duration, 0.0);
    });
  });

  group('SleepTimeUtils defaultTimesForShift', () {
    test('night shift suggests daytime sleep (08:30 -> 15:30)', () {
      final times = SleepTimeUtils.defaultTimesForShift('night');
      expect(times.bedtime, const TimeOfDay(hour: 8, minute: 30));
      expect(times.wakeTime, const TimeOfDay(hour: 15, minute: 30));
    });

    test('day shift suggests nighttime sleep (23:00 -> 06:30)', () {
      final times = SleepTimeUtils.defaultTimesForShift('day');
      expect(times.bedtime, const TimeOfDay(hour: 23, minute: 0));
      expect(times.wakeTime, const TimeOfDay(hour: 6, minute: 30));
    });

    test('null shift defaults to day shift sleep (23:00 -> 06:30)', () {
      final times = SleepTimeUtils.defaultTimesForShift(null);
      expect(times.bedtime, const TimeOfDay(hour: 23, minute: 0));
      expect(times.wakeTime, const TimeOfDay(hour: 6, minute: 30));
    });
  });

  group('formatHoursMinutes', () {
    test('7.5 -> 7h30', () {
      expect(formatHoursMinutes(7.5), '7h30');
    });

    test('8.82 -> 8h49', () {
      expect(formatHoursMinutes(8.82), '8h49');
    });

    test('7.0 -> 7h', () {
      expect(formatHoursMinutes(7.0), '7h');
    });

    test('0.0 -> 0 phút', () {
      expect(formatHoursMinutes(0.0), '0 phút');
    });

    test('7.999 -> 8h', () {
      expect(formatHoursMinutes(7.999), '8h');
    });

    test('handles 59.5 minutes rounding to next hour', () {
      expect(formatHoursMinutes(7 + 59.5 / 60), '8h');
    });

    test('handles less than 1 hour as X phút', () {
      expect(formatHoursMinutes(0.5), '30 phút');
    });
  });
}
