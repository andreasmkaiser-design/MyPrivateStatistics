import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_statistics/features/health/providers/health_providers.dart';
import 'package:private_statistics/features/onboarding/domain/onboarding_completion.dart';
import 'package:private_statistics/features/onboarding/presentation/onboarding_screen_1.dart';
import 'package:private_statistics/features/onboarding/presentation/onboarding_screen_2.dart';
import 'package:private_statistics/features/onboarding/presentation/onboarding_screen_3.dart';
import 'package:private_statistics/features/onboarding/providers/onboarding_providers.dart';

/// Root widget for the onboarding wizard.
///
/// Watches [hcPermissionsGrantedProvider], [hasCategoriesProvider], and
/// [appVersionProvider] to determine which screens to show:
/// - Screen 2 is skipped when HC permissions are already granted.
/// - Screen 3 is skipped when the categories table is non-empty.
///
/// Completion and skip are delegated to `OnboardingNotifier`. When
/// [OnboardingCompletion.isDone] becomes `true`, `App` rebuilds and replaces
/// this widget with `AppShell` automatically — no [Navigator] call is needed.
class OnboardingFlow extends ConsumerStatefulWidget {
  /// Creates the [OnboardingFlow].
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  late final PageController _pageController;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage(int pageCount) {
    if (_pageIndex >= pageCount - 1) {
      ref.read(onboardingNotifierProvider.notifier).skip();
    } else {
      _pageIndex++;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hcGranted = ref.watch(hcPermissionsGrantedProvider);
    final hasCategories = ref.watch(hasCategoriesProvider);
    final version = ref.watch(appVersionProvider);

    if (hcGranted.isLoading || hasCategories.isLoading || version.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final showScreen2 = !(hcGranted.value ?? false);
    final showScreen3 = !(hasCategories.value ?? false);
    final pageCount = 1 + (showScreen2 ? 1 : 0) + (showScreen3 ? 1 : 0);

    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final requestHcPermission = ref
        .read(hcPermissionNotifierProvider.notifier)
        .requestPermission;

    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        OnboardingScreen1(
          onNext: () => _nextPage(pageCount),
          onSkip: notifier.skip,
          version: version.value ?? '',
        ),
        if (showScreen2)
          OnboardingScreen2(
            onContinue: () => _nextPage(pageCount),
            onSkip: notifier.skip,
            requestPermission: requestHcPermission,
          ),
        if (showScreen3)
          OnboardingScreen3(onChoice: notifier.complete, onSkip: notifier.skip),
      ],
    );
  }
}
