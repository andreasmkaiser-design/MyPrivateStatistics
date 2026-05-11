import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_statistics/features/backup/domain/exceptions.dart';
import 'package:private_statistics/features/backup/domain/export_backup_use_case.dart';
import 'package:private_statistics/features/backup/domain/models/backup_validation_result.dart';
import 'package:private_statistics/features/backup/domain/restore_backup_use_case.dart';
import 'package:private_statistics/features/backup/domain/validate_backup_use_case.dart';
import 'package:private_statistics/features/backup/presentation/restore_state.dart';

/// Drives the Backup & Restore section of Settings.
///
/// Use [backupNotifierProvider] to access this notifier. Call [exportBackup]
/// to export, [pickAndValidate] to start a restore flow, [confirmRestore] to
/// complete it, and [cancelRestore] to abort.
class BackupNotifier extends AsyncNotifier<RestoreState> {
  @override
  Future<RestoreState> build() async => const RestoreIdle();

  /// Exports the live database to a user-chosen location.
  ///
  /// Sets state to [RestoreBusy] during the operation, then back to
  /// [RestoreIdle] on success. On failure the state transitions to
  /// [RestoreError] and the exception is also surfaced via [AsyncValue.error]
  /// so the central [ProviderObserver] can show a Snackbar.
  Future<void> exportBackup() async {
    state = const AsyncData(RestoreBusy());
    try {
      await ref.read(exportBackupUseCaseProvider).call();
      state = const AsyncData(RestoreIdle());
    } on BackupCancelledException {
      state = const AsyncData(RestoreIdle());
    } on BackupRestoreException catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Opens the file-picker, validates the chosen file, and transitions to
  /// [RestoreAwaitingConfirmation] on success or [RestoreError] on failure.
  ///
  /// Silently returns to [RestoreIdle] when the user cancels the picker.
  Future<void> pickAndValidate() async {
    state = const AsyncData(RestoreBusy());
    try {
      final result = await ref.read(validateBackupUseCaseProvider).call();
      state = AsyncData(RestoreAwaitingConfirmation(result));
    } on BackupCancelledException {
      state = const AsyncData(RestoreIdle());
    } on BackupRestoreException catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Completes the restore using a previously validated [result].
  ///
  /// Precondition: state is [RestoreAwaitingConfirmation].
  /// Does not return normally on success — the app restarts.
  Future<void> confirmRestore(BackupValidationResult result) async {
    state = const AsyncData(RestoreBusy());
    try {
      await ref.read(restoreBackupUseCaseProvider).call(result);
    } on BackupRestoreException catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Cancels a pending confirmation and returns to [RestoreIdle].
  ///
  /// Precondition: state is [RestoreAwaitingConfirmation].
  void cancelRestore() => state = const AsyncData(RestoreIdle());
}

/// Provides the [BackupNotifier].
final backupNotifierProvider =
    AsyncNotifierProvider<BackupNotifier, RestoreState>(BackupNotifier.new);

/// Provides [ExportBackupUseCase] wired with the production repository.
///
/// Overridden in tests with a fake use-case.
final exportBackupUseCaseProvider = Provider<ExportBackupUseCase>((ref) {
  throw UnimplementedError(
    'exportBackupUseCaseProvider must be overridden at the ProviderScope root',
  );
});

/// Provides [ValidateBackupUseCase] wired with the production repository.
///
/// Overridden in tests with a fake use-case.
final validateBackupUseCaseProvider = Provider<ValidateBackupUseCase>((ref) {
  throw UnimplementedError(
    'validateBackupUseCaseProvider must be overridden '
    'at the ProviderScope root',
  );
});

/// Provides [RestoreBackupUseCase] wired with the production repository.
///
/// Overridden in tests with a fake use-case.
final restoreBackupUseCaseProvider = Provider<RestoreBackupUseCase>((ref) {
  throw UnimplementedError(
    'restoreBackupUseCaseProvider must be overridden at the ProviderScope root',
  );
});
