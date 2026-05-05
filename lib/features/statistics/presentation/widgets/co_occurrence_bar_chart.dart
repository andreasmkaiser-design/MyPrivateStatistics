import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:private_statistics/features/statistics/domain/models/co_occurrence_result.dart';

/// Maximum number of bars rendered in the chart.
const _maxBars = 8;

/// A vertical bar chart showing co-occurrence scores for the top candidate
/// categories, ordered by [CoOccurrenceResult.score] descending.
///
/// The Y axis represents Correlation Strength (Jaccard score, 0.0–1.0).
/// The X axis labels show abbreviated candidate category names.
/// At most [_maxBars] results are shown for readability.
class CoOccurrenceBarChart extends StatelessWidget {
  /// Creates a [CoOccurrenceBarChart].
  const CoOccurrenceBarChart({required this.results, super.key});

  /// Pre-sorted list of co-occurrence results (highest score first).
  final List<CoOccurrenceResult> results;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = results.take(_maxBars).toList();

    final barGroups = <BarChartGroupData>[];
    for (var i = 0; i < visible.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: visible[i].score,
              color: theme.colorScheme.primary,
              width: 20,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        maxY: 1,
        minY: 0,
        barGroups: barGroups,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: const BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: 0.5,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(1),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= visible.length) {
                  return const SizedBox.shrink();
                }
                final label = visible[idx].candidateCategoryName;
                final truncated = label.length > 10
                    ? '${label.substring(0, 9)}…'
                    : label;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    truncated,
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
