import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/features/onboarding/domain/onboarding_completion.dart';
import 'package:private_statistics/features/onboarding/presentation/onboarding_screen_3.dart';
import 'package:private_statistics/l10n/app_localizations.dart';

Widget _buildScreen({
  Future<void> Function(SeedChoice)? onChoice,
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
      onChoice: onChoice ?? (_) async {},
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
    await tester.pumpWidget(_buildScreen(onChoice: (c) async => chosen = c));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start with example categories'));
    // Use pump() not pumpAndSettle(): on success the spinner persists until
    // navigation removes the widget, so pumpAndSettle() would time out.
    await tester.pump();
    await tester.pump();
    expect(chosen, equals(SeedChoice.exampleCategories));
  });

  testWidgets('tapping "Start empty" calls onChoice with SeedChoice.empty', (
    tester,
  ) async {
    SeedChoice? chosen;
    await tester.pumpWidget(_buildScreen(onChoice: (c) async => chosen = c));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start empty'));
    await tester.pump();
    await tester.pump();
    expect(chosen, equals(SeedChoice.empty));
  });

  testWidgets('"Start with example categories" tile shows loading state while '
      'onChoice is in-flight and both tiles are disabled', (tester) async {
    final completer = Completer<void>();
    await tester.pumpWidget(_buildScreen(onChoice: (_) => completer.future));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start with example categories'));
    await tester.pump(); // one frame — future not yet resolved

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Both tiles must be disabled while loading
    final exampleTile = tester.widget<ListTile>(
      find
          .ancestor(
            of: find.text('Start with example categories'),
            matching: find.byType(ListTile),
          )
          .first,
    );
    final emptyTile = tester.widget<ListTile>(
      find
          .ancestor(
            of: find.text('Start empty'),
            matching: find.byType(ListTile),
          )
          .first,
    );
    expect(exampleTile.onTap, isNull);
    expect(emptyTile.onTap, isNull);

    completer.complete();
    // Use pump() not pumpAndSettle(): spinner persists on success until nav.
    await tester.pump();
    await tester.pump();
  });

  testWidgets('shows error snackbar when onChoice throws', (tester) async {
    await tester.pumpWidget(
      _buildScreen(onChoice: (_) async => throw Exception('seed failed')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start with example categories'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Setup failed'), findsOneWidget);
  });

  testWidgets('tiles are re-enabled after onChoice throws', (tester) async {
    await tester.pumpWidget(
      _buildScreen(onChoice: (_) async => throw Exception('seed failed')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start with example categories'));
    await tester.pumpAndSettle();

    final exampleTile = tester.widget<ListTile>(
      find
          .ancestor(
            of: find.text('Start with example categories'),
            matching: find.byType(ListTile),
          )
          .first,
    );
    expect(exampleTile.onTap, isNotNull);
  });

  testWidgets('Skip button triggers onSkip callback', (tester) async {
    var skipped = false;
    await tester.pumpWidget(_buildScreen(onSkip: () => skipped = true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    expect(skipped, isTrue);
  });
}
