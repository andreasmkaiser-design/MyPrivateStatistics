import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:private_statistics/core/database/app_database.dart';
import 'package:private_statistics/core/logging/app_logger.dart';
import 'package:private_statistics/features/categories/domain/models/category.dart';
import 'package:private_statistics/features/categories/domain/models/category_node.dart';
import 'package:private_statistics/features/categories/domain/models/field.dart';
import 'package:private_statistics/features/categories/domain/models/field_constraint.dart';
import 'package:private_statistics/features/categories/domain/models/field_type.dart';
import 'package:private_statistics/features/categories/domain/models/time_model.dart';
import 'package:private_statistics/features/categories/domain/repositories/category_repository.dart';
import 'package:private_statistics/features/categories/domain/schema_inheritance_resolver.dart';

/// Drift-backed implementation of [CategoryRepository].
///
/// Assembles the category tree in Dart from an adjacency-list schema.
/// Foreign-key cascades (enabled via `PRAGMA foreign_keys = ON` in
/// [AppDatabase]) handle recursive deletion of subcategories.
class CategoryRepositoryImpl implements CategoryRepository {
  /// Creates a [CategoryRepositoryImpl] backed by the given [AppDatabase].
  CategoryRepositoryImpl(this._db) : _resolver = SchemaInheritanceResolver();

  final AppDatabase _db;
  final SchemaInheritanceResolver _resolver;

  @override
  Stream<List<CategoryNode>> watchTree() {
    return _db.select(_db.categories).watch().asyncMap((_) => _buildTree());
  }

  @override
  Future<Category?> findByUid(String uid) async {
    final row = await (_db.select(
      _db.categories,
    )..where((t) => t.uid.equals(uid))).getSingleOrNull();
    if (row == null) return null;

    final fieldRows =
        await (_db.select(_db.fields)
              ..where((t) => t.categoryUid.equals(uid))
              ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
            .get();

    return _toCategory(row, fieldRows.map(_toField).toList());
  }

  @override
  Future<void> save(Category category) async {
    if (category.parentUid != null) {
      final allCats = await _allCategoriesMap();
      _resolver.validateDepth(category, allCats);
    }

    AppLogger.debug('CategoryRepository: saving ${category.uid}');

    await _db.transaction(() async {
      await _db
          .into(_db.categories)
          .insertOnConflictUpdate(
            CategoriesCompanion(
              uid: Value(category.uid),
              parentUid: Value(category.parentUid),
              name: Value(category.name),
              timeModelIndex: Value(category.timeModel.index),
            ),
          );

      await (_db.delete(
        _db.fields,
      )..where((t) => t.categoryUid.equals(category.uid))).go();

      for (final field in category.ownFields) {
        await _db
            .into(_db.fields)
            .insert(
              FieldsCompanion(
                uid: Value(field.uid),
                categoryUid: Value(category.uid),
                name: Value(field.name),
                fieldTypeIndex: Value(field.fieldType.index),
                sortOrder: Value(field.sortOrder),
                constraintMin: Value(field.constraint?.min),
                constraintMax: Value(field.constraint?.max),
                unit: Value(field.unit),
                enumOptionsJson: Value(
                  field.enumOptions.isEmpty
                      ? null
                      : jsonEncode(field.enumOptions),
                ),
              ),
            );
      }
    });
  }

  @override
  Future<void> rename(String uid, String newName) async {
    AppLogger.debug('CategoryRepository: renaming $uid to $newName');
    await (_db.update(_db.categories)..where((t) => t.uid.equals(uid))).write(
      CategoriesCompanion(name: Value(newName)),
    );
  }

  @override
  Future<void> delete(String uid) async {
    AppLogger.debug('CategoryRepository: deleting $uid');
    await (_db.delete(_db.categories)..where((t) => t.uid.equals(uid))).go();
  }

  Future<List<CategoryNode>> _buildTree() async {
    final catRows = await _db.select(_db.categories).get();
    final fieldRows = await _db.select(_db.fields).get();

    final fieldsByCategory = <String, List<Field>>{};
    for (final row in fieldRows) {
      fieldsByCategory
          .putIfAbsent(row.categoryUid, () => [])
          .add(_toField(row));
    }

    final allCategories = <String, Category>{};
    for (final row in catRows) {
      final fields = (fieldsByCategory[row.uid] ?? [])
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      allCategories[row.uid] = _toCategory(row, fields);
    }

    CategoryNode buildNode(Category cat) {
      final children = allCategories.values
          .where((c) => c.parentUid == cat.uid)
          .map(buildNode)
          .toList();
      return CategoryNode(
        category: cat,
        children: children,
        mergedSchema: _resolver.resolveSchema(cat, allCategories),
      );
    }

    return allCategories.values.where((c) => c.isRoot).map(buildNode).toList();
  }

  Future<Map<String, Category>> _allCategoriesMap() async {
    final catRows = await _db.select(_db.categories).get();
    final fieldRows = await _db.select(_db.fields).get();

    final fieldsByCategory = <String, List<Field>>{};
    for (final row in fieldRows) {
      fieldsByCategory
          .putIfAbsent(row.categoryUid, () => [])
          .add(_toField(row));
    }

    return {
      for (final row in catRows)
        row.uid: _toCategory(
          row,
          (fieldsByCategory[row.uid] ?? [])
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
        ),
    };
  }

  Category _toCategory(CategoryRow row, List<Field> fields) => Category(
    uid: row.uid,
    parentUid: row.parentUid,
    name: row.name,
    timeModel: TimeModel.values[row.timeModelIndex],
    ownFields: fields,
  );

  Field _toField(FieldRow row) {
    final constraint = (row.constraintMin != null || row.constraintMax != null)
        ? FieldConstraint(min: row.constraintMin, max: row.constraintMax)
        : null;

    final enumOptions = row.enumOptionsJson != null
        ? List<String>.from(jsonDecode(row.enumOptionsJson!) as List<dynamic>)
        : <String>[];

    return Field(
      uid: row.uid,
      categoryUid: row.categoryUid,
      name: row.name,
      fieldType: FieldType.values[row.fieldTypeIndex],
      sortOrder: row.sortOrder,
      constraint: constraint,
      unit: row.unit,
      enumOptions: enumOptions,
    );
  }
}
