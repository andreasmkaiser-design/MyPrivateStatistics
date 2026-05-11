import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/features/backup/domain/backup_repository.dart';
import 'package:private_statistics/features/backup/domain/exceptions.dart';
import 'package:private_statistics/features/backup/domain/export_backup_use_case.dart';

// ---------------------------------------------------------------------------
// Fake
// ---------------------------------------------------------------------------

class _FakeRepo implements BackupRepository {
  _FakeRepo({
    this.exportDestination = '/sdcard/backup.db',
    this.cancelExport = false,
  });

  final String exportDestination;
  final bool cancelExport;

  File? capturedSource;

  @override
  Future<String> getDatabasePath() async => '/data/private_statistics.db';

  @override
  Future<String> exportFile(File sourceFile) async {
    if (cancelExport) throw const BackupCancelledException();
    capturedSource = sourceFile;
    return exportDestination;
  }

  // Unused in export tests.
  @override
  Future<String> pickRestoreFile() async => '';
  @override
  Future<int> readSchemaVersion(String filePath) async => 0;
  @override
  Future<void> replaceDatabase(File replacementFile) async {}
  @override
  Future<void> restartApp() async {}
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ExportBackupUseCase', () {
    test('exports the database file from getDatabasePath', () async {
      final repo = _FakeRepo();
      await ExportBackupUseCase(repo).call();

      expect(repo.capturedSource?.path, equals('/data/private_statistics.db'));
    });

    test('returns the destination path reported by the repository', () async {
      final repo = _FakeRepo(exportDestination: '/sdcard/Downloads/backup.db');
      final destination = await ExportBackupUseCase(repo).call();

      expect(destination, equals('/sdcard/Downloads/backup.db'));
    });

    test(
      'propagates BackupCancelledException when picker is dismissed',
      () async {
        final repo = _FakeRepo(cancelExport: true);

        await expectLater(
          ExportBackupUseCase(repo).call,
          throwsA(isA<BackupCancelledException>()),
        );
      },
    );
  });
}
