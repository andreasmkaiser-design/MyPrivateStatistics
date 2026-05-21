import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/app.dart';
import 'package:private_statistics/core/database/app_database.dart';
import 'package:private_statistics/core/database/database_provider.dart';
import 'package:private_statistics/features/categories/providers/category_providers.dart';
import 'package:private_statistics/features/events/providers/event_providers.dart';
import 'package:private_statistics/features/health/providers/health_providers.dart';
import 'package:private_statistics/features/settings/presentation/settings_screen.dart';
import 'package:private_statistics/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Fake HcPermissionNotifier
// ---------------------------------------------------------------------------

class _FakeHcPermissionNotifier extends HcPermissionNotifier {
  _FakeHcPermissionNotifier({required bool granted, this.onRequest})
    : _granted = granted;

  final bool _granted;

  /// Called when [requestPermission] is invoked — used to verify the tap.
  final void Function()? onRequest;

  @override
  Future<bool> build() async => _granted;

  @override
  Future<bool> requestPermission() async {
    onRequest?.call();
    return _granted;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _buildApp(AppDatabase db) => ProviderScope(
  overrides: [
    appDatabaseProvider.overrideWithValue(db),
    categoryTreeProvider.overrideWith((_) => Stream.value(const [])),
    eventDaysInMonthProvider.overrideWith((ref, _) => Stream.value(const {})),
    eventsByDayProvider.overrideWith((ref, _) => Stream.value(const [])),
    syncHourProvider.overrideWith((_) => Future.value(2)),
    hcPermissionNotifierProvider.overrideWith(
      () => _FakeHcPermissionNotifier(granted: false),
    ),
  ],
  child: const App(),
);

Widget _buildSettingsScreen({
  required bool hcGranted,
  void Function()? onRequest,
}) => ProviderScope(
  overrides: [
    syncHourProvider.overrideWith((_) => Future.value(2)),
    hcPermissionNotifierProvider.overrideWith(
      () => _FakeHcPermissionNotifier(granted: hcGranted, onRequest: onRequest),
    ),
  ],
  child: const MaterialApp(
    localizationsDelegates: [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SettingsScreen()),
  ),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  testWidgets('tapping settings icon navigates to SettingsScreen', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(db));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  group('Health Connect status tile', () {
    testWidgets('shows connected tile when permissions are granted', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSettingsScreen(hcGranted: true));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Health Connect connected'), findsOneWidget);
      expect(find.byIcon(Icons.link), findsNothing);
    });

    testWidgets('shows grant button tile when permissions are not granted', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSettingsScreen(hcGranted: false));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.link), findsOneWidget);
      expect(find.text('Grant Health Connect access'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('tapping grant tile invokes the authorization callback', (
      tester,
    ) async {
      var callCount = 0;
      await tester.pumpWidget(
        _buildSettingsScreen(hcGranted: false, onRequest: () => callCount++),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Grant Health Connect access'));
      await tester.pumpAndSettle();

      expect(callCount, 1);
    });
  });
}
