import 'package:flutter/material.dart';
import 'package:private_statistics/l10n/app_localizations.dart';

/// First onboarding screen — explains the app concept to the user.
class OnboardingScreen1 extends StatelessWidget {
  /// Creates [OnboardingScreen1].
  ///
  /// [onNext] is called when the user taps the Next button.
  /// [onSkip] is called when the user taps the Skip button.
  const OnboardingScreen1({
    required this.onNext,
    required this.onSkip,
    super.key,
  });

  /// Called when the user taps Next.
  final VoidCallback onNext;

  /// Called when the user taps Skip.
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Text(
            l10n.onboardingScreen1Title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.onboardingScreen1Body,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(onPressed: onSkip, child: Text(l10n.onboardingSkip)),
              FilledButton(onPressed: onNext, child: const Text('Next')),
            ],
          ),
        ],
      ),
    );
  }
}
