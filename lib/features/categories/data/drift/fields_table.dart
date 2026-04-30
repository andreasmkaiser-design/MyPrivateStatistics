import 'package:drift/drift.dart';
import 'package:private_statistics/features/categories/data/drift/categories_table.dart';

/// Drift table definition for the `fields` SQL table.
///
/// Each row is one `Field` owned by a [Categories] row. The [categoryUid]
/// foreign key has `ON DELETE CASCADE` so fields are removed automatically
/// when their owning category is deleted.
@DataClassName('FieldRow')
class Fields extends Table {
  /// Primary key — globally unique identifier for this field.
  TextColumn get uid => text()();

  /// UID of the owning [Categories] row.
  ///
  /// Cascade-deletes this field when the owning category is deleted.
  TextColumn get categoryUid =>
      text().references(Categories, #uid, onDelete: KeyAction.cascade)();

  /// Human-readable field label.
  TextColumn get name => text()();

  /// Ordinal index of the `FieldType` enum value for this field.
  IntColumn get fieldTypeIndex => integer()();

  /// Zero-based display order within the owning category's own field list.
  IntColumn get sortOrder => integer()();

  /// Optional lower bound for numeric fields; `NULL` if unconstrained.
  RealColumn get constraintMin => real().nullable()();

  /// Optional upper bound for numeric fields; `NULL` if unconstrained.
  RealColumn get constraintMax => real().nullable()();

  /// Unit of measurement for float fields (e.g. `'km'`); `NULL` otherwise.
  TextColumn get unit => text().nullable()();

  /// JSON-encoded list of allowed values for enum fields; `NULL` otherwise.
  TextColumn get enumOptionsJson => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {uid};
}
