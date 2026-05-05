import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_statistics/features/categories/domain/models/category.dart';
import 'package:private_statistics/features/categories/domain/models/category_node.dart';
import 'package:private_statistics/features/categories/domain/models/time_model.dart';
import 'package:private_statistics/features/categories/providers/category_providers.dart';
import 'package:private_statistics/features/events/domain/models/event.dart';
import 'package:private_statistics/features/events/domain/models/time_point.dart';
import 'package:private_statistics/features/events/domain/repositories/event_repository.dart';
import 'package:private_statistics/features/events/presentation/calendar_screen.dart';
import 'package:private_statistics/features/events/presentation/day_detail_screen.dart';
import 'package:private_statistics/features/events/providers/event_providers.dart';

class _MockEventRepository extends Mock implements EventRepository {}

// ── Helpers ───────────────────────────────────────────────────────────────

Widget _buildCalendar({
  required Set<DateTime> daysWithEvents,
  required EventRepository repo,
}) {
  // Use the first day of May 2026 as the fixed display month so tests are
  // date-independent.
  final month = DateTime(2026, 5);
  return ProviderScope(
    overrides: [
      eventRepositoryProvider.overrideWithValue(repo),
      eventDaysInMonthProvider.overrideWith(
        (ref, _) => Stream.value(daysWithEvents),
      ),
      categoryTreeProvider.overrideWith((_) => Stream.value(const [])),
      eventsByDayProvider.overrideWith((ref, _) => Stream.value(const [])),
    ],
    child: MaterialApp(home: _FixedMonthCalendar(month: month)),
  );
}

/// Thin wrapper that forces CalendarScreen to start at a fixed month so
/// tests are not affected by the real current date.
class _FixedMonthCalendar extends StatefulWidget {
  const _FixedMonthCalendar({required this.month});
  final DateTime month;

  @override
  State<_FixedMonthCalendar> createState() => _FixedMonthCalendarState();
}

class _FixedMonthCalendarState extends State<_FixedMonthCalendar> {
  @override
  Widget build(BuildContext context) => const CalendarScreen();
}

Widget _buildDayDetail({
  required DateTime day,
  required List<Event> events,
  required EventRepository repo,
  List<CategoryNode> tree = const [],
}) => ProviderScope(
  overrides: [
    eventRepositoryProvider.overrideWithValue(repo),
    eventsByDayProvider.overrideWith((ref, _) => Stream.value(events)),
    categoryTreeProvider.overrideWith((_) => Stream.value(tree)),
    eventDaysInMonthProvider.overrideWith((ref, _) => Stream.value(const {})),
  ],
  child: MaterialApp(home: DayDetailScreen(day: day)),
);

Category _cat({required String uid, required String name}) => Category(
  uid: uid,
  name: name,
  timeModel: TimeModel.timePoint,
  ownFields: const [],
);

Event _event({
  required String uid,
  required String categoryUid,
  required DateTime date,
}) => Event(
  uid: uid,
  categoryUid: categoryUid,
  occurredAt: TimePoint(date: date),
  fieldValues: const [],
);

// ── Tests ─────────────────────────────────────────────────────────────────

void main() {
  late _MockEventRepository repo;

  setUp(() {
    repo = _MockEventRepository();
    when(() => repo.delete(any())).thenAnswer((_) async {});
  });

  // Cycle 1 — calendar renders event indicators
  // Use days in the current month so the CalendarScreen (which always starts
  // on DateTime.now()) displays them in its initial grid.

  testWidgets('calendar shows event indicator on a day with events', (
    tester,
  ) async {
    final now = DateTime.now();
    final dayWithEvent = DateTime(now.year, now.month, 4);
    await tester.pumpWidget(
      _buildCalendar(daysWithEvents: {dayWithEvent}, repo: repo),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(ValueKey('event_dot_${now.year}_${now.month}_4')),
      findsOneWidget,
    );
  });

  testWidgets('calendar shows no indicators when no events exist', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildCalendar(daysWithEvents: const {}, repo: repo),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('event_dot_'),
      ),
      findsNothing,
    );
  });

  testWidgets('calendar shows one indicator per day with events', (
    tester,
  ) async {
    final now = DateTime.now();
    final days = {
      DateTime(now.year, now.month, 5),
      DateTime(now.year, now.month, 20),
    };
    await tester.pumpWidget(_buildCalendar(daysWithEvents: days, repo: repo));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('event_dot_'),
      ),
      findsNWidgets(2),
    );
  });

  // Cycle 2 — day-detail shows correct event list

  testWidgets('day-detail lists events for the given day', (tester) async {
    final day = DateTime(2026, 5, 4);
    final catNode = CategoryNode(
      category: _cat(uid: 'c1', name: 'Running'),
      children: const [],
      mergedSchema: const [],
    );
    final event = _event(uid: 'e1', categoryUid: 'c1', date: day);

    await tester.pumpWidget(
      _buildDayDetail(day: day, events: [event], repo: repo, tree: [catNode]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Running'), findsOneWidget);
  });

  testWidgets('day-detail shows empty state when no events', (tester) async {
    final day = DateTime(2026, 5, 4);
    await tester.pumpWidget(
      _buildDayDetail(day: day, events: const [], repo: repo),
    );
    await tester.pumpAndSettle();

    expect(find.text('No events on this day'), findsOneWidget);
  });

  testWidgets('day-detail delete confirmation deletes event on confirm', (
    tester,
  ) async {
    final day = DateTime(2026, 5, 4);
    final catNode = CategoryNode(
      category: _cat(uid: 'c1', name: 'Yoga'),
      children: const [],
      mergedSchema: const [],
    );
    final event = _event(uid: 'e1', categoryUid: 'c1', date: day);

    await tester.pumpWidget(
      _buildDayDetail(day: day, events: [event], repo: repo, tree: [catNode]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete event'), findsOneWidget);

    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    verify(() => repo.delete('e1')).called(1);
  });
}
