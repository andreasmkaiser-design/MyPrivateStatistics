import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_statistics/features/categories/domain/models/category.dart';
import 'package:private_statistics/features/categories/domain/models/category_node.dart';
import 'package:private_statistics/features/categories/providers/category_providers.dart';
import 'package:private_statistics/features/events/providers/event_providers.dart';
import 'package:private_statistics/features/statistics/domain/algorithms/co_occurrence_calculator.dart';
import 'package:private_statistics/features/statistics/domain/algorithms/temporal_proximity_calculator.dart';
import 'package:private_statistics/features/statistics/domain/models/analysis_window.dart';
import 'package:private_statistics/features/statistics/domain/models/co_occurrence_result.dart';
import 'package:private_statistics/features/statistics/domain/models/temporal_proximity_result.dart';
import 'package:private_statistics/features/statistics/domain/models/time_window.dart';

/// The UID of the source `Category` selected on the Statistics tab.
///
/// `null` means no category has been selected yet.
final statisticsSourceCategoryProvider = StateProvider<String?>((ref) => null);

/// The `AnalysisWindow` selected on the Statistics tab.
///
/// Defaults to the last 30 calendar days.
final statisticsAnalysisWindowProvider = StateProvider<AnalysisWindow>(
  (ref) => const LastNDaysWindow(30),
);

/// The `TimeWindow` used for Temporal Proximity analysis on the Statistics tab.
///
/// Defaults to 24 hours. Persists while the app is running — switching away
/// from the Statistics tab and back restores the last selection (ADR-0009).
final statisticsTimeWindowProvider = StateProvider<TimeWindow>(
  (ref) => const HoursTimeWindow(24),
);

/// Preset [TimeWindow] options shown in the time window selector.
const statisticsTimeWindowOptions = [
  HoursTimeWindow(24),
  HoursTimeWindow(48),
  DaysTimeWindow(7),
];

/// Ranked [CoOccurrenceResult] list for the current source category and
/// analysis window.
///
/// Returns an empty list when no source category is selected. Recomputes
/// whenever the source category, analysis window, or category tree changes
/// (ADR-0009).
final coOccurrenceResultsProvider = FutureProvider<List<CoOccurrenceResult>>((
  ref,
) async {
  final sourceCategoryUid = ref.watch(statisticsSourceCategoryProvider);
  if (sourceCategoryUid == null) return [];

  final window = ref.watch(statisticsAnalysisWindowProvider);
  final categoryTree = await ref.watch(categoryTreeProvider.future);
  final eventsInWindow = await ref
      .read(eventRepositoryProvider)
      .findInWindow(window.from, window.to);

  final allCategories = _flattenTree(categoryTree);

  return CoOccurrenceCalculator().compute(
    sourceCategoryUid: sourceCategoryUid,
    eventsInWindow: eventsInWindow,
    allCategories: allCategories,
    windowFrom: window.from,
    windowTo: window.to,
  );
});

/// Ranked [TemporalProximityResult] list for the current source category,
/// analysis window, and time window.
///
/// Returns an empty list when no source category is selected. Recomputes
/// whenever the source category, analysis window, time window, or category
/// tree changes (ADR-0009).
final temporalProximityResultsProvider =
    FutureProvider<List<TemporalProximityResult>>((ref) async {
      final sourceCategoryUid = ref.watch(statisticsSourceCategoryProvider);
      if (sourceCategoryUid == null) return [];

      final window = ref.watch(statisticsAnalysisWindowProvider);
      final timeWindow = ref.watch(statisticsTimeWindowProvider);
      final categoryTree = await ref.watch(categoryTreeProvider.future);
      final eventsInWindow = await ref
          .read(eventRepositoryProvider)
          .findInWindow(window.from, window.to);

      final allCategories = _flattenTree(categoryTree);

      return TemporalProximityCalculator().compute(
        sourceCategoryUid: sourceCategoryUid,
        eventsInWindow: eventsInWindow,
        allCategories: allCategories,
        timeWindow: timeWindow.duration,
      );
    });

List<Category> _flattenTree(List<CategoryNode> nodes) {
  final result = <Category>[];
  for (final node in nodes) {
    result
      ..add(node.category)
      ..addAll(_flattenTree(node.children));
  }
  return result;
}
