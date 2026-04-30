import 'package:private_statistics/features/categories/domain/models/field_constraint.dart';
import 'package:private_statistics/features/categories/domain/models/field_type.dart';

/// A single typed data attribute within a Category's Schema.
///
/// Fields are defined on the `Category` that owns them. Subcategories inherit
/// their parent's fields at read time via `SchemaInheritanceResolver` and may
/// add their own, but cannot remove or override inherited ones.
class Field {
  /// Creates an immutable [Field].
  const Field({
    required this.uid,
    required this.categoryUid,
    required this.name,
    required this.fieldType,
    required this.sortOrder,
    this.constraint,
    this.unit,
    this.enumOptions = const [],
  });

  /// Globally unique identifier for this field.
  final String uid;

  /// The UID of the `Category` that defines (owns) this field.
  final String categoryUid;

  /// Human-readable label shown in event forms and category detail screens.
  final String name;

  /// The data type that determines how values for this field are stored and
  /// validated.
  final FieldType fieldType;

  /// Zero-based position within the owning category's own field list.
  ///
  /// Lower values appear first. Inherited fields preserve the sort order
  /// defined by their ancestor.
  final int sortOrder;

  /// Optional numeric bounds; meaningful only for [FieldType.integer] and
  /// [FieldType.float].
  final FieldConstraint? constraint;

  /// The unit of measurement (e.g. `'km'`, `'bpm'`); meaningful only for
  /// [FieldType.float].
  final String? unit;

  /// The fixed set of allowed values; meaningful only for
  /// [FieldType.enumeration].
  final List<String> enumOptions;
}
