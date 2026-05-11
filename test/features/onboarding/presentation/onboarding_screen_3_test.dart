import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/features/onboarding/domain/onboarding_completion.dart';
import 'package:private_statistics/features/onboarding/presentation/onboarding_screen_3.dart';
import 'package:private_statistics/l10n/app_localizations.dart';

Widget _buildScreen({
  void Function(SeedChoice)? onChoice,
  VoidCallback? onSkip,
}) => MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: OnboardingScreen3(
      onChoice: onChoice ?? (_) {},
      onSkip: onSkip ?? () {},
    ),
  ),
);

void main() {
  testWidgets('Screen 3 renders both choice options', (tester) async {
    await tester.pumpWidget(_buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Start with example categories'), findsOneWidget);
    expect(find.text('Start empty'), findsOneWidget);
  });

  testWidgets('tapping "Start with example categories" calls onChoice with '
      'SeedChoice.exampleCategories', (tester) async {
    SeedChoice? chosen;
    await tester.pumpWidget(_buildScreen(onChoice: (c) => chosen = c));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start with example categories'));
    expect(chosen, equals(SeedChoice.exampleCategories));
  });

  testWidgets('tapping "Start empty" calls onChoice with SeedChoice.empty', (
    tester,
  ) async {
    SeedChoice? chosen;
    await tester.pumpWidget(_buildScreen(onChoice: (c) => chosen = c));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start empty'));
    expect(chosen, equals(SeedChoice.empty));
  });

  testWidgets('Skip button triggers onSkip callback', (tester) async {
    var skipped = false;
    await tester.pumpWidget(_buildScreen(onSkip: () => skipped = true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    expect(skipped, isTrue);
  });
}
