import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/features/backup/domain/backup_repository.dart';
import 'package:private_statistics/features/backup/domain/exceptions.dart';
import 'package:private_statistics/features/backup/domain/export_backup_use_case.dart';
import 'package:private_statistics/features/backup/domain/models/backup_validation_result.dart';
import 'package:private_statistics/features/backup/domain/restore_backup_use_case.dart';
import 'package:private_statistics/features/backup/domain/validate_backup_use_case.dart';
import 'package:private_statistics/features/backup/presentation/backup_notifier.dart';
import 'package:private_statistics/features/backup/presentation/backup_section.dart';
import 'package:private_statistics/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Sentinel repository — satisfies constructor types; never actually called
// ---------------------------------------------------------------------------

class _NeverCalledRepo implements BackupRepository {
  const _NeverCalledRepo();

  @override
  Future<String> getDatabasePath() => throw StateError('not called');
  @override
  Future<String> exportFile(File f) => throw StateError('not called');
  @override
  Future<String> pickRestoreFile() => throw StateError('not called');
  @override
  Future<int> readSchemaVersion(String p) => throw StateError('not called');
  @override
  Future<void> replaceDatabase(File f) => throw StateError('not called');
  @override
  Future<void> restartApp() => throw StateError('not called');
}

// ---------------------------------------------------------------------------
// Controllable fake use-cases
// ---------------------------------------------------------------------------

/// A [ValidateBackupUseCase] whose outcome can be set before each test.
class _ControllableValidate extends ValidateBackupUseCase {
  _ControllableValidate()
    : super(const _NeverCalledRepo(), currentSchemaVersion: 5);

  /// Set before calling pickAndValidate in the widget.
  Object? nextResult;

  @override
  Future<BackupValidationResult> call() async {
    final r = nextResult;
    if (r is BackupRestoreException) throw r;
    return r! as BackupValidationResult;
  }
}

class _NoOpExport extends ExportBackupUseCase {
  _NoOpExport() : super(const _NeverCalledRepo());

  @override
  Future<String> call() async => '/sdcard/backup.db';
}

class _NoOpRestore extends RestoreBackupUseCase {
  _NoOpRestore() : super(const _NeverCalledRepo());

  @override
  Future<void> call(BackupValidationResult result) async {}
}

// ---------------------------------------------------------------------------
// Test helper
// ---------------------------------------------------------------------------

Widget _buildWidget(_ControllableValidate validate) => ProviderScope(
  overrides: [
    exportBackupUseCaseProvider.overrideWithValue(_NoOpExport()),
    validateBackupUseCaseProvider.overrideWithValue(validate),
    restoreBackupUseCaseProvider.overrideWithValue(_NoOpRestore()),
  ],
  child: const MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: BackupSection()),
  ),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('BackupSection widget', () {
    testWidgets('confirmation dialog appears after picking a valid backup', (
      tester,
    ) async {
      final validate = _ControllableValidate()
        ..nextResult = const ValidationOk(
          filePath: '/backup/db.sqlite',
          schemaVersion: 5,
        );

      await tester.pumpWidget(_buildWidget(validate));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Restore backup'));
      await tester.pumpAndSettle();

      expect(find.text('Replace all data?'), findsOneWidget);
      expect(
        find.text('All current data will be replaced with the backup.'),
        findsOneWidget,
      );
    });

    testWidgets('migration warning shown in dialog for older-schema backup', (
      tester,
    ) async {
      final validate = _ControllableValidate()
        ..nextResult = const ValidationOkOlderSchema(
          filePath: '/backup/old.sqlite',
          backupVersion: 3,
          appVersion: 5,
        );

      await tester.pumpWidget(_buildWidget(validate));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Restore backup'));
      await tester.pumpAndSettle();

      expect(find.text('Replace all data?'), findsOneWidget);
      expect(find.textContaining('older schema'), findsOneWidget);
    });

    testWidgets('tapping Cancel dismisses dialog without restoring', (
      tester,
    ) async {
      final validate = _ControllableValidate()
        ..nextResult = const ValidationOk(
          filePath: '/backup/db.sqlite',
          schemaVersion: 5,
        );

      await tester.pumpWidget(_buildWidget(validate));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Restore backup'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Replace all data?'), findsNothing);
    });

    testWidgets('incompatible schema error does not show dialog', (
      tester,
    ) async {
      final validate = _ControllableValidate()
        ..nextResult = const IncompatibleSchemaVersionException(
          backupVersion: 9,
          appVersion: 5,
        );

      await tester.pumpWidget(_buildWidget(validate));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Restore backup'));
      // Use explicit pumps instead of pumpAndSettle: the briefly-visible
      // RestoreBusy spinner is indeterminate and pumpAndSettle never settles
      // while it is in the tree. Two pumps are sufficient for the async fake
      // to throw and the notifier to set AsyncError.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Replace all data?'), findsNothing);
    });
  });
}
