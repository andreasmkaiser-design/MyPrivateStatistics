import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/app.dart';
import 'package:private_statistics/core/database/app_database.dart';
import 'package:private_statistics/core/database/database_provider.dart';
import 'package:private_statistics/features/categories/domain/models/category.dart';
import 'package:private_statistics/features/categories/domain/models/category_node.dart';
import 'package:private_statistics/features/categories/domain/models/time_model.dart';
import 'package:private_statistics/features/categories/domain/repositories/category_repository.dart';
import 'package:private_statistics/features/categories/providers/category_providers.dart';
import 'package:private_statistics/features/events/providers/event_providers.dart';
import 'package:private_statistics/features/onboarding/domain/onboarding_store.dart';
import 'package:private_statistics/features/onboarding/presentation/onboarding_flow.dart';
import 'package:private_statistics/features/onboarding/providers/onboarding_providers.dart';
import 'package:private_statistics/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Fake OnboardingStore
// ---------------------------------------------------------------------------

class _FakeOnboardingStore implements OnboardingStore {
  _FakeOnboardingStore({required bool completed}) : _completed = completed;

  bool _completed;
  bool get completeCalled => _completeCalled;
  bool _completeCalled = false;

  @override
  bool get isCompleted => _completed;

  @override
  Future<void> complete() async {
    _completed = true;
    _completeCalled = true;
  }
}

// ---------------------------------------------------------------------------
// Fake CategoryRepository
// ---------------------------------------------------------------------------

class _FakeCategoryRepository implements CategoryRepository {
  _FakeCategoryRepository({required List<Category> categories})
    : _categories = categories;

  final List<Category> _categories;

  @override
  Future<List<Category>> getAll() async => _categories;

  @override
  Stream<List<CategoryNode>> watchTree() => Stream.value(const []);

  @override
  Future<Category?> findByUid(String uid) async => null;

  @override
  Future<void> save(Category category) async {}

  @override
  Future<void> rename(String uid, String newName) async {}

  @override
  Future<void> delete(String uid) async {}
}

Category _stubCategory(String uid) => Category(
  uid: uid,
  name: uid,
  timeModel: TimeModel.timePoint,
  ownFields: const [],
);

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

/// Builds the full [App] widget, bypassing onboarding platform calls.
Widget _buildApp({
  required AppDatabase db,
  required OnboardingStore store,
}) => ProviderScope(
  overrides: [
    appDatabaseProvider.overrideWithValue(db),
    onboardingStoreProvider.overrideWithValue(store),
    categoryTreeProvider.overrideWith((_) => Stream.value(const [])),
    eventDaysInMonthProvider.overrideWith((ref, _) => Stream.value(const {})),
    eventsByDayProvider.overrideWith((ref, _) => Stream.value(const [])),
    // Prevent real platform calls during tests.
    hcPermissionsGrantedProvider.overrideWith((_) async => false),
    appVersionProvider.overrideWith((_) async => '1.0.0'),
    hasCategoriesProvider.overrideWith((_) async => false),
  ],
  child: const App(),
);

/// Builds [OnboardingFlow] directly with injected skip-decision overrides.
Widget _buildFlow({
  required OnboardingStore store,
  bool hcGranted = false,
  List<Category> categories = const [],
}) => ProviderScope(
  overrides: [
    onboardingStoreProvider.overrideWithValue(store),
    categoryRepositoryProvider.overrideWithValue(
      _FakeCategoryRepository(categories: categories),
    ),
    hcPermissionsGrantedProvider.overrideWith((_) async => hcGranted),
    appVersionProvider.overrideWith((_) async => '1.0.0'),
    hasCategoriesProvider.overrideWith((_) async => categories.isNotEmpty),
  ],
  child: const MaterialApp(
    localizationsDelegates: [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: OnboardingFlow()),
  ),
);

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  // -------------------------------------------------------------------------
  // App-level routing tests
  // -------------------------------------------------------------------------

  testWidgets('onboarding wizard is shown on first launch', (tester) async {
    final store = _FakeOnboardingStore(completed: false);
    await tester.pumpWidget(_buildApp(db: db, store: store));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Private Statistics'), findsOneWidget);
  });

  testWidgets('AppShell is shown when onboarding is already completed', (
    tester,
  ) async {
    final store = _FakeOnboardingStore(completed: true);
    await tester.pumpWidget(_buildApp(db: db, store: store));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Private Statistics'), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('tapping Skip on Screen 1 marks onboarding completed '
      'and shows AppShell', (tester) async {
    final store = _FakeOnboardingStore(completed: false);
    await tester.pumpWidget(_buildApp(db: db, store: store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(store.completeCalled, isTrue);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  // -------------------------------------------------------------------------
  // Smart-skip tests
  // -------------------------------------------------------------------------

  testWidgets('OnboardingFlow skips Screen 2 when HC permissions already '
      'granted — tapping Next goes straight to Screen 3', (tester) async {
    final store = _FakeOnboardingStore(completed: false);
    await tester.pumpWidget(_buildFlow(store: store, hcGranted: true));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Private Statistics'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Health Connect'), findsNothing);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('OnboardingFlow skips Screen 3 when DB already contains '
      'categories — Screen 3 is never shown', (tester) async {
    final store = _FakeOnboardingStore(completed: false);
    await tester.pumpWidget(
      _buildFlow(store: store, categories: [_stubCategory('cat-1')]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Health Connect'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Get started'), findsNothing);
    expect(store.completeCalled, isTrue);
  });

  testWidgets('OnboardingFlow skips both Screen 2 and 3 — Next on Screen 1 '
      'completes onboarding', (tester) async {
    final store = _FakeOnboardingStore(completed: false);
    await tester.pumpWidget(
      _buildFlow(
        store: store,
        hcGranted: true,
        categories: [_stubCategory('cat-1')],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(store.completeCalled, isTrue);
  });
}
