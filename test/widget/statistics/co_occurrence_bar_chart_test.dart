import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/features/statistics/domain/models/co_occurrence_result.dart';
import 'package:private_statistics/features/statistics/presentation/widgets/co_occurrence_bar_chart.dart';

void main() {
  group('CoOccurrenceBarChart', () {
    testWidgets('renders correct number of bars', (tester) async {
      final results = [
        const CoOccurrenceResult(
          candidateCategoryUid: 'b',
          candidateCategoryName: 'Running',
          sharedDays: 5,
          unionDays: 10,
          score: 0.5,
          hasLimitedData: false,
        ),
        const CoOccurrenceResult(
          candidateCategoryUid: 'c',
          candidateCategoryName: 'Sleep',
          sharedDays: 3,
          unionDays: 10,
          score: 0.3,
          hasLimitedData: false,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: CoOccurrenceBarChart(results: results),
            ),
          ),
        ),
      );

      final chart = tester.widget<BarChart>(find.byType(BarChart));
      expect(chart.data.barGroups.length, 2);
    });

    testWidgets('renders single bar for single result', (tester) async {
      final results = [
        const CoOccurrenceResult(
          candidateCategoryUid: 'b',
          candidateCategoryName: 'Running',
          sharedDays: 8,
          unionDays: 10,
          score: 0.8,
          hasLimitedData: false,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: CoOccurrenceBarChart(results: results),
            ),
          ),
        ),
      );

      final chart = tester.widget<BarChart>(find.byType(BarChart));
      expect(chart.data.barGroups.length, 1);
      expect(chart.data.barGroups.first.barRods.first.toY, closeTo(0.8, 0.001));
    });
  });
}
