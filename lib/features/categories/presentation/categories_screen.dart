import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_statistics/core/logging/app_logger.dart';
import 'package:private_statistics/features/categories/domain/models/category_node.dart';
import 'package:private_statistics/features/categories/presentation/category_form_screen.dart';
import 'package:private_statistics/features/categories/presentation/category_tree_tile.dart';
import 'package:private_statistics/features/categories/providers/category_providers.dart';

/// The Categories tab — shows the full category tree and entry points for
/// creating, editing, renaming, and deleting categories.
class CategoriesScreen extends ConsumerWidget {
  /// Creates the [CategoriesScreen].
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeAsync = ref.watch(categoryTreeProvider);
    final expandedUids = ref.watch(expandedCategoryUidsProvider);

    return Scaffold(
      body: treeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          AppLogger.error('Failed to load category tree', error);
          return const Center(child: Text('Failed to load categories'));
        },
        data: (roots) => roots.isEmpty
            ? const _CategoryEmptyState()
            : ListView.builder(
                itemCount: roots.length,
                itemBuilder: (_, i) => CategoryTreeTile(
                  node: roots[i],
                  depth: 0,
                  expandedUids: expandedUids,
                  onToggleExpand: (uid) =>
                      _toggleExpand(ref, expandedUids, uid),
                  onEdit: (node) => _openEditForm(context, node, roots),
                  onDelete: (node) => _showDeleteDialog(context, ref, node),
                  onAddChild: (node) =>
                      _openCreateSubcategoryForm(context, node),
                  onRename: (node) => _showRenameDialog(context, ref, node),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateRootForm(context),
        tooltip: 'New category',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _toggleExpand(WidgetRef ref, Set<String> current, String uid) {
    final updated = Set<String>.from(current);
    if (updated.contains(uid)) {
      updated.remove(uid);
    } else {
      updated.add(uid);
    }
    ref.read(expandedCategoryUidsProvider.notifier).state = updated;
  }

  CategoryNode? _findParent(List<CategoryNode> roots, CategoryNode target) {
    for (final root in roots) {
      final result = _findParentIn(root, target);
      if (result != null) return result;
    }
    return null;
  }

  CategoryNode? _findParentIn(CategoryNode current, CategoryNode target) {
    for (final child in current.children) {
      if (child.category.uid == target.category.uid) return current;
      final deeper = _findParentIn(child, target);
      if (deeper != null) return deeper;
    }
    return null;
  }

  Future<void> _openCreateRootForm(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const CategoryFormScreen.createRoot(),
      ),
    );
  }

  Future<void> _openCreateSubcategoryForm(
    BuildContext context,
    CategoryNode parent,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            CategoryFormScreen.createSubcategory(parentNode: parent),
      ),
    );
  }

  Future<void> _openEditForm(
    BuildContext context,
    CategoryNode node,
    List<CategoryNode> roots,
  ) async {
    final parentNode = _findParent(roots, node);
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            CategoryFormScreen.fromNode(node: node, parentNode: parentNode),
      ),
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    CategoryNode node,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteCategoryDialog(categoryName: node.category.name),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final repo = ref.read(categoryRepositoryProvider);
    try {
      await repo.delete(node.category.uid);
      AppLogger.info('Category deleted: ${node.category.uid}');
    } on Object catch (e, st) {
      AppLogger.error('Failed to delete category', e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete category')),
        );
      }
    }
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    CategoryNode node,
  ) async {
    final controller = TextEditingController(text: node.category.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => _RenameCategoryDialog(controller: controller),
    );
    if (newName == null || newName.trim().isEmpty) return;
    if (!context.mounted) return;

    final repo = ref.read(categoryRepositoryProvider);
    try {
      await repo.rename(node.category.uid, newName.trim());
      AppLogger.info('Category renamed: ${node.category.uid}');
    } on Object catch (e, st) {
      AppLogger.error('Failed to rename category', e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to rename category')),
        );
      }
    }
  }
}

// ── Private widgets ──────────────────────────────────────────────────────

class _CategoryEmptyState extends StatelessWidget {
  const _CategoryEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No categories yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first category',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _DeleteCategoryDialog extends StatelessWidget {
  const _DeleteCategoryDialog({required this.categoryName});

  final String categoryName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete category'),
      content: Text(
        'Delete "$categoryName" and all its subcategories? '
        'This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

class _RenameCategoryDialog extends StatelessWidget {
  const _RenameCategoryDialog({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename category'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Name'),
        textCapitalization: TextCapitalization.sentences,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: const Text('Rename'),
        ),
      ],
    );
  }
}
