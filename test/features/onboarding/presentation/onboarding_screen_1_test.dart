import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/features/onboarding/presentation/onboarding_screen_1.dart';
import 'package:private_statistics/l10n/app_localizations.dart';

Widget _buildScreen({VoidCallback? onNext, VoidCallback? onSkip}) =>
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: OnboardingScreen1(
          onNext: onNext ?? () {},
          onSkip: onSkip ?? () {},
        ),
      ),
    );

void main() {
  testWidgets('Screen 1 renders the concept explanation headline', (
    tester,
  ) async {
    await tester.pumpWidget(_buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Private Statistics'), findsOneWidget);
  });

  testWidgets('Screen 1 renders the concept explanation body text', (
    tester,
  ) async {
    await tester.pumpWidget(_buildScreen());
    await tester.pumpAndSettle();

    expect(find.textContaining('Track the events that matter'), findsOneWidget);
  });

  testWidgets('Screen 1 has a Skip button that triggers onSkip callback', (
    tester,
  ) async {
    var skipped = false;
    await tester.pumpWidget(_buildScreen(onSkip: () => skipped = true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    expect(skipped, isTrue);
  });

  testWidgets('Screen 1 has a Next button that triggers onNext callback', (
    tester,
  ) async {
    var nextCalled = false;
    await tester.pumpWidget(_buildScreen(onNext: () => nextCalled = true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next'));
    expect(nextCalled, isTrue);
  });
}
