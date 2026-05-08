import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_statistics/core/logging/app_logger.dart';
import 'package:private_statistics/features/categories/domain/exceptions.dart';
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

  /// Returns lower-cased names of all siblings of [node] (excluding itself).
  Set<String> _siblingNamesFor(List<CategoryNode> roots, CategoryNode node) {
    final uid = node.category.uid;
    if (node.category.parentUid == null) {
      return roots
          .where((n) => n.category.uid != uid)
          .map((n) => n.category.name.toLowerCase())
          .toSet();
    }
    final parent = _findParent(roots, node);
    return parent?.children
            .where((n) => n.category.uid != uid)
            .map((n) => n.category.name.toLowerCase())
            .toSet() ??
        {};
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    CategoryNode node,
  ) async {
    final roots = ref.read(categoryTreeProvider).valueOrNull ?? [];
    final siblingNames = _siblingNamesFor(roots, node);
    final repo = ref.read(categoryRepositoryProvider);

    await showDialog<void>(
      context: context,
      builder: (_) => _RenameCategoryDialog(
        initialName: node.category.name,
        siblingNames: siblingNames,
        onRename: (newName) async {
          await repo.rename(node.category.uid, newName);
          AppLogger.info('Category renamed: ${node.category.uid}');
        },
      ),
    );
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

class _RenameCategoryDialog extends StatefulWidget {
  const _RenameCategoryDialog({
    required this.initialName,
    required this.siblingNames,
    required this.onRename,
  });

  /// The current name of the category being renamed.
  final String initialName;

  /// Lower-cased names of all siblings (self excluded).
  final Set<String> siblingNames;

  /// Called with the trimmed new name when the user confirms.
  ///
  /// Throws [DuplicateCategoryNameException] if the name is already taken;
  /// throws other exceptions for infrastructure failures.
  final Future<void> Function(String) onRename;

  @override
  State<_RenameCategoryDialog> createState() => _RenameCategoryDialogState();
}

class _RenameCategoryDialogState extends State<_RenameCategoryDialog> {
  late final TextEditingController _controller;
  String? _error;
  bool _isRenaming = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChange(String value) {
    setState(() {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty &&
          widget.siblingNames.contains(trimmed.toLowerCase())) {
        _error = 'Name already used by a sibling category';
      } else {
        _error = null;
      }
    });
  }

  Future<void> _submit() async {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) return;
    setState(() => _isRenaming = true);
    try {
      await widget.onRename(trimmed);
      if (mounted) Navigator.of(context).pop();
    } on DuplicateCategoryNameException catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Name already used by a sibling category';
          _isRenaming = false;
        });
      }
    } on Object catch (e, st) {
      AppLogger.error('Failed to rename category', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to rename category')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  bool get _canRename =>
      _error == null && _controller.text.trim().isNotEmpty && !_isRenaming;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename category'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: 'Name', errorText: _error),
        textCapitalization: TextCapitalization.sentences,
        onChanged: _onChange,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _canRename ? _submit : null,
          child: const Text('Rename'),
        ),
      ],
    );
  }
}
