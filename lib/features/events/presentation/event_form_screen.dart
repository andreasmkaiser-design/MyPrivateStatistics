import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:private_statistics/core/logging/app_logger.dart';
import 'package:private_statistics/features/categories/domain/models/category_node.dart';
import 'package:private_statistics/features/categories/domain/models/field_type.dart';
import 'package:private_statistics/features/categories/domain/models/resolved_field.dart';
import 'package:private_statistics/features/categories/providers/category_providers.dart';
import 'package:private_statistics/features/events/domain/models/event.dart';
import 'package:private_statistics/features/events/domain/models/field_value.dart';
import 'package:private_statistics/features/events/domain/models/time_point.dart';
import 'package:private_statistics/features/events/providers/event_providers.dart';

final _random = Random.secure();

String _generateUid() {
  final timestamp = DateTime.now().microsecondsSinceEpoch;
  final suffix = _random.nextInt(999999).toString().padLeft(6, '0');
  return '$timestamp-$suffix';
}

enum _FormMode { createNew, edit }

/// Full-screen form for creating or editing a time-point [Event].
///
/// Use [EventFormScreen.createNew] to record a new event for a given day, or
/// [EventFormScreen.fromEvent] to edit an existing event.
///
/// The form renders a dynamic field set derived from the selected category's
/// merged schema. Constraint validation is performed client-side before the
/// event is passed to the repository.
class EventFormScreen extends ConsumerStatefulWidget {
  /// Creates a form pre-filled with [defaultDay] for a new event.
  const EventFormScreen.createNew({required DateTime defaultDay, super.key})
    : _mode = _FormMode.createNew,
      _defaultDay = defaultDay,
      _existingEvent = null,
      _preselectedNode = null;

  /// Creates a form pre-populated from [event] for editing.
  ///
  /// Pass the resolved [categoryNode] so the field schema is available
  /// immediately without waiting for the category tree to load.
  const EventFormScreen.fromEvent({
    required Event event,
    required CategoryNode? categoryNode,
    super.key,
  }) : _mode = _FormMode.edit,
       _defaultDay = null,
       _existingEvent = event,
       _preselectedNode = categoryNode;

  final _FormMode _mode;
  final DateTime? _defaultDay;
  final Event? _existingEvent;
  final CategoryNode? _preselectedNode;

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  CategoryNode? _category;
  late DateTime _date;
  bool _hasClockTime = false;
  TimeOfDay? _clockTime;

  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, bool> _boolValues = {};
  final Map<String, String?> _enumValues = {};
  final Map<String, String?> _fieldErrors = {};

