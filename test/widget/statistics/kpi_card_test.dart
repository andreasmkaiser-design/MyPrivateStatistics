import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/features/statistics/domain/models/co_occurrence_result.dart';
import 'package:private_statistics/features/statistics/presentation/widgets/kpi_card.dart';
import 'package:private_statistics/l10n/app_localizations.dart';

Widget _buildCard(
  CoOccurrenceResult result, {
  String sourceName = 'Meditation',
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
    body: KpiCard(sourceCategoryName: sourceName, result: result),
  ),
);

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

      await tester.pumpWidget(_buildCard(result));

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

      await tester.pumpWidget(_buildCard(result));

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

      await tester.pumpWidget(_buildCard(result));

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

      await tester.pumpWidget(_buildCard(result));

      expect(find.textContaining('Limited data'), findsNothing);
    });

    testWidgets('de locale: renders German co-occurrence summary', (
      tester,
    ) async {
      const result = CoOccurrenceResult(
        candidateCategoryUid: 'b',
        candidateCategoryName: 'Laufen',
        sharedDays: 3,
        unionDays: 7,
        score: 0.43,
        hasLimitedData: false,
      );

      await tester.pumpWidget(_buildCard(result, locale: const Locale('de')));

      expect(
        find.textContaining('traten gemeinsam an 3 von 7 Tagen auf'),
        findsOneWidget,
      );
    });

    testWidgets('de locale: shows German limited-data warning', (tester) async {
      const result = CoOccurrenceResult(
        candidateCategoryUid: 'b',
        candidateCategoryName: 'Laufen',
        sharedDays: 1,
        unionDays: 2,
        score: 0.5,
        hasLimitedData: true,
      );

      await tester.pumpWidget(_buildCard(result, locale: const Locale('de')));

      expect(find.textContaining('Wenig Daten'), findsOneWidget);
    });
  });
}
