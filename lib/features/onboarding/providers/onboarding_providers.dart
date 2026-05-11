import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_statistics/core/database/database_provider.dart';
import 'package:private_statistics/features/categories/data/category_repository_impl.dart';
import 'package:private_statistics/features/onboarding/data/drift_category_seeder.dart';
import 'package:private_statistics/features/onboarding/domain/category_seeder.dart';
import 'package:private_statistics/features/onboarding/domain/default_seed_specs.dart';
import 'package:private_statistics/features/onboarding/domain/onboarding_completion.dart';
import 'package:private_statistics/features/onboarding/domain/onboarding_store.dart';

/// Provides the [OnboardingStore].
///
/// Defaults to a store that reports onboarding as already completed, so that
/// widget tests that render `App` without caring about onboarding see
/// `AppShell` immediately. Override in `main()` with a
/// `SharedPrefsOnboardingStore` backed by a pre-warmed `SharedPreferences`
/// instance. Override in onboarding-specific tests with a fake.
final onboardingStoreProvider = Provider<OnboardingStore>((ref) {
  return const _CompletedOnboardingStore();
});

class _CompletedOnboardingStore implements OnboardingStore {
  const _CompletedOnboardingStore();

  @override
  bool get isCompleted => true;

  @override
  Future<void> complete() async {}
}

/// Whether the user has already completed onboarding.
///
/// Re-evaluated whenever [onboardingStoreProvider] is invalidated.
final onboardingCompletedProvider = Provider<bool>((ref) {
  return ref.watch(onboardingStoreProvider).isCompleted;
});

/// Provides the [CategorySeeder] backed by the app's Drift database.
final categorySeederProvider = Provider<CategorySeeder>((ref) {
  return DriftCategorySeeder(
    repository: CategoryRepositoryImpl(ref.watch(appDatabaseProvider)),
  );
});

/// Drives the onboarding wizard.
///
/// Holds [OnboardingCompletion] state. Call [OnboardingNotifier.skip] or
/// [OnboardingNotifier.complete] to finish the wizard.
final onboardingNotifierProvider =
    NotifierProvider<OnboardingNotifier, OnboardingCompletion>(
      OnboardingNotifier.new,
    );

/// Manages the shared state produced by the onboarding wizard.
class OnboardingNotifier extends Notifier<OnboardingCompletion> {
  @override
  OnboardingCompletion build() => const OnboardingCompletion();

  /// Skips the wizard: writes the first-launch flag and marks done.
  Future<void> skip() async {
    await ref.read(onboardingStoreProvider).complete();
    ref.invalidate(onboardingCompletedProvider);
    state = state.copyWith(isDone: true);
  }

  /// Completes the wizard: seeds the database, writes the flag, marks done.
  Future<void> complete(SeedChoice choice) async {
    await applySeed(choice);
    await ref.read(onboardingStoreProvider).complete();
    ref.invalidate(onboardingCompletedProvider);
    state = state.copyWith(seedChoice: choice, isDone: true);
  }

  /// Seeds the database according to [choice].
  ///
  /// Does nothing when [choice] is [SeedChoice.empty].
  Future<void> applySeed(SeedChoice choice) async {
    if (choice == SeedChoice.exampleCategories) {
      await ref.read(categorySeederProvider).seed(kDefaultSeedSpecs);
    }
  }
}
