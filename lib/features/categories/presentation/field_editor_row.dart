import 'package:flutter/material.dart';
import 'package:private_statistics/features/categories/domain/models/field_type.dart';
import 'package:private_statistics/features/categories/presentation/field_draft.dart';

/// An editable row representing one field in a category form.
///
/// Shows a name text field and a set of [FieldType] chips. Conditional
/// extras appear below based on the chosen type:
/// - [FieldType.integer] / [FieldType.float]: min / max constraint inputs.
/// - [FieldType.float]: additionally a unit text input.
/// - [FieldType.enumeration]: a chip list plus an add-option input.
/// - [FieldType.boolean]: no extras.
///
/// This widget is reusable; the Event creation form (issue #16) can import
/// and use it without modification.
class FieldEditorRow extends StatefulWidget {
  /// Creates a [FieldEditorRow].
  const FieldEditorRow({
    required this.draft,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  /// The current in-progress field state.
  final FieldDraft draft;

  /// Called when any field property changes.
  final ValueChanged<FieldDraft> onChanged;

  /// Called when the user taps the remove button for this row.
  final VoidCallback onRemove;

  @override
  State<FieldEditorRow> createState() => _FieldEditorRowState();
}

class _FieldEditorRowState extends State<FieldEditorRow> {
  late final TextEditingController _nameController;
  late final TextEditingController _unitController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.draft.name);
    _unitController = TextEditingController(text: widget.draft.unit ?? '');
  }

  @override
  void didUpdateWidget(FieldEditorRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync name only when the external value changed and differs from the
    // controller (preserves in-progress IME composition during normal typing).
    if (oldWidget.draft.name != widget.draft.name &&
        _nameController.text != widget.draft.name) {
      _nameController.text = widget.draft.name;
    }
    final newUnit = widget.draft.unit ?? '';
    if (oldWidget.draft.unit != widget.draft.unit &&
        _unitController.text != newUnit) {
      _unitController.text = newUnit;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _onTypeSelected(FieldType newType) {
    // Construct a fresh draft on type change to clear type-irrelevant fields.
    widget.onChanged(
      FieldDraft(
        draftUid: widget.draft.draftUid,
        existingUid: widget.draft.existingUid,
        name: widget.draft.name,
        fieldType: newType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Row: name field + remove button ──────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Field name'),
                    textCapitalization: TextCapitalization.sentences,
                    controller: _nameController,
                    onChanged: (v) =>
                        widget.onChanged(widget.draft.copyWith(name: v)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove field',
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Field-type chips ─────────────────────────────────────────
            Wrap(
              spacing: 6,
              children: FieldType.values
                  .map(
                    (type) => ChoiceChip(
                      label: Text(_typeLabel(type)),
                      selected: widget.draft.fieldType == type,
                      onSelected: (selected) {
                        if (selected) _onTypeSelected(type);
                      },
                    ),
                  )
                  .toList(),
            ),

            // ── Conditional extras ───────────────────────────────────────
            if (widget.draft.fieldType == FieldType.integer ||
                widget.draft.fieldType == FieldType.float) ...[
              const SizedBox(height: 8),
              _ConstraintEditor(
                min: widget.draft.constraintMin,
                max: widget.draft.constraintMax,
                onMinChanged: (v) =>
                    widget.onChanged(widget.draft.copyWith(constraintMin: v)),
                onMaxChanged: (v) =>
                    widget.onChanged(widget.draft.copyWith(constraintMax: v)),
              ),
            ],

            if (widget.draft.fieldType == FieldType.float) ...[
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Unit (optional)',
                  hintText: 'e.g. km, bpm',
                ),
                controller: _unitController,
                onChanged: (v) => widget.onChanged(
                  widget.draft.copyWith(unit: v.isEmpty ? null : v),
                ),
              ),
            ],

            if (widget.draft.fieldType == FieldType.enumeration) ...[
              const SizedBox(height: 8),
              _EnumOptionsEditor(
                options: widget.draft.enumOptions,
                onChanged: (opts) =>
                    widget.onChanged(widget.draft.copyWith(enumOptions: opts)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _typeLabel(FieldType type) => switch (type) {
    FieldType.integer => 'Integer',
    FieldType.float => 'Float',
    FieldType.boolean => 'Boolean',
    FieldType.enumeration => 'Enum',
  };
}

// ── Private sub-widgets ──────────────────────────────────────────────────

class _ConstraintEditor extends StatefulWidget {
  const _ConstraintEditor({
    required this.min,
    required this.max,
    required this.onMinChanged,
    required this.onMaxChanged,
  });

  final double? min;
  final double? max;
  final ValueChanged<double?> onMinChanged;
  final ValueChanged<double?> onMaxChanged;

  @override
  State<_ConstraintEditor> createState() => _ConstraintEditorState();
}

class _ConstraintEditorState extends State<_ConstraintEditor> {
  late final TextEditingController _minController;
  late final TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _minController = TextEditingController(
      text: widget.min != null ? widget.min.toString() : '',
    );
    _maxController = TextEditingController(
      text: widget.max != null ? widget.max.toString() : '',
    );
  }

  @override
  void didUpdateWidget(_ConstraintEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Compare parsed doubles so that '5' and 5.0 are treated as equal,
    // avoiding unwanted reformatting while the user is mid-edit.
    if (oldWidget.min != widget.min &&
        double.tryParse(_minController.text) != widget.min) {
      _minController.text = widget.min != null ? widget.min.toString() : '';
    }
    if (oldWidget.max != widget.max &&
        double.tryParse(_maxController.text) != widget.max) {
      _maxController.text = widget.max != null ? widget.max.toString() : '';
    }
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: const InputDecoration(labelText: 'Min'),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            controller: _minController,
            onChanged: (v) => widget.onMinChanged(double.tryParse(v)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            decoration: const InputDecoration(labelText: 'Max'),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            controller: _maxController,
            onChanged: (v) => widget.onMaxChanged(double.tryParse(v)),
          ),
        ),
      ],
    );
  }
}

class _EnumOptionsEditor extends StatefulWidget {
  const _EnumOptionsEditor({required this.options, required this.onChanged});

  final List<String> options;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_EnumOptionsEditor> createState() => _EnumOptionsEditorState();
}

class _EnumOptionsEditorState extends State<_EnumOptionsEditor> {
  late final TextEditingController _addController;

  @override
  void initState() {
    super.initState();
    _addController = TextEditingController();
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  void _addOption() {
    final text = _addController.text.trim();
    if (text.isEmpty) return;
    widget.onChanged([...widget.options, text]);
    _addController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 6,
          children: widget.options
              .map(
                (opt) => Chip(
                  label: Text(opt),
                  onDeleted: () {
                    final updated = List<String>.from(widget.options)
                      ..remove(opt);
                    widget.onChanged(updated);
                  },
                ),
              )
              .toList(),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _addController,
                decoration: const InputDecoration(hintText: 'Add option…'),
                onSubmitted: (_) => _addOption(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add option',
              onPressed: _addOption,
            ),
          ],
        ),
      ],
    );
  }
}
