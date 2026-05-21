import 'package:flutter/material.dart';
import 'package:private_statistics/core/logging/app_logger.dart';
import 'package:private_statistics/features/onboarding/domain/onboarding_completion.dart';
import 'package:private_statistics/l10n/app_localizations.dart';

/// Third onboarding screen — lets the user choose between example categories
/// or starting with an empty database.
class OnboardingScreen3 extends StatefulWidget {
  /// Creates [OnboardingScreen3].
  ///
  /// [onChoice] is awaited — if it throws, the error is logged and a
  /// localized [SnackBar] is shown. [onSkip] is called when the user taps Skip.
  const OnboardingScreen3({
    required this.onChoice,
    required this.onSkip,
    super.key,
  });

  /// Called with [SeedChoice.exampleCategories] or [SeedChoice.empty].
  ///
  /// The returned [Future] is awaited; errors are surfaced via [SnackBar].
  final Future<void> Function(SeedChoice choice) onChoice;

  /// Called when the user taps Skip.
  final VoidCallback onSkip;

  @override
  State<OnboardingScreen3> createState() => _OnboardingScreen3State();
}

class _OnboardingScreen3State extends State<OnboardingScreen3> {
  SeedChoice? _loadingChoice;

  Future<void> _choose(SeedChoice choice) async {
    if (_loadingChoice != null) return;
    setState(() => _loadingChoice = choice);
    try {
      await widget.onChoice(choice);
    } on Exception catch (e, st) {
      AppLogger.error('Onboarding seed failed', e, st);
      if (mounted) {
        setState(() => _loadingChoice = null);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.onboardingScreen3SetupError)),
        );
      }
    }
  }

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
            isLoading: _loadingChoice == SeedChoice.exampleCategories,
            isDisabled: _loadingChoice != null,
            onTap: () => _choose(SeedChoice.exampleCategories),
          ),
          const SizedBox(height: 16),
          _ChoiceTile(
            title: l10n.onboardingScreen3EmptyTitle,
            subtitle: l10n.onboardingScreen3EmptySubtitle,
            icon: Icons.add_circle_outline,
            isLoading: _loadingChoice == SeedChoice.empty,
            isDisabled: _loadingChoice != null,
            onTap: () => _choose(SeedChoice.empty),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _loadingChoice != null ? null : widget.onSkip,
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
    this.isLoading = false,
    this.isDisabled = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  /// Whether this tile is showing a loading spinner (choice in-flight).
  final bool isLoading;

  /// Whether taps should be ignored (another choice is in-flight).
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: isLoading ? null : const Icon(Icons.chevron_right),
        onTap: isDisabled ? null : onTap,
      ),
    );
  }
}
