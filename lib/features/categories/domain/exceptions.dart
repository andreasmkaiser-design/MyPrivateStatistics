import 'package:private_statistics/core/exceptions.dart';

/// Thrown when a new category would exceed the maximum hierarchy depth of 5.
class CategoryDepthLimitExceededException extends AppException {
  /// Creates a [CategoryDepthLimitExceededException] with the given [message].
  const CategoryDepthLimitExceededException(super.message);
}

/// Thrown when a category with the requested UID cannot be found.
class CategoryNotFoundException extends AppException {
  /// Creates a [CategoryNotFoundException] for the category with [uid].
  const CategoryNotFoundException(String uid)
    : super('Category not found: $uid');
}

/// Thrown when a category name is already in use within the same parent.
class DuplicateCategoryNameException extends AppException {
  /// Creates a [DuplicateCategoryNameException] for the duplicate [name].
  const DuplicateCategoryNameException(String name)
    : super('Category name already exists: $name');
}

/// Thrown when a caller attempts to modify a field that was inherited from an
/// ancestor category.
class CannotModifyInheritedFieldException extends AppException {
  /// Creates a [CannotModifyInheritedFieldException] for the field with
  /// UID `fieldUid`.
  const CannotModifyInheritedFieldException(String fieldUid)
    : super('Cannot modify inherited field: $fieldUid');
}

/// Thrown when a `FieldConstraint` is invalid (e.g. min > max).
class InvalidFieldConstraintException extends AppException {
  /// Creates an [InvalidFieldConstraintException] with the given [message].
  const InvalidFieldConstraintException(super.message);
}
