import 'package:private_statistics/features/backup/domain/exceptions.dart';
import 'package:private_statistics/features/backup/domain/models/backup_validation_result.dart';

/// The UI state for the Backup & Restore section of Settings.
sealed class RestoreState {
  /// Creates a [RestoreState].
  const RestoreState();
}

/// No backup or restore operation is in progress.
final class RestoreIdle extends RestoreState {
  /// Creates a [RestoreIdle] state.
  const RestoreIdle();
}

/// An export or restore operation is executing.
final class RestoreBusy extends RestoreState {
  /// Creates a [RestoreBusy] state.
  const RestoreBusy();
}

/// Validation succeeded; awaiting the user's confirmation to proceed.
///
/// Display [result] in the confirmation dialog to show whether a migration
/// warning is needed.
final class RestoreAwaitingConfirmation extends RestoreState {
  /// Creates a [RestoreAwaitingConfirmation] state.
  const RestoreAwaitingConfirmation(this.result);

  /// The validated backup result carrying the file path and version info.
  final BackupValidationResult result;
}

/// The last operation failed with [exception].
final class RestoreError extends RestoreState {
  /// Creates a [RestoreError] state.
  const RestoreError(this.exception);

  /// The typed exception that caused the failure.
  final BackupRestoreException exception;
}
