import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:private_statistics/features/categories/data/drift/categories_table.dart';
import 'package:private_statistics/features/categories/data/drift/fields_table.dart';
import 'package:private_statistics/features/events/data/drift/event_field_values_table.dart';
import 'package:private_statistics/features/events/data/drift/events_table.dart';

part 'app_database.g.dart';

/// The app's Drift database.
///
/// Exposes the [Categories], [Fields], [Events], and [EventFieldValues] tables
/// and manages schema migrations.
/// Use [AppDatabase.forTesting] to create an in-memory instance for tests.
@DriftDatabase(tables: [Categories, Fields, Events, EventFieldValues])
class AppDatabase extends _$AppDatabase {
  /// Creates the production database backed by an on-device SQLite file.
  AppDatabase() : super(_openConnection());

  /// Creates an in-memory database for use in tests.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (kDebugMode) {
        // Destructive in debug: drop all and recreate for fast iteration.
        await customStatement('PRAGMA foreign_keys = OFF');
        for (final table in allTables.toList().reversed) {
          await m.deleteTable(table.actualTableName);
        }
        await customStatement('PRAGMA foreign_keys = ON');
        await m.createAll();
      } else {
        if (from < 2) {
          await m.createTable(categories);
          await m.createTable(fields);
        }
        if (from < 3) {
          await m.createTable(events);
          await m.createTable(eventFieldValues);
        }
        if (from < 4) {
          // Add nullable range_end_ms column for DayPreciseRange and
          // DatetimePreciseRange events. Existing rows (time-point events)
          // default to NULL, preserving backwards compatibility.
          await customStatement(
            'ALTER TABLE events ADD COLUMN range_end_ms INTEGER;',
          );
        }
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(path.join(dbFolder.path, 'private_statistics.db'));
    return NativeDatabase.createInBackground(file);
  });
}
