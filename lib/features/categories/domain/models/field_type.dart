/// The data type of a `Field`.
enum FieldType {
  /// A whole-number value.
  integer,

  /// A floating-point value; may carry a `Field.unit`.
  float,

  /// A true / false flag.
  boolean,

  /// A value chosen from a fixed set of options defined in `Field.enumOptions`.
  enumeration,
}
