import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_statistics/features/categories/domain/models/category.dart';
import 'package:private_statistics/features/categories/domain/models/category_node.dart';
import 'package:private_statistics/features/categories/providers/category_providers.dart';
import 'package:private_statistics/features/events/domain/models/event.dart';
import 'package:private_statistics/features/events/domain/models/event_time.dart';
import 'package:private_statistics/features/events/providers/event_providers.dart';
import 'package:private_statistics/features/statistics/domain/models/analysis_window.dart';
import 'package:private_statistics/features/statistics/domain/models/calendar_data.dart';
import 'package:private_statistics/features/statistics/domain/models/co_occurrence_result.dart';
import 'package:private_statistics/features/statistics/domain/models/temporal_proximity_result.dart';
import 'package:private_statistics/features/statistics/domain/models/time_window.dart';
import 'package:private_statistics/features/statistics/presentation/widgets/co_occurrence_bar_chart.dart';
import 'package:private_statistics/features/statistics/presentation/widgets/co_occurrence_calendar.dart';
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
                const _CalendarSliver(),
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

// ── Calendar section ─────────────────────────────────────────────────────────

class _CalendarSliver extends ConsumerWidget {
  const _CalendarSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calDataAsync = ref.watch(calendarDataProvider);
    final resultsAsync = ref.watch(coOccurrenceResultsProvider);
    final selectedIndex = ref.watch(calendarCandidateIndexProvider);

    return calDataAsync.when(
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (calData) {
        if (calData == null) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        final results = resultsAsync.valueOrNull ?? <CoOccurrenceResult>[];
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Calendar', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                if (results.length > 1)
                  _CandidateChipRow(
                    results: results,
                    selectedIndex: selectedIndex,
                    onSelected: (i) =>
                        ref
                                .read(calendarCandidateIndexProvider.notifier)
                                .state =
                            i,
                  ),
                const SizedBox(height: 4),
                CoOccurrenceCalendar(
                  data: calData,
                  onDayTapped: (date) => _showDaySheet(context, date, calData),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDaySheet(
    BuildContext context,
    DateTime date,
    CalendarData calData,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DayEventsSheet(date: date, calendarData: calData),
    );
  }
}

class _CandidateChipRow extends StatelessWidget {
  const _CandidateChipRow({
    required this.results,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<CoOccurrenceResult> results;
  final int selectedIndex;
  final void Function(int index) onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (var i = 0; i < results.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(results[i].candidateCategoryName),
                selected: i == selectedIndex,
                onSelected: (_) => onSelected(i),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Day-events bottom sheet ──────────────────────────────────────────────────

class _DayEventsSheet extends ConsumerWidget {
  const _DayEventsSheet({required this.date, required this.calendarData});

  final DateTime date;
  final CalendarData calendarData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsByDayProvider(date));
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _formatDate(date),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            eventsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Failed to load events.'),
              data: (events) {
                final sourceEvents = events
                    .where(
                      (e) => e.categoryUid == calendarData.sourceCategoryUid,
                    )
                    .toList();
                final candidateEvents = events
                    .where(
                      (e) => e.categoryUid == calendarData.candidateCategoryUid,
                    )
                    .toList();
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _EventSection(
                      categoryName: calendarData.sourceCategoryName,
                      events: sourceEvents,
                    ),
                    const SizedBox(height: 12),
                    _EventSection(
                      categoryName: calendarData.candidateCategoryName,
                      events: candidateEvents,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _EventSection extends StatelessWidget {
  const _EventSection({required this.categoryName, required this.events});

  final String categoryName;
  final List<Event> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(categoryName, style: Theme.of(context).textTheme.titleSmall),
        if (events.isEmpty)
          const Text('No events on this day.')
        else
          ...events.map(
            (e) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_formatEventTime(e.occurredAt)),
            ),
          ),
      ],
    );
  }

  static String _formatEventTime(EventTime time) => switch (time) {
    TimePoint(:final date, :final clockTime) =>
      clockTime != null ? '${_ymd(date)}, ${_hm(clockTime)}' : _ymd(date),
    DayPreciseRange(:final from, :final to) =>
      from == to ? _ymd(from) : '${_ymd(from)} – ${_ymd(to)}',
    DatetimePreciseRange(:final from, :final to) =>
      '${_ymd(from)} ${_hm(from)} – ${_ymd(to)} ${_hm(to)}',
  };

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}
