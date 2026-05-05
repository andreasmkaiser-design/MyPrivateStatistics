import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/features/statistics/domain/models/co_occurrence_result.dart';
import 'package:private_statistics/features/statistics/presentation/widgets/kpi_card.dart';

void main() {
  group('KpiCard', () {
    testWidgets('renders candidate name and formatted score', (tester) async {
      const result = CoOccurrenceResult(
        candidateCategoryUid: 'b',
        candidateCategoryName: 'Running',
        sharedDays: 5,
        unionDays: 10,
        score: 0.5,
        hasLimitedData: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KpiCard(sourceCategoryName: 'Meditation', result: result),
          ),
        ),
      );

      expect(find.text('Running'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('renders correct co-occurrence text', (tester) async {
      const result = CoOccurrenceResult(
        candidateCategoryUid: 'b',
        candidateCategoryName: 'Running',
        sharedDays: 3,
        unionDays: 7,
        score: 0.43,
        hasLimitedData: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KpiCard(sourceCategoryName: 'Meditation', result: result),
          ),
        ),
      );

      expect(find.textContaining('co-occurred on 3 of 7 days'), findsOneWidget);
    });

    testWidgets('shows limited-data warning when hasLimitedData is true', (
      tester,
    ) async {
      const result = CoOccurrenceResult(
        candidateCategoryUid: 'b',
        candidateCategoryName: 'Running',
        sharedDays: 1,
        unionDays: 2,
        score: 0.5,
        hasLimitedData: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KpiCard(sourceCategoryName: 'Meditation', result: result),
          ),
        ),
      );

      expect(find.textContaining('Limited data'), findsOneWidget);
    });

    testWidgets('hides limited-data warning when hasLimitedData is false', (
      tester,
    ) async {
      const result = CoOccurrenceResult(
        candidateCategoryUid: 'b',
        candidateCategoryName: 'Running',
        sharedDays: 5,
        unionDays: 10,
        score: 0.5,
        hasLimitedData: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KpiCard(sourceCategoryName: 'Meditation', result: result),
          ),
        ),
      );

      expect(find.textContaining('Limited data'), findsNothing);
    });
  });
}
