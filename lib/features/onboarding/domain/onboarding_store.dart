/// Contract for persisting and reading the onboarding completion flag.
///
/// [isCompleted] is synchronous because the underlying `SharedPreferences`
/// instance is pre-warmed before the widget tree is built.
abstract interface class OnboardingStore {
  /// Whether the user has already completed or skipped onboarding.
  ///
  /// Returns `false` on a fresh install.
  bool get isCompleted;

  /// Marks onboarding as completed and persists the flag.
  Future<void> complete();
}
