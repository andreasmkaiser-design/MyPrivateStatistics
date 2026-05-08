import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/features/categories/domain/models/field_type.dart';
import 'package:private_statistics/features/categories/presentation/field_draft.dart';
import 'package:private_statistics/features/categories/presentation/field_editor_row.dart';

Widget _buildRow({required FieldDraft initial}) {
  var draft = initial;
  return MaterialApp(
    home: Scaffold(
      body: StatefulBuilder(
        builder: (context, setState) => FieldEditorRow(
          draft: draft,
          onChanged: (d) => setState(() => draft = d),
          onRemove: () {},
        ),
      ),
    ),
  );
}

Finder _fieldWithLabel(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(TextField));

void main() {
  // ── name field ────────────────────────────────────────────────────────────

  testWidgets('typing in name field does not lose focus', (tester) async {
    await tester.pumpWidget(_buildRow(initial: FieldDraft()));

    final nameField = _fieldWithLabel('Field name');

    await tester.tap(nameField);
    await tester.pump();

    final nameEditable = tester.state<EditableTextState>(
      find.descendant(of: nameField, matching: find.byType(EditableText)),
    );
    expect(nameEditable.widget.focusNode.hasFocus, isTrue);

    // Entering text triggers onChanged → StatefulBuilder setState → rebuild.
    await tester.enterText(nameField, 'Running');
    await tester.pump();

    // After the rebuild the name field must still have focus.
    expect(nameEditable.widget.focusNode.hasFocus, isTrue);
  });

  testWidgets('name field text is preserved after rebuild', (tester) async {
    await tester.pumpWidget(_buildRow(initial: FieldDraft()));

    await tester.enterText(_fieldWithLabel('Field name'), 'Cycling');
    await tester.pump();

    expect(find.text('Cycling'), findsOneWidget);
  });

  // ── unit field (float type) ──────────────────────────────────────────────

  testWidgets('unit field appears when field type is float', (tester) async {
    await tester.pumpWidget(
      _buildRow(initial: FieldDraft(fieldType: FieldType.float)),
    );
    await tester.pump();

    expect(_fieldWithLabel('Unit (optional)'), findsOneWidget);
  });

  testWidgets('unit field retains input across rebuilds', (tester) async {
    await tester.pumpWidget(
      _buildRow(initial: FieldDraft(fieldType: FieldType.float)),
    );

    await tester.enterText(_fieldWithLabel('Unit (optional)'), 'km');
    await tester.pump();

    expect(find.text('km'), findsOneWidget);
  });

  // ── min / max fields (integer and float types) ───────────────────────────

  testWidgets('min and max fields appear when field type is integer', (
    tester,
  ) async {
    await tester.pumpWidget(_buildRow(initial: FieldDraft()));
    await tester.pump();

    expect(_fieldWithLabel('Min'), findsOneWidget);
    expect(_fieldWithLabel('Max'), findsOneWidget);
  });

  testWidgets('min and max fields appear when field type is float', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildRow(initial: FieldDraft(fieldType: FieldType.float)),
    );
    await tester.pump();

    expect(_fieldWithLabel('Min'), findsOneWidget);
    expect(_fieldWithLabel('Max'), findsOneWidget);
  });

  testWidgets('min field retains input across rebuilds', (tester) async {
    await tester.pumpWidget(_buildRow(initial: FieldDraft()));

    await tester.enterText(_fieldWithLabel('Min'), '0');
    await tester.pump();

    // Trigger a second rebuild by typing in the name field.
    await tester.enterText(_fieldWithLabel('Field name'), 'Steps');
    await tester.pump();

    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('max field retains input across rebuilds', (tester) async {
    await tester.pumpWidget(_buildRow(initial: FieldDraft()));

    await tester.enterText(_fieldWithLabel('Max'), '100');
    await tester.pump();

    // Trigger a second rebuild by typing in the name field.
    await tester.enterText(_fieldWithLabel('Field name'), 'Steps');
    await tester.pump();

    expect(find.text('100'), findsOneWidget);
  });

  testWidgets('min and max reset to empty when field type changes', (
    tester,
  ) async {
    await tester.pumpWidget(_buildRow(initial: FieldDraft()));

    await tester.enterText(_fieldWithLabel('Min'), '5');
    await tester.enterText(_fieldWithLabel('Max'), '50');
    await tester.pump();

    // Switch to boolean — _ConstraintEditor leaves and re-enters the tree.
    await tester.tap(find.text('Boolean'));
    await tester.pump();

    // Switch back to integer — fresh _ConstraintEditorState with empty fields.
    await tester.tap(find.text('Integer'));
    await tester.pump();

    expect(find.text('5'), findsNothing);
    expect(find.text('50'), findsNothing);
  });
}
