import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import 'package:private_statistics/features/onboarding/domain/onboarding_completion.dart';
import 'package:private_statistics/features/onboarding/presentation/onboarding_screen_1.dart';
import 'package:private_statistics/features/onboarding/presentation/onboarding_screen_2.dart';
import 'package:private_statistics/features/onboarding/presentation/onboarding_screen_3.dart';
import 'package:private_statistics/features/onboarding/providers/onboarding_providers.dart';

/// Root widget for the onboarding wizard.
///
/// Hosts a [PageView] with three screens. Page navigation is driven by a local
/// [PageController]; completion and skip are delegated to
/// `OnboardingNotifier`. When `OnboardingNotifier.skip` or
/// `OnboardingNotifier.complete` sets [OnboardingCompletion.isDone] to `true`,
/// `App` rebuilds and replaces this widget with `AppShell` automatically —
/// no [Navigator] call is needed here.
class OnboardingFlow extends ConsumerStatefulWidget {
  /// Creates the [OnboardingFlow].
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  late final PageController _pageController;

  static const _types = [
    HealthDataType.STEPS,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.WORKOUT,
  ];

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

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<bool> _requestHcPermission() async {
    try {
      await Health().configure();
      return Health().requestAuthorization(_types);
    } on Exception catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        OnboardingScreen1(
          onNext: _nextPage,
          onSkip: () => ref.read(onboardingNotifierProvider.notifier).skip(),
        ),
        OnboardingScreen2(
          onContinue: _nextPage,
          onSkip: () => ref.read(onboardingNotifierProvider.notifier).skip(),
          requestPermission: _requestHcPermission,
        ),
        OnboardingScreen3(
          onChoice: (choice) =>
              ref.read(onboardingNotifierProvider.notifier).complete(choice),
          onSkip: () => ref.read(onboardingNotifierProvider.notifier).skip(),
        ),
      ],
    );
  }
}
