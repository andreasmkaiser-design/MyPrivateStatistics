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
/// This widget is intentionally stateless and reusable; the Event creation
/// form (issue #16) can import and use it without modification.
class FieldEditorRow extends StatelessWidget {
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

  void _onTypeSelected(FieldType newType) {
    // Construct a fresh draft on type change to clear type-irrelevant fields.
    onChanged(
      FieldDraft(
        draftUid: draft.draftUid,
        existingUid: draft.existingUid,
        name: draft.name,
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
                    controller: TextEditingController(text: draft.name),
                    onChanged: (v) => onChanged(draft.copyWith(name: v)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove field',
                  onPressed: onRemove,
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
                      selected: draft.fieldType == type,
                      onSelected: (selected) {
                        if (selected) _onTypeSelected(type);
                      },
                    ),
                  )
                  .toList(),
            ),

            // ── Conditional extras ───────────────────────────────────────
            if (draft.fieldType == FieldType.integer ||
                draft.fieldType == FieldType.float) ...[
              const SizedBox(height: 8),
              _ConstraintEditor(
                min: draft.constraintMin,
                max: draft.constraintMax,
                onMinChanged: (v) =>
                    onChanged(draft.copyWith(constraintMin: v)),
                onMaxChanged: (v) =>
                    onChanged(draft.copyWith(constraintMax: v)),
              ),
            ],

            if (draft.fieldType == FieldType.float) ...[
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Unit (optional)',
                  hintText: 'e.g. km, bpm',
                ),
                controller: TextEditingController(text: draft.unit ?? ''),
                onChanged: (v) =>
                    onChanged(draft.copyWith(unit: v.isEmpty ? null : v)),
              ),
            ],

            if (draft.fieldType == FieldType.enumeration) ...[
              const SizedBox(height: 8),
              _EnumOptionsEditor(
                options: draft.enumOptions,
                onChanged: (opts) =>
                    onChanged(draft.copyWith(enumOptions: opts)),
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

class _ConstraintEditor extends StatelessWidget {
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
            controller: TextEditingController(
              text: min != null ? min.toString() : '',
            ),
            onChanged: (v) => onMinChanged(double.tryParse(v)),
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
            controller: TextEditingController(
              text: max != null ? max.toString() : '',
            ),
            onChanged: (v) => onMaxChanged(double.tryParse(v)),
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
