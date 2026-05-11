import 'package:private_statistics/core/exceptions.dart';

/// Thrown by `HealthDataSource.fetchSince` when Health Connect permissions
/// have not been granted.
///
/// The `HealthSyncOrchestrator` catches this and returns `SyncPermissionDenied`
/// rather than propagating the exception to callers.
class HealthConnectPermissionDeniedException extends AppException {
  /// Creates a [HealthConnectPermissionDeniedException].
  const HealthConnectPermissionDeniedException()
    : super('Health Connect permissions were denied.');
}
