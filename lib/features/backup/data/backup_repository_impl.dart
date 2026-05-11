import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:private_statistics/core/logging/app_logger.dart';
import 'package:private_statistics/features/backup/domain/backup_repository.dart';
import 'package:private_statistics/features/backup/domain/exceptions.dart';

/// Production implementation of `BackupRepository` using [FilePicker],
/// `path_provider`, and `dart:io` for file operations.
///
/// Database swap is atomic: the replacement is first copied to a `.tmp` file
/// next to the database, then renamed over it, so a mid-operation failure
/// leaves the original intact.
class BackupRepositoryImpl implements BackupRepository {
  /// Creates a [BackupRepositoryImpl].
  const BackupRepositoryImpl(this._databasePath);

  final String _databasePath;

  @override
  Future<String> getDatabasePath() async => _databasePath;

  @override
  Future<String> exportFile(File sourceFile) async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save backup',
      fileName: p.basename(sourceFile.path),
      bytes: await sourceFile.readAsBytes(),
    );

    if (result == null) throw const BackupCancelledException();
    return result;
  }

  @override
  Future<String> pickRestoreFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select backup file',
    );

    if (result == null || result.files.isEmpty) {
      throw const BackupCancelledException();
    }
    final path = result.files.single.path;
    if (path == null) throw const BackupCancelledException();
    return path;
  }

  @override
  Future<int> readSchemaVersion(String filePath) async {
    // Open the SQLite file as raw bytes and read the user_version pragma at
    // byte offset 60 (big-endian 32-bit integer per the SQLite file format).
    final file = File(filePath);
    if (!file.existsSync()) return 0;

    RandomAccessFile? raf;
    try {
      raf = await file.open();
      // SQLite header is 100 bytes. The 16-byte magic string starts at offset
      // 0. A valid SQLite 3 file starts with "SQLite format 3\000".
      final header = Uint8List(100);
      final bytesRead = await raf.readInto(header);
      if (bytesRead < 100) return 0;

      const magic = 'SQLite format 3\x00';
      for (var i = 0; i < magic.length; i++) {
        if (header[i] != magic.codeUnitAt(i)) return 0;
      }

      // user_version is at offset 60, big-endian int32.
      final version =
          (header[60] << 24) |
          (header[61] << 16) |
          (header[62] << 8) |
          header[63];
      return version;
    } on Exception catch (e) {
      AppLogger.error('readSchemaVersion failed for $filePath: $e');
      return 0;
    } finally {
      await raf?.close();
    }
  }

  @override
  Future<void> replaceDatabase(File replacementFile) async {
    final dbFile = File(_databasePath);
    final tmpFile = File('$_databasePath.tmp');

    try {
      await replacementFile.copy(tmpFile.path);
      await tmpFile.rename(dbFile.path);
    } on Exception catch (e, st) {
      AppLogger.error('replaceDatabase failed: $e', e, st);
      // Clean up the tmp file if it exists to leave nothing stale.
      if (tmpFile.existsSync()) {
        try {
          tmpFile.deleteSync();
        } on Exception {
          // Ignore secondary cleanup failure.
        }
      }
      throw RestoreFailedException(e.toString());
    }
  }

  @override
  Future<void> restartApp() async {
    // SystemNavigator.pop() exits the Flutter activity cleanly on Android.
    // The user must reopen the app manually — no fully in-process restart API
    // exists in Flutter without a native plugin.
    await SystemNavigator.pop();
  }
}

/// Creates a production [BackupRepositoryImpl] using the app's documents
/// directory for the database path.
Future<BackupRepositoryImpl> createBackupRepository() async {
  final dir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(dir.path, 'private_statistics.db');
  return BackupRepositoryImpl(dbPath);
}
