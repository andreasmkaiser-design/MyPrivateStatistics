import 'package:drift/drift.dart';
import 'package:private_statistics/features/categories/data/drift/categories_table.dart';

/// Drift table definition for the `events` SQL table.
///
/// Each row is one `Event`. The [categoryUid] foreign key has
/// `ON DELETE CASCADE` so events are removed automatically when their owning
/// category is deleted.
///
/// Time model encoding:
/// - [rangeEndMs] is `null` → time-point event; [hasClockTime] determines
///   day-precision vs. datetime-precision.
/// - [rangeEndMs] is not `null` and [hasClockTime] is `false` → day-precise
///   range (`DayPreciseRange`).
/// - [rangeEndMs] is not `null` and [hasClockTime] is `true` → datetime-
///   precise range (`DatetimePreciseRange`).
@DataClassName('EventRow')
class Events extends Table {
  /// Primary key — globally unique identifier for this event.
  TextColumn get uid => text()();

  /// UID of the owning [Categories] row.
  ///
  /// Cascade-deletes this event when the owning category is deleted.
  TextColumn get categoryUid =>
      text().references(Categories, #uid, onDelete: KeyAction.cascade)();

  /// Unix timestamp in milliseconds for the event's start (or sole) moment.
  ///
  /// For time-point events: stores the clock time when [hasClockTime] is
  /// `true`, otherwise the calendar date at midnight.
  /// For range events: stores the range start.
  IntColumn get occurredAtMs => integer()();

  /// Whether this event carries a precise clock time.
  ///
  /// For time-point events: `true` when [occurredAtMs] encodes a full
  /// date-time; `false` when it encodes only the calendar date at midnight.
  /// For range events: `true` for `DatetimePreciseRange`, `false` for
  /// `DayPreciseRange`.
  BoolColumn get hasClockTime => boolean()();

  /// Unix timestamp in milliseconds for the end of a range event.
  ///
  /// `null` for time-point events. Non-null for `DayPreciseRange` and
  /// `DatetimePreciseRange`, storing the inclusive end timestamp.
  IntColumn get rangeEndMs => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {uid};
}
