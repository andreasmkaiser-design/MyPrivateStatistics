import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_statistics/core/logging/app_logger.dart';
import 'package:private_statistics/features/categories/domain/exceptions.dart';
import 'package:private_statistics/features/categories/domain/models/category.dart';
import 'package:private_statistics/features/categories/domain/models/category_node.dart';
import 'package:private_statistics/features/categories/domain/models/resolved_field.dart';
import 'package:private_statistics/features/categories/domain/models/time_model.dart';
import 'package:private_statistics/features/categories/domain/schema_inheritance_resolver.dart';
import 'package:private_statistics/features/categories/presentation/field_draft.dart';
import 'package:private_statistics/features/categories/presentation/field_editor_row.dart';
import 'package:private_statistics/features/categories/providers/category_providers.dart';

final Random _random = Random.secure();

String _generateUid() {
  final timestamp = DateTime.now().microsecondsSinceEpoch;
  final suffix = _random.nextInt(999999).toString().padLeft(6, '0');
  return '$timestamp-$suffix';
}

enum _FormMode { createRoot, createSubcategory, edit }

// ── Form data ────────────────────────────────────────────────────────────

class _FormData {
  _FormData({
    this.existingUid,
    this.parentUid,
    this.name = '',
    this.timeModel = TimeModel.timePoint,
    this.fields = const [],
    this.inheritedFields = const [],
  });

  final String? existingUid;
  final String? parentUid;
  final String name;
  final TimeModel timeModel;
  final List<FieldDraft> fields;
  final List<ResolvedField> inheritedFields;

  bool get isRoot => parentUid == null;
  bool get isEditing => existingUid != null;

  _FormData copyWith({
    String? name,
    TimeModel? timeModel,
    List<FieldDraft>? fields,
  }) => _FormData(
    existingUid: existingUid,
    parentUid: parentUid,
    name: name ?? this.name,
    timeModel: timeModel ?? this.timeModel,
    fields: fields ?? this.fields,
    inheritedFields: inheritedFields,
  );
}

// ── Screen ───────────────────────────────────────────────────────────────

/// Full-screen form for creating or editing a [Category].
///
/// Use the named constructors [CategoryFormScreen.createRoot],
/// [CategoryFormScreen.createSubcategory], and [CategoryFormScreen.fromNode]
/// to open the appropriate mode. The form validates the name inline and
/// shows infrastructure errors via a [SnackBar] (per ADR-0014).
class CategoryFormScreen extends ConsumerStatefulWidget {
  /// Creates a form for a new root category.
  const CategoryFormScreen.createRoot({super.key})
    : _mode = _FormMode.createRoot,
      _parentNode = null,
      _existingNode = null;

  /// Creates a form for a new subcategory under [parentNode].
  const CategoryFormScreen.createSubcategory({
    required CategoryNode parentNode,
    super.key,
  }) : _mode = _FormMode.createSubcategory,
       _parentNode = parentNode,
       _existingNode = null;

  /// Creates a form pre-populated with data from [node] for editing.
  const CategoryFormScreen.fromNode({
    required CategoryNode node,
    CategoryNode? parentNode,
    super.key,
  }) : _mode = _FormMode.edit,
       _existingNode = node,
       _parentNode = parentNode;

  final _FormMode _mode;
  final CategoryNode? _parentNode;
  final CategoryNode? _existingNode;

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  late _FormData _data;
  late TextEditingController _nameController;
  String? _nameError;
  bool _isSaving = false;
  List<String> _pendingChildren = [];

