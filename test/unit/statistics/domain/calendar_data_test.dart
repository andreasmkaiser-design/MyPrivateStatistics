import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/features/events/domain/models/event.dart';
import 'package:private_statistics/features/events/domain/models/event_time.dart';
import 'package:private_statistics/features/statistics/domain/algorithms/co_occurrence_calculator.dart';
import 'package:private_statistics/features/statistics/domain/models/calendar_day_state.dart';
import 'package:private_statistics/features/statistics/domain/models/co_occurrence_result.dart';

void main() {
  final calc = CoOccurrenceCalculator();

  final windowFrom = DateTime(2024);
  final windowTo = DateTime(2024, 1, 7);

  Event makeEvent(String uid, String categoryUid, DateTime date) => Event(
    uid: uid,
    categoryUid: categoryUid,
    occurredAt: TimePoint(date: date),
    fieldValues: const [],
  );

  CoOccurrenceResult makeResult(String uid, String name) => CoOccurrenceResult(
    candidateCategoryUid: uid,
    candidateCategoryName: name,
    sharedDays: 1,
    unionDays: 2,
    score: 0.5,
    hasLimitedData: false,
  );

  group('CoOccurrenceCalculator.buildCalendarData', () {
    test('returns null when results list is empty', () {
      final data = calc.buildCalendarData(
        sourceCategoryUid: 'a',
        sourceCategoryName: 'A',
        results: const [],
        candidateIndex: 0,
        eventsInWindow: [],
        windowFrom: windowFrom,
        windowTo: windowTo,
      );
      expect(data, isNull);
    });

    test('returns null when candidateIndex is out of range', () {
      final data = calc.buildCalendarData(
        sourceCategoryUid: 'a',
        sourceCategoryName: 'A',
        results: [makeResult('b', 'B')],
        candidateIndex: 1,
        eventsInWindow: [],
        windowFrom: windowFrom,
        windowTo: windowTo,
      );
      expect(data, isNull);
    });

    test(
      'classifies a day as both when source and candidate both have events',
      () {
        final events = [
          makeEvent('e1', 'a', DateTime(2024)),
          makeEvent('e2', 'b', DateTime(2024)),
        ];
        final data = calc.buildCalendarData(
          sourceCategoryUid: 'a',
          sourceCategoryName: 'A',
          results: [makeResult('b', 'B')],
          candidateIndex: 0,
          eventsInWindow: events,
          windowFrom: windowFrom,
          windowTo: windowTo,
        );
        expect(data, isNotNull);
        expect(data!.stateByDay[DateTime(2024)], CalendarDayState.both);
      },
    );

    test('classifies a day as sourceOnly when only source has an event', () {
      final events = [makeEvent('e1', 'a', DateTime(2024))];
      final data = calc.buildCalendarData(
        sourceCategoryUid: 'a',
        sourceCategoryName: 'A',
        results: [makeResult('b', 'B')],
        candidateIndex: 0,
        eventsInWindow: events,
        windowFrom: windowFrom,
        windowTo: windowTo,
      );
      expect(data!.stateByDay[DateTime(2024)], CalendarDayState.sourceOnly);
    });

    test(
      'classifies a day as candidateOnly when only candidate has an event',
      () {
        final events = [makeEvent('e1', 'b', DateTime(2024, 1, 2))];
        final data = calc.buildCalendarData(
          sourceCategoryUid: 'a',
          sourceCategoryName: 'A',
          results: [makeResult('b', 'B')],
          candidateIndex: 0,
          eventsInWindow: events,
          windowFrom: windowFrom,
          windowTo: windowTo,
        );
        expect(
          data!.stateByDay[DateTime(2024, 1, 2)],
          CalendarDayState.candidateOnly,
        );
      },
    );

    test('classifies a day as neither when no events on that day', () {
      final events = [makeEvent('e1', 'a', DateTime(2024))];
      final data = calc.buildCalendarData(
        sourceCategoryUid: 'a',
        sourceCategoryName: 'A',
        results: [makeResult('b', 'B')],
        candidateIndex: 0,
        eventsInWindow: events,
        windowFrom: windowFrom,
        windowTo: windowTo,
      );
      expect(data!.stateByDay[DateTime(2024, 1, 3)], CalendarDayState.neither);
    });

    test('stateByDay contains every day in the window', () {
      final data = calc.buildCalendarData(
        sourceCategoryUid: 'a',
        sourceCategoryName: 'A',
        results: [makeResult('b', 'B')],
        candidateIndex: 0,
        eventsInWindow: [],
        windowFrom: windowFrom,
        windowTo: windowTo,
      );
      // windowFrom=Jan 1, windowTo=Jan 7 → 7 days
      expect(data!.stateByDay.length, 7);
      for (var i = 1; i <= 7; i++) {
        expect(data.stateByDay.containsKey(DateTime(2024, 1, i)), isTrue);
      }
    });

    test('uses candidateIndex to select the correct candidate', () {
      final events = [
        makeEvent('e1', 'a', DateTime(2024)),
        makeEvent('e2', 'c', DateTime(2024)),
      ];
      // results[0]=B, results[1]=C — select index 1 → should see C events
      final data = calc.buildCalendarData(
        sourceCategoryUid: 'a',
        sourceCategoryName: 'A',
        results: [makeResult('b', 'B'), makeResult('c', 'C')],
        candidateIndex: 1,
        eventsInWindow: events,
        windowFrom: windowFrom,
        windowTo: windowTo,
      );
      expect(data!.candidateCategoryUid, 'c');
      expect(data.stateByDay[DateTime(2024)], CalendarDayState.both);
    });

    test('populates CalendarData metadata fields correctly', () {
      final data = calc.buildCalendarData(
        sourceCategoryUid: 'a',
        sourceCategoryName: 'Alpha',
        results: [makeResult('b', 'Beta')],
        candidateIndex: 0,
        eventsInWindow: [],
        windowFrom: windowFrom,
        windowTo: windowTo,
      );
      expect(data!.sourceCategoryUid, 'a');
      expect(data.sourceCategoryName, 'Alpha');
      expect(data.candidateCategoryUid, 'b');
      expect(data.candidateCategoryName, 'Beta');
      expect(data.windowFrom, windowFrom);
      expect(data.windowTo, windowTo);
    });
  });
}
