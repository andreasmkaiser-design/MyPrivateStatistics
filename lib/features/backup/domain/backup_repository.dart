import 'dart:io';

/// Port: raw filesystem and SAF operations for Backup & Restore.
///
/// The production implementation uses `file_picker` for SAF-based destination
/// and source picking, `dart:io` for file operations, and `path_provider` to
/// locate the live database file. Substitute a fake in tests.
abstract interface class BackupRepository {
  /// Returns the absolute path of the live SQLite database file.
  Future<String> getDatabasePath();

  /// Opens the Android SAF save-picker and copies [sourceFile] to the chosen
  /// location.
  ///
  /// Returns the destination path/URI written to.
  /// Throws `BackupCancelledException` if the user dismissed the picker.
  Future<String> exportFile(File sourceFile);

  /// Opens the Android SAF open-picker for the user to choose a backup file.
  ///
  /// Returns the absolute path of the selected file.
  /// Throws `BackupCancelledException` if the user dismissed the picker.
  Future<String> pickRestoreFile();

  /// Reads the `user_version` PRAGMA from the SQLite file at [filePath].
  ///
  /// Returns the integer version, or `0` if the file is not a valid SQLite
  /// database. Does not open a Drift connection.
  Future<int> readSchemaVersion(String filePath);

  /// Atomically replaces the live database with [replacementFile].
  ///
  /// Copies [replacementFile] to a `.tmp` path, then renames it over the live
  /// database path. If the copy fails, the original file is left intact.
  /// Throws `RestoreFailedException` if the atomic swap cannot complete.
  Future<void> replaceDatabase(File replacementFile);

  /// Fully restarts the Android process.
  ///
  /// Called after a successful restore. This method does not return normally.
  Future<void> restartApp();
}
