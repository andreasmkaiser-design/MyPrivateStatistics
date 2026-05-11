import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/app.dart';
import 'package:private_statistics/core/database/app_database.dart';
import 'package:private_statistics/core/database/database_provider.dart';
import 'package:private_statistics/features/categories/providers/category_providers.dart';
import 'package:private_statistics/features/events/providers/event_providers.dart';
import 'package:private_statistics/features/onboarding/domain/onboarding_store.dart';
import 'package:private_statistics/features/onboarding/providers/onboarding_providers.dart';

// ---------------------------------------------------------------------------
// Fake OnboardingStore for testing.
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
// Test helper
// ---------------------------------------------------------------------------

Widget _buildApp({required AppDatabase db, required OnboardingStore store}) =>
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        onboardingStoreProvider.overrideWithValue(store),
        categoryTreeProvider.overrideWith((_) => Stream.value(const [])),
        eventDaysInMonthProvider.overrideWith(
          (ref, _) => Stream.value(const {}),
        ),
        eventsByDayProvider.overrideWith((ref, _) => Stream.value(const [])),
      ],
      child: const App(),
    );

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

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
}
