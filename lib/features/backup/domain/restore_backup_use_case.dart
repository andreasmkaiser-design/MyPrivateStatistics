import 'dart:io';

import 'package:private_statistics/core/logging/app_logger.dart';
import 'package:private_statistics/features/backup/domain/backup_repository.dart';
import 'package:private_statistics/features/backup/domain/models/backup_validation_result.dart';

/// Replaces the live database with a validated backup and restarts the app.
///
/// Call only with a [BackupValidationResult] previously returned by
/// `ValidateBackupUseCase`. The caller is responsible for obtaining user
/// confirmation before invoking this use-case.
///
/// This method does not return normally on success — the app restarts.
class RestoreBackupUseCase {
  /// Creates a [RestoreBackupUseCase] with the given `repository`.
  const RestoreBackupUseCase(this._repository);

  final BackupRepository _repository;

  /// Replaces the database using [result] and restarts the app.
  ///
  /// Throws `RestoreFailedException` if the atomic swap fails — the original
  /// database is left intact in that case.
  Future<void> call(BackupValidationResult result) async {
    final filePath = switch (result) {
      ValidationOk(:final filePath) => filePath,
      ValidationOkOlderSchema(:final filePath) => filePath,
    };

    await _repository.replaceDatabase(File(filePath));
    AppLogger.info('Backup restored — restarting app');
    await _repository.restartApp();
  }
}
