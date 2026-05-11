import 'package:private_statistics/features/onboarding/domain/onboarding_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [OnboardingStore] implementation backed by [SharedPreferences].
///
/// The `prefs` instance must be pre-warmed by the caller (typically in
/// `main()`) so that [isCompleted] can be read synchronously.
class SharedPrefsOnboardingStore implements OnboardingStore {
  /// Creates a store backed by the given `prefs` instance.
  const SharedPrefsOnboardingStore(this._prefs);

  static const _kKey = 'onboarding_completed';

  final SharedPreferences _prefs;

  @override
  bool get isCompleted => _prefs.getBool(_kKey) ?? false;

  @override
  Future<void> complete() => _prefs.setBool(_kKey, true);
}
