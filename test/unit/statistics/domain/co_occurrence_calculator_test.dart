import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/features/categories/domain/models/category.dart';
import 'package:private_statistics/features/categories/domain/models/time_model.dart';
import 'package:private_statistics/features/events/domain/models/event.dart';
import 'package:private_statistics/features/events/domain/models/event_time.dart';
import 'package:private_statistics/features/statistics/domain/algorithms/co_occurrence_calculator.dart';

void main() {
  final calc = CoOccurrenceCalculator();

  const catA = Category(
    uid: 'a',
    name: 'A',
    timeModel: TimeModel.timePoint,
    ownFields: [],
  );
  const catB = Category(
    uid: 'b',
    name: 'B',
    timeModel: TimeModel.timePoint,
    ownFields: [],
  );
  const catC = Category(
    uid: 'c',
    name: 'C',
    timeModel: TimeModel.timePoint,
    ownFields: [],
  );

  final windowFrom = DateTime(2024);
  final windowTo = DateTime(2024, 1, 31);

  Event makeEvent(String uid, String categoryUid, DateTime date) => Event(
    uid: uid,
    categoryUid: categoryUid,
    occurredAt: TimePoint(date: date),
    fieldValues: const [],
  );

  group('CoOccurrenceCalculator.compute', () {
    test('score is 0 when categories never share a day', () {
      final events = [
        makeEvent('e1', 'a', DateTime(2024)),
        makeEvent('e2', 'b', DateTime(2024, 1, 2)),
      ];
      final results = calc.compute(
        sourceCategoryUid: 'a',
        eventsInWindow: events,
        allCategories: [catA, catB],
        windowFrom: windowFrom,
        windowTo: windowTo,
      );
      expect(results.length, 1);
      expect(results.first.score, 0.0);
    });

    test('score is correct for partial overlap', () {
      // A: days 1,2,3 | B: days 2,3,4 → intersection={2,3} union={1,2,3,4}
      // Jaccard = 2/4 = 0.5
      final events = [
        makeEvent('e1', 'a', DateTime(2024)),
        makeEvent('e2', 'a', DateTime(2024, 1, 2)),
        makeEvent('e3', 'a', DateTime(2024, 1, 3)),
        makeEvent('e4', 'b', DateTime(2024, 1, 2)),
        makeEvent('e5', 'b', DateTime(2024, 1, 3)),
        makeEvent('e6', 'b', DateTime(2024, 1, 4)),
      ];
      final results = calc.compute(
        sourceCategoryUid: 'a',
        eventsInWindow: events,
        allCategories: [catA, catB],
        windowFrom: windowFrom,
        windowTo: windowTo,
      );
      expect(results.first.score, closeTo(0.5, 0.001));
      expect(results.first.sharedDays, 2);
      expect(results.first.unionDays, 4);
    });

    test('score is 1.0 for full overlap', () {
      final events = [
        makeEvent('e1', 'a', DateTime(2024)),
        makeEvent('e2', 'a', DateTime(2024, 1, 2)),
        makeEvent('e3', 'a', DateTime(2024, 1, 3)),
        makeEvent('e4', 'b', DateTime(2024)),
        makeEvent('e5', 'b', DateTime(2024, 1, 2)),
        makeEvent('e6', 'b', DateTime(2024, 1, 3)),
      ];
      final results = calc.compute(
        sourceCategoryUid: 'a',
        eventsInWindow: events,
        allCategories: [catA, catB],
        windowFrom: windowFrom,
        windowTo: windowTo,
      );
      expect(results.first.score, closeTo(1.0, 0.001));
    });

    test('categories with zero events in the window are excluded', () {
      final events = [
        makeEvent('e1', 'a', DateTime(2024)),
        // catB has no events
      ];
      final results = calc.compute(
        sourceCategoryUid: 'a',
        eventsInWindow: events,
        allCategories: [catA, catB],
        windowFrom: windowFrom,
        windowTo: windowTo,
      );
      expect(results, isEmpty);
    });

    test('results are sorted by correlation strength descending', () {
      // B shares all 3 days with A; C shares only 1 day
      final events = [
        makeEvent('e1', 'a', DateTime(2024)),
        makeEvent('e2', 'a', DateTime(2024, 1, 2)),
        makeEvent('e3', 'a', DateTime(2024, 1, 3)),
        makeEvent('e4', 'b', DateTime(2024)),
        makeEvent('e5', 'b', DateTime(2024, 1, 2)),
        makeEvent('e6', 'b', DateTime(2024, 1, 3)),
        makeEvent('e7', 'c', DateTime(2024)),
      ];
      final results = calc.compute(
        sourceCategoryUid: 'a',
        eventsInWindow: events,
        allCategories: [catA, catB, catC],
        windowFrom: windowFrom,
        windowTo: windowTo,
      );
      expect(results.length, 2);
      expect(results[0].score, greaterThanOrEqualTo(results[1].score));
      expect(results[0].candidateCategoryUid, 'b');
    });

    test('hasLimitedData is true when source has fewer than 5 events', () {
      final events = [
        makeEvent('e1', 'a', DateTime(2024)),
        makeEvent('e2', 'b', DateTime(2024)),
      ];
      final results = calc.compute(
        sourceCategoryUid: 'a',
        eventsInWindow: events,
        allCategories: [catA, catB],
        windowFrom: windowFrom,
        windowTo: windowTo,
      );
      expect(results.first.hasLimitedData, isTrue);
    });

    test('hasLimitedData is false when both categories have 5+ events', () {
      final events = [
        for (var i = 1; i <= 5; i++)
          makeEvent('a$i', 'a', DateTime(2024, 1, i)),
        for (var i = 1; i <= 5; i++)
          makeEvent('b$i', 'b', DateTime(2024, 1, i)),
      ];
      final results = calc.compute(
        sourceCategoryUid: 'a',
        eventsInWindow: events,
        allCategories: [catA, catB],
        windowFrom: windowFrom,
        windowTo: windowTo,
      );
      expect(results.first.hasLimitedData, isFalse);
    });
  });
}
