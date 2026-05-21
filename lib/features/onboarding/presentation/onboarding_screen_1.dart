import 'package:flutter/material.dart';
import 'package:private_statistics/l10n/app_localizations.dart';

/// First onboarding screen — explains the app concept to the user.
class OnboardingScreen1 extends StatelessWidget {
  /// Creates [OnboardingScreen1].
  ///
  /// [onNext] is called when the user taps the Next button.
  /// [onSkip] is called when the user taps the Skip button.
  /// [version] is displayed prominently below the body text; pass an empty
  /// string to suppress the label (e.g. when the platform info is unavailable).
  const OnboardingScreen1({
    required this.onNext,
    required this.onSkip,
    required this.version,
    super.key,
  });

  /// Called when the user taps Next.
  final VoidCallback onNext;

  /// Called when the user taps Skip.
  final VoidCallback onSkip;

  /// App version string shown below the body text (e.g. `'1.0.0'`).
  final String version;

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
          if (version.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              l10n.onboardingScreen1Version(version),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(onPressed: onSkip, child: Text(l10n.onboardingSkip)),
              FilledButton(
                onPressed: onNext,
                child: Text(l10n.onboardingScreen2ContinueButton),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
