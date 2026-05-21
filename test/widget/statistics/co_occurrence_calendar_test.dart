import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/features/statistics/domain/models/calendar_data.dart';
import 'package:private_statistics/features/statistics/domain/models/calendar_day_state.dart';
import 'package:private_statistics/features/statistics/presentation/widgets/co_occurrence_calendar.dart';

void main() {
  final windowFrom = DateTime(2024);
  final windowTo = DateTime(2024, 1, 7);

  CalendarData makeData(Map<DateTime, CalendarDayState> stateByDay) =>
      CalendarData(
        windowFrom: windowFrom,
        windowTo: windowTo,
        sourceCategoryUid: 'a',
        sourceCategoryName: 'Alpha',
        candidateCategoryUid: 'b',
        candidateCategoryName: 'Beta',
        stateByDay: stateByDay,
      );

  Widget buildWidget(
    CalendarData data, {
    void Function(DateTime)? onDayTapped,
    Locale locale = const Locale('en'),
  }) => MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('de')],
    home: Scaffold(
      body: SingleChildScrollView(
        child: CoOccurrenceCalendar(
          data: data,
          onDayTapped: onDayTapped ?? (_) {},
        ),
      ),
    ),
  );

  // Helper: find the Container keyed to a specific calendar day.
  Finder dayFinder(int year, int month, int day) =>
      find.byKey(Key('cal_day_${year}_${month}_$day'));

  // Helper: get the BoxDecoration color of a keyed day cell.
  Color? dayColor(WidgetTester tester, int year, int month, int day) {
    final container = tester.widget<Container>(dayFinder(year, month, day));
    return (container.decoration! as BoxDecoration).color;
  }

  group('CoOccurrenceCalendar', () {
    testWidgets('renders a key for every in-window day', (tester) async {
      final data = makeData({
        for (var i = 1; i <= 7; i++)
          DateTime(2024, 1, i): CalendarDayState.neither,
      });
      await tester.pumpWidget(buildWidget(data));
      for (var i = 1; i <= 7; i++) {
        expect(dayFinder(2024, 1, i), findsOneWidget);
      }
    });

    testWidgets('both days use a distinct non-null color', (tester) async {
      final data = makeData({
        DateTime(2024): CalendarDayState.both,
        DateTime(2024, 1, 2): CalendarDayState.neither,
        for (var i = 3; i <= 7; i++)
          DateTime(2024, 1, i): CalendarDayState.neither,
      });
      await tester.pumpWidget(buildWidget(data));
      final bothColor = dayColor(tester, 2024, 1, 1);
      final neitherColor = dayColor(tester, 2024, 1, 2);
      expect(bothColor, isNotNull);
      expect(bothColor, isNot(equals(neitherColor)));
    });

    testWidgets(
      'sourceOnly and candidateOnly have distinct colors from each other '
      'and from both',
      (tester) async {
        final data = makeData({
          DateTime(2024): CalendarDayState.both,
          DateTime(2024, 1, 2): CalendarDayState.sourceOnly,
          DateTime(2024, 1, 3): CalendarDayState.candidateOnly,
          for (var i = 4; i <= 7; i++)
            DateTime(2024, 1, i): CalendarDayState.neither,
        });
        await tester.pumpWidget(buildWidget(data));
        final bothColor = dayColor(tester, 2024, 1, 1);
        final sourceColor = dayColor(tester, 2024, 1, 2);
        final candidateColor = dayColor(tester, 2024, 1, 3);
        expect(sourceColor, isNot(equals(bothColor)));
        expect(candidateColor, isNot(equals(bothColor)));
        expect(candidateColor, isNot(equals(sourceColor)));
      },
    );

    testWidgets('neither days have no fill color', (tester) async {
      final data = makeData({
        for (var i = 1; i <= 7; i++)
          DateTime(2024, 1, i): CalendarDayState.neither,
      });
      await tester.pumpWidget(buildWidget(data));
      for (var i = 1; i <= 7; i++) {
        expect(dayColor(tester, 2024, 1, i), isNull);
      }
    });

    testWidgets('days outside the analysis window have no keyed cell', (
      tester,
    ) async {
      // Window is Jan 5–7; Jan 1–4 are outside.
      final data = CalendarData(
        windowFrom: DateTime(2024, 1, 5),
        windowTo: DateTime(2024, 1, 7),
        sourceCategoryUid: 'a',
        sourceCategoryName: 'Alpha',
        candidateCategoryUid: 'b',
        candidateCategoryName: 'Beta',
        stateByDay: {
          DateTime(2024, 1, 5): CalendarDayState.both,
          DateTime(2024, 1, 6): CalendarDayState.neither,
          DateTime(2024, 1, 7): CalendarDayState.sourceOnly,
        },
      );
      await tester.pumpWidget(buildWidget(data));
      // Days 1–4 are outside the window — no key assigned.
      for (var i = 1; i <= 4; i++) {
        expect(dayFinder(2024, 1, i), findsNothing);
      }
      // Day 5 is inside the window — key present.
      expect(dayFinder(2024, 1, 5), findsOneWidget);
    });

    testWidgets(
      'tapping a highlighted day fires onDayTapped with correct date',
      (tester) async {
        DateTime? tapped;
        final data = makeData({
          DateTime(2024): CalendarDayState.both,
          for (var i = 2; i <= 7; i++)
            DateTime(2024, 1, i): CalendarDayState.neither,
        });
        await tester.pumpWidget(
          buildWidget(data, onDayTapped: (date) => tapped = date),
        );
        await tester.tap(dayFinder(2024, 1, 1));
        await tester.pump();
        expect(tapped, equals(DateTime(2024)));
      },
    );

    testWidgets('tapping a neither day does not fire onDayTapped', (
      tester,
    ) async {
      var callCount = 0;
      final data = makeData({
        for (var i = 1; i <= 7; i++)
          DateTime(2024, 1, i): CalendarDayState.neither,
      });
      await tester.pumpWidget(
        buildWidget(data, onDayTapped: (_) => callCount++),
      );
      await tester.tap(dayFinder(2024, 1, 1));
      await tester.pump();
      expect(callCount, 0);
    });

    testWidgets('de locale: month header shows German month name', (
      tester,
    ) async {
      final data = makeData({
        for (var i = 1; i <= 7; i++)
          DateTime(2024, 1, i): CalendarDayState.neither,
      });
      await tester.pumpWidget(buildWidget(data, locale: const Locale('de')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Januar'), findsOneWidget);
    });
  });
}
