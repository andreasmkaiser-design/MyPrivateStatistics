import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/app.dart';
import 'package:private_statistics/core/database/app_database.dart';
import 'package:private_statistics/core/database/database_provider.dart';
import 'package:private_statistics/features/categories/providers/category_providers.dart';
import 'package:private_statistics/features/events/providers/event_providers.dart';
import 'package:private_statistics/features/health/providers/health_providers.dart';
import 'package:private_statistics/features/settings/presentation/settings_screen.dart';

Widget _buildApp(AppDatabase db) => ProviderScope(
  overrides: [
    appDatabaseProvider.overrideWithValue(db),
    categoryTreeProvider.overrideWith((_) => Stream.value(const [])),
    eventDaysInMonthProvider.overrideWith((ref, _) => Stream.value(const {})),
    eventsByDayProvider.overrideWith((ref, _) => Stream.value(const [])),
    syncHourProvider.overrideWith((_) => Future.value(2)),
  ],
  child: const App(),
);

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  testWidgets('tapping settings icon navigates to SettingsScreen', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(db));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}
