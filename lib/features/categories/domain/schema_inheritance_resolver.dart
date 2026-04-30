import 'package:private_statistics/features/categories/domain/exceptions.dart';
import 'package:private_statistics/features/categories/domain/models/category.dart';
import 'package:private_statistics/features/categories/domain/models/resolved_field.dart';

/// Resolves the full Schema for a [Category] by walking its ancestor chain.
///
/// This is a pure synchronous domain class with no I/O dependencies; it
/// operates entirely on in-memory [Category] maps.
class SchemaInheritanceResolver {
  /// Maximum number of levels in the category hierarchy (root = level 1).
  static const int maxDepth = 5;

  /// Returns the merged, ordered list of [ResolvedField]s for [category].
  ///
  /// Fields from ancestor categories appear first (top-most ancestor first),
  /// each with [ResolvedField.isInherited] set to `true`. The category's own
  /// fields appear last with [ResolvedField.isInherited] set to `false`.
  ///
  /// [allCategories] must be a map of UID → [Category] containing every
  /// category reachable from [category]'s ancestor chain.
  List<ResolvedField> resolveSchema(
    Category category,
    Map<String, Category> allCategories,
  ) {
    final ancestors = _ancestorChain(category, allCategories);
    final resolved = <ResolvedField>[];
    for (final ancestor in ancestors.reversed) {
      for (final field in ancestor.ownFields) {
        resolved.add(ResolvedField(field: field, isInherited: true));
      }
    }
    for (final field in category.ownFields) {
      resolved.add(ResolvedField(field: field, isInherited: false));
    }
    return resolved;
  }

  /// Throws [CategoryDepthLimitExceededException] if placing [category]
  /// in the hierarchy would exceed [maxDepth].
  ///
  /// [allCategories] should contain the existing persisted categories but
  /// NOT [category] itself (which has not yet been saved).
  void validateDepth(Category category, Map<String, Category> allCategories) {
    final ancestors = _ancestorChain(category, allCategories);
    if (ancestors.length >= maxDepth) {
      throw const CategoryDepthLimitExceededException(
        'Category hierarchy exceeds max depth of $maxDepth levels',
      );
    }
  }

  List<Category> _ancestorChain(
    Category category,
    Map<String, Category> allCategories,
  ) {
    final chain = <Category>[];
    var current = category;
    while (current.parentUid != null) {
      final parent = allCategories[current.parentUid];
      if (parent == null) break;
      chain.add(parent);
      current = parent;
    }
    return chain;
  }
}
