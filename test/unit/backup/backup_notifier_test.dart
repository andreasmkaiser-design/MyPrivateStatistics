import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/features/backup/domain/backup_repository.dart';
import 'package:private_statistics/features/backup/domain/exceptions.dart';
import 'package:private_statistics/features/backup/domain/export_backup_use_case.dart';
import 'package:private_statistics/features/backup/domain/models/backup_validation_result.dart';
import 'package:private_statistics/features/backup/domain/restore_backup_use_case.dart';
import 'package:private_statistics/features/backup/domain/validate_backup_use_case.dart';
import 'package:private_statistics/features/backup/presentation/backup_notifier.dart';
import 'package:private_statistics/features/backup/presentation/restore_state.dart';

// ---------------------------------------------------------------------------
// Sentinel repository — never actually called; satisfies constructor types
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
// Fake use-cases
// ---------------------------------------------------------------------------

class _FakeExport extends ExportBackupUseCase {
  _FakeExport({this.throws}) : super(const _NeverCalledRepo());

  final BackupRestoreException? throws;

  @override
  Future<String> call() async {
    if (throws != null) throw throws!;
    return '/sdcard/backup.db';
  }
}

class _FakeValidate extends ValidateBackupUseCase {
  _FakeValidate({BackupValidationResult? result, this.throws})
    : _result =
          result ??
          const ValidationOk(filePath: '/backup/db.sqlite', schemaVersion: 5),
      super(const _NeverCalledRepo(), currentSchemaVersion: 5);

  final BackupValidationResult _result;
  final BackupRestoreException? throws;

  @override
  Future<BackupValidationResult> call() async {
    if (throws != null) throw throws!;
    return _result;
  }
}

class _FakeRestore extends RestoreBackupUseCase {
  _FakeRestore({this.throws}) : super(const _NeverCalledRepo());

  final BackupRestoreException? throws;
  BackupValidationResult? calledWith;

