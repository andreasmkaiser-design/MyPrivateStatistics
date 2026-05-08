import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_statistics/features/categories/domain/exceptions.dart';
import 'package:private_statistics/features/categories/domain/models/category.dart';
import 'package:private_statistics/features/categories/domain/models/category_node.dart';
import 'package:private_statistics/features/categories/domain/models/field.dart';
import 'package:private_statistics/features/categories/domain/models/field_type.dart';
import 'package:private_statistics/features/categories/domain/models/resolved_field.dart';
import 'package:private_statistics/features/categories/domain/models/time_model.dart';
import 'package:private_statistics/features/categories/domain/repositories/category_repository.dart';
import 'package:private_statistics/features/categories/presentation/category_form_screen.dart';
import 'package:private_statistics/features/categories/providers/category_providers.dart';

class _MockCategoryRepository extends Mock implements CategoryRepository {}

Widget _buildForm(
  Widget screen,
  _MockCategoryRepository repo, {
  List<CategoryNode> tree = const [],
}) => ProviderScope(
  overrides: [
    categoryRepositoryProvider.overrideWithValue(repo),
    categoryTreeProvider.overrideWith((_) => Stream.value(tree)),
  ],
  child: MaterialApp(home: screen),
);

// Default name is 'Category' (not 'Running') so tests that pass name: 'Running'
// are never flagged as redundant by avoid_redundant_argument_values.
CategoryNode _rootNode({
  String uid = 'root',
  String name = 'Category',
  List<CategoryNode> children = const [],
  List<ResolvedField> mergedSchema = const [],
}) => CategoryNode(
  category: Category(
    uid: uid,
    name: name,
    timeModel: TimeModel.timePoint,
    ownFields: const [],
  ),
  children: children,
  mergedSchema: mergedSchema,
);

CategoryNode _childNode({
  required String uid,
  required String name,
  required String parentUid,
}) => CategoryNode(
  category: Category(
    uid: uid,
    name: name,
    parentUid: parentUid,
    timeModel: TimeModel.timePoint,
    ownFields: const [],
  ),
  children: const [],
  mergedSchema: const [],
);

Field _field({
  required String uid,
  required String categoryUid,
  required FieldType type,
}) => Field(
  uid: uid,
  categoryUid: categoryUid,
  name: uid,
  fieldType: type,
  sortOrder: 0,
);

