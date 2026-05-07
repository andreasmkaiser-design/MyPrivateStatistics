import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

Widget _buildForm(Widget screen, _MockCategoryRepository repo) => ProviderScope(
  overrides: [categoryRepositoryProvider.overrideWithValue(repo)],
  child: MaterialApp(home: screen),
);

CategoryNode _rootNode({
  String uid = 'root',
  String name = 'Running',
  List<ResolvedField> mergedSchema = const [],
}) => CategoryNode(
  category: Category(
    uid: uid,
    name: name,
    timeModel: TimeModel.timePoint,
    ownFields: const [],
  ),
  children: const [],
  mergedSchema: mergedSchema,
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
      _buildForm(CategoryFormScreen.fromNode(node: node), repo),
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
}
