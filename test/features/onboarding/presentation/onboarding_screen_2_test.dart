import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/features/onboarding/presentation/onboarding_screen_2.dart';
import 'package:private_statistics/l10n/app_localizations.dart';

Widget _buildScreen({
  VoidCallback? onContinue,
  VoidCallback? onSkip,
  Future<bool> Function()? requestPermission,
  Locale locale = const Locale('en'),
}) => MaterialApp(
  locale: locale,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: OnboardingScreen2(
      onContinue: onContinue ?? () {},
      onSkip: onSkip ?? () {},
      requestPermission: requestPermission ?? () async => false,
    ),
  ),
);

void main() {
  testWidgets('Screen 2 renders the Health Connect headline', (tester) async {
    await tester.pumpWidget(_buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Health Connect'), findsOneWidget);
  });

  testWidgets('Screen 2 renders the permission rationale text', (tester) async {
    await tester.pumpWidget(_buildScreen());
    await tester.pumpAndSettle();

    expect(find.textContaining('Connect to Health Connect'), findsOneWidget);
  });

  testWidgets('Screen 2 has a Grant button', (tester) async {
    await tester.pumpWidget(_buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Grant Health Connect access'), findsOneWidget);
  });

  testWidgets('grant button shows CircularProgressIndicator while '
      'requestPermission is in-flight', (tester) async {
    final completer = Completer<bool>();
    await tester.pumpWidget(
      _buildScreen(requestPermission: () => completer.future),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Grant Health Connect access'));
    await tester.pump(); // one frame — future not yet resolved

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Grant Health Connect access'), findsNothing);

    completer.complete(false);
    await tester.pumpAndSettle();
  });

  testWidgets('declining permission (requestPermission returns false) '
      'still allows tapping Continue', (tester) async {
    var continueCalled = false;
    await tester.pumpWidget(
      _buildScreen(
        requestPermission: () async => false,
        onContinue: () => continueCalled = true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Grant Health Connect access'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    expect(continueCalled, isTrue);
  });

  testWidgets(
    'Screen 2 shows German permission-denied text after a failed request',
    (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          locale: const Locale('de'),
          requestPermission: () async => false,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Health Connect-Zugriff erteilen'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Berechtigung nicht erteilt'), findsOneWidget);
    },
  );

  testWidgets('Screen 2 shows error text when requestPermission throws', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildScreen(
        requestPermission: () async => throw Exception('HC unavailable'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Grant Health Connect access'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Failed to request Health Connect'),
      findsOneWidget,
    );
  });

  testWidgets('Skip button triggers onSkip callback', (tester) async {
    var skipped = false;
    await tester.pumpWidget(_buildScreen(onSkip: () => skipped = true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    expect(skipped, isTrue);
  });
}
