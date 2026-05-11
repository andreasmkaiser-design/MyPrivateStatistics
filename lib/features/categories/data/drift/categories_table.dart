import 'package:drift/drift.dart';

/// Drift table definition for the `categories` SQL table.
///
/// Stores the category adjacency list. Each row is one `Category` node.
/// The self-referential [parentUid] foreign key has `ON DELETE CASCADE` so
/// that deleting a parent automatically deletes all descendants.
@DataClassName('CategoryRow')
class Categories extends Table {
  /// Primary key — globally unique identifier for this category.
  TextColumn get uid => text()();

  /// UID of the parent category; `NULL` for root categories.
  ///
  /// Cascade-deletes all child rows when the parent is deleted.
  TextColumn get parentUid => text().nullable().references(
    Categories,
    #uid,
    onDelete: KeyAction.cascade,
  )();

  /// Human-readable category name.
  TextColumn get name => text()();

  /// Ordinal index of the `TimeModel` enum value for this category.
  IntColumn get timeModelIndex => integer()();

  /// UID of the category this was originally imported from, or `null` for
  /// locally-created categories and first-generation exports.
  ///
  /// Set to the exporting app's [uid] when this category is imported from a
  /// JSON template so that future "update from source" features can match rows.
  TextColumn get sourceUid => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {uid};
}