  String? _categoryError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget._mode == _FormMode.createNew) {
      _date = widget._defaultDay!;
    } else {
      final event = widget._existingEvent!;
      _date = event.occurredAt.date;
      if (event.occurredAt.clockTime != null) {
        _hasClockTime = true;
        _clockTime = TimeOfDay.fromDateTime(event.occurredAt.clockTime!);
      }
      if (widget._preselectedNode != null) {
        _applyCategory(widget._preselectedNode!, event.fieldValues);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // Sets up per-field controllers / state for [node], optionally seeding
  // values from [existingValues].
  void _applyCategory(CategoryNode node, List<FieldValue> existingValues) {
    for (final c in _textControllers.values) {
      c.dispose();
    }
    _textControllers.clear();
    _boolValues.clear();
    _enumValues.clear();
    _fieldErrors.clear();

    _category = node;

    final byUid = {for (final fv in existingValues) fv.fieldUid: fv};

    for (final rf in node.mergedSchema) {
      final field = rf.field;
      switch (field.fieldType) {
        case FieldType.integer:
          final existing = byUid[field.uid];
          final text = existing is IntFieldValue ? '${existing.value}' : '';
          _textControllers[field.uid] = TextEditingController(text: text);
        case FieldType.float:
          final existing = byUid[field.uid];
          final text = existing is FloatFieldValue
              ? existing.value.toStringAsFixed(1)
              : '';
          _textControllers[field.uid] = TextEditingController(text: text);
        case FieldType.boolean:
          final existing = byUid[field.uid];
          _boolValues[field.uid] = existing is BoolFieldValue && existing.value;
        case FieldType.enumeration:
          final existing = byUid[field.uid];
          _enumValues[field.uid] = existing is EnumFieldValue
              ? existing.value
              : (field.enumOptions.isNotEmpty ? field.enumOptions.first : null);
      }
    }
  }

  Future<void> _pickCategory() async {
    final tree = ref.read(categoryTreeProvider).valueOrNull ?? [];
    if (tree.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No categories defined yet')),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CategoryPickerSheet(
        roots: tree,
        onSelected: (node) {
          setState(() {
            _categoryError = null;
            _applyCategory(node, const []);
          });
        },
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _clockTime ?? TimeOfDay.now(),
    );
    if (picked == null || !mounted) return;
    setState(() => _clockTime = picked);
  }

  bool _validateFields() {
    if (_category == null) {
      setState(() => _categoryError = 'Select a category');
      return false;
    }

    var valid = true;
    final newErrors = <String, String?>{};

    for (final rf in _category!.mergedSchema) {
      final field = rf.field;
      switch (field.fieldType) {
        case FieldType.integer:
          final text = _textControllers[field.uid]?.text.trim() ?? '';
          if (text.isEmpty) {
            newErrors[field.uid] = 'Enter a whole number';
            valid = false;
            break;
          }
          final parsed = int.tryParse(text);
          if (parsed == null) {
            newErrors[field.uid] = 'Enter a whole number';
            valid = false;
            break;
          }
          final constraint = field.constraint;
          if (constraint != null) {
            if (constraint.min != null && parsed < constraint.min!) {
              newErrors[field.uid] =
                  'Must be at least ${constraint.min!.toInt()}';
              valid = false;
            } else if (constraint.max != null && parsed > constraint.max!) {
              newErrors[field.uid] =
                  'Must be at most ${constraint.max!.toInt()}';
              valid = false;
            }
          }
        case FieldType.float:
          final text = _textControllers[field.uid]?.text.trim() ?? '';
          if (text.isEmpty) {
            newErrors[field.uid] = 'Enter a number';
            valid = false;
            break;
          }
          final parsed = double.tryParse(text);
          if (parsed == null) {
            newErrors[field.uid] = 'Enter a number';
            valid = false;
            break;
          }
          final constraint = field.constraint;
          if (constraint != null) {
            if (constraint.min != null && parsed < constraint.min!) {
              newErrors[field.uid] = 'Must be at least ${constraint.min}';
              valid = false;
            } else if (constraint.max != null && parsed > constraint.max!) {
              newErrors[field.uid] = 'Must be at most ${constraint.max}';
              valid = false;
            }
          }
        case FieldType.boolean:
        case FieldType.enumeration:
          break;
      }
    }

    setState(() {
      _fieldErrors
        ..clear()
        ..addAll(newErrors);
    });
    return valid;
  }

  List<FieldValue> _buildFieldValues() {
    final values = <FieldValue>[];
    for (final rf in _category!.mergedSchema) {
      final field = rf.field;
      switch (field.fieldType) {
        case FieldType.integer:
          final v = int.tryParse(
            _textControllers[field.uid]?.text.trim() ?? '',
          );
          if (v != null) {
            values.add(IntFieldValue(fieldUid: field.uid, value: v));
          }
        case FieldType.float:
          final v = double.tryParse(
            _textControllers[field.uid]?.text.trim() ?? '',
          );
          if (v != null) {
            values.add(FloatFieldValue(fieldUid: field.uid, value: v));
          }
        case FieldType.boolean:
          values.add(
            BoolFieldValue(
              fieldUid: field.uid,
              value: _boolValues[field.uid] ?? false,
            ),
          );
        case FieldType.enumeration:
          final v = _enumValues[field.uid];
          if (v != null) {
            values.add(EnumFieldValue(fieldUid: field.uid, value: v));
          }
      }
    }
    return values;
  }

  Future<void> _save() async {
    if (!_validateFields()) return;

    setState(() => _isSaving = true);
    try {
      final uid = widget._existingEvent?.uid ?? _generateUid();
      final clockDateTime = (_hasClockTime && _clockTime != null)
          ? DateTime(
              _date.year,
              _date.month,
              _date.day,
              _clockTime!.hour,
              _clockTime!.minute,
            )
          : null;

      final event = Event(
        uid: uid,
        categoryUid: _category!.category.uid,
        occurredAt: TimePoint(
          date: DateTime(_date.year, _date.month, _date.day),
          clockTime: clockDateTime,
        ),
        fieldValues: _buildFieldValues(),
      );

      await ref.read(eventRepositoryProvider).save(event);
      AppLogger.info('Event saved: $uid');

      if (mounted) Navigator.of(context).pop();
    } on Object catch (e, st) {
      AppLogger.error('Failed to save event', e, st);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to save event')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete event'),
        content: const Text('Delete this event? This cannot be undone.'),
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
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(eventRepositoryProvider)
          .delete(widget._existingEvent!.uid);
      AppLogger.info('Event deleted: ${widget._existingEvent!.uid}');
      if (mounted) Navigator.of(context).pop();
    } on Object catch (e, st) {
      AppLogger.error('Failed to delete event', e, st);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to delete event')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget._mode == _FormMode.edit;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit event' : 'New event'),
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
            // Category picker
            _CategoryTile(
              selected: _category,
              error: _categoryError,
              onTap: _pickCategory,
            ),
            const SizedBox(height: 16),

            // Date / time
            _DateTimeTile(
              date: _date,
              hasClockTime: _hasClockTime,
              clockTime: _clockTime,
              onPickDate: _pickDate,
              onToggleClockTime: (enabled) => setState(() {
                _hasClockTime = enabled;
                if (!enabled) _clockTime = null;
              }),
              onPickTime: _pickTime,
            ),

            // Dynamic fields
            if (_category != null) ...[
              const SizedBox(height: 16),
              ..._category!.mergedSchema.map(
                (rf) => _FieldFormRow(
                  resolvedField: rf,
                  textController: _textControllers[rf.field.uid],
                  boolValue: _boolValues[rf.field.uid],
                  enumValue: _enumValues[rf.field.uid],
                  errorText: _fieldErrors[rf.field.uid],
                  onBoolChanged: (v) =>
                      setState(() => _boolValues[rf.field.uid] = v),
                  onEnumChanged: (v) =>
                      setState(() => _enumValues[rf.field.uid] = v),
                  onTextChanged: (_) =>
                      setState(() => _fieldErrors.remove(rf.field.uid)),
                ),
              ),
            ],

            // Delete button — edit mode only
            if (isEdit) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _deleteEvent,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete event'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Private sub-widgets ───────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.selected,
    required this.error,
    required this.onTap,
  });

  final CategoryNode? selected;
  final String? error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Category',
        errorText: error,
        border: const OutlineInputBorder(),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Text(
                selected?.category.name ?? 'Select category…',
                style: selected == null
                    ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      )
                    : Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
    required this.date,
    required this.hasClockTime,
    required this.clockTime,
    required this.onPickDate,
    required this.onToggleClockTime,
    required this.onPickTime,
  });

  final DateTime date;
  final bool hasClockTime;
  final TimeOfDay? clockTime;
  final VoidCallback onPickDate;
  final ValueChanged<bool> onToggleClockTime;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: onPickDate,
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(DateFormat.yMMMd().format(date)),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Set time'),
          value: hasClockTime,
          onChanged: onToggleClockTime,
          contentPadding: EdgeInsets.zero,
        ),
        if (hasClockTime)
          OutlinedButton.icon(
            onPressed: onPickTime,
            icon: const Icon(Icons.access_time_outlined),
            label: Text(
              clockTime != null ? clockTime!.format(context) : 'Pick time',
            ),
          ),
      ],
    );
  }
}

