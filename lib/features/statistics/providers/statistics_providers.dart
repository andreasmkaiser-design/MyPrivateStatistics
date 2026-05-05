import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_statistics/features/categories/domain/models/category.dart';
import 'package:private_statistics/features/categories/domain/models/category_node.dart';
import 'package:private_statistics/features/categories/providers/category_providers.dart';
import 'package:private_statistics/features/events/providers/event_providers.dart';
import 'package:private_statistics/features/statistics/domain/algorithms/co_occurrence_calculator.dart';
import 'package:private_statistics/features/statistics/domain/models/analysis_window.dart';
import 'package:private_statistics/features/statistics/domain/models/co_occurrence_result.dart';

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

List<Category> _flattenTree(List<CategoryNode> nodes) {
  final result = <Category>[];
  for (final node in nodes) {
    result
      ..add(node.category)
      ..addAll(_flattenTree(node.children));
  }
  return result;
}
