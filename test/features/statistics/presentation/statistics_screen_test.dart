import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/features/categories/domain/models/category.dart';
import 'package:private_statistics/features/categories/domain/models/category_node.dart';
import 'package:private_statistics/features/categories/domain/models/time_model.dart';
import 'package:private_statistics/features/categories/providers/category_providers.dart';
import 'package:private_statistics/features/statistics/domain/models/co_occurrence_result.dart';
import 'package:private_statistics/features/statistics/domain/models/temporal_proximity_result.dart';
import 'package:private_statistics/features/statistics/presentation/statistics_screen.dart';
import 'package:private_statistics/features/statistics/providers/statistics_providers.dart';
import 'package:private_statistics/l10n/app_localizations.dart';

const _sourceCategory = Category(
  uid: 'src',
  name: 'Sleep',
  timeModel: TimeModel.timePoint,
  ownFields: [],
);

Widget _buildScreen({
  Locale locale = const Locale('en'),
  String? sourceCategoryUid,
  List<CoOccurrenceResult> coOccurrenceResults = const [],
}) {
  final overrides = <Override>[
    categoryTreeProvider.overrideWith(
      (_) => Stream.value([
        const CategoryNode(
          category: _sourceCategory,
          children: [],
          mergedSchema: [],
        ),
      ]),
    ),
    coOccurrenceResultsProvider.overrideWith(
      (_) => Future.value(coOccurrenceResults),
    ),
    temporalProximityResultsProvider.overrideWith(
      (_) => Future.value(<TemporalProximityResult>[]),
    ),
    calendarDataProvider.overrideWith((_) async => null),
  ];

  if (sourceCategoryUid != null) {
    overrides.add(
      statisticsSourceCategoryProvider.overrideWith((ref) => sourceCategoryUid),
    );
  }

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: StatisticsScreen()),
    ),
  );
}

void main() {
  group('StatisticsScreen', () {
    testWidgets('dropdown has no hint text when no category is selected', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      // The hint widget that caused the label/hint overlap must be absent.
      expect(find.text('Select a category'), findsNothing);
      // The InputDecorator label must still be visible.
      expect(find.textContaining('Source category'), findsWidgets);
    });

    testWidgets('de locale: dropdown label shows Quellkategorie', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen(locale: const Locale('de')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Quellkategorie'), findsWidgets);
    });

    testWidgets('de locale: co-occurrence title shows Gemeinsames Auftreten '
        'when results are present', (tester) async {
      const result = CoOccurrenceResult(
        candidateCategoryUid: 'b',
        candidateCategoryName: 'Sport',
        sharedDays: 5,
        unionDays: 10,
        score: 0.5,
        hasLimitedData: false,
      );

      await tester.pumpWidget(
        _buildScreen(
          locale: const Locale('de'),
          sourceCategoryUid: 'src',
          coOccurrenceResults: [result],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gemeinsames Auftreten'), findsOneWidget);
    });

    testWidgets('de locale: temporal proximity title shows Zeitliche Nähe '
        'when source category is selected', (tester) async {
      await tester.pumpWidget(
        _buildScreen(locale: const Locale('de'), sourceCategoryUid: 'src'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Zeitliche Nähe'), findsOneWidget);
    });
  });
}