class _FieldFormRow extends StatelessWidget {
  const _FieldFormRow({
    required this.resolvedField,
    required this.textController,
    required this.boolValue,
    required this.enumValue,
    required this.errorText,
    required this.onBoolChanged,
    required this.onEnumChanged,
    required this.onTextChanged,
  });

  final ResolvedField resolvedField;
  final TextEditingController? textController;
  final bool? boolValue;
  final String? enumValue;
  final String? errorText;
  final ValueChanged<bool> onBoolChanged;
  final ValueChanged<String?> onEnumChanged;
  final ValueChanged<String> onTextChanged;

  @override
  Widget build(BuildContext context) {
    final field = resolvedField.field;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: switch (field.fieldType) {
        FieldType.integer => TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: field.name,
            suffixText: field.unit,
            errorText: errorText,
            border: const OutlineInputBorder(),
          ),
          onChanged: onTextChanged,
        ),
        FieldType.float => TextField(
          controller: textController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: field.name,
            suffixText: field.unit,
            errorText: errorText,
            border: const OutlineInputBorder(),
          ),
          onChanged: onTextChanged,
        ),
        FieldType.boolean => SwitchListTile(
          title: Text(field.name),
          value: boolValue ?? false,
          onChanged: onBoolChanged,
          contentPadding: EdgeInsets.zero,
        ),
        FieldType.enumeration => DropdownButtonFormField<String>(
          initialValue: enumValue,
          decoration: InputDecoration(
            labelText: field.name,
            border: const OutlineInputBorder(),
          ),
          items: field.enumOptions
              .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
              .toList(),
          onChanged: onEnumChanged,
        ),
      },
    );
  }
}

// ── Category picker sheet ─────────────────────────────────────────────────

class _CategoryPickerSheet extends StatelessWidget {
  const _CategoryPickerSheet({required this.roots, required this.onSelected});

  final List<CategoryNode> roots;
  final ValueChanged<CategoryNode> onSelected;

  @override
  Widget build(BuildContext context) {
    final flat = <({CategoryNode node, int depth})>[];
    _flatten(roots, 0, flat);

    return DraggableScrollableSheet(
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (sheetContext, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Select category',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: flat.length,
              itemBuilder: (_, i) {
                final entry = flat[i];
                return ListTile(
                  contentPadding: EdgeInsets.only(
                    left: 16 + entry.depth * 16.0,
                    right: 16,
                  ),
                  title: Text(entry.node.category.name),
                  onTap: () {
                    Navigator.of(context).pop();
                    onSelected(entry.node);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _flatten(
    List<CategoryNode> nodes,
    int depth,
    List<({CategoryNode node, int depth})> out,
  ) {
    for (final n in nodes) {
      out.add((node: n, depth: depth));
      _flatten(n.children, depth + 1, out);
    }
  }
}
