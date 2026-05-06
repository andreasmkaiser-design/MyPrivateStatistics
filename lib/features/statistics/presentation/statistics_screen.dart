import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_statistics/features/categories/domain/models/category.dart';
import 'package:private_statistics/features/categories/domain/models/category_node.dart';
import 'package:private_statistics/features/categories/providers/category_providers.dart';
import 'package:private_statistics/features/statistics/domain/models/analysis_window.dart';
import 'package:private_statistics/features/statistics/domain/models/co_occurrence_result.dart';
import 'package:private_statistics/features/statistics/domain/models/temporal_proximity_result.dart';
import 'package:private_statistics/features/statistics/domain/models/time_window.dart';
import 'package:private_statistics/features/statistics/presentation/widgets/co_occurrence_bar_chart.dart';
import 'package:private_statistics/features/statistics/presentation/widgets/kpi_card.dart';
import 'package:private_statistics/features/statistics/presentation/widgets/temporal_proximity_kpi_card.dart';
import 'package:private_statistics/features/statistics/presentation/widgets/time_window_selector.dart';
import 'package:private_statistics/features/statistics/providers/statistics_providers.dart';

/// The Statistics tab — source category selector, analysis window picker,
/// Co-Occurrence results, time window picker, and Temporal Proximity results.
///
/// Computation is triggered on-demand whenever the source category, analysis
/// window, or time window changes (ADR-0009). Co-Occurrence uses the Jaccard
/// index; Temporal Proximity uses mode A (ADR-0017).
class StatisticsScreen extends ConsumerWidget {
  /// Creates the [StatisticsScreen].
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeAsync = ref.watch(categoryTreeProvider);
    final sourceCategoryUid = ref.watch(statisticsSourceCategoryProvider);
    final window = ref.watch(statisticsAnalysisWindowProvider);
    final timeWindow = ref.watch(statisticsTimeWindowProvider);
    final coOccurrenceAsync = ref.watch(coOccurrenceResultsProvider);
    final proximityAsync = ref.watch(temporalProximityResultsProvider);

    return Scaffold(
      body: treeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Failed to load categories.')),
        data: (tree) {
          final allCategories = _flattenTree(tree);
          final sourceName = allCategories
              .where((c) => c.uid == sourceCategoryUid)
              .map((c) => c.name)
              .firstOrNull;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Source category',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                        isEmpty: sourceCategoryUid == null,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: sourceCategoryUid,
                            isExpanded: true,
                            isDense: true,
                            hint: const Text('Select a category'),
                            items: allCategories
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c.uid,
                                    child: Text(c.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (uid) =>
                                ref
                                        .read(
                                          statisticsSourceCategoryProvider
                                              .notifier,
                                        )
                                        .state =
                                    uid,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _WindowPicker(
                        window: window,
                        onChanged: (w) =>
                            ref
                                    .read(
                                      statisticsAnalysisWindowProvider.notifier,
                                    )
                                    .state =
                                w,
                      ),
                    ],
                  ),
                ),
              ),
              if (sourceCategoryUid == null)
                const SliverFillRemaining(
                  child: Center(
                    child: Text('Select a category to see correlations.'),
                  ),
                )
              else ...[
                _CoOccurrenceSliver(
                  resultsAsync: coOccurrenceAsync,
                  sourceName: sourceName ?? '',
                ),
                _ProximitySliver(
                  resultsAsync: proximityAsync,
                  sourceName: sourceName ?? '',
                  timeWindow: timeWindow,
                  onTimeWindowChanged: (w) =>
                      ref.read(statisticsTimeWindowProvider.notifier).state = w,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  List<Category> _flattenTree(List<CategoryNode> nodes) {
    final result = <Category>[];
    for (final node in nodes) {
      result
        ..add(node.category)
        ..addAll(_flattenTree(node.children));
    }
    return result;
  }
}

class _WindowPicker extends StatelessWidget {
  const _WindowPicker({required this.window, required this.onChanged});

  final AnalysisWindow window;
  final ValueChanged<AnalysisWindow> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedDays = switch (window) {
      LastNDaysWindow(:final days) => days,
      CustomWindow() => 30,
    };

    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 30, label: Text('30 days')),
        ButtonSegment(value: 60, label: Text('60 days')),
        ButtonSegment(value: 90, label: Text('90 days')),
      ],
      selected: {selectedDays},
      onSelectionChanged: (selection) =>
          onChanged(LastNDaysWindow(selection.first)),
    );
  }
}

class _CoOccurrenceSliver extends StatelessWidget {
  const _CoOccurrenceSliver({
    required this.resultsAsync,
    required this.sourceName,
  });

  final AsyncValue<List<CoOccurrenceResult>> resultsAsync;
  final String sourceName;

  @override
  Widget build(BuildContext context) {
    return resultsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Failed to compute Co-Occurrence statistics.'),
        ),
      ),
      data: (results) {
        if (results.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text('No co-occurrence data in this window.'),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Co-Occurrence',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SizedBox(
                height: 200,
                child: CoOccurrenceBarChart(results: results),
              ),
            ),
            ...results.map(
              (r) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: KpiCard(sourceCategoryName: sourceName, result: r),
              ),
            ),
          ]),
        );
      },
    );
  }
}

class _ProximitySliver extends StatelessWidget {
  const _ProximitySliver({
    required this.resultsAsync,
    required this.sourceName,
    required this.timeWindow,
    required this.onTimeWindowChanged,
  });

  final AsyncValue<List<TemporalProximityResult>> resultsAsync;
  final String sourceName;
  final TimeWindow timeWindow;
  final ValueChanged<TimeWindow> onTimeWindowChanged;

  @override
  Widget build(BuildContext context) {
    return resultsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Failed to compute Temporal Proximity statistics.'),
        ),
      ),
      data: (results) {
        return SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Temporal Proximity',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TimeWindowSelector(
                selected: timeWindow,
                options: statisticsTimeWindowOptions,
                onChanged: onTimeWindowChanged,
              ),
            ),
            if (results.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text('No temporal proximity data in this window.'),
              )
            else
              ...results.map(
                (r) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: TemporalProximityKpiCard(
                    sourceCategoryName: sourceName,
                    result: r,
                    timeWindowLabel: timeWindow.label,
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ]),
        );
      },
    );
  }
}
