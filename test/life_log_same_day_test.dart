import 'package:flutter_test/flutter_test.dart';
import 'package:enigma/screens/student/life_log_screen.dart';

void main() {
  group('isSameLocalDay', () {
    final now = DateTime(2026, 10, 31, 10, 30);

    test('returns true for today ISO string', () {
      expect(isSameLocalDay(now.toIso8601String(), now), isTrue);
      expect(isSameLocalDay('2026-10-31', now), isTrue);
      expect(isSameLocalDay('2026-10-31T06:15:00.000', now), isTrue);
    });

    test('returns false for yesterday ISO string', () {
      final yesterday = now.subtract(const Duration(days: 1));
      expect(isSameLocalDay(yesterday.toIso8601String(), now), isFalse);
      expect(isSameLocalDay('2026-10-30', now), isFalse);
    });

    test('returns false for null, empty or invalid strings', () {
      expect(isSameLocalDay(null, now), isFalse);
      expect(isSameLocalDay('', now), isFalse);
      expect(isSameLocalDay('   ', now), isFalse);
      expect(isSameLocalDay('invalid-date', now), isFalse);
    });

    test('handles UTC string near midnight in UTC+7', () {
      // In UTC+7:
      // 17:30 UTC on Oct 30 = 00:30 on Oct 31 (same local day as Oct 31 morning)
      // 16:30 UTC on Oct 30 = 23:30 on Oct 30 (previous local day / yesterday)
      if (now.timeZoneOffset == const Duration(hours: 7)) {
        const utcNearMidnightToday = '2026-10-30T17:30:00.000Z';
        const utcBeforeMidnightYesterday = '2026-10-30T16:30:00.000Z';

        expect(isSameLocalDay(utcNearMidnightToday, now), isTrue);
        expect(isSameLocalDay(utcBeforeMidnightYesterday, now), isFalse);
      }

      // Timezone-independent dynamic check: UTC string 15 min after local midnight
      final localMidnight = DateTime(now.year, now.month, now.day);
      final justAfterMidnightUtc = localMidnight.add(const Duration(minutes: 15)).toUtc().toIso8601String();
      final justBeforeMidnightUtc = localMidnight.subtract(const Duration(minutes: 15)).toUtc().toIso8601String();

      expect(isSameLocalDay(justAfterMidnightUtc, now), isTrue);
      expect(isSameLocalDay(justBeforeMidnightUtc, now), isFalse);
    });
  });
}
