/// The result of validating a candidate backup file before restore.
sealed class BackupValidationResult {
  /// Creates a [BackupValidationResult].
  const BackupValidationResult();
}

/// The backup schema version matches the running app — restore can proceed.
final class ValidationOk extends BackupValidationResult {
  /// Creates a [ValidationOk] result.
  const ValidationOk({required this.filePath, required this.schemaVersion});

  /// Absolute path to the validated backup file.
  final String filePath;

  /// Schema version embedded in the backup, equal to the app version.
  final int schemaVersion;
}

/// The backup was created with an older schema version.
///
/// Restore can proceed — Drift will auto-migrate on next open.
/// Display [schemaWarning] in the confirmation dialog body.
final class ValidationOkOlderSchema extends BackupValidationResult {
  /// Creates a [ValidationOkOlderSchema] result.
  const ValidationOkOlderSchema({
    required this.filePath,
    required this.backupVersion,
    required this.appVersion,
  });

  /// Absolute path to the validated backup file.
  final String filePath;

  /// Schema version embedded in the backup (older than [appVersion]).
  final int backupVersion;

  /// Current app schema version.
  final int appVersion;

  /// Human-readable warning to show in the restore confirmation dialog.
  String get schemaWarning =>
      'This backup uses schema v$backupVersion. '
      'It will be automatically updated to v$appVersion.';
}
