import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/app.dart';
import 'package:private_statistics/core/database/app_database.dart';
import 'package:private_statistics/core/database/database_provider.dart';
import 'package:private_statistics/features/categories/providers/category_providers.dart';
import 'package:private_statistics/features/events/providers/event_providers.dart';

Widget _buildApp(AppDatabase db) => ProviderScope(
  overrides: [
    appDatabaseProvider.overrideWithValue(db),
    categoryTreeProvider.overrideWith((_) => Stream.value(const [])),
    eventDaysInMonthProvider.overrideWith((ref, _) => Stream.value(const {})),
    eventsByDayProvider.overrideWith((ref, _) => Stream.value(const [])),
  ],
  child: const App(),
);

Finder _navLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  testWidgets('Calendar tab is active by default', (tester) async {
    await tester.pumpWidget(_buildApp(db));
    await tester.pumpAndSettle();
    expect(find.text('Calendar'), findsWidgets);
  });

  testWidgets('tapping Events tab shows Events screen', (tester) async {
    await tester.pumpWidget(_buildApp(db));
    await tester.pumpAndSettle();
    await tester.tap(_navLabel('Events'));
    await tester.pumpAndSettle();
    expect(find.text('Events'), findsWidgets);
  });

  testWidgets('tapping Statistics tab shows Statistics screen', (tester) async {
    await tester.pumpWidget(_buildApp(db));
    await tester.pumpAndSettle();
    await tester.tap(_navLabel('Statistics'));
    await tester.pumpAndSettle();
    expect(find.text('Statistics'), findsWidgets);
  });

  testWidgets('tapping Categories tab shows Categories screen', (tester) async {
    await tester.pumpWidget(_buildApp(db));
    await tester.pumpAndSettle();
    await tester.tap(_navLabel('Categories'));
    await tester.pumpAndSettle();
    expect(find.text('Categories'), findsWidgets);
  });
}
