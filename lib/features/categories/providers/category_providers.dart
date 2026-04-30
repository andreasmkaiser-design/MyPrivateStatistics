import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_statistics/core/database/database_provider.dart';
import 'package:private_statistics/features/categories/data/category_repository_impl.dart';
import 'package:private_statistics/features/categories/domain/models/category.dart';
import 'package:private_statistics/features/categories/domain/models/category_node.dart';
import 'package:private_statistics/features/categories/domain/repositories/category_repository.dart';

/// Provides the [CategoryRepository] backed by the app's Drift database.
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(ref.watch(appDatabaseProvider));
});

/// Reactive stream of the full category tree.
///
/// Re-emits whenever any category or field is created, modified, or deleted.
/// Backed by [CategoryRepository.watchTree].
final categoryTreeProvider = StreamProvider<List<CategoryNode>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchTree();
});

/// Resolves a single [Category] by UID.
///
/// Returns `null` if no category with the given UID exists.
/// Backed by [CategoryRepository.findByUid].
final categoryProvider = FutureProvider.family<Category?, String>((
  ref,
  uid,
) async {
  return ref.watch(categoryRepositoryProvider).findByUid(uid);
});
