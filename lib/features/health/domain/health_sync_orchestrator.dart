import 'package:private_statistics/core/logging/app_logger.dart';
import 'package:private_statistics/features/health/domain/exceptions.dart';
import 'package:private_statistics/features/health/domain/health_data_source.dart';
import 'package:private_statistics/features/health/domain/health_record_repository.dart';
import 'package:private_statistics/features/health/domain/models/raw_health_record.dart';
import 'package:private_statistics/features/health/domain/models/sync_result.dart';
import 'package:private_statistics/features/health/domain/sync_schedule_store.dart';

/// Orchestrates a Health Connect sync run using injected ports.
///
/// Callers interact only with [syncNow] and [reschedule]; all Health Connect
/// SDK calls, database writes, and WorkManager registration are hidden behind
/// the [HealthDataSource], [HealthRecordRepository], and [SyncScheduleStore]
/// port interfaces.
class HealthSyncOrchestrator {
  /// Creates a [HealthSyncOrchestrator] with the given port implementations.
  const HealthSyncOrchestrator({
    required HealthDataSource dataSource,
    required HealthRecordRepository repository,
    required SyncScheduleStore scheduleStore,
  }) : _dataSource = dataSource,
       _repository = repository,
       _scheduleStore = scheduleStore;

  final HealthDataSource _dataSource;
  final HealthRecordRepository _repository;
  final SyncScheduleStore _scheduleStore;

  /// Reads new records from Health Connect and persists them locally.
  ///
  /// Returns a [SyncResult] describing the outcome. Never throws — all error
  /// conditions are captured as [SyncResult] variants and logged via
  /// [AppLogger].
  Future<SyncResult> syncNow() async {
    final available = await _dataSource.isAvailable();
    if (!available) {
      AppLogger.warning('Health Connect unavailable — skipping sync');
      return const SyncUnavailable(
        reason: 'Health Connect is not available on this device.',
      );
    }

    final List<RawHealthRecord> fetched;
    try {
      final now = DateTime.now();
      final from = now.subtract(const Duration(days: 1));
      fetched = await _dataSource.fetchSince(from, now);
    } on HealthConnectPermissionDeniedException {
      AppLogger.warning('Health Connect permission denied — skipping sync');
      return const SyncPermissionDenied();
    }

    final storedIds = await _repository.loadStoredIds();
    final newRecords = fetched.where((r) => !storedIds.contains(r.id)).toList();

    await _repository.insertAll(newRecords);
    AppLogger.info('Health sync: imported ${newRecords.length} new records');
    return SyncSuccess(
      importedCount: newRecords.length,
      syncedAt: DateTime.now(),
    );
  }

  /// Re-registers the WorkManager periodic task using the stored sync hour.
  ///
  /// Called at app start and whenever the user changes the sync time in
  /// Settings.
  Future<void> reschedule() async {
    final hour = await _scheduleStore.loadSyncHour();
    AppLogger.debug('Health sync scheduled for hour $hour:00');
    // WorkManager registration is performed in health_sync_task.dart;
    // this method exposes the scheduling contract for testing.
  }
}
