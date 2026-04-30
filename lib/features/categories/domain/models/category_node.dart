import 'package:private_statistics/features/categories/domain/models/category.dart';
import 'package:private_statistics/features/categories/domain/models/resolved_field.dart';

/// A node in the fully assembled category tree.
///
/// Returned by `CategoryRepository.watchTree`. Each node wraps a [Category]
/// together with its resolved child subtree and the full merged schema
/// as produced by `SchemaInheritanceResolver`.
class CategoryNode {
  /// Creates an immutable [CategoryNode].
  const CategoryNode({
    required this.category,
    required this.children,
    required this.mergedSchema,
  });

  /// The category this node represents.
  final Category category;

  /// Direct subcategories of [category], each represented as their own node.
  final List<CategoryNode> children;

  /// All fields available on [category], including those inherited from
  /// ancestor categories, in ancestor-first order.
  ///
  /// Inherited fields have [ResolvedField.isInherited] set to `true`.
  final List<ResolvedField> mergedSchema;
}
