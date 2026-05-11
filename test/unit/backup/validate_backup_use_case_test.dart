import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/features/backup/domain/backup_repository.dart';
import 'package:private_statistics/features/backup/domain/exceptions.dart';
import 'package:private_statistics/features/backup/domain/models/backup_validation_result.dart';
import 'package:private_statistics/features/backup/domain/validate_backup_use_case.dart';

// ---------------------------------------------------------------------------
// Fake
// ---------------------------------------------------------------------------

class _FakeRepo implements BackupRepository {
  _FakeRepo({
    this.pickedPath = '/backup/db.sqlite',
    this.schemaVersion = 5,
    this.cancelPick = false,
  });

  final String pickedPath;
  final int schemaVersion;
  final bool cancelPick;

  @override
  Future<String> pickRestoreFile() async {
    if (cancelPick) throw const BackupCancelledException();
    return pickedPath;
  }

  @override
  Future<int> readSchemaVersion(String filePath) async => schemaVersion;

  // Unused in validation tests.
  @override
  Future<String> getDatabasePath() async => '';
  @override
  Future<String> exportFile(File sourceFile) async => '';
  @override
  Future<void> replaceDatabase(File replacementFile) async {}
  @override
  Future<void> restartApp() async {}
}

ValidateBackupUseCase _useCase({
  String pickedPath = '/backup/db.sqlite',
  int fileSchemaVersion = 5,
  int appSchemaVersion = 5,
  bool cancelPick = false,
}) => ValidateBackupUseCase(
  _FakeRepo(
    pickedPath: pickedPath,
    schemaVersion: fileSchemaVersion,
    cancelPick: cancelPick,
  ),
  currentSchemaVersion: appSchemaVersion,
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ValidateBackupUseCase', () {
    test(
      'same schema version returns ValidationOk with correct path',
      () async {
        final result = await _useCase().call();

        expect(result, isA<ValidationOk>());
        final ok = result as ValidationOk;
        expect(ok.filePath, equals('/backup/db.sqlite'));
        expect(ok.schemaVersion, equals(5));
      },
    );

    test('older backup schema returns ValidationOkOlderSchema', () async {
      final result = await _useCase(fileSchemaVersion: 3).call();

      expect(result, isA<ValidationOkOlderSchema>());
      final older = result as ValidationOkOlderSchema;
      expect(older.backupVersion, equals(3));
      expect(older.appVersion, equals(5));
      expect(older.filePath, equals('/backup/db.sqlite'));
    });

    test(
      'newer backup schema throws IncompatibleSchemaVersionException',
      () async {
        await expectLater(
          () => _useCase(fileSchemaVersion: 9).call(),
          throwsA(
            isA<IncompatibleSchemaVersionException>()
                .having((e) => e.backupVersion, 'backupVersion', 9)
                .having((e) => e.appVersion, 'appVersion', 5),
          ),
        );
      },
    );

    test(
      'schema version 0 (invalid file) throws InvalidBackupFileException',
      () async {
        await expectLater(
          _useCase(fileSchemaVersion: 0).call,
          throwsA(isA<InvalidBackupFileException>()),
        );
      },
    );

    test('cancelled file-picker propagates BackupCancelledException', () async {
      await expectLater(
        _useCase(cancelPick: true).call,
        throwsA(isA<BackupCancelledException>()),
      );
    });
  });
}
