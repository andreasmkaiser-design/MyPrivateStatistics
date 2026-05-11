import 'package:private_statistics/core/logging/app_logger.dart';
import 'package:private_statistics/features/backup/domain/backup_repository.dart';
import 'package:private_statistics/features/backup/domain/exceptions.dart';
import 'package:private_statistics/features/backup/domain/models/backup_validation_result.dart';

/// Opens the file-picker and validates the chosen file as a restorable backup.
///
/// Business rules:
/// - `user_version == 0` → throws `InvalidBackupFileException`
/// - `backup version > app version` →
///   throws `IncompatibleSchemaVersionException`
/// - `backup version == app version` → returns [ValidationOk]
/// - `backup version < app version` → returns [ValidationOkOlderSchema]
///
/// Throws `BackupCancelledException` when the picker is dismissed.
class ValidateBackupUseCase {
  /// Creates a [ValidateBackupUseCase].
  ///
  /// [currentSchemaVersion] should match `AppDatabase.schemaVersion`.
  const ValidateBackupUseCase(
    this._repository, {
    required this.currentSchemaVersion,
  });

  final BackupRepository _repository;

  /// The schema version the running app supports.
  final int currentSchemaVersion;

  /// Lets the user pick a file and validates it for restore compatibility.
  ///
  /// Returns a [BackupValidationResult] on success.
  /// Throws [BackupRestoreException] subclasses on failure or cancellation.
  Future<BackupValidationResult> call() async {
    final filePath = await _repository.pickRestoreFile();

    final backupVersion = await _repository.readSchemaVersion(filePath);

    if (backupVersion == 0) {
      throw InvalidBackupFileException(filePath);
    }

    if (backupVersion > currentSchemaVersion) {
      AppLogger.error(
        'Restore failed: incompatible schema — '
        'backup v$backupVersion > app v$currentSchemaVersion',
      );
      throw IncompatibleSchemaVersionException(
        backupVersion: backupVersion,
        appVersion: currentSchemaVersion,
      );
    }

    if (backupVersion < currentSchemaVersion) {
      AppLogger.warning(
        'Backup schema v$backupVersion < app v$currentSchemaVersion — '
        'will auto-migrate on restore',
      );
      return ValidationOkOlderSchema(
        filePath: filePath,
        backupVersion: backupVersion,
        appVersion: currentSchemaVersion,
      );
    }

    return ValidationOk(filePath: filePath, schemaVersion: backupVersion);
  }
}
