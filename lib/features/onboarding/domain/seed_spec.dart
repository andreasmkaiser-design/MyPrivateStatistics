import 'package:flutter/foundation.dart';
import 'package:private_statistics/features/categories/domain/models/field_type.dart';
import 'package:private_statistics/features/categories/domain/models/time_model.dart';

/// Declarative specification for a single field in a seed category.
///
/// Mapped to a `Field` domain object by `DriftCategorySeeder`.
@immutable
class FieldSpec {
  /// Creates a [FieldSpec].
  const FieldSpec({
    required this.uid,
    required this.name,
    this.type = FieldType.float,
    this.unit,
  });

  /// Stable, globally unique identifier for this field.
  final String uid;

  /// Human-readable label for this field.
  final String name;

  /// Data type; defaults to [FieldType.float].
  final FieldType type;

  /// Optional unit of measurement (e.g. `'h'`, `'km'`).
  final String? unit;
}

/// Declarative specification for a seed category tree node.
///
/// `DriftCategorySeeder` walks this tree and creates `Category` objects
/// idempotently. The [uid] is the idempotency key: if a category with this UID
/// already exists the node (and its subtree) is skipped.
@immutable
class SeedSpec {
  /// Creates a [SeedSpec].
  const SeedSpec({
    required this.uid,
    required this.name,
    this.parentUid,
    this.timeModel = TimeModel.timePoint,
    this.fields = const [],
    this.children = const [],
  });

  /// Stable unique identifier used as the idempotency key.
  final String uid;

  /// Display name of the category.
  final String name;

  /// UID of the parent category; `null` for root categories.
  final String? parentUid;

  /// Time model applied to Events in this category.
  final TimeModel timeModel;

  /// Fields owned by this category (not inherited).
  final List<FieldSpec> fields;

  /// Child categories nested under this node.
  final List<SeedSpec> children;
}
