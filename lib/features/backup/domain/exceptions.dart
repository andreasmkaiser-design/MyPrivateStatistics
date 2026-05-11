import 'package:private_statistics/core/exceptions.dart';

/// Base class for all backup and restore failures.
///
/// Callers catch [BackupRestoreException] centrally via a Riverpod
/// `ProviderObserver` and surface a Snackbar. Feature-specific subclasses
/// carry additional context where needed.
abstract class BackupRestoreException extends AppException {
  /// Creates a [BackupRestoreException] with [message].
  const BackupRestoreException(super.message);
}

/// Thrown when the user dismisses the file-picker without selecting a file.
class BackupCancelledException extends BackupRestoreException {
  /// Creates a [BackupCancelledException].
  const BackupCancelledException() : super('Backup operation was cancelled.');
}

/// Thrown when the selected file is not a valid SQLite database.
class InvalidBackupFileException extends BackupRestoreException {
  /// Creates an [InvalidBackupFileException] for [path].
  const InvalidBackupFileException(String path)
    : super('Not a valid SQLite database: $path');
}

/// Thrown when the backup was created with a newer app schema version.
///
/// [backupVersion] is the version found in the file;
/// [appVersion] is the version the running app understands.
/// The user must update the app before restoring this backup.
class IncompatibleSchemaVersionException extends BackupRestoreException {
  /// Creates an [IncompatibleSchemaVersionException].
  const IncompatibleSchemaVersionException({
    required this.backupVersion,
    required this.appVersion,
  }) : super(
         'Backup schema v$backupVersion is newer than app schema v$appVersion. '
         'Update the app before restoring.',
       );

  /// The schema version embedded in the backup file.
  final int backupVersion;

  /// The schema version the running app supports.
  final int appVersion;
}

/// Thrown when the atomic database swap fails mid-flight.
///
/// The original database is preserved when this is thrown — no data is lost.
class RestoreFailedException extends BackupRestoreException {
  /// Creates a [RestoreFailedException] with [message].
  const RestoreFailedException(super.message);
}
