import 'package:flutter_test/flutter_test.dart';
import 'package:enigma/core/utils/sleep_detector.dart';

void main() {
  group('SleepDetector', () {
    test('normal night sleep detection (23:00 -> 06:30)', () {
      final baseDate = DateTime(2026, 10, 29);
      final events = [
        ScreenEvent(
          type: ScreenEventType.screenInteractive,
          timestamp: baseDate.add(const Duration(hours: 22, minutes: 45)),
        ),
        ScreenEvent(
          type: ScreenEventType.screenNonInteractive,
          timestamp: baseDate.add(const Duration(hours: 23, minutes: 0)),
        ),
        ScreenEvent(
          type: ScreenEventType.screenInteractive,
          timestamp: baseDate.add(const Duration(hours: 30, minutes: 30)), // 06:30 next day
        ),
      ];

      final gap = SleepDetector.findLongestSleepGap(events);
      expect(gap, isNotNull);
      expect(gap!.start, baseDate.add(const Duration(hours: 23, minutes: 0)));
      expect(gap.end, baseDate.add(const Duration(hours: 30, minutes: 30)));
      expect(gap.durationHours, 7.5);
    });

    test('midnight bathroom interruption (< 10 min screen on merges correctly)', () {
      final baseDate = DateTime(2026, 10, 29);
      final events = [
        // Bedtime at 23:30
        ScreenEvent(
          type: ScreenEventType.screenNonInteractive,
          timestamp: baseDate.add(const Duration(hours: 23, minutes: 30)),
        ),
        // Woke up at 02:00 for bathroom
        ScreenEvent(
          type: ScreenEventType.screenInteractive,
          timestamp: baseDate.add(const Duration(hours: 26, minutes: 0)), // 02:00 next day
        ),
        // Screen off again at 02:06 (interruption = 6 mins < 10 mins)
        ScreenEvent(
          type: ScreenEventType.screenNonInteractive,
          timestamp: baseDate.add(const Duration(hours: 26, minutes: 6)), // 02:06 next day
        ),
        // Morning wake up at 06:45
        ScreenEvent(
          type: ScreenEventType.screenInteractive,
          timestamp: baseDate.add(const Duration(hours: 30, minutes: 45)), // 06:45 next day
        ),
      ];

      final gap = SleepDetector.findLongestSleepGap(events);
      expect(gap, isNotNull);
      // Merged from 23:30 to 06:45 = 7 hours 15 minutes = 7.25 hours
      expect(gap!.start, baseDate.add(const Duration(hours: 23, minutes: 30)));
      expect(gap.end, baseDate.add(const Duration(hours: 30, minutes: 45)));
      expect(gap.durationHours, 7.25);
    });

    test('interruption >= 10 min does not merge, picks longest valid gap', () {
      final baseDate = DateTime(2026, 10, 29);
      final events = [
        // Gap 1: 22:00 -> 00:30 (2.5h)
        ScreenEvent(
          type: ScreenEventType.screenNonInteractive,
          timestamp: baseDate.add(const Duration(hours: 22, minutes: 0)),
        ),
        ScreenEvent(
          type: ScreenEventType.screenInteractive,
          timestamp: baseDate.add(const Duration(hours: 24, minutes: 30)), // 00:30 next day
        ),
        // Screen on for 30 minutes (00:30 -> 01:00) >= 10 mins
        // Gap 2: 01:00 -> 06:00 (5.0h)
        ScreenEvent(
          type: ScreenEventType.screenNonInteractive,
          timestamp: baseDate.add(const Duration(hours: 25, minutes: 0)), // 01:00 next day
        ),
        ScreenEvent(
          type: ScreenEventType.screenInteractive,
          timestamp: baseDate.add(const Duration(hours: 30, minutes: 0)), // 06:00 next day
        ),
      ];

      final gap = SleepDetector.findLongestSleepGap(events);
      expect(gap, isNotNull);
      expect(gap!.start, baseDate.add(const Duration(hours: 25, minutes: 0)));
      expect(gap.end, baseDate.add(const Duration(hours: 30, minutes: 0)));
      expect(gap.durationHours, 5.0);
    });

    test('no gap found (empty events, or all gaps under 2 hours)', () {
      // Empty events
      expect(SleepDetector.findLongestSleepGap([]), isNull);

      final baseDate = DateTime(2026, 10, 29);
      // Gaps under 2 hours
      final events = [
        ScreenEvent(
          type: ScreenEventType.screenNonInteractive,
          timestamp: baseDate.add(const Duration(hours: 22, minutes: 0)),
        ),
        ScreenEvent(
          type: ScreenEventType.screenInteractive,
          timestamp: baseDate.add(const Duration(hours: 23, minutes: 30)), // 1.5h < 2h
        ),
      ];
      expect(SleepDetector.findLongestSleepGap(events), isNull);
    });

    test('gap starting outside 20:00 to 12:00 window is ignored (e.g. afternoon nap 14:00)', () {
      final baseDate = DateTime(2026, 10, 29);
      final events = [
        ScreenEvent(
          type: ScreenEventType.screenNonInteractive,
          timestamp: baseDate.add(const Duration(hours: 14, minutes: 0)), // 14:00
        ),
        ScreenEvent(
          type: ScreenEventType.screenInteractive,
          timestamp: baseDate.add(const Duration(hours: 17, minutes: 0)), // 17:00 (3h)
        ),
      ];

      final gap = SleepDetector.findLongestSleepGap(events);
      expect(gap, isNull);
    });

    test('night shift sleep starting at 08:30 morning is accepted', () {
      final baseDate = DateTime(2026, 10, 29);
      final events = [
        ScreenEvent(
          type: ScreenEventType.screenNonInteractive,
          timestamp: baseDate.add(const Duration(hours: 8, minutes: 30)), // 08:30 morning
        ),
        ScreenEvent(
          type: ScreenEventType.screenInteractive,
          timestamp: baseDate.add(const Duration(hours: 15, minutes: 30)), // 15:30 afternoon (7h)
        ),
      ];

      final gap = SleepDetector.findLongestSleepGap(events, shiftType: 'night');
      expect(gap, isNotNull);
      expect(gap!.durationHours, 7.0);
    });

    test('12h work-time gap is ignored for each shift (day and night)', () {
      final baseDate = DateTime(2026, 10, 29);

      // Day shift worker puts phone in locker during work: 08:00 -> 20:00 (12h)
      final dayWorkEvents = [
        ScreenEvent(
          type: ScreenEventType.screenNonInteractive,
          timestamp: baseDate.add(const Duration(hours: 8, minutes: 0)), // 08:00 work starts
        ),
        ScreenEvent(
          type: ScreenEventType.screenInteractive,
          timestamp: baseDate.add(const Duration(hours: 20, minutes: 0)), // 20:00 work ends (12h)
        ),
      ];
      // For day shift (sleep window 20:00 - 04:00), gap starting at 08:00 is ignored
      final dayGap = SleepDetector.findLongestSleepGap(dayWorkEvents, shiftType: 'day');
      expect(dayGap, isNull);

      // Night shift worker puts phone in locker during work: 20:00 -> 08:00 (12h)
      final nightWorkEvents = [
        ScreenEvent(
          type: ScreenEventType.screenNonInteractive,
          timestamp: baseDate.add(const Duration(hours: 20, minutes: 0)), // 20:00 work starts
        ),
        ScreenEvent(
          type: ScreenEventType.screenInteractive,
          timestamp: baseDate.add(const Duration(hours: 32, minutes: 0)), // 08:00 next day (12h)
        ),
      ];
      // For night shift (sleep window 08:00 - 14:00), gap starting at 20:00 is ignored
      final nightGap = SleepDetector.findLongestSleepGap(nightWorkEvents, shiftType: 'night');
      expect(nightGap, isNull);
    });

    test('7h sleep wins over a 12h work gap', () {
      final baseDate = DateTime(2026, 10, 29);
      final events = [
        // 12h work gap in locker during day (08:00 -> 20:00)
        ScreenEvent(
          type: ScreenEventType.screenNonInteractive,
          timestamp: baseDate.add(const Duration(hours: 8, minutes: 0)),
        ),
        ScreenEvent(
          type: ScreenEventType.screenInteractive,
          timestamp: baseDate.add(const Duration(hours: 20, minutes: 0)),
        ),
        // 7h sleep at night (23:00 -> 06:00 next day)
        ScreenEvent(
          type: ScreenEventType.screenNonInteractive,
          timestamp: baseDate.add(const Duration(hours: 23, minutes: 0)),
        ),
        ScreenEvent(
          type: ScreenEventType.screenInteractive,
          timestamp: baseDate.add(const Duration(hours: 30, minutes: 0)), // 06:00 next day
        ),
      ];

      // With day shift, the 12h work gap is filtered out by window, 7h sleep wins
      final gap = SleepDetector.findLongestSleepGap(events, shiftType: 'day');
      expect(gap, isNotNull);
      expect(gap!.durationHours, 7.0);
      expect(gap.start, baseDate.add(const Duration(hours: 23, minutes: 0)));
      expect(gap.end, baseDate.add(const Duration(hours: 30, minutes: 0)));
    });

    test('gap longer than 12 hours is dropped in all cases', () {
      final baseDate = DateTime(2026, 10, 29);
      // 13h gap starting at 21:00 (inside window, but duration > 12h)
      final events = [
        ScreenEvent(
          type: ScreenEventType.screenNonInteractive,
          timestamp: baseDate.add(const Duration(hours: 21, minutes: 0)),
        ),
        ScreenEvent(
          type: ScreenEventType.screenInteractive,
          timestamp: baseDate.add(const Duration(hours: 34, minutes: 0)), // 10:00 next day = 13h
        ),
      ];

      // Dropped because > 12h
      expect(SleepDetector.findLongestSleepGap(events, shiftType: 'day'), isNull);
      expect(SleepDetector.findLongestSleepGap(events, shiftType: null), isNull);
    });

    test('with shiftType null, an 11.5h gap starting 08:15 is ignored and a 7h sleep wins', () {
      final baseDate = DateTime(2026, 10, 29);
      final events = [
        // 11.5h gap starting 08:15 -> 19:45 (work shift with phone in locker)
        ScreenEvent(
          type: ScreenEventType.screenNonInteractive,
          timestamp: baseDate.add(const Duration(hours: 8, minutes: 15)),
        ),
        ScreenEvent(
          type: ScreenEventType.screenInteractive,
          timestamp: baseDate.add(const Duration(hours: 19, minutes: 45)),
        ),
        // 7h sleep at night (23:00 -> 06:00 next day)
        ScreenEvent(
          type: ScreenEventType.screenNonInteractive,
          timestamp: baseDate.add(const Duration(hours: 23, minutes: 0)),
        ),
        ScreenEvent(
          type: ScreenEventType.screenInteractive,
          timestamp: baseDate.add(const Duration(hours: 30, minutes: 0)),
        ),
      ];

      final gap = SleepDetector.findLongestSleepGap(events, shiftType: null);
      expect(gap, isNotNull);
      expect(gap!.durationHours, 7.0);
      expect(gap.start, baseDate.add(const Duration(hours: 23, minutes: 0)));
      expect(gap.end, baseDate.add(const Duration(hours: 30, minutes: 0)));
    });

    test('with shiftType null, a 7h sleep alone is still detected', () {
      final baseDate = DateTime(2026, 10, 29);
      final events = [
        ScreenEvent(
          type: ScreenEventType.screenNonInteractive,
          timestamp: baseDate.add(const Duration(hours: 23, minutes: 0)),
        ),
        ScreenEvent(
          type: ScreenEventType.screenInteractive,
          timestamp: baseDate.add(const Duration(hours: 30, minutes: 0)),
        ),
      ];

      final gap = SleepDetector.findLongestSleepGap(events, shiftType: null);
      expect(gap, isNotNull);
      expect(gap!.durationHours, 7.0);
      expect(gap.start, baseDate.add(const Duration(hours: 23, minutes: 0)));
      expect(gap.end, baseDate.add(const Duration(hours: 30, minutes: 0)));
    });

    test('test mode: detects gap >= 5 min without sleep window or cap restriction', () {
      final baseDate = DateTime(2026, 10, 29);
      // 15-minute gap in the middle of the afternoon (15:00 -> 15:15)
      final events = [
        ScreenEvent(
          type: ScreenEventType.screenNonInteractive,
          timestamp: baseDate.add(const Duration(hours: 15, minutes: 0)),
        ),
        ScreenEvent(
          type: ScreenEventType.screenInteractive,
          timestamp: baseDate.add(const Duration(hours: 15, minutes: 15)),
        ),
      ];

      // Normally ignored because < 2h and outside window
      expect(SleepDetector.findLongestSleepGap(events), isNull);

      // In test mode: detected
      final gap = SleepDetector.findLongestSleepGap(
        events,
        minSleepDuration: const Duration(minutes: 5),
        maxSleepDuration: null,
        ignoreSleepWindow: true,
      );
      expect(gap, isNotNull);
      expect(gap!.durationHours, 0.25);
      expect(gap.start, baseDate.add(const Duration(hours: 15, minutes: 0)));
      expect(gap.end, baseDate.add(const Duration(hours: 15, minutes: 15)));
    });

    test('real data of 29-30/10: bounded merge stops at morning wake-up 07:31:49, no 15h chain', () {
      final events = [
        // off 22:42:06 (29/10)
        ScreenEvent(
          type: ScreenEventType.screenNonInteractive,
          timestamp: DateTime(2026, 10, 29, 22, 42, 6),
        ),
        // on/off 00:10:18-19 (30/10)
        ScreenEvent(
          type: ScreenEventType.screenInteractive,
          timestamp: DateTime(2026, 10, 30, 0, 10, 18),
        ),
        ScreenEvent(
          type: ScreenEventType.screenNonInteractive,
          timestamp: DateTime(2026, 10, 30, 0, 10, 19),
        ),
        // on/off 01:46:43 (30/10)
        ScreenEvent(
          type: ScreenEventType.screenInteractive,
          timestamp: DateTime(2026, 10, 30, 1, 46, 43),
        ),
        ScreenEvent(
          type: ScreenEventType.screenNonInteractive,
          timestamp: DateTime(2026, 10, 30, 1, 46, 44),
        ),
        // on 07:31:49 (30/10) -> morning wake-up time!
        ScreenEvent(
          type: ScreenEventType.screenInteractive,
          timestamp: DateTime(2026, 10, 30, 7, 31, 49),
        ),
        // off 07:32:11
        ScreenEvent(
          type: ScreenEventType.screenNonInteractive,
          timestamp: DateTime(2026, 10, 30, 7, 32, 11),
        ),
        // on 09:04:50
        ScreenEvent(
          type: ScreenEventType.screenInteractive,
          timestamp: DateTime(2026, 10, 30, 9, 4, 50),
        ),
        // later short use until 13:51
        ScreenEvent(
          type: ScreenEventType.screenNonInteractive,
          timestamp: DateTime(2026, 10, 30, 9, 5, 20),
        ),
        ScreenEvent(
          type: ScreenEventType.screenInteractive,
          timestamp: DateTime(2026, 10, 30, 11, 0, 0),
        ),
        ScreenEvent(
          type: ScreenEventType.screenNonInteractive,
          timestamp: DateTime(2026, 10, 30, 11, 1, 0),
        ),
        ScreenEvent(
          type: ScreenEventType.screenInteractive,
          timestamp: DateTime(2026, 10, 30, 13, 51, 0),
        ),
      ];

      // For shiftType null: expected 22:42:06 -> 07:31:49 (~8.8h)
      final gapNull = SleepDetector.findLongestSleepGap(events, shiftType: null);
      expect(gapNull, isNotNull);
      expect(gapNull!.start, DateTime(2026, 10, 29, 22, 42, 6));
      expect(gapNull.end, DateTime(2026, 10, 30, 7, 31, 49));
      expect(gapNull.durationHours, closeTo(8.8, 0.1));

      // For shiftType 'day': expected 22:42:06 -> 07:31:49 (~8.8h)
      final gapDay = SleepDetector.findLongestSleepGap(events, shiftType: 'day');
      expect(gapDay, isNotNull);
      expect(gapDay!.start, DateTime(2026, 10, 29, 22, 42, 6));
      expect(gapDay.end, DateTime(2026, 10, 30, 7, 31, 49));
      expect(gapDay.durationHours, closeTo(8.8, 0.1));

      // Test mode: no longer returns 15h gap (stops at morning wake-up 07:31:49)
      final gapTest = SleepDetector.findLongestSleepGap(
        events,
        minSleepDuration: const Duration(minutes: 5),
        maxSleepDuration: null,
        ignoreSleepWindow: true,
      );
      expect(gapTest, isNotNull);
      expect(gapTest!.start, DateTime(2026, 10, 29, 22, 42, 6));
      expect(gapTest.end, DateTime(2026, 10, 30, 7, 31, 49));
      expect(gapTest.durationHours, closeTo(8.8, 0.1));
      expect(gapTest.durationHours, isNot(closeTo(15.0, 1.0)));
    });

    test('never merge across interruption with keyguardHidden when interruption >= 3 min', () {
      final baseDate = DateTime(2026, 10, 29);
      final events = [
        // Sleep part 1: 23:00 -> 01:00 (2h < 4h)
        ScreenEvent(
          type: ScreenEventType.screenNonInteractive,
          timestamp: baseDate.add(const Duration(hours: 23, minutes: 0)),
        ),
        // Screen on at 01:00
        ScreenEvent(
          type: ScreenEventType.screenInteractive,
          timestamp: baseDate.add(const Duration(hours: 25, minutes: 0)), // 01:00
        ),
        // Phone unlocked at 01:00:10
        ScreenEvent(
          type: ScreenEventType.keyguardHidden,
          timestamp: baseDate.add(const Duration(hours: 25, minutes: 0, seconds: 10)),
        ),
        // Screen off at 01:04 (interruption = 4 mins >= 3 min with unlock)
        ScreenEvent(
          type: ScreenEventType.screenNonInteractive,
          timestamp: baseDate.add(const Duration(hours: 25, minutes: 4)), // 01:04
        ),
        // Sleep part 2: 01:04 -> 06:30 (5h 26m)
        ScreenEvent(
          type: ScreenEventType.screenInteractive,
          timestamp: baseDate.add(const Duration(hours: 30, minutes: 30)), // 06:30
        ),
      ];

      // Because interruption is >= 3 min and contains keyguardHidden, it does not merge.
      // Part 2 (01:04 -> 06:30, 5.43h) wins over Part 1 (2h).
      final gap = SleepDetector.findLongestSleepGap(events);
      expect(gap, isNotNull);
      expect(gap!.start, baseDate.add(const Duration(hours: 25, minutes: 4)));
      expect(gap.end, baseDate.add(const Duration(hours: 30, minutes: 30)));
    });

    group('inferShiftTypeFromGapStart pure function', () {
      test('gap start 20:00 - 04:00 infers day shift', () {
        // 20:00 boundary
        expect(SleepDetector.inferShiftTypeFromGapStart(DateTime(2026, 10, 29, 20, 0)), 'day');
        // 22:42 night
        expect(SleepDetector.inferShiftTypeFromGapStart(DateTime(2026, 10, 29, 22, 42)), 'day');
        // 00:00 midnight
        expect(SleepDetector.inferShiftTypeFromGapStart(DateTime(2026, 10, 30, 0, 0)), 'day');
        // 03:59 early morning
        expect(SleepDetector.inferShiftTypeFromGapStart(DateTime(2026, 10, 30, 3, 59)), 'day');
        // 04:00 boundary
        expect(SleepDetector.inferShiftTypeFromGapStart(DateTime(2026, 10, 30, 4, 0)), 'day');
      });

      test('gap start 08:00 - 14:00 infers night shift', () {
        // 08:00 boundary
        expect(SleepDetector.inferShiftTypeFromGapStart(DateTime(2026, 10, 30, 8, 0)), 'night');
        // 09:30 morning
        expect(SleepDetector.inferShiftTypeFromGapStart(DateTime(2026, 10, 30, 9, 30)), 'night');
        // 13:59 afternoon
        expect(SleepDetector.inferShiftTypeFromGapStart(DateTime(2026, 10, 30, 13, 59)), 'night');
        // 14:00 boundary
        expect(SleepDetector.inferShiftTypeFromGapStart(DateTime(2026, 10, 30, 14, 0)), 'night');
      });

      test('gap start outside windows returns null', () {
        // 04:01 past day window
        expect(SleepDetector.inferShiftTypeFromGapStart(DateTime(2026, 10, 30, 4, 1)), isNull);
        // 07:59 before night window
        expect(SleepDetector.inferShiftTypeFromGapStart(DateTime(2026, 10, 30, 7, 59)), isNull);
        // 14:01 past night window
        expect(SleepDetector.inferShiftTypeFromGapStart(DateTime(2026, 10, 30, 14, 1)), isNull);
        // 17:30 afternoon/evening
        expect(SleepDetector.inferShiftTypeFromGapStart(DateTime(2026, 10, 30, 17, 30)), isNull);
        // 19:59 right before 20:00
        expect(SleepDetector.inferShiftTypeFromGapStart(DateTime(2026, 10, 30, 19, 59)), isNull);
      });
    });
  });
}