  @override
  void initState() {
    super.initState();
    switch (widget._mode) {
      case _FormMode.createRoot:
        _data = _FormData();
      case _FormMode.createSubcategory:
        final parent = widget._parentNode!;
        _data = _FormData(
          parentUid: parent.category.uid,
          timeModel: parent.category.timeModel,
          inheritedFields: parent.mergedSchema,
        );
      case _FormMode.edit:
        final node = widget._existingNode!;
        _data = _FormData(
          existingUid: node.category.uid,
          parentUid: node.category.parentUid,
          name: node.category.name,
          timeModel: node.category.timeModel,
          fields: node.category.ownFields
              .map(
                (f) => FieldDraft(
                  existingUid: f.uid,
                  name: f.name,
                  fieldType: f.fieldType,
                  constraintMin: f.constraint?.min,
                  constraintMax: f.constraint?.max,
                  unit: f.unit,
                  enumOptions: List<String>.from(f.enumOptions),
                ),
              )
              .toList(),
          inheritedFields: node.mergedSchema
              .where((f) => f.isInherited)
              .toList(),
        );
    }
    _nameController = TextEditingController(text: _data.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String get _title {
    return switch (widget._mode) {
      _FormMode.createRoot => 'New category',
      _FormMode.createSubcategory => 'New subcategory',
      _FormMode.edit => 'Edit category',
    };
  }

  void _setName(String value, Set<String> siblingNames) => setState(() {
    _data = _data.copyWith(name: value);
    final trimmed = value.trim();
    if (trimmed.isNotEmpty && siblingNames.contains(trimmed.toLowerCase())) {
      _nameError = 'Name already used by a sibling category';
    } else {
      _nameError = null;
    }
  });

  /// Returns the lower-cased names of all sibling categories for the current
  /// form mode, used for live duplicate-name validation.
  Set<String> _getSiblingNames(List<CategoryNode> roots) {
    switch (widget._mode) {
      case _FormMode.createRoot:
        return roots.map((n) => n.category.name.toLowerCase()).toSet();
      case _FormMode.createSubcategory:
        final parentUid = widget._parentNode!.category.uid;
        final parent = _findNodeByUid(roots, parentUid);
        return parent?.children
                .map((n) => n.category.name.toLowerCase())
                .toSet() ??
            {};
      case _FormMode.edit:
        final selfUid = widget._existingNode!.category.uid;
        final parentUid = widget._existingNode!.category.parentUid;
        if (parentUid == null) {
          return roots
              .where((n) => n.category.uid != selfUid)
              .map((n) => n.category.name.toLowerCase())
              .toSet();
        }
        final parent = _findNodeByUid(roots, parentUid);
        return parent?.children
                .where((n) => n.category.uid != selfUid)
                .map((n) => n.category.name.toLowerCase())
                .toSet() ??
            {};
    }
  }

  CategoryNode? _findNodeByUid(List<CategoryNode> nodes, String uid) {
    for (final node in nodes) {
      if (node.category.uid == uid) return node;
      final found = _findNodeByUid(node.children, uid);
      if (found != null) return found;
    }
    return null;
  }

  /// Returns the 0-based depth of the node with [uid] in [nodes], or -1.
  int _nodeDepth(List<CategoryNode> nodes, String uid, int depth) {
    for (final node in nodes) {
      if (node.category.uid == uid) return depth;
      final found = _nodeDepth(node.children, uid, depth + 1);
      if (found >= 0) return found;
    }
    return -1;
  }

  /// Whether the inline subcategory section should be shown.
  ///
  /// Hidden in edit mode and when the new category would sit at
  /// [SchemaInheritanceResolver.maxDepth] − 1, meaning its inline children
  /// would exceed the depth limit.
  bool _showSubcategorySection(List<CategoryNode> roots) {
    if (widget._mode == _FormMode.edit) return false;
    if (widget._mode == _FormMode.createRoot) return true;
    final parentUid = widget._parentNode!.category.uid;
    final parentDepth = _nodeDepth(roots, parentUid, 0);
    if (parentDepth < 0) return true; // tree not yet indexed — safe default
    // children of new category would be at parentDepth + 2
    return parentDepth + 2 < SchemaInheritanceResolver.maxDepth;
  }

  void _setTimeModel(TimeModel value) =>
      setState(() => _data = _data.copyWith(timeModel: value));

  void _addField() => setState(() {
    _data = _data.copyWith(fields: [..._data.fields, FieldDraft()]);
  });

  void _updateField(int index, FieldDraft updated) => setState(() {
    final list = List<FieldDraft>.from(_data.fields);
    list[index] = updated;
    _data = _data.copyWith(fields: list);
  });

  void _removeField(int index) => setState(() {
    final list = List<FieldDraft>.from(_data.fields)..removeAt(index);
    _data = _data.copyWith(fields: list);
  });

  void _reorderFields(int oldIndex, int newIndex) => setState(() {
    final list = List<FieldDraft>.from(_data.fields);
    final item = list.removeAt(oldIndex);
    final insertAt = newIndex > oldIndex ? newIndex - 1 : newIndex;
    list.insert(insertAt, item);
    _data = _data.copyWith(fields: list);
  });

  void _addChild(String name) =>
      setState(() => _pendingChildren = [..._pendingChildren, name]);

  void _removeChild(int index) => setState(() {
    final list = List<String>.from(_pendingChildren)..removeAt(index);
    _pendingChildren = list;
  });

  Future<void> _save() async {
    if (_data.name.trim().isEmpty) {
      setState(() => _nameError = 'Name is required');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uid = _data.existingUid ?? _generateUid();
      final fields = [
        for (var i = 0; i < _data.fields.length; i++)
          _data.fields[i].toField(categoryUid: uid, sortOrder: i),
      ];
      final category = Category(
        uid: uid,
        name: _data.name.trim(),
        parentUid: _data.parentUid,
        timeModel: _data.timeModel,
        ownFields: fields,
      );

      await ref.read(categoryRepositoryProvider).save(category);
      AppLogger.info('Category saved: $uid');

      if (_pendingChildren.isNotEmpty) {
        var failCount = 0;
        for (final childName in _pendingChildren) {
          try {
            await ref
                .read(categoryRepositoryProvider)
                .save(
                  Category(
                    uid: _generateUid(),
                    name: childName,
                    parentUid: uid,
                    timeModel: _data.timeModel,
                    ownFields: const [],
                  ),
                );
            AppLogger.info('Inline child saved: $childName');
          } on Object catch (e, st) {
            AppLogger.error('Failed to save inline child "$childName"', e, st);
            failCount++;
          }
        }
        if (failCount > 0 && mounted) {
          final suffix = failCount == 1 ? 'y' : 'ies';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$failCount subcategor$suffix could not be saved'),
            ),
          );
        }
      }

      if (mounted) Navigator.of(context).pop();
    } on DuplicateCategoryNameException catch (_) {
      if (mounted) {
        setState(() => _nameError = 'Name already used by a sibling category');
      }
    } on Object catch (e, st) {
      AppLogger.error('Failed to save category', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save category')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final treeAsync = ref.watch(categoryTreeProvider);
    final siblingNames = treeAsync.maybeWhen(
      data: _getSiblingNames,
      orElse: () => const <String>{},
    );
    final showSubcatSection = treeAsync.maybeWhen(
      data: _showSubcategorySection,
      orElse: () => widget._mode != _FormMode.edit,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          TextButton(
            onPressed: (_isSaving || _nameError != null) ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Name field
            TextField(
              decoration: InputDecoration(
                labelText: 'Name',
                errorText: _nameError,
              ),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (v) => _setName(v, siblingNames),
              controller: _nameController,
            ),
            const SizedBox(height: 16),

            // Time model — root categories only
            if (_data.isRoot) ...[
              Text('Time model', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              _TimeModelSelector(
                selected: _data.timeModel,
                onChanged: _setTimeModel,
              ),
              const SizedBox(height: 16),
            ],

            // Inherited fields — subcategories only
            if (_data.inheritedFields.isNotEmpty) ...[
              Text(
                'Inherited fields',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              ..._data.inheritedFields.map(
                (rf) => _InheritedFieldChip(resolvedField: rf),
              ),
              const SizedBox(height: 16),
            ],

            // Own fields header
            Text('Fields', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),

            // Reorderable own-field list
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: _reorderFields,
              children: [
                for (var i = 0; i < _data.fields.length; i++)
                  KeyedSubtree(
                    key: ValueKey(_data.fields[i].draftUid),
                    child: FieldEditorRow(
                      draft: _data.fields[i],
                      onChanged: (updated) => _updateField(i, updated),
                      onRemove: () => _removeField(i),
                    ),
                  ),
              ],
            ),

            // Add field button
            TextButton.icon(
              onPressed: _addField,
              icon: const Icon(Icons.add),
              label: const Text('Add field'),
            ),

            // Inline subcategory section — create modes only, depth-limited
            if (showSubcatSection) ...[
              const SizedBox(height: 16),
              _SubcategorySection(
                pendingNames: _pendingChildren,
                onAdd: _addChild,
                onRemove: _removeChild,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Private sub-widgets ──────────────────────────────────────────────────

class _TimeModelSelector extends StatelessWidget {
  const _TimeModelSelector({required this.selected, required this.onChanged});

  final TimeModel selected;
  final ValueChanged<TimeModel> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TimeModel>(
      segments: const [
        ButtonSegment(value: TimeModel.timePoint, label: Text('Time point')),
        ButtonSegment(
          value: TimeModel.dayPreciseRange,
          label: Text('Day range'),
        ),
        ButtonSegment(
          value: TimeModel.datetimePreciseRange,
          label: Text('Datetime range'),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (set) => onChanged(set.first),
    );
  }
}

class _InheritedFieldChip extends StatelessWidget {
  const _InheritedFieldChip({required this.resolvedField});

  final ResolvedField resolvedField;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: resolvedField.field.name,
          enabled: false,
          suffixText: 'inherited',
          border: const OutlineInputBorder(),
        ),
        child: Text(
          resolvedField.field.fieldType.name,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _SubcategorySection extends StatefulWidget {
  const _SubcategorySection({
    required this.pendingNames,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> pendingNames;
  final ValueChanged<String> onAdd;
  final ValueChanged<int> onRemove;

  @override
  State<_SubcategorySection> createState() => _SubcategorySectionState();
}

class _SubcategorySectionState extends State<_SubcategorySection> {
  bool _editing = false;
  String? _inputError;
  late final TextEditingController _nameController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _editing = true;
      _inputError = null;
    });
    _nameController.clear();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  void _cancel() => setState(() {
    _editing = false;
    _inputError = null;
    _nameController.clear();
  });

  void _confirm() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _inputError = 'Name is required');
      return;
    }
    if (widget.pendingNames.any((n) => n.toLowerCase() == name.toLowerCase())) {
      setState(() => _inputError = 'Already in list');
      return;
    }
    widget.onAdd(name);
    setState(() {
      _editing = false;
      _inputError = null;
    });
    _nameController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Subcategories', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        if (widget.pendingNames.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (var i = 0; i < widget.pendingNames.length; i++)
                InputChip(
                  label: Text(widget.pendingNames[i]),
                  onDeleted: () => widget.onRemove(i),
                ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        if (!_editing)
          TextButton.icon(
            onPressed: _startEditing,
            icon: const Icon(Icons.add),
            label: const Text('Add subcategory'),
          ),
        if (_editing) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Subcategory name',
                    errorText: _inputError,
                    isDense: true,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _confirm(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check),
                tooltip: 'Confirm',
                onPressed: _confirm,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Cancel',
                onPressed: _cancel,
              ),
            ],
          ),
        ],
      ],
    );
  }
}
