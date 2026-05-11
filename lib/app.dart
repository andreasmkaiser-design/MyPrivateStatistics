import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_statistics/app_shell.dart';
import 'package:private_statistics/features/onboarding/presentation/onboarding_flow.dart';
import 'package:private_statistics/features/onboarding/providers/onboarding_providers.dart';
import 'package:private_statistics/l10n/app_localizations.dart';

/// Root widget of the application.
///
/// Configures [MaterialApp] with localisation delegates, the indigo colour
/// scheme, and Material 3. On first launch the home is [OnboardingFlow];
/// on subsequent launches (or after the wizard completes) it is [AppShell].
/// The routing decision is driven by [onboardingCompletedProvider].
class App extends ConsumerWidget {
  /// Creates the root [App] widget.
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingDone = ref.watch(onboardingCompletedProvider);
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: onboardingDone ? const AppShell() : const OnboardingFlow(),
    );
  }
}
