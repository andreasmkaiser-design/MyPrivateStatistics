import 'package:private_statistics/features/categories/domain/models/field.dart';
import 'package:private_statistics/features/categories/domain/models/time_model.dart';

/// A user-defined classification that groups Events of the same kind.
///
/// A Category carries a Schema (its [ownFields]) and a [timeModel]. Categories
/// can be nested up to 5 levels deep via [parentUid]. A Category without a
/// [parentUid] is a root category. The full merged schema — including fields
/// inherited from ancestor categories — is resolved by
/// `SchemaInheritanceResolver`.
class Category {
  /// Creates an immutable [Category].
  const Category({
    required this.uid,
    required this.name,
    required this.timeModel,
    required this.ownFields,
    this.parentUid,
  });

  /// Globally unique identifier for this category within this app installation.
  final String uid;

  /// The UID of the parent category, or `null` if this is a root category.
  final String? parentUid;

  /// Human-readable name shown throughout the UI.
  final String name;

  /// Determines whether Events in this category are recorded as a
  /// `TimeModel.timePoint` or one of the time-range variants.
  final TimeModel timeModel;

  /// The fields defined directly on this category, in [Field.sortOrder] order.
  ///
  /// Does NOT include inherited fields. Use `SchemaInheritanceResolver` to
  /// obtain the full merged schema including ancestor fields.
  final List<Field> ownFields;

  /// Whether this category has no parent (i.e. it is at the top of the tree).
  bool get isRoot => parentUid == null;
}
