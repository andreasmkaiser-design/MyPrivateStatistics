import 'package:private_statistics/features/categories/domain/models/field.dart';

/// A single flat entry in a JSON template, representing one `Category`.
///
/// The flat array format (ADR-0010) stores all categories at the same level;
/// the tree is reconstructed from [parentUid] references on import.
///
/// On export the category's own [uid] is stored as [sourceUid] so that a
/// receiving installation can track which original category an imported one
/// came from.
class TemplateEntry {
  /// Creates a [TemplateEntry].
  const TemplateEntry({
    required this.uid,
    required this.name,
    required this.parentUid,
    required this.timeModelIndex,
    required this.fields,
    this.sourceUid,
  });

  /// Creates a [TemplateEntry] from a JSON object.
  factory TemplateEntry.fromJson(Map<String, dynamic> json) {
    final fieldsList = (json['fields'] as List<dynamic>? ?? [])
        .map((f) => TemplateFieldEntry.fromJson(f as Map<String, dynamic>))
        .toList();
    return TemplateEntry(
      uid: json['uid'] as String,
      name: json['name'] as String,
      parentUid: json['parent_uid'] as String?,
      sourceUid: json['source_uid'] as String?,
      timeModelIndex: json['time_model_index'] as int,
      fields: fieldsList,
    );
  }

  /// The UID of this category in the exporting app.
  final String uid;

  /// Human-readable category name.
  final String name;

  /// UID of the parent category in the exporting app, or `null` for roots.
  final String? parentUid;

  /// The UID this entry was originally imported from; `null` on first export.
  final String? sourceUid;

  /// Ordinal index of the `TimeModel` enum value.
  final int timeModelIndex;

  /// Field definitions owned directly by this category.
  final List<TemplateFieldEntry> fields;

  /// Serialises this entry to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'parent_uid': parentUid,
    'source_uid': sourceUid,
    'time_model_index': timeModelIndex,
    'fields': fields.map((f) => f.toJson()).toList(),
  };
}

/// A single field definition within a [TemplateEntry].
///
/// Carries the full field schema — type, constraints, unit, and enum options —
/// so the hierarchy can be fully reconstructed on import.
class TemplateFieldEntry {
  /// Creates a [TemplateFieldEntry].
  const TemplateFieldEntry({
    required this.uid,
    required this.name,
    required this.fieldTypeIndex,
    required this.sortOrder,
    this.unit,
    this.constraintMin,
    this.constraintMax,
    this.enumOptions = const [],
  });

  /// Creates a [TemplateFieldEntry] from a [Field] domain object.
  factory TemplateFieldEntry.fromField(Field field) => TemplateFieldEntry(
    uid: field.uid,
    name: field.name,
    fieldTypeIndex: field.fieldType.index,
    sortOrder: field.sortOrder,
    unit: field.unit,
    constraintMin: field.constraint?.min,
    constraintMax: field.constraint?.max,
    enumOptions: field.enumOptions,
  );

  /// Creates a [TemplateFieldEntry] from a JSON object.
  factory TemplateFieldEntry.fromJson(Map<String, dynamic> json) =>
      TemplateFieldEntry(
        uid: json['uid'] as String,
        name: json['name'] as String,
        fieldTypeIndex: json['field_type_index'] as int,
        sortOrder: json['sort_order'] as int,
        unit: json['unit'] as String?,
        constraintMin: (json['constraint_min'] as num?)?.toDouble(),
        constraintMax: (json['constraint_max'] as num?)?.toDouble(),
        enumOptions: (json['enum_options'] as List<dynamic>? ?? [])
            .cast<String>(),
      );

  /// Globally unique identifier for this field.
  final String uid;

  /// Human-readable field label.
  final String name;

  /// Ordinal index of the `FieldType` enum.
  final int fieldTypeIndex;

  /// Zero-based display order within the owning category.
  final int sortOrder;

  /// Unit of measurement; meaningful only for float fields.
  final String? unit;

  /// Inclusive lower bound; meaningful only for numeric fields.
  final double? constraintMin;

  /// Inclusive upper bound; meaningful only for numeric fields.
  final double? constraintMax;

  /// Fixed set of allowed values; meaningful only for enumeration fields.
  final List<String> enumOptions;

  /// Serialises this entry to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'field_type_index': fieldTypeIndex,
    'sort_order': sortOrder,
    'unit': unit,
    'constraint_min': constraintMin,
    'constraint_max': constraintMax,
    'enum_options': enumOptions,
  };
}
