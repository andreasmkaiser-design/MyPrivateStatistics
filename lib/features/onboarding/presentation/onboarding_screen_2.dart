import 'package:flutter/material.dart';
import 'package:private_statistics/core/logging/app_logger.dart';
import 'package:private_statistics/l10n/app_localizations.dart';

/// Tracks the Health Connect authorization state within Screen 2.
enum _HcStatus {
  /// No request has been made yet.
  idle,

  /// A permission request is in-flight.
  requesting,

  /// The user granted permission.
  granted,

  /// The user denied permission (requestPermission returned false).
  denied,

  /// requestPermission threw an exception.
  error,
}

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
  ///
  /// May throw; errors are caught, logged via `AppLogger`, and shown to the
  /// user as a localized error message.
  final Future<bool> Function() requestPermission;

  @override
  State<OnboardingScreen2> createState() => _OnboardingScreen2State();
}

class _OnboardingScreen2State extends State<OnboardingScreen2> {
  _HcStatus _status = _HcStatus.idle;

  Future<void> _request() async {
    setState(() => _status = _HcStatus.requesting);
    try {
      final granted = await widget.requestPermission();
      if (mounted) {
        setState(
          () => _status = granted ? _HcStatus.granted : _HcStatus.denied,
        );
      }
    } on Exception catch (e, st) {
      AppLogger.error('Health Connect authorization failed', e, st);
      if (mounted) {
        setState(() => _status = _HcStatus.error);
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
          _buildStatus(l10n),
          const SizedBox(height: 16),
          if (_status != _HcStatus.granted)
            FilledButton(
              onPressed: _status == _HcStatus.requesting ? null : _request,
              child: _status == _HcStatus.requesting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.onboardingScreen2GrantButton),
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

  Widget _buildStatus(AppLocalizations l10n) {
    return switch (_status) {
      _HcStatus.granted => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 8),
          Text(l10n.onboardingScreen2PermissionGranted),
        ],
      ),
      _HcStatus.denied => Text(
        l10n.onboardingScreen2PermissionDenied,
        textAlign: TextAlign.center,
      ),
      _HcStatus.error => Text(
        l10n.onboardingScreen2PermissionError,
        textAlign: TextAlign.center,
      ),
      _HcStatus.idle || _HcStatus.requesting => const SizedBox.shrink(),
    };
  }
}
