import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/features/onboarding/data/shared_prefs_onboarding_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('SharedPrefsOnboardingStore', () {
    test('isCompleted returns false on a fresh install', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = SharedPrefsOnboardingStore(prefs);
      expect(store.isCompleted, isFalse);
    });

    test('isCompleted returns true after complete() is called', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = SharedPrefsOnboardingStore(prefs);
      await store.complete();
      expect(store.isCompleted, isTrue);
    });

    test(
      'flag persists across separate store instances sharing the same prefs',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await SharedPrefsOnboardingStore(prefs).complete();
        expect(SharedPrefsOnboardingStore(prefs).isCompleted, isTrue);
      },
    );
  });
}
