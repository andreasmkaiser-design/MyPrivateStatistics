import 'package:flutter/material.dart';
import 'package:private_statistics/l10n/app_localizations.dart';

/// Second onboarding screen — requests Health Connect permission in context.
///
/// Owns HC permission state locally; calls [requestPermission] when the user
/// taps the grant button. Declining does not block progress — [onContinue] is
/// always available.
class OnboardingScreen2 extends StatefulWidget {
  /// Creates [OnboardingScreen2].
  ///
  /// [requestPermission] is injected so tests can supply a mock without
  /// touching the real Health Connect plugin.
  const OnboardingScreen2({
    required this.onContinue,
    required this.onSkip,
    required this.requestPermission,
    super.key,
  });

  /// Called when the user taps Continue (with or without granting permission).
  final VoidCallback onContinue;

  /// Called when the user taps Skip.
  final VoidCallback onSkip;

  /// Returns `true` if the user granted Health Connect permission.
  final Future<bool> Function() requestPermission;

  @override
  State<OnboardingScreen2> createState() => _OnboardingScreen2State();
}

class _OnboardingScreen2State extends State<OnboardingScreen2> {
  bool? _permissionGranted;
  bool _requesting = false;

  Future<void> _request() async {
    setState(() => _requesting = true);
    final granted = await widget.requestPermission();
    if (mounted) {
      setState(() {
        _permissionGranted = granted;
        _requesting = false;
      });
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
            l10n.onboardingScreen2Title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.onboardingScreen2Rationale,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (_permissionGranted ?? false)
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Permission granted'),
              ],
            )
          else if (!(_permissionGranted ?? true))
            const Text(
              'Permission not granted — you can enable it later in Settings.',
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 16),
          if (!(_permissionGranted ?? false))
            FilledButton(
              onPressed: _requesting ? null : _request,
              child: Text(l10n.onboardingScreen2GrantButton),
            ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: widget.onSkip,
                child: Text(l10n.onboardingSkip),
              ),
              FilledButton(
                onPressed: widget.onContinue,
                child: Text(l10n.onboardingScreen2ContinueButton),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
