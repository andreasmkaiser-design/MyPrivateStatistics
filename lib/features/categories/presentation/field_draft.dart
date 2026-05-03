import 'package:private_statistics/features/categories/domain/models/field.dart';
import 'package:private_statistics/features/categories/domain/models/field_constraint.dart';
import 'package:private_statistics/features/categories/domain/models/field_type.dart';

int _draftCounter = 0;

/// An in-progress field definition held in memory during category create/edit.
///
/// Each [FieldDraft] has a stable [draftUid] used as a key in
/// `ReorderableListView`; this key is not persisted to the database.
/// Call [toField] to convert to a [Field] when the form is saved.
class FieldDraft {
  /// Creates a [FieldDraft].
  ///
  /// If [draftUid] is omitted a unique local identifier is generated
  /// automatically.
  FieldDraft({
    String? draftUid,
    this.existingUid,
    this.name = '',
    this.fieldType = FieldType.integer,
    this.constraintMin,
    this.constraintMax,
    this.unit,
    this.enumOptions = const [],
  }) : draftUid = draftUid ?? 'draft-${_draftCounter++}';

  /// A stable local key for `ReorderableListView`; never written to the
  /// database.
  final String draftUid;

  /// The UID of the persisted [Field] this draft represents, or `null` when
  /// this is a new field that has not yet been saved.
  final String? existingUid;

  /// Human-readable label shown in event forms and the category detail screen.
  final String name;

  /// Data type that determines how values for this field are stored and
  /// validated.
  final FieldType fieldType;

  /// Inclusive lower bound; meaningful only for [FieldType.integer] and
  /// [FieldType.float].
  final double? constraintMin;

  /// Inclusive upper bound; meaningful only for [FieldType.integer] and
  /// [FieldType.float].
  final double? constraintMax;

  /// Unit of measurement (e.g. `'km'`); meaningful only for [FieldType.float].
  final String? unit;

  /// Fixed set of allowed values; meaningful only for [FieldType.enumeration].
  final List<String> enumOptions;

  /// Returns a copy of this draft with the given fields replaced.
  ///
  /// [draftUid] and [existingUid] are always preserved from the original.
  FieldDraft copyWith({
    String? name,
    FieldType? fieldType,
    double? constraintMin,
    double? constraintMax,
    String? unit,
    List<String>? enumOptions,
  }) => FieldDraft(
    draftUid: draftUid,
    existingUid: existingUid,
    name: name ?? this.name,
    fieldType: fieldType ?? this.fieldType,
    constraintMin: constraintMin ?? this.constraintMin,
    constraintMax: constraintMax ?? this.constraintMax,
    unit: unit ?? this.unit,
    enumOptions: enumOptions ?? this.enumOptions,
  );

  /// Converts this draft to a persisted [Field].
  ///
  /// Uses [existingUid] as the field UID when available (edit mode); otherwise
  /// falls back to [draftUid] (create mode). Fields not relevant to the
  /// current [fieldType] are cleared: [unit] is only kept for
  /// [FieldType.float], [enumOptions] only for [FieldType.enumeration], and
  /// constraint is only kept for [FieldType.integer] and [FieldType.float].
  Field toField({required String categoryUid, required int sortOrder}) {
    final keepConstraint =
        fieldType == FieldType.integer || fieldType == FieldType.float;
    return Field(
      uid: existingUid ?? draftUid,
      categoryUid: categoryUid,
      name: name,
      fieldType: fieldType,
      sortOrder: sortOrder,
      constraint:
          keepConstraint && (constraintMin != null || constraintMax != null)
          ? FieldConstraint(min: constraintMin, max: constraintMax)
          : null,
      unit: fieldType == FieldType.float ? unit : null,
      enumOptions: fieldType == FieldType.enumeration
          ? List<String>.unmodifiable(enumOptions)
          : const [],
    );
  }
}
