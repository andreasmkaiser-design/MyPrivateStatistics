import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import 'package:private_statistics/core/database/database_provider.dart';
import 'package:private_statistics/core/logging/app_logger.dart';
import 'package:private_statistics/features/health/data/drift_health_record_repository.dart';
import 'package:private_statistics/features/health/data/health_connect_data_source.dart';
import 'package:private_statistics/features/health/data/shared_prefs_sync_schedule_store.dart';
import 'package:private_statistics/features/health/domain/health_data_source.dart';
import 'package:private_statistics/features/health/domain/health_record_repository.dart';
import 'package:private_statistics/features/health/domain/health_sync_orchestrator.dart';
import 'package:private_statistics/features/health/domain/models/sync_result.dart';
import 'package:private_statistics/features/health/domain/sync_schedule_store.dart';

/// Health Connect data types used across onboarding and settings.
const kHcDataTypes = [
  HealthDataType.STEPS,
  HealthDataType.SLEEP_SESSION,
  HealthDataType.WORKOUT,
];

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

/// Manages Health Connect permission state for both onboarding and settings.
///
/// [build] checks whether all [kHcDataTypes] permissions are currently granted.
/// [requestPermission] triggers the authorization dialog and updates state.
/// Override in tests via [ProviderScope] overrides to avoid platform calls.
class HcPermissionNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    try {
      await Health().configure();
      return (await Health().hasPermissions(kHcDataTypes)) ?? false;
    } on Exception catch (e, st) {
      AppLogger.warning('HC permission check failed', e, st);
      return false;
    }
  }

  /// Requests Health Connect authorization and updates [state].
  ///
  /// Returns `true` when the user grants all permissions, `false` otherwise.
  Future<bool> requestPermission() async {
    state = const AsyncLoading();
    try {
      await Health().configure();
      final granted = await Health().requestAuthorization(kHcDataTypes);
      state = AsyncData(granted);
      return granted;
    } on Exception catch (e, st) {
      AppLogger.error('HC permission request failed', e, st);
      state = const AsyncData(false);
      return false;
    }
  }
}

/// Provides [HcPermissionNotifier] — the single source of truth for HC
/// permission state across onboarding and settings.
final hcPermissionNotifierProvider =
    AsyncNotifierProvider<HcPermissionNotifier, bool>(HcPermissionNotifier.new);
