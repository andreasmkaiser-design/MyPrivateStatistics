import 'package:flutter/material.dart';
import 'package:private_statistics/l10n/app_localizations.dart';

/// Full-page settings screen, accessible via the toolbar icon in `AppShell`.
class SettingsScreen extends StatelessWidget {
  /// Creates the [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: const SizedBox.shrink(),
    );
  }
}
