import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_statistics/core/logging/app_logger.dart';
import 'package:private_statistics/features/categories/domain/models/category.dart';
import 'package:private_statistics/features/categories/domain/models/category_node.dart';
import 'package:private_statistics/features/categories/domain/models/resolved_field.dart';
import 'package:private_statistics/features/categories/domain/models/time_model.dart';
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
  String? _nameError;
  bool _isSaving = false;

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
  }

  String get _title {
    return switch (widget._mode) {
      _FormMode.createRoot => 'New category',
      _FormMode.createSubcategory => 'New subcategory',
      _FormMode.edit => 'Edit category',
    };
  }

  void _setName(String value) => setState(() {
    _data = _data.copyWith(name: value);
    _nameError = null;
  });

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

      if (mounted) Navigator.of(context).pop();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
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
              onChanged: _setName,
              controller: TextEditingController(text: _data.name),
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