void main() {
  setUpAll(() {
    registerFallbackValue(
      const Category(
        uid: '',
        name: '',
        timeModel: TimeModel.timePoint,
        ownFields: [],
      ),
    );
  });

  late _MockCategoryRepository repo;

  setUp(() {
    repo = _MockCategoryRepository();
    when(() => repo.save(any())).thenAnswer((_) async {});
  });

  // ── Cycle 4: all four field type options ─────────────────────────────────

  testWidgets(
    'create root category form shows all four field type options after '
    'adding a field',
    (tester) async {
      await tester.pumpWidget(
        _buildForm(const CategoryFormScreen.createRoot(), repo),
      );
      await tester.pumpAndSettle();

      // Tap Add field
      await tester.tap(find.text('Add field'));
      await tester.pumpAndSettle();

      // All four FieldType chip labels must appear
      expect(find.text('Integer'), findsOneWidget);
      expect(find.text('Float'), findsOneWidget);
      expect(find.text('Boolean'), findsOneWidget);
      expect(find.text('Enum'), findsOneWidget);
    },
  );

  testWidgets('create root form shows name field and time model selector', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildForm(const CategoryFormScreen.createRoot(), repo),
    );
    await tester.pumpAndSettle();

    expect(find.text('New category'), findsOneWidget);
    expect(find.text('Time model'), findsOneWidget);
    // SegmentedButton segments
    expect(find.text('Time point'), findsOneWidget);
    expect(find.text('Day range'), findsOneWidget);
    expect(find.text('Datetime range'), findsOneWidget);
  });

  testWidgets('save calls repository with correct category data', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildForm(const CategoryFormScreen.createRoot(), repo),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Cycling');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final captured =
        verify(() => repo.save(captureAny())).captured.single as Category;
    expect(captured.name, 'Cycling');
    expect(captured.isRoot, isTrue);
  });

  // ── Cycle 5: inherited fields read-only ──────────────────────────────────

  testWidgets('subcategory form shows inherited fields as read-only and '
      'hides time model selector', (tester) async {
    final inheritedField = ResolvedField(
      field: _field(uid: 'f1', categoryUid: 'root', type: FieldType.float),
      isInherited: true,
    );
    final parent = CategoryNode(
      category: const Category(
        uid: 'root',
        name: 'Running',
        timeModel: TimeModel.timePoint,
        ownFields: [],
      ),
      children: const [],
      mergedSchema: [inheritedField],
    );

    await tester.pumpWidget(
      _buildForm(
        CategoryFormScreen.createSubcategory(parentNode: parent),
        repo,
        tree: [parent],
      ),
    );
    await tester.pumpAndSettle();

    // Inherited field name visible
    expect(find.text('f1'), findsWidgets);
    // 'inherited' suffix label
    expect(find.text('inherited'), findsOneWidget);
    // No time model selector (subcategory inherits it)
    expect(find.text('Time model'), findsNothing);
    // No editable TextField for the inherited field name
    // (the chip uses InputDecorator with enabled:false, not a TextField)
    final nameFields = tester
        .widgetList<TextField>(find.byType(TextField))
        .where((tf) => tf.controller?.text == 'f1')
        .toList();
    expect(nameFields, isEmpty);
  });

  testWidgets('edit form pre-populates name and shows edit title', (
    tester,
  ) async {
    final node = _rootNode(uid: 'r1', name: 'Yoga');

    await tester.pumpWidget(
      _buildForm(CategoryFormScreen.fromNode(node: node), repo, tree: [node]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit category'), findsOneWidget);
  });

  testWidgets(
    'name field controller is the same instance across setState rebuilds',
    (tester) async {
      await tester.pumpWidget(
        _buildForm(const CategoryFormScreen.createRoot(), repo),
      );
      await tester.pumpAndSettle();

      // Capture controller before a rebuild-triggering keystroke
      final controllerBefore = tester
          .widget<TextField>(find.byType(TextField).first)
          .controller;

      // Enter text — triggers onChanged → setState → rebuild
      await tester.enterText(find.byType(TextField).first, 'Running');
      await tester.pump();

      // Controller must be the same object (not recreated on rebuild)
      final controllerAfter = tester
          .widget<TextField>(find.byType(TextField).first)
          .controller;
      expect(controllerAfter, same(controllerBefore));
    },
  );

  // ── Cycle 6: inline sibling-name validation ──────────────────────────────

  testWidgets('typing a name matching an existing root shows an inline error', (
    tester,
  ) async {
    final existing = _rootNode(uid: 'r1', name: 'Running');
    await tester.pumpWidget(
      _buildForm(const CategoryFormScreen.createRoot(), repo, tree: [existing]),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Running');
    await tester.pump();

    expect(
      find.text('Name already used by a sibling category'),
      findsOneWidget,
    );
  });

  testWidgets('Save button is disabled while an inline name error is shown', (
    tester,
  ) async {
    final existing = _rootNode(uid: 'r1', name: 'Running');
    await tester.pumpWidget(
      _buildForm(const CategoryFormScreen.createRoot(), repo, tree: [existing]),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Running');
    await tester.pump();

    final saveButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Save'),
    );
    expect(saveButton.onPressed, isNull);
  });

  testWidgets(
    'clearing a conflicting name removes the error and re-enables Save',
    (tester) async {
      final existing = _rootNode(uid: 'r1', name: 'Running');
      await tester.pumpWidget(
        _buildForm(
          const CategoryFormScreen.createRoot(),
          repo,
          tree: [existing],
        ),
      );
      await tester.pumpAndSettle();

      // Enter conflicting name → error
      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Running');
      await tester.pump();
      expect(
        find.text('Name already used by a sibling category'),
        findsOneWidget,
      );

      // Change to unique name → error gone
      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Yoga');
      await tester.pump();
      expect(
        find.text('Name already used by a sibling category'),
        findsNothing,
      );

      final saveButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Save'),
      );
      expect(saveButton.onPressed, isNotNull);
    },
  );

  testWidgets('name validation is case-insensitive', (tester) async {
    final existing = _rootNode(uid: 'r1', name: 'Running');
    await tester.pumpWidget(
      _buildForm(const CategoryFormScreen.createRoot(), repo, tree: [existing]),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'RUNNING');
    await tester.pump();

    expect(
      find.text('Name already used by a sibling category'),
      findsOneWidget,
    );
  });

  testWidgets('subcategory validation checks children of the parent, '
      'not the parent itself', (tester) async {
    final child = _childNode(uid: 'c1', name: 'Sprinting', parentUid: 'r1');
    final parent = _rootNode(uid: 'r1', name: 'Running', children: [child]);

    await tester.pumpWidget(
      _buildForm(
        CategoryFormScreen.createSubcategory(parentNode: parent),
        repo,
        tree: [parent],
      ),
    );
    await tester.pumpAndSettle();

    // Parent name is not a sibling → no error
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Running');
    await tester.pump();
    expect(find.text('Name already used by a sibling category'), findsNothing);

    // Sibling name → error
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Sprinting');
    await tester.pump();
    expect(
      find.text('Name already used by a sibling category'),
      findsOneWidget,
    );
  });

  testWidgets('edit mode excludes self — typing own name shows no error', (
    tester,
  ) async {
    final yoga = _rootNode(uid: 'r2', name: 'Yoga');
    final running = _rootNode(uid: 'r1', name: 'Running');

    await tester.pumpWidget(
      _buildForm(
        CategoryFormScreen.fromNode(node: yoga),
        repo,
        tree: [running, yoga],
      ),
    );
    await tester.pumpAndSettle();

    // Clear and retype own name — should not trigger error
    final nameField = find.widgetWithText(TextField, 'Name');
    await tester.enterText(nameField, '');
    await tester.pump();
    await tester.enterText(nameField, 'Yoga');
    await tester.pump();
    expect(find.text('Name already used by a sibling category'), findsNothing);

    // Type sibling name → error
    await tester.enterText(nameField, 'Running');
    await tester.pump();
    expect(
      find.text('Name already used by a sibling category'),
      findsOneWidget,
    );
  });

  testWidgets(
    'DuplicateCategoryNameException from save() shows as inline error',
    (tester) async {
      when(
        () => repo.save(any()),
      ).thenThrow(const DuplicateCategoryNameException('Cycling'));

      await tester.pumpWidget(
        _buildForm(const CategoryFormScreen.createRoot(), repo),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Cycling');
      await tester.pump();

      // No inline error yet (tree is empty — no known siblings)
      expect(
        find.text('Name already used by a sibling category'),
        findsNothing,
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Repository threw — inline error must appear
      expect(
        find.text('Name already used by a sibling category'),
        findsOneWidget,
      );
    },
  );
}
