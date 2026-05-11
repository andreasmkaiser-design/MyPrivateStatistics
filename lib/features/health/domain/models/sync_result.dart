import 'package:private_statistics/features/health/domain/models/health_record_type.dart';

/// The result of a Health Connect sync operation.
///
/// Pattern-match exhaustively at every call site — never catch exceptions for
/// the cases covered by these variants.
sealed class SyncResult {
  /// Creates a [SyncResult].
  const SyncResult();
}

/// The sync completed successfully.
final class SyncSuccess extends SyncResult {
  /// Creates a [SyncSuccess] result.
  const SyncSuccess({required this.importedCount, required this.syncedAt});

  /// The number of records newly imported in this sync run.
  final int importedCount;

  /// The timestamp at which this sync completed.
  ///
  /// Use to display "Last synced: HH:mm" in the Settings screen.
  final DateTime syncedAt;
}

/// Health Connect is not installed or not available on this device.
final class SyncUnavailable extends SyncResult {
  /// Creates a [SyncUnavailable] result.
  const SyncUnavailable({required this.reason});

  /// A human-readable description of why Health Connect is unavailable.
  final String reason;
}

/// The user has not granted the required Health Connect permissions.
final class SyncPermissionDenied extends SyncResult {
  /// Creates a [SyncPermissionDenied] result.
  const SyncPermissionDenied();
}

/// Some record types were synced successfully but others failed.
final class SyncPartialFailure extends SyncResult {
  /// Creates a [SyncPartialFailure] result.
  const SyncPartialFailure({
    required this.importedCount,
    required this.failedTypes,
  });

  /// The number of records successfully imported.
  final int importedCount;

  /// The record types that could not be read during this sync.
  final List<HealthRecordType> failedTypes;
}
