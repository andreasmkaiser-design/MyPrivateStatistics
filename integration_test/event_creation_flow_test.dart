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
import 'package:private_statistics/features/categories/domain/models/field.dart';
import 'package:private_statistics/features/categories/domain/models/field_type.dart';
import 'package:private_statistics/features/categories/domain/models/time_model.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('create event flow: pick category → fill fields → save'
      ' → indicator → day detail lists event', (tester) async {
    // ── Seed database ────────────────────────────────────────────────────
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final catRepo = CategoryRepositoryImpl(db);
    await catRepo.save(
      const Category(
        uid: 'cat-run',
        name: 'Running',
        timeModel: TimeModel.timePoint,
        ownFields: [
          Field(
            uid: 'f-dist',
            categoryUid: 'cat-run',
            name: 'Distance',
            fieldType: FieldType.float,
            sortOrder: 0,
          ),
        ],
      ),
    );

    // ── Launch app ───────────────────────────────────────────────────────
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    // The Calendar tab opens by default. Navigate to today's date.
    final today = DateTime.now();
    final dayLabel = today.day.toString();

    // Tap the cell matching today's day number in the grid.
    await tester.tap(find.text(dayLabel).first);
    await tester.pumpAndSettle();

    // ── DayDetailScreen ──────────────────────────────────────────────────
    expect(find.byIcon(Icons.add), findsOneWidget);

    // Open the new-event form.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // ── EventFormScreen — pick category ──────────────────────────────────
    await tester.tap(find.text('Select category…'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Running'));
    await tester.pumpAndSettle();

    // ── Fill the float field ─────────────────────────────────────────────
    await tester.enterText(find.byType(TextField).first, '5.0');
    await tester.pumpAndSettle();

    // ── Save ─────────────────────────────────────────────────────────────
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Back on DayDetailScreen — the event should appear.
    expect(find.text('Running'), findsOneWidget);

    // ── Navigate back to CalendarScreen ──────────────────────────────────
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    // The calendar must now show an event indicator for today.
    final dotKey = ValueKey(
      'event_dot_${today.year}_${today.month}_${today.day}',
    );
    expect(find.byKey(dotKey), findsOneWidget);

    await db.close();
  });
}
