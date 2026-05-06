import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/features/categories/domain/models/category.dart';
import 'package:private_statistics/features/categories/domain/models/time_model.dart';
import 'package:private_statistics/features/events/domain/models/event.dart';
import 'package:private_statistics/features/events/domain/models/event_time.dart';
import 'package:private_statistics/features/statistics/domain/algorithms/temporal_proximity_calculator.dart';

void main() {
  final calc = TemporalProximityCalculator();

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

  const window24h = Duration(hours: 24);

  Event makePoint(String uid, String categoryUid, DateTime dateTime) => Event(
    uid: uid,
    categoryUid: categoryUid,
    occurredAt: TimePoint(date: dateTime, clockTime: dateTime),
    fieldValues: const [],
  );

  Event makeDayPoint(String uid, String categoryUid, DateTime date) => Event(
    uid: uid,
    categoryUid: categoryUid,
    occurredAt: TimePoint(date: date),
    fieldValues: const [],
  );

  final base = DateTime(2024, 1, 1, 10); // 10:00

  group('TemporalProximityCalculator.compute', () {
    test('returns empty list when source has zero events', () {
      final results = calc.compute(
        sourceCategoryUid: 'a',
        eventsInWindow: [makePoint('b1', 'b', base)],
        allCategories: [catA, catB],
        timeWindow: window24h,
      );
      expect(results, isEmpty);
    });

    test('score is 0% when no candidate events follow within window', () {
      // source at 10:00; candidate at 10:00 of day BEFORE (before source)
      final before = base.subtract(const Duration(hours: 1));
      final results = calc.compute(
        sourceCategoryUid: 'a',
        eventsInWindow: [
          makePoint('a1', 'a', base),
          makePoint('b1', 'b', before),
        ],
        allCategories: [catA, catB],
        timeWindow: window24h,
      );
      expect(results.length, 1);
      expect(results.first.score, 0.0);
      expect(results.first.followCount, 0);
    });

    test('score is 100% when every source event is followed within window', () {
      final after = base.add(const Duration(hours: 2));
      final source2 = DateTime(2024, 1, 2, 10);
      final after2 = source2.add(const Duration(hours: 3));
      final results = calc.compute(
        sourceCategoryUid: 'a',
        eventsInWindow: [
          makePoint('a1', 'a', base),
          makePoint('a2', 'a', source2),
          makePoint('b1', 'b', after),
          makePoint('b2', 'b', after2),
        ],
        allCategories: [catA, catB],
        timeWindow: window24h,
      );
      expect(results.first.score, closeTo(1.0, 0.001));
      expect(results.first.followCount, 2);
      expect(results.first.sourceEventCount, 2);
    });

    test('correct percentage for partial follow-through', () {
      // 3 source events, 2 are followed → 2/3
      final source1 = DateTime(2024, 1, 1, 10);
      final source2 = DateTime(2024, 1, 2, 10);
      final source3 = DateTime(2024, 1, 3, 10);
      // B after source1 and source2, but nothing within 24h after source3
      final b1 = source1.add(const Duration(hours: 5));
      final b2 = source2.add(const Duration(hours: 12));
      final results = calc.compute(
        sourceCategoryUid: 'a',
        eventsInWindow: [
          makePoint('a1', 'a', source1),
          makePoint('a2', 'a', source2),
          makePoint('a3', 'a', source3),
          makePoint('b1', 'b', b1),
          makePoint('b2', 'b', b2),
        ],
        allCategories: [catA, catB],
        timeWindow: window24h,
      );
      expect(results.first.score, closeTo(2 / 3, 0.001));
      expect(results.first.followCount, 2);
    });

    test('event exactly at window boundary is included', () {
      // candidate at exactly source + 24h (boundary, closed interval)
      final exactly = base.add(window24h);
      final results = calc.compute(
        sourceCategoryUid: 'a',
        eventsInWindow: [
          makePoint('a1', 'a', base),
          makePoint('b1', 'b', exactly),
        ],
        allCategories: [catA, catB],
        timeWindow: window24h,
      );
      expect(results.first.score, closeTo(1.0, 0.001));
      expect(results.first.followCount, 1);
    });

    test('event one millisecond past boundary is excluded', () {
      final justOver = base.add(window24h).add(const Duration(milliseconds: 1));
      final results = calc.compute(
        sourceCategoryUid: 'a',
        eventsInWindow: [
          makePoint('a1', 'a', base),
          makePoint('b1', 'b', justOver),
        ],
        allCategories: [catA, catB],
        timeWindow: window24h,
      );
      expect(results.first.score, 0.0);
    });

    test('candidates with zero events in window are excluded from results', () {
      final results = calc.compute(
        sourceCategoryUid: 'a',
        eventsInWindow: [
          makePoint('a1', 'a', base),
          // catB has no events
        ],
        allCategories: [catA, catB],
        timeWindow: window24h,
      );
      expect(results, isEmpty);
    });

    test('results are sorted by score descending', () {
      const catC = Category(
        uid: 'c',
        name: 'C',
        timeModel: TimeModel.timePoint,
        ownFields: [],
      );
      // B follows all 2 source events; C follows only 1
      final s1 = DateTime(2024, 1, 1, 10);
      final s2 = DateTime(2024, 1, 2, 10);
      final results = calc.compute(
        sourceCategoryUid: 'a',
        eventsInWindow: [
          makePoint('a1', 'a', s1),
          makePoint('a2', 'a', s2),
          makePoint('b1', 'b', s1.add(const Duration(hours: 1))),
          makePoint('b2', 'b', s2.add(const Duration(hours: 1))),
          makePoint('c1', 'c', s1.add(const Duration(hours: 1))),
          // no C event follows s2
        ],
        allCategories: [catA, catB, catC],
        timeWindow: window24h,
      );
      expect(results.length, 2);
      expect(results[0].score, greaterThanOrEqualTo(results[1].score));
      expect(results[0].candidateCategoryUid, 'b');
    });

    test('hasLimitedData is true when source has fewer than 5 events', () {
      final results = calc.compute(
        sourceCategoryUid: 'a',
        eventsInWindow: [
          makePoint('a1', 'a', base),
          makePoint('b1', 'b', base.add(const Duration(hours: 1))),
        ],
        allCategories: [catA, catB],
        timeWindow: window24h,
      );
      expect(results.first.hasLimitedData, isTrue);
    });

    test('hasLimitedData is false when both categories have 5+ events', () {
      final events = [
        for (var i = 0; i < 5; i++)
          makePoint('a$i', 'a', DateTime(2024, 1, i + 1, 10)),
        for (var i = 0; i < 5; i++)
          makePoint(
            'b$i',
            'b',
            DateTime(2024, 1, i + 1, 10).add(const Duration(hours: 1)),
          ),
      ];
      final results = calc.compute(
        sourceCategoryUid: 'a',
        eventsInWindow: events,
        allCategories: [catA, catB],
        timeWindow: window24h,
      );
      expect(results.first.hasLimitedData, isFalse);
    });

    test('uses start of day for day-precision TimePoint (no clockTime)', () {
      // Source: day-precision at 2024-01-01 (treated as 00:00)
      // Candidate: 6 hours later (00:00 + 6h = 06:00) — within 24h
      final sourceDay = DateTime(2024);
      final candidateTime = DateTime(2024, 1, 1, 6);
      final results = calc.compute(
        sourceCategoryUid: 'a',
        eventsInWindow: [
          makeDayPoint('a1', 'a', sourceDay),
          makePoint('b1', 'b', candidateTime),
        ],
        allCategories: [catA, catB],
        timeWindow: window24h,
      );
      expect(results.first.score, closeTo(1.0, 0.001));
    });

    test('uses from datetime for DatetimePreciseRange', () {
      final from = DateTime(2024, 1, 1, 10);
      final to = DateTime(2024, 1, 3, 10);
      final candidate = from.add(const Duration(hours: 3));
      final rangeEvent = Event(
        uid: 'a1',
        categoryUid: 'a',
        occurredAt: DatetimePreciseRange(from: from, to: to),
        fieldValues: const [],
      );
      final results = calc.compute(
        sourceCategoryUid: 'a',
        eventsInWindow: [rangeEvent, makePoint('b1', 'b', candidate)],
        allCategories: [catA, catB],
        timeWindow: window24h,
      );
      expect(results.first.score, closeTo(1.0, 0.001));
    });
  });
}
