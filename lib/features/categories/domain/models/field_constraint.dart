/// An optional min/max bound applied to a numeric `Field`.
///
/// Applies only to `FieldType.integer` and `FieldType.float` fields.
/// Either bound may be omitted independently.
class FieldConstraint {
  /// Creates a [FieldConstraint] with optional lower and upper bounds.
  const FieldConstraint({this.min, this.max});

  /// Inclusive lower bound, or `null` if there is no lower bound.
  final double? min;

  /// Inclusive upper bound, or `null` if there is no upper bound.
  final double? max;
}
