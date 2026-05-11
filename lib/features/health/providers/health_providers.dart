import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_statistics/core/database/database_provider.dart';
import 'package:private_statistics/features/health/data/drift_health_record_repository.dart';
import 'package:private_statistics/features/health/data/health_connect_data_source.dart';
import 'package:private_statistics/features/health/data/shared_prefs_sync_schedule_store.dart';
import 'package:private_statistics/features/health/domain/health_data_source.dart';
import 'package:private_statistics/features/health/domain/health_record_repository.dart';
import 'package:private_statistics/features/health/domain/health_sync_orchestrator.dart';
import 'package:private_statistics/features/health/domain/models/sync_result.dart';
import 'package:private_statistics/features/health/domain/sync_schedule_store.dart';

/// Provides the [HealthDataSource] backed by the `health` Flutter package.
final healthDataSourceProvider = Provider<HealthDataSource>((ref) {
  return HealthConnectDataSource();
});

/// Provides the [HealthRecordRepository] backed by the app's Drift database.
final healthRecordRepositoryProvider = Provider<HealthRecordRepository>((ref) {
  return DriftHealthRecordRepository(ref.watch(appDatabaseProvider));
});

/// Provides the [SyncScheduleStore] backed by `SharedPreferences`.
final syncScheduleStoreProvider = Provider<SyncScheduleStore>((ref) {
  return SharedPrefsSyncScheduleStore();
});

/// Provides the [HealthSyncOrchestrator] wired with all port implementations.
final healthSyncOrchestratorProvider = Provider<HealthSyncOrchestrator>((ref) {
  return HealthSyncOrchestrator(
    dataSource: ref.watch(healthDataSourceProvider),
    repository: ref.watch(healthRecordRepositoryProvider),
    scheduleStore: ref.watch(syncScheduleStoreProvider),
  );
});

/// Holds the [SyncResult] from the most recent manual or scheduled sync.
///
/// `null` until the first sync attempt in this session.
final lastSyncResultProvider = StateProvider<SyncResult?>((ref) => null);

/// The stored daily sync hour (0–23), loaded from [SyncScheduleStore].
///
/// Defaults to `2` (02:00) when no value has been saved.
final syncHourProvider = FutureProvider<int>((ref) {
  return ref.watch(syncScheduleStoreProvider).loadSyncHour();
});
