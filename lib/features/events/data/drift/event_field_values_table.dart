import 'package:drift/drift.dart';
import 'package:private_statistics/features/events/data/drift/events_table.dart';

/// Drift table definition for the `event_field_values` SQL table.
///
/// Each row is one `FieldValue` belonging to an [Events] row. The composite
/// primary key `(eventUid, fieldUid)` ensures at most one value per field per
/// event. The [eventUid] foreign key has `ON DELETE CASCADE` so values are
/// removed automatically when their owning event is deleted.
@DataClassName('EventFieldValueRow')
class EventFieldValues extends Table {
  /// UID of the owning [Events] row.
  ///
  /// Cascade-deletes this value when the owning event is deleted.
  TextColumn get eventUid =>
      text().references(Events, #uid, onDelete: KeyAction.cascade)();

  /// UID of the field this value belongs to.
  TextColumn get fieldUid => text()();

  /// Ordinal index of the `FieldType` enum value; determines which nullable
  /// value column is populated.
  IntColumn get valueTypeIndex => integer()();

  /// Integer value; populated when [valueTypeIndex] equals
  /// `FieldType.integer.index`.
  IntColumn get intValue => integer().nullable()();

  /// Float value; populated when [valueTypeIndex] equals
  /// `FieldType.float.index`.
  RealColumn get floatValue => real().nullable()();

  /// Boolean value; populated when [valueTypeIndex] equals
  /// `FieldType.boolean.index`.
  BoolColumn get boolValue => boolean().nullable()();

  /// String value; populated when [valueTypeIndex] equals
  /// `FieldType.enumeration.index`.
  TextColumn get stringValue => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {eventUid, fieldUid};
}
