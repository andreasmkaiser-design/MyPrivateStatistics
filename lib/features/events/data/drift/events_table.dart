import 'package:drift/drift.dart';
import 'package:private_statistics/features/categories/data/drift/categories_table.dart';

/// Drift table definition for the `events` SQL table.
///
/// Each row is one time-point `Event`. The [categoryUid] foreign key has
/// `ON DELETE CASCADE` so events are removed automatically when their owning
/// category is deleted.
@DataClassName('EventRow')
class Events extends Table {
  /// Primary key — globally unique identifier for this event.
  TextColumn get uid => text()();

  /// UID of the owning [Categories] row.
  ///
  /// Cascade-deletes this event when the owning category is deleted.
  TextColumn get categoryUid =>
      text().references(Categories, #uid, onDelete: KeyAction.cascade)();

  /// Unix timestamp in milliseconds for the event's occurrence.
  ///
  /// Stores `TimePoint.clockTime` when present, otherwise `TimePoint.date`
  /// at midnight (local time). Use [hasClockTime] to distinguish.
  IntColumn get occurredAtMs => integer()();

  /// Whether this event carries a precise clock time.
  ///
  /// When `true`, [occurredAtMs] encodes a full date-time; when `false`,
  /// it encodes only the calendar date at midnight.
  BoolColumn get hasClockTime => boolean()();

  @override
  Set<Column<Object>> get primaryKey => {uid};
}
