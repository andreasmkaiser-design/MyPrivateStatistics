import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/features/statistics/domain/models/temporal_proximity_result.dart';
import 'package:private_statistics/features/statistics/presentation/widgets/temporal_proximity_kpi_card.dart';

void main() {
  group('TemporalProximityKpiCard', () {
    testWidgets('renders candidate name and formatted score', (tester) async {
      const result = TemporalProximityResult(
        candidateCategoryUid: 'b',
        candidateCategoryName: 'Running',
        followCount: 2,
        sourceEventCount: 3,
        score: 2 / 3,
        hasLimitedData: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TemporalProximityKpiCard(
              sourceCategoryName: 'Meditation',
              result: result,
              timeWindowLabel: '24 h',
            ),
          ),
        ),
      );

      expect(find.text('Running'), findsOneWidget);
      expect(find.text('67%'), findsOneWidget);
    });

    testWidgets('renders correct plain-language text (ADR-0017)', (
      tester,
    ) async {
      const result = TemporalProximityResult(
        candidateCategoryUid: 'b',
        candidateCategoryName: 'Running',
        followCount: 2,
        sourceEventCount: 3,
        score: 2 / 3,
        hasLimitedData: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TemporalProximityKpiCard(
              sourceCategoryName: 'Meditation',
              result: result,
              timeWindowLabel: '24 h',
            ),
          ),
        ),
      );

      expect(
        find.textContaining('Running followed Meditation within 24 h'),
        findsOneWidget,
      );
    });

    testWidgets('shows limited-data warning when hasLimitedData is true', (
      tester,
    ) async {
      const result = TemporalProximityResult(
        candidateCategoryUid: 'b',
        candidateCategoryName: 'Running',
        followCount: 1,
        sourceEventCount: 2,
        score: 0.5,
        hasLimitedData: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TemporalProximityKpiCard(
              sourceCategoryName: 'Meditation',
              result: result,
              timeWindowLabel: '48 h',
            ),
          ),
        ),
      );

      expect(find.textContaining('Limited data'), findsOneWidget);
    });

    testWidgets('hides limited-data warning when hasLimitedData is false', (
      tester,
    ) async {
      const result = TemporalProximityResult(
        candidateCategoryUid: 'b',
        candidateCategoryName: 'Running',
        followCount: 5,
        sourceEventCount: 5,
        score: 1,
        hasLimitedData: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TemporalProximityKpiCard(
              sourceCategoryName: 'Meditation',
              result: result,
              timeWindowLabel: '7 days',
            ),
          ),
        ),
      );

      expect(find.textContaining('Limited data'), findsNothing);
    });
  });
}
