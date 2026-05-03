import 'package:flutter/material.dart';
import 'package:private_statistics/features/categories/domain/models/category_node.dart';

enum _TileAction { edit, rename, addChild, delete }

/// A single row in the category tree.
///
/// Renders [node] at the given [depth] (0 = root). When [node] has children
/// and its UID is in [expandedUids] the children are rendered recursively
/// below this tile, each indented by one level. A popup menu provides Edit,
/// Rename, Add subcategory (hidden at [depth] ≥ 4), and Delete actions.
class CategoryTreeTile extends StatelessWidget {
  /// Creates a [CategoryTreeTile].
  const CategoryTreeTile({
    required this.node,
    required this.depth,
    required this.expandedUids,
    required this.onToggleExpand,
    required this.onEdit,
    required this.onDelete,
    required this.onAddChild,
    required this.onRename,
    super.key,
  });

  /// The category node to render.
  final CategoryNode node;

  /// Zero-based nesting level (0 = root category).
  final int depth;

  /// Set of category UIDs whose children are currently visible.
  final Set<String> expandedUids;

  /// Called when the user taps the expand/collapse chevron.
  final void Function(String uid) onToggleExpand;

  /// Called when the user selects Edit from the popup menu.
  final void Function(CategoryNode node) onEdit;

  /// Called when the user selects Delete from the popup menu.
  final void Function(CategoryNode node) onDelete;

  /// Called when the user selects Add subcategory from the popup menu.
  ///
  /// Not shown when [depth] ≥ 4 (which would exceed the 5-level maximum).
  final void Function(CategoryNode node) onAddChild;

  /// Called when the user selects Rename from the popup menu.
  final void Function(CategoryNode node) onRename;

  void _handleAction(_TileAction action) {
    switch (action) {
      case _TileAction.edit:
        onEdit(node);
      case _TileAction.rename:
        onRename(node);
      case _TileAction.addChild:
        onAddChild(node);
      case _TileAction.delete:
        onDelete(node);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpanded = expandedUids.contains(node.category.uid);
    final hasChildren = node.children.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.only(left: 8.0 + depth * 16.0, right: 8),
          leading: hasChildren
              ? IconButton(
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () => onToggleExpand(node.category.uid),
                )
              : const SizedBox(width: 48),
          title: Text(node.category.name),
          onTap: () => onEdit(node),
          trailing: PopupMenuButton<_TileAction>(
            onSelected: _handleAction,
            itemBuilder: (_) => [
              const PopupMenuItem(value: _TileAction.edit, child: Text('Edit')),
              const PopupMenuItem(
                value: _TileAction.rename,
                child: Text('Rename'),
              ),
              if (depth < 4)
                const PopupMenuItem(
                  value: _TileAction.addChild,
                  child: Text('Add subcategory'),
                ),
              const PopupMenuItem(
                value: _TileAction.delete,
                child: Text('Delete'),
              ),
            ],
          ),
        ),
        if (isExpanded)
          ...node.children.map(
            (child) => CategoryTreeTile(
              node: child,
              depth: depth + 1,
              expandedUids: expandedUids,
              onToggleExpand: onToggleExpand,
              onEdit: onEdit,
              onDelete: onDelete,
              onAddChild: onAddChild,
              onRename: onRename,
            ),
          ),
      ],
    );
  }
}
