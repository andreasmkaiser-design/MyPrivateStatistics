import 'package:private_statistics/features/categories/domain/models/category.dart';
import 'package:private_statistics/features/events/domain/models/event.dart';
import 'package:private_statistics/features/events/domain/models/event_time.dart';
import 'package:private_statistics/features/statistics/domain/models/calendar_data.dart';
import 'package:private_statistics/features/statistics/domain/models/calendar_day_state.dart';
import 'package:private_statistics/features/statistics/domain/models/co_occurrence_result.dart';

/// Computes [CoOccurrenceResult] lists using the Jaccard index (ADR-0017).
///
/// Instantiate once and call [compute] for each source category / window
/// combination. All methods are pure — no I/O or side effects.
class CoOccurrenceCalculator {
  /// The minimum event count below which a result is flagged as limited data.
  static const int minimumEventCount = 5;

  /// Computes ranked co-occurrence results for all candidate categories.
  ///
  /// [sourceCategoryUid] is excluded from the candidate set. Candidate
  /// categories with no events in [eventsInWindow] are excluded from results.
  /// Results are sorted by [CoOccurrenceResult.score] descending.
  ///
  /// Formula (ADR-0017):
  /// `score = |days(A) ∩ days(B)| / |days(A) ∪ days(B)|`
  /// where `days(X)` is the set of distinct calendar days **within the
  /// window** on which category X has at least one event.
  List<CoOccurrenceResult> compute({
    required String sourceCategoryUid,
    required List<Event> eventsInWindow,
    required List<Category> allCategories,
    required DateTime windowFrom,
    required DateTime windowTo,
  }) {
    final countByCategory = <String, int>{};
    for (final event in eventsInWindow) {
      countByCategory[event.categoryUid] =
          (countByCategory[event.categoryUid] ?? 0) + 1;
    }

    final daysByCategory = _buildDaysByCategory(
      eventsInWindow,
      windowFrom,
      windowTo,
    );

    final sourceDays = daysByCategory[sourceCategoryUid] ?? {};
    final sourceCount = countByCategory[sourceCategoryUid] ?? 0;

    final results = <CoOccurrenceResult>[];
    for (final category in allCategories) {
      if (category.uid == sourceCategoryUid) continue;
      final candidateDays = daysByCategory[category.uid];
      if (candidateDays == null || candidateDays.isEmpty) continue;

      final candidateCount = countByCategory[category.uid] ?? 0;
      final intersection = sourceDays.intersection(candidateDays);
      final union = sourceDays.union(candidateDays);
      final score = union.isEmpty ? 0.0 : intersection.length / union.length;

      results.add(
        CoOccurrenceResult(
          candidateCategoryUid: category.uid,
          candidateCategoryName: category.name,
          sharedDays: intersection.length,
          unionDays: union.length,
          score: score,
          hasLimitedData:
              sourceCount < minimumEventCount ||
              candidateCount < minimumEventCount,
        ),
      );
    }
    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  Map<String, Set<DateTime>> _buildDaysByCategory(
    List<Event> events,
    DateTime windowFrom,
    DateTime windowTo,
  ) {
    final fromDay = DateTime(windowFrom.year, windowFrom.month, windowFrom.day);
    final toDay = DateTime(windowTo.year, windowTo.month, windowTo.day);
    final map = <String, Set<DateTime>>{};
    for (final event in events) {
      final days = _eventDaysInWindow(event.occurredAt, fromDay, toDay);
      map.putIfAbsent(event.categoryUid, () => {}).addAll(days);
    }
    return map;
  }

  Set<DateTime> _eventDaysInWindow(
    EventTime time,
    DateTime windowFromDay,
    DateTime windowToDay,
  ) {
    switch (time) {
      case TimePoint(:final date):
        final day = DateTime(date.year, date.month, date.day);
        if (day.isBefore(windowFromDay) || day.isAfter(windowToDay)) {
          return {};
        }
        return {day};
      case DayPreciseRange(:final from, :final to):
        return _dayRange(
          from.isBefore(windowFromDay) ? windowFromDay : from,
          to.isAfter(windowToDay) ? windowToDay : to,
        );
      case DatetimePreciseRange(:final from, :final to):
        final fromDay = DateTime(from.year, from.month, from.day);
        final toDay = DateTime(to.year, to.month, to.day);
        return _dayRange(
          fromDay.isBefore(windowFromDay) ? windowFromDay : fromDay,
          toDay.isAfter(windowToDay) ? windowToDay : toDay,
        );
    }
  }

  /// Builds a [CalendarData] value object for a specific source/candidate pair.
  ///
  /// Selects the candidate at [candidateIndex] from the pre-sorted [results]
  /// list (0 = top-ranked). Returns `null` when [results] is empty or
  /// [candidateIndex] is out of range.
  ///
  /// Every calendar day from [windowFrom] to [windowTo] inclusive is present
  /// in [CalendarData.stateByDay], classified as [CalendarDayState.both],
  /// [CalendarDayState.sourceOnly], [CalendarDayState.candidateOnly], or
  /// [CalendarDayState.neither].
  CalendarData? buildCalendarData({
    required String sourceCategoryUid,
    required String sourceCategoryName,
    required List<CoOccurrenceResult> results,
    required int candidateIndex,
    required List<Event> eventsInWindow,
    required DateTime windowFrom,
    required DateTime windowTo,
  }) {
    if (results.isEmpty || candidateIndex >= results.length) return null;

    final candidate = results[candidateIndex];
    final daysByCategory = _buildDaysByCategory(
      eventsInWindow,
      windowFrom,
      windowTo,
    );
    final sourceDays = daysByCategory[sourceCategoryUid] ?? const <DateTime>{};
    final candidateDays =
        daysByCategory[candidate.candidateCategoryUid] ?? const <DateTime>{};

    final stateByDay = <DateTime, CalendarDayState>{};
    var cursor = DateTime(windowFrom.year, windowFrom.month, windowFrom.day);
    final lastDay = DateTime(windowTo.year, windowTo.month, windowTo.day);
    while (!cursor.isAfter(lastDay)) {
      final inSource = sourceDays.contains(cursor);
      final inCandidate = candidateDays.contains(cursor);
      stateByDay[cursor] = switch ((inSource, inCandidate)) {
        (true, true) => CalendarDayState.both,
        (true, false) => CalendarDayState.sourceOnly,
        (false, true) => CalendarDayState.candidateOnly,
        (false, false) => CalendarDayState.neither,
      };
      cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
    }

    return CalendarData(
      windowFrom: windowFrom,
      windowTo: windowTo,
      sourceCategoryUid: sourceCategoryUid,
      sourceCategoryName: sourceCategoryName,
      candidateCategoryUid: candidate.candidateCategoryUid,
      candidateCategoryName: candidate.candidateCategoryName,
      stateByDay: stateByDay,
    );
  }

  Set<DateTime> _dayRange(DateTime from, DateTime to) {
    if (from.isAfter(to)) return {};
    final days = <DateTime>{};
    var current = DateTime(from.year, from.month, from.day);
    final last = DateTime(to.year, to.month, to.day);
    while (!current.isAfter(last)) {
      days.add(current);
      current = DateTime(current.year, current.month, current.day + 1);
    }
    return days;
  }
}
