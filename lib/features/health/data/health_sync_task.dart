import 'package:private_statistics/core/database/app_database.dart';
import 'package:private_statistics/core/logging/app_logger.dart';
import 'package:private_statistics/features/health/data/drift_health_record_repository.dart';
import 'package:private_statistics/features/health/data/health_connect_data_source.dart';
import 'package:private_statistics/features/health/data/shared_prefs_sync_schedule_store.dart';
import 'package:private_statistics/features/health/domain/health_sync_orchestrator.dart';
import 'package:workmanager/workmanager.dart';

/// Unique task name used as the WorkManager task identifier.
const _kHealthSyncTaskName = 'health_daily_sync';

/// Top-level WorkManager callback dispatcher.
///
/// Must be a top-level function annotated with `@pragma('vm:entry-point')` so
/// the Dart VM preserves it in release builds. Runs in a separate Dart isolate;
/// Riverpod is not available here — dependencies are constructed manually.
@pragma('vm:entry-point')
void healthSyncCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != _kHealthSyncTaskName) return true;

    final db = AppDatabase();
    try {
      final result = await HealthSyncOrchestrator(
        dataSource: HealthConnectDataSource(),
        repository: DriftHealthRecordRepository(db),
        scheduleStore: SharedPrefsSyncScheduleStore(),
      ).syncNow();
      AppLogger.info('Background health sync completed: $result');
    } finally {
      await db.close();
    }
    return true;
  });
}

/// Registers the daily Health Connect periodic sync task with WorkManager.
///
/// Call once from `main` after `Workmanager.initialize`. Uses [syncHour]
/// (0–23) to compute the initial delay so the first run fires near the
/// user-configured hour; subsequent runs follow the 24-hour period.
/// Replaces any previously registered task with the same unique name.
Future<void> registerHealthSyncTask({required int syncHour}) async {
  final now = DateTime.now();
  var target = DateTime(now.year, now.month, now.day, syncHour);
  if (!target.isAfter(now)) {
    target = target.add(const Duration(days: 1));
  }
  final initialDelay = target.difference(now);

  await Workmanager().registerPeriodicTask(
    _kHealthSyncTaskName,
    _kHealthSyncTaskName,
    frequency: const Duration(hours: 24),
    initialDelay: initialDelay,
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );
  AppLogger.debug(
    'Health sync task registered; first run in '
    '${initialDelay.inMinutes} min',
  );
}
