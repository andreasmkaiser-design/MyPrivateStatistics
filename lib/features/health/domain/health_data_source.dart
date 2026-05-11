import 'package:private_statistics/features/health/domain/models/raw_health_record.dart';

/// Port: reads health records from Health Connect.
///
/// The production implementation (`HealthConnectDataSource`) wraps the
/// `health` Flutter package. Substitute a fake in unit tests.
abstract interface class HealthDataSource {
  /// Returns whether Health Connect is installed and accessible on this device.
  Future<bool> isAvailable();

  /// Returns all health records whose [RawHealthRecord.startTime] falls within
  /// [[from], [to]].
  ///
  /// Throws `HealthConnectPermissionDeniedException` when the user has not
  /// granted the required permissions.
  Future<List<RawHealthRecord>> fetchSince(DateTime from, DateTime to);
}
