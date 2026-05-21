import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/features/statistics/domain/models/temporal_proximity_result.dart';
import 'package:private_statistics/features/statistics/presentation/widgets/temporal_proximity_kpi_card.dart';
import 'package:private_statistics/l10n/app_localizations.dart';

Widget _buildCard(
  TemporalProximityResult result, {
  String sourceName = 'Meditation',
  String timeWindowLabel = '24 h',
  Locale locale = const Locale('en'),
}) => MaterialApp(
  locale: locale,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: TemporalProximityKpiCard(
      sourceCategoryName: sourceName,
      result: result,
      timeWindowLabel: timeWindowLabel,
    ),
  ),
);

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

      await tester.pumpWidget(_buildCard(result));

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

      await tester.pumpWidget(_buildCard(result));

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

      await tester.pumpWidget(_buildCard(result, timeWindowLabel: '48 h'));

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

      await tester.pumpWidget(_buildCard(result, timeWindowLabel: '7 days'));

      expect(find.textContaining('Limited data'), findsNothing);
    });

    testWidgets('de locale: renders German proximity summary', (tester) async {
      const result = TemporalProximityResult(
        candidateCategoryUid: 'b',
        candidateCategoryName: 'Laufen',
        followCount: 2,
        sourceEventCount: 3,
        score: 2 / 3,
        hasLimitedData: false,
      );

      await tester.pumpWidget(_buildCard(result, locale: const Locale('de')));

      expect(
        find.textContaining('Laufen folgte Meditation innerhalb von 24 h'),
        findsOneWidget,
      );
    });

    testWidgets('de locale: shows German limited-data warning', (tester) async {
      const result = TemporalProximityResult(
        candidateCategoryUid: 'b',
        candidateCategoryName: 'Laufen',
        followCount: 1,
        sourceEventCount: 2,
        score: 0.5,
        hasLimitedData: true,
      );

      await tester.pumpWidget(_buildCard(result, locale: const Locale('de')));

      expect(find.textContaining('Wenig Daten'), findsOneWidget);
    });
  });
}
