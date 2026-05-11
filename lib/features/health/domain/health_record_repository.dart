import 'package:private_statistics/features/health/domain/models/raw_health_record.dart';

/// Port: persists [RawHealthRecord]s in local storage.
///
/// The production implementation (`DriftHealthRecordRepository`) writes to the
/// app's Drift database. Substitute a fake in unit tests.
abstract interface class HealthRecordRepository {
  /// Returns the set of Health Connect record IDs already stored locally.
  ///
  /// Used by the orchestrator to compute the set of new records before
  /// calling [insertAll].
  Future<Set<String>> loadStoredIds();

  /// Persists [records] in local storage.
  ///
  /// Records whose [RawHealthRecord.id] already exists are silently ignored
  /// (insert-or-ignore semantics).
  Future<void> insertAll(List<RawHealthRecord> records);
}
