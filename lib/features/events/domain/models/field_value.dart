/// A typed value recorded for one field on an `Event`.
///
/// Use the appropriate concrete subclass that matches the owning
/// `Field.fieldType`:
/// - [IntFieldValue] for `FieldType.integer`
/// - [FloatFieldValue] for `FieldType.float`
/// - [BoolFieldValue] for `FieldType.boolean`
/// - [EnumFieldValue] for `FieldType.enumeration`
sealed class FieldValue {
  /// Creates a [FieldValue] bound to the field identified by [fieldUid].
  const FieldValue({required this.fieldUid});

  /// The UID of the `Field` this value belongs to.
  final String fieldUid;
}

/// A [FieldValue] for `FieldType.integer` fields.
final class IntFieldValue extends FieldValue {
  /// Creates an [IntFieldValue].
  const IntFieldValue({required super.fieldUid, required this.value});

  /// The integer value.
  final int value;
}

/// A [FieldValue] for `FieldType.float` fields.
final class FloatFieldValue extends FieldValue {
  /// Creates a [FloatFieldValue].
  const FloatFieldValue({required super.fieldUid, required this.value});

  /// The float value.
  final double value;
}

/// A [FieldValue] for `FieldType.boolean` fields.
final class BoolFieldValue extends FieldValue {
  /// Creates a [BoolFieldValue].
  const BoolFieldValue({required super.fieldUid, required this.value});

  /// The boolean value.
  final bool value;
}

/// A [FieldValue] for `FieldType.enumeration` fields.
final class EnumFieldValue extends FieldValue {
  /// Creates an [EnumFieldValue].
  const EnumFieldValue({required super.fieldUid, required this.value});

  /// The selected enum option; must be one of the owning `Field.enumOptions`.
  final String value;
}
