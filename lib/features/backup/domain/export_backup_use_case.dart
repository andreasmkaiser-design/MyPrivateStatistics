import 'dart:io';

import 'package:private_statistics/core/logging/app_logger.dart';
import 'package:private_statistics/features/backup/domain/backup_repository.dart';

/// Copies the live Drift SQLite file to a user-chosen location via Android SAF.
///
/// Throws `BackupCancelledException` if the user dismisses the picker.
/// Throws `BackupRestoreException` on I/O failure.
class ExportBackupUseCase {
  /// Creates an [ExportBackupUseCase] with the given `repository`.
  const ExportBackupUseCase(this._repository);

  final BackupRepository _repository;

  /// Exports the backup and returns the destination path.
  ///
  /// Logs `"Backup exported"` at [AppLogger.info] on success.
  Future<String> call() async {
    final dbPath = await _repository.getDatabasePath();
    final destination = await _repository.exportFile(File(dbPath));
    AppLogger.info('Backup exported to $destination');
    return destination;
  }
}
