import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/features/backup/domain/backup_repository.dart';
import 'package:private_statistics/features/backup/domain/models/backup_validation_result.dart';
import 'package:private_statistics/features/backup/domain/restore_backup_use_case.dart';

// ---------------------------------------------------------------------------
// Fake
// ---------------------------------------------------------------------------

class _FakeRepo implements BackupRepository {
  File? replacedWith;
  bool restarted = false;

  @override
  Future<void> replaceDatabase(File replacementFile) async {
    replacedWith = replacementFile;
  }

  @override
  Future<void> restartApp() async => restarted = true;

  // Unused in restore tests.
  @override
  Future<String> getDatabasePath() async => '';
  @override
  Future<String> exportFile(File sourceFile) async => '';
  @override
  Future<String> pickRestoreFile() async => '';
  @override
  Future<int> readSchemaVersion(String filePath) async => 0;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('RestoreBackupUseCase', () {
    test('calls replaceDatabase with the path from ValidationOk', () async {
      final repo = _FakeRepo();
      await RestoreBackupUseCase(repo).call(
        const ValidationOk(filePath: '/backup/db.sqlite', schemaVersion: 5),
      );

      expect(repo.replacedWith?.path, equals('/backup/db.sqlite'));
    });

    test(
      'calls replaceDatabase with path from ValidationOkOlderSchema',
      () async {
        final repo = _FakeRepo();
        await RestoreBackupUseCase(repo).call(
          const ValidationOkOlderSchema(
            filePath: '/backup/old.sqlite',
            backupVersion: 3,
            appVersion: 5,
          ),
        );

        expect(repo.replacedWith?.path, equals('/backup/old.sqlite'));
      },
    );

    test('calls restartApp after successful replaceDatabase', () async {
      final repo = _FakeRepo();
      await RestoreBackupUseCase(repo).call(
        const ValidationOk(filePath: '/backup/db.sqlite', schemaVersion: 5),
      );

      expect(repo.restarted, isTrue);
    });
  });
}
