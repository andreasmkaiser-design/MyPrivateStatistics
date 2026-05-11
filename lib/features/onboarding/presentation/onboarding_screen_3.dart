import 'package:flutter/material.dart';
import 'package:private_statistics/features/onboarding/domain/onboarding_completion.dart';
import 'package:private_statistics/l10n/app_localizations.dart';

/// Third onboarding screen — lets the user choose between example categories
/// or starting with an empty database.
class OnboardingScreen3 extends StatelessWidget {
  /// Creates [OnboardingScreen3].
  ///
  /// [onChoice] is called with the user's [SeedChoice] when they tap a tile.
  /// [onSkip] is called when the user taps Skip.
  const OnboardingScreen3({
    required this.onChoice,
    required this.onSkip,
    super.key,
  });

  /// Called with [SeedChoice.exampleCategories] or [SeedChoice.empty].
  final void Function(SeedChoice choice) onChoice;

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
            l10n.onboardingScreen3Title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _ChoiceTile(
            title: l10n.onboardingScreen3ExampleTitle,
            subtitle: l10n.onboardingScreen3ExampleSubtitle,
            icon: Icons.category,
            onTap: () => onChoice(SeedChoice.exampleCategories),
          ),
          const SizedBox(height: 16),
          _ChoiceTile(
            title: l10n.onboardingScreen3EmptyTitle,
            subtitle: l10n.onboardingScreen3EmptySubtitle,
            icon: Icons.add_circle_outline,
            onTap: () => onChoice(SeedChoice.empty),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onSkip,
              child: Text(l10n.onboardingSkip),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
