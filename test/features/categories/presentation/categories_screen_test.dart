import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'package:private_statistics/features/categories/presentation/categories_screen.dart';
import 'package:private_statistics/features/categories/providers/category_providers.dart';
import 'package:private_statistics/l10n/app_localizations.dart';

class _MockCategoryRepository extends Mock implements CategoryRepository {}

Widget _buildScreen({
  required List<CategoryNode> tree,
  required CategoryRepository repo,
  Set<String> expandedUids = const {},
}) => ProviderScope(
  overrides: [
    categoryRepositoryProvider.overrideWithValue(repo),
    categoryTreeProvider.overrideWith((_) => Stream.value(tree)),
    expandedCategoryUidsProvider.overrideWith((_) => expandedUids),
  ],
  child: const MaterialApp(
    localizationsDelegates: [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: CategoriesScreen(),
  ),
);

Category _cat({
  required String uid,
  required String name,
  String? parentUid,
  TimeModel timeModel = TimeModel.timePoint,
}) => Category(
  uid: uid,
  name: name,
  parentUid: parentUid,
  timeModel: timeModel,
  ownFields: const [],
);

CategoryNode _leaf(Category cat) =>
    CategoryNode(category: cat, children: const [], mergedSchema: const []);

void main() {
  late _MockCategoryRepository repo;

  setUp(() {
    repo = _MockCategoryRepository();
    when(() => repo.delete(any())).thenAnswer((_) async {});
    when(() => repo.rename(any(), any())).thenAnswer((_) async {});
  });

  // ── Cycle 1: empty state ─────────────────────────────────────────────────

  testWidgets('shows empty state when there are no categories', (tester) async {
    await tester.pumpWidget(_buildScreen(tree: const [], repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('No categories yet'), findsOneWidget);
  });

  // ── Cycle 2: tree renders hierarchy ─────────────────────────────────────

  testWidgets('shows root category name in tree', (tester) async {
    final root = _leaf(_cat(uid: 'r', name: 'Running'));
    await tester.pumpWidget(_buildScreen(tree: [root], repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('Running'), findsOneWidget);
  });

  testWidgets('renders a 3-level hierarchy when ancestor nodes are expanded', (
    tester,
  ) async {
    final grandchild = _leaf(
      _cat(uid: 'gc', name: 'Grandchild', parentUid: 'child'),
    );
    final child = CategoryNode(
      category: _cat(uid: 'child', name: 'Child', parentUid: 'root'),
      children: [grandchild],
      mergedSchema: const [],
    );
    final root = CategoryNode(
      category: _cat(uid: 'root', name: 'Root'),
      children: [child],
      mergedSchema: const [],
    );

    await tester.pumpWidget(
      _buildScreen(tree: [root], repo: repo, expandedUids: {'root', 'child'}),
    );
    await tester.pumpAndSettle();

    expect(find.text('Root'), findsOneWidget);
    expect(find.text('Child'), findsOneWidget);
    expect(find.text('Grandchild'), findsOneWidget);
  });

  // ── Cycle 3: delete confirmation dialog ─────────────────────────────────

  testWidgets(
    'delete confirmation dialog appears and triggers deletion on confirm',
    (tester) async {
      final root = _leaf(_cat(uid: 'r1', name: 'Yoga'));
      await tester.pumpWidget(_buildScreen(tree: [root], repo: repo));
      await tester.pumpAndSettle();

      // Open the popup menu on the tile
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap Delete in the popup
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirmation dialog must appear
      expect(find.text('Delete category'), findsOneWidget);
      expect(find.textContaining('Yoga'), findsWidgets);

      // Tap the confirm button
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      verify(() => repo.delete('r1')).called(1);
    },
  );

  testWidgets('empty state is shown when category list is empty', (
    tester,
  ) async {
    await tester.pumpWidget(_buildScreen(tree: const [], repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('No categories yet'), findsOneWidget);
    expect(find.byIcon(Icons.category_outlined), findsOneWidget);
  });

  testWidgets(
    'Add subcategory option is hidden when tile is at maximum depth',
    (tester) async {
      // depth 0 → 4 (level 1 → 5): at depth 4 add-subcategory must not appear.
      // Build a 5-deep chain and expand all.
      CategoryNode buildChain(int depth) {
        if (depth == 0) return _leaf(_cat(uid: 'd0', name: 'L1'));
        final child = buildChain(depth - 1);
        return CategoryNode(
          category: _cat(
            uid: 'd$depth',
            name: 'L${depth + 1}',
            parentUid: 'd${depth - 1}',
          ),
          children: [child],
          mergedSchema: const [],
        );
      }

      final tree = [buildChain(4)]; // root is depth 4 = level 5
      final allUids = {'d0', 'd1', 'd2', 'd3', 'd4'};

      await tester.pumpWidget(
        _buildScreen(tree: tree, repo: repo, expandedUids: allUids),
      );
      await tester.pumpAndSettle();

      // Open popup on deepest tile (L1, displayed last in the hierarchy)
      final tiles = find.byIcon(Icons.more_vert);
      await tester.tap(tiles.last);
      await tester.pumpAndSettle();

      expect(find.text('Add subcategory'), findsNothing);
    },
  );

  testWidgets('renaming calls repository rename', (tester) async {
    final root = _leaf(_cat(uid: 'r1', name: 'Running'));
    await tester.pumpWidget(_buildScreen(tree: [root], repo: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    // Clear the text field and type a new name
    await tester.enterText(find.byType(TextField), 'Trail Running');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename').last);
    await tester.pumpAndSettle();

    verify(() => repo.rename('r1', 'Trail Running')).called(1);
  });

  testWidgets('tapping add-field button navigates to create-root form', (
    tester,
  ) async {
    await tester.pumpWidget(_buildScreen(tree: const [], repo: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // The form screen's AppBar title must appear
    expect(find.text('New category'), findsOneWidget);
  });

  // ── field helpers for inherited-fields test used by form-screen tests ───

  Field makeField({
    required String uid,
    required String categoryUid,
    FieldType type = FieldType.integer,
  }) => Field(
    uid: uid,
    categoryUid: categoryUid,
    name: uid,
    fieldType: type,
    sortOrder: 0,
  );

  // ── Cycle 4: rename dialog inline validation ─────────────────────────────

  testWidgets(
    'rename dialog shows inline error when typed name matches a sibling',
    (tester) async {
      final running = _leaf(_cat(uid: 'r1', name: 'Running'));
      final yoga = _leaf(_cat(uid: 'r2', name: 'Yoga'));
      await tester.pumpWidget(_buildScreen(tree: [running, yoga], repo: repo));
      await tester.pumpAndSettle();

      // Open rename dialog for the first tile (Running); sibling is Yoga
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      // Type the sibling name → inline error must appear
      await tester.enterText(find.byType(TextField), 'Yoga');
      await tester.pump();

      expect(
        find.text('Name already used by a sibling category'),
        findsOneWidget,
      );

      // Rename button must be disabled
      final renameButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Rename'),
      );
      expect(renameButton.onPressed, isNull);
    },
  );

  testWidgets(
    'rename dialog allows renaming to own name (self excluded from siblings)',
    (tester) async {
      final running = _leaf(_cat(uid: 'r1', name: 'Running'));
      final yoga = _leaf(_cat(uid: 'r2', name: 'Yoga'));
      await tester.pumpWidget(_buildScreen(tree: [running, yoga], repo: repo));
      await tester.pumpAndSettle();

      // Open rename dialog for the first tile (Running)
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      // Retype own name → must not trigger an error
      await tester.enterText(find.byType(TextField), 'Running');
      await tester.pump();

      expect(
        find.text('Name already used by a sibling category'),
        findsNothing,
      );
    },
  );

  testWidgets('subcategory tile shows parent name above depth-1 node', (
    tester,
  ) async {
    final child = _leaf(
      _cat(uid: 'child', name: 'Tempo Runs', parentUid: 'root'),
    );
    final root = CategoryNode(
      category: _cat(uid: 'root', name: 'Running'),
      children: [child],
      mergedSchema: [
        ResolvedField(
          field: makeField(uid: 'f1', categoryUid: 'root'),
          isInherited: false,
        ),
      ],
    );

    await tester.pumpWidget(
      _buildScreen(tree: [root], repo: repo, expandedUids: {'root'}),
    );
    await tester.pumpAndSettle();

    expect(find.text('Running'), findsOneWidget);
    expect(find.text('Tempo Runs'), findsOneWidget);
  });
}
