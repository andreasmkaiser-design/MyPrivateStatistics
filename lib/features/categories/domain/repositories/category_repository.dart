import 'package:private_statistics/features/categories/domain/exceptions.dart';
import 'package:private_statistics/features/categories/domain/models/category.dart';
import 'package:private_statistics/features/categories/domain/models/category_node.dart';

/// Contract for persisting and querying [Category] data.
///
/// Implementations provide reactive access to the category tree and CRUD
/// operations. Depth validation and schema inheritance are enforced at the
/// domain layer, not at the database layer.
abstract class CategoryRepository {
  /// Emits the full category tree whenever any category or field changes.
  ///
  /// Root categories appear at the top level; subcategories are nested in
  /// [CategoryNode.children]. Each node carries the fully resolved merged
  /// schema. Emits the current state immediately upon subscription.
  Stream<List<CategoryNode>> watchTree();

  /// Returns every category in the database as a flat (unordered) list.
  ///
  /// Used by the template export flow to serialise the full hierarchy without
  /// building the tree structure.
  Future<List<Category>> getAll();

  /// Returns the category identified by [uid], or `null` if not found.
  Future<Category?> findByUid(String uid);

  /// Persists [category] as an upsert (insert or replace).
  ///
  /// All own fields for this category are replaced with those in
  /// [Category.ownFields]. Throws [CategoryDepthLimitExceededException] if
  /// placing [category] in the hierarchy would exceed the maximum depth.
  /// Throws [DuplicateCategoryNameException] if a sibling with the same name
  /// (case-insensitive) already exists.
  Future<void> save(Category category);

  /// Renames the category with [uid] to [newName].
  ///
  /// Throws [DuplicateCategoryNameException] if a sibling with the same name
  /// (case-insensitive) already exists.
  Future<void> rename(String uid, String newName);

  /// Deletes the category with [uid].
  ///
  /// Cascades to all subcategories and their associated Events.
  Future<void> delete(String uid);
}
