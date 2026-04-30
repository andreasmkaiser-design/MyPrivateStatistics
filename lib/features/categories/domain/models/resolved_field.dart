import 'package:private_statistics/features/categories/domain/models/field.dart';

/// A [Field] annotated with whether it was inherited from an ancestor Category.
///
/// Produced by `SchemaInheritanceResolver.resolveSchema`. Consumers use
/// [isInherited] to mark inherited fields as read-only in the UI and to
/// prevent modification from subcategories.
class ResolvedField {
  /// Creates a [ResolvedField].
  const ResolvedField({required this.field, required this.isInherited});

  /// The underlying field definition.
  final Field field;

  /// Whether this field was defined by an ancestor category.
  ///
  /// `true` means the field is inherited and must not be modified by the
  /// current category. `false` means it is defined directly on the current
  /// category.
  final bool isInherited;
}
