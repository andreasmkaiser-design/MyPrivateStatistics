import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:private_statistics/app.dart';
import 'package:private_statistics/core/database/app_database.dart';
import 'package:private_statistics/core/database/database_provider.dart';
import 'package:private_statistics/features/categories/data/category_repository_impl.dart';
import 'package:private_statistics/features/categories/domain/models/category.dart';
import 'package:private_statistics/features/categories/domain/models/time_model.dart';
import 'package:private_statistics/features/events/data/event_repository_impl.dart';
import 'package:private_statistics/features/events/domain/models/event.dart';
import 'package:private_statistics/features/events/domain/models/event_time.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('statistics flow: events on same day → co-occurrence > 0', (
    tester,
  ) async {
    // ── Seed database ──────────────────────────────────────────────────
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final catRepo = CategoryRepositoryImpl(db);
    final eventRepo = EventRepositoryImpl(db);

    await catRepo.save(
      const Category(
        uid: 'cat-meditation',
        name: 'Meditation',
        timeModel: TimeModel.timePoint,
        ownFields: [],
      ),
    );
    await catRepo.save(
      const Category(
        uid: 'cat-running',
        name: 'Running',
        timeModel: TimeModel.timePoint,
        ownFields: [],
      ),
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await eventRepo.save(
      Event(
        uid: 'ev-1',
        categoryUid: 'cat-meditation',
        occurredAt: TimePoint(date: today),
        fieldValues: const [],
      ),
    );
    await eventRepo.save(
      Event(
        uid: 'ev-2',
        categoryUid: 'cat-running',
        occurredAt: TimePoint(date: today),
        fieldValues: const [],
      ),
    );

    // ── Launch app ─────────────────────────────────────────────────────
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to Statistics tab (index 2).
    await tester.tap(find.byIcon(Icons.bar_chart_outlined));
    await tester.pumpAndSettle();

    // Select "Meditation" as source category via the dropdown.
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Meditation').last);
    await tester.pumpAndSettle();

    // Results should contain "Running" with co-occurrence > 0.
    expect(find.text('Running'), findsOneWidget);
    expect(find.textContaining('1 of 1 days'), findsOneWidget);
  });
}
