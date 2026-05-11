import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_statistics/features/backup/data/backup_repository_impl.dart';
import 'package:private_statistics/features/backup/domain/export_backup_use_case.dart';
import 'package:private_statistics/features/backup/domain/restore_backup_use_case.dart';
import 'package:private_statistics/features/backup/domain/validate_backup_use_case.dart';
import 'package:private_statistics/features/backup/presentation/backup_notifier.dart';

/// The current app-database schema version.
///
/// Must stay in sync with `AppDatabase.schemaVersion` in
/// `core/database/app_database.dart`.
const _currentSchemaVersion = 5;

/// Creates the production [Override] list for all backup providers.
///
/// Call once at app startup (after `WidgetsFlutterBinding.ensureInitialized`)
/// and spread the result into [ProviderScope.overrides].
Future<List<Override>> createBackupOverrides() async {
  final repo = await createBackupRepository();
  return [
    exportBackupUseCaseProvider.overrideWithValue(ExportBackupUseCase(repo)),
    validateBackupUseCaseProvider.overrideWithValue(
      ValidateBackupUseCase(repo, currentSchemaVersion: _currentSchemaVersion),
    ),
    restoreBackupUseCaseProvider.overrideWithValue(RestoreBackupUseCase(repo)),
  ];
}