  @override
  Future<void> call(BackupValidationResult result) async {
    calledWith = result;
    if (throws != null) throw throws!;
  }
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

ProviderContainer _container({
  _FakeExport? export$,
  _FakeValidate? validate,
  _FakeRestore? restore,
}) {
  return ProviderContainer(
    overrides: [
      exportBackupUseCaseProvider.overrideWithValue(export$ ?? _FakeExport()),
      validateBackupUseCaseProvider.overrideWithValue(
        validate ?? _FakeValidate(),
      ),
      restoreBackupUseCaseProvider.overrideWithValue(restore ?? _FakeRestore()),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('BackupNotifier', () {
    test('initial state is RestoreIdle', () async {
      final container = _container();
      addTearDown(container.dispose);

      final state = await container.read(backupNotifierProvider.future);
      expect(state, isA<RestoreIdle>());
    });

    group('exportBackup', () {
      test('transitions busy → idle on success', () async {
        final container = _container();
        addTearDown(container.dispose);
        await container.read(backupNotifierProvider.future);

        await container.read(backupNotifierProvider.notifier).exportBackup();

        final state = container.read(backupNotifierProvider).value;
        expect(state, isA<RestoreIdle>());
      });

      test('returns to idle silently when picker is cancelled', () async {
        final container = _container(
          export$: _FakeExport(throws: const BackupCancelledException()),
        );
        addTearDown(container.dispose);
        await container.read(backupNotifierProvider.future);

        await container.read(backupNotifierProvider.notifier).exportBackup();

        final state = container.read(backupNotifierProvider).value;
        expect(state, isA<RestoreIdle>());
      });

      test('becomes AsyncError on BackupRestoreException', () async {
        final container = _container(
          export$: _FakeExport(
            throws: const RestoreFailedException('I/O error'),
          ),
        );
        addTearDown(container.dispose);
        await container.read(backupNotifierProvider.future);

        await container.read(backupNotifierProvider.notifier).exportBackup();

        expect(
          container.read(backupNotifierProvider),
          isA<AsyncError<RestoreState>>(),
        );
      });
    });

    group('pickAndValidate', () {
      test(
        'transitions to RestoreAwaitingConfirmation on ValidationOk',
        () async {
          final container = _container();
          addTearDown(container.dispose);
          await container.read(backupNotifierProvider.future);

          await container
              .read(backupNotifierProvider.notifier)
              .pickAndValidate();

          final state = container.read(backupNotifierProvider).value;
          expect(state, isA<RestoreAwaitingConfirmation>());
          final confirmed = state! as RestoreAwaitingConfirmation;
          expect(confirmed.result, isA<ValidationOk>());
        },
      );

      test(
        'transitions to RestoreAwaitingConfirmation on older schema',
        () async {
          final container = _container(
            validate: _FakeValidate(
              result: const ValidationOkOlderSchema(
                filePath: '/backup/old.sqlite',
                backupVersion: 3,
                appVersion: 5,
              ),
            ),
          );
          addTearDown(container.dispose);
          await container.read(backupNotifierProvider.future);

          await container
              .read(backupNotifierProvider.notifier)
              .pickAndValidate();

          final state = container.read(backupNotifierProvider).value;
          expect(state, isA<RestoreAwaitingConfirmation>());
          final confirmed = state! as RestoreAwaitingConfirmation;
          expect(confirmed.result, isA<ValidationOkOlderSchema>());
        },
      );

      test('returns to RestoreIdle when picker is cancelled', () async {
        final container = _container(
          validate: _FakeValidate(throws: const BackupCancelledException()),
        );
        addTearDown(container.dispose);
        await container.read(backupNotifierProvider.future);

        await container.read(backupNotifierProvider.notifier).pickAndValidate();

        final state = container.read(backupNotifierProvider).value;
        expect(state, isA<RestoreIdle>());
      });

      test(
        'becomes AsyncError on IncompatibleSchemaVersionException',
        () async {
          final container = _container(
            validate: _FakeValidate(
              throws: const IncompatibleSchemaVersionException(
                backupVersion: 9,
                appVersion: 5,
              ),
            ),
          );
          addTearDown(container.dispose);
          await container.read(backupNotifierProvider.future);

          await container
              .read(backupNotifierProvider.notifier)
              .pickAndValidate();

          expect(
            container.read(backupNotifierProvider),
            isA<AsyncError<RestoreState>>(),
          );
        },
      );
    });

    group('cancelRestore', () {
      test('returns to RestoreIdle from RestoreAwaitingConfirmation', () async {
        final container = _container();
        addTearDown(container.dispose);
        await container.read(backupNotifierProvider.future);

        await container.read(backupNotifierProvider.notifier).pickAndValidate();
        container.read(backupNotifierProvider.notifier).cancelRestore();

        final state = container.read(backupNotifierProvider).value;
        expect(state, isA<RestoreIdle>());
      });
    });

    group('confirmRestore', () {
      test('calls RestoreBackupUseCase with the provided result', () async {
        final fakeRestore = _FakeRestore();
        final container = _container(restore: fakeRestore);
        addTearDown(container.dispose);
        await container.read(backupNotifierProvider.future);

        const result = ValidationOk(
          filePath: '/backup/db.sqlite',
          schemaVersion: 5,
        );
        await container
            .read(backupNotifierProvider.notifier)
            .confirmRestore(result);

        expect(fakeRestore.calledWith, equals(result));
      });

      test('becomes AsyncError when restore throws', () async {
        final container = _container(
          restore: _FakeRestore(
            throws: const RestoreFailedException('swap failed'),
          ),
        );
        addTearDown(container.dispose);
        await container.read(backupNotifierProvider.future);

        await container
            .read(backupNotifierProvider.notifier)
            .confirmRestore(
              const ValidationOk(
                filePath: '/backup/db.sqlite',
                schemaVersion: 5,
              ),
            );

        expect(
          container.read(backupNotifierProvider),
          isA<AsyncError<RestoreState>>(),
        );
      });
    });
  });
}
