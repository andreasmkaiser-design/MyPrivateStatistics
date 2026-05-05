import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_statistics/features/categories/domain/models/category.dart';
import 'package:private_statistics/features/categories/domain/models/category_node.dart';
import 'package:private_statistics/features/categories/domain/models/field.dart';
import 'package:private_statistics/features/categories/domain/models/field_constraint.dart';
import 'package:private_statistics/features/categories/domain/models/field_type.dart';
import 'package:private_statistics/features/categories/domain/models/resolved_field.dart';
import 'package:private_statistics/features/categories/domain/models/time_model.dart';
import 'package:private_statistics/features/categories/providers/category_providers.dart';
import 'package:private_statistics/features/events/domain/models/event.dart';
import 'package:private_statistics/features/events/domain/models/field_value.dart';
import 'package:private_statistics/features/events/domain/models/time_point.dart';
import 'package:private_statistics/features/events/domain/repositories/event_repository.dart';
import 'package:private_statistics/features/events/presentation/event_form_screen.dart';
import 'package:private_statistics/features/events/providers/event_providers.dart';

class _MockEventRepository extends Mock implements EventRepository {}

// ── Helpers ───────────────────────────────────────────────────────────────

Field _field({
  required String uid,
  required FieldType type,
  FieldConstraint? constraint,
  List<String> enumOptions = const [],
}) => Field(
  uid: uid,
  categoryUid: 'cat1',
  name: uid,
  fieldType: type,
  sortOrder: 0,
  constraint: constraint,
  enumOptions: enumOptions,
);

ResolvedField _resolved(Field field) =>
    ResolvedField(field: field, isInherited: false);

CategoryNode _nodeWithFields(List<Field> fields) => CategoryNode(
  category: Category(
    uid: 'cat1',
    name: 'Test',
    timeModel: TimeModel.timePoint,
    ownFields: fields,
  ),
  children: const [],
  mergedSchema: fields.map(_resolved).toList(),
);

Widget _buildEditForm({
  required CategoryNode node,
  required Event event,
  required EventRepository repo,
}) => ProviderScope(
  overrides: [
    eventRepositoryProvider.overrideWithValue(repo),
    categoryRepositoryProvider.overrideWith((_) => throw UnimplementedError()),
    categoryTreeProvider.overrideWith((_) => Stream.value([node])),
  ],
  child: MaterialApp(
    home: EventFormScreen.fromEvent(event: event, categoryNode: node),
  ),
);

Event _event({String uid = 'e1', List<FieldValue> fieldValues = const []}) =>
    Event(
      uid: uid,
      categoryUid: 'cat1',
      occurredAt: TimePoint(date: DateTime(2026, 5, 4)),
      fieldValues: fieldValues,
    );

// ── Tests ─────────────────────────────────────────────────────────────────

void main() {
  late _MockEventRepository repo;

  setUpAll(() {
    registerFallbackValue(_event());
  });

  setUp(() {
    repo = _MockEventRepository();
    when(() => repo.save(any())).thenAnswer((_) async {});
    when(() => repo.delete(any())).thenAnswer((_) async {});
  });

  // Cycle 3 — form renders all four field types

  testWidgets('event form renders integer, float, bool and enum fields', (
    tester,
  ) async {
    final fields = [
      _field(uid: 'f-int', type: FieldType.integer),
      _field(uid: 'f-float', type: FieldType.float),
      _field(uid: 'f-bool', type: FieldType.boolean),
      _field(uid: 'f-enum', type: FieldType.enumeration, enumOptions: ['a']),
    ];
    final node = _nodeWithFields(fields);

    await tester.pumpWidget(
      _buildEditForm(
        node: node,
        event: _event(
          fieldValues: const [
            IntFieldValue(fieldUid: 'f-int', value: 1),
            FloatFieldValue(fieldUid: 'f-float', value: 1),
            BoolFieldValue(fieldUid: 'f-bool', value: false),
            EnumFieldValue(fieldUid: 'f-enum', value: 'a'),
          ],
        ),
        repo: repo,
      ),
    );
    await tester.pumpAndSettle();

    // Integer and float fields render as TextFields
    expect(find.byType(TextField), findsNWidgets(2));
    // Boolean field renders as a SwitchListTile with its field name
    expect(find.widgetWithText(SwitchListTile, 'f-bool'), findsOneWidget);
    // Enum field renders as a DropdownButtonFormField
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
  });

  // Cycle 4 — out-of-range blocks save

  testWidgets(
    'out-of-range integer value shows validation error and blocks save',
    (tester) async {
      final fields = [
        _field(
          uid: 'f-int',
          type: FieldType.integer,
          constraint: const FieldConstraint(min: 0, max: 10),
        ),
      ];
      final node = _nodeWithFields(fields);

      await tester.pumpWidget(
        _buildEditForm(
          node: node,
          event: _event(
            fieldValues: const [IntFieldValue(fieldUid: 'f-int', value: 5)],
          ),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      // Clear the field and enter an out-of-range value
      await tester.enterText(find.byType(TextField).first, '-3');
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Inline error must appear
      expect(find.text('Must be at least 0'), findsOneWidget);
      // Repository must NOT have been called
      verifyNever(() => repo.save(any()));
    },
  );

  // Cycle 5 — enum dropdown options

  testWidgets('enum dropdown shows all configured options', (tester) async {
    final fields = [
      _field(
        uid: 'f-enum',
        type: FieldType.enumeration,
        enumOptions: ['low', 'medium', 'high'],
      ),
    ];
    final node = _nodeWithFields(fields);

    await tester.pumpWidget(
      _buildEditForm(
        node: node,
        event: _event(
          fieldValues: const [EnumFieldValue(fieldUid: 'f-enum', value: 'low')],
        ),
        repo: repo,
      ),
    );
    await tester.pumpAndSettle();

    // Open the dropdown
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    expect(find.text('low'), findsWidgets);
    expect(find.text('medium'), findsOneWidget);
    expect(find.text('high'), findsOneWidget);
  });

  // Cycle 6 — float displays 1 decimal place

  testWidgets('float field displays existing value with 1 decimal place', (
    tester,
  ) async {
    final fields = [_field(uid: 'f-float', type: FieldType.float)];
    final node = _nodeWithFields(fields);

    await tester.pumpWidget(
      _buildEditForm(
        node: node,
        event: _event(
          fieldValues: const [
            FloatFieldValue(fieldUid: 'f-float', value: 3.14),
          ],
        ),
        repo: repo,
      ),
    );
    await tester.pumpAndSettle();

    // The float TextField must show the value rounded to 1 decimal place
    expect(find.widgetWithText(TextField, '3.1'), findsOneWidget);
  });
}
