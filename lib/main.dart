import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_statistics/app.dart';
import 'package:private_statistics/core/database/app_database.dart';
import 'package:private_statistics/core/database/database_provider.dart';
import 'package:private_statistics/core/logging/app_logger.dart';
import 'package:private_statistics/features/backup/providers/backup_providers.dart';
import 'package:private_statistics/features/health/data/health_sync_task.dart';
import 'package:private_statistics/features/health/data/shared_prefs_sync_schedule_store.dart';
import 'package:workmanager/workmanager.dart';

/// Application entry point.
///
/// Initialises [AppDatabase], registers the WorkManager Health Connect sync
/// task, and injects the database via [ProviderScope] before running [App].
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();
  AppLogger.info('Database initialised');

  await Workmanager().initialize(healthSyncCallbackDispatcher);
  final syncHour = await SharedPrefsSyncScheduleStore().loadSyncHour();
  await registerHealthSyncTask(syncHour: syncHour);
  AppLogger.info('WorkManager health sync task registered');

  final backupOverrides = await createBackupOverrides();

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        ...backupOverrides,
      ],
      child: const App(),
    ),
  );
}
