import 'package:private_statistics/features/categories/domain/models/category.dart';
import 'package:private_statistics/features/events/domain/models/event.dart';
import 'package:private_statistics/features/events/domain/models/event_time.dart';
import 'package:private_statistics/features/statistics/domain/models/temporal_proximity_result.dart';

/// Computes [TemporalProximityResult] lists using mode A (ADR-0017).
///
/// Mode A: a source event is counted as "followed" when at least one candidate
/// event falls within the closed interval
/// `[source_time, source_time + timeWindow]`.
///
/// The reference time of an event is its earliest possible moment:
/// - [TimePoint] with `clockTime`: the clock time
/// - [TimePoint] without `clockTime`: midnight of the date
/// - [DayPreciseRange]: midnight of `from`
/// - [DatetimePreciseRange]: the `from` datetime
class TemporalProximityCalculator {
  /// The minimum event count below which a result is flagged as limited data.
  static const int minimumEventCount = 5;

  /// Computes ranked temporal proximity results for all candidate categories.
  ///
  /// [sourceCategoryUid] is excluded from the candidate set. Candidate
  /// categories with no events in [eventsInWindow] are excluded from results.
  /// Results are sorted by [TemporalProximityResult.score] descending.
  List<TemporalProximityResult> compute({
    required String sourceCategoryUid,
    required List<Event> eventsInWindow,
    required List<Category> allCategories,
    required Duration timeWindow,
  }) {
    final sourceEvents = eventsInWindow
        .where((e) => e.categoryUid == sourceCategoryUid)
        .toList();
    if (sourceEvents.isEmpty) return [];

    final sourceTimes = sourceEvents.map(_referenceTime).toList();
    final sourceCount = sourceEvents.length;

    final results = <TemporalProximityResult>[];

    for (final category in allCategories) {
      if (category.uid == sourceCategoryUid) continue;

      final candidateEvents = eventsInWindow
          .where((e) => e.categoryUid == category.uid)
          .toList();
      if (candidateEvents.isEmpty) continue;

      final candidateTimes = candidateEvents.map(_referenceTime).toList();

      var followCount = 0;
      for (final sourceTime in sourceTimes) {
        final windowEnd = sourceTime.add(timeWindow);
        final hasFollow = candidateTimes.any(
          (t) => !t.isBefore(sourceTime) && !t.isAfter(windowEnd),
        );
        if (hasFollow) followCount++;
      }

      results.add(
        TemporalProximityResult(
          candidateCategoryUid: category.uid,
          candidateCategoryName: category.name,
          followCount: followCount,
          sourceEventCount: sourceCount,
          score: followCount / sourceCount,
          hasLimitedData:
              sourceCount < minimumEventCount ||
              candidateEvents.length < minimumEventCount,
        ),
      );
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  DateTime _referenceTime(Event event) {
    return switch (event.occurredAt) {
      TimePoint(:final clockTime) when clockTime != null => clockTime,
      TimePoint(:final date) => DateTime(date.year, date.month, date.day),
      DayPreciseRange(:final from) => DateTime(from.year, from.month, from.day),
      DatetimePreciseRange(:final from) => from,
    };
  }
}
