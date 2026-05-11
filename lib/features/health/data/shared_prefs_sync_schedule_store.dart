import 'package:private_statistics/features/health/domain/sync_schedule_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [SyncScheduleStore] implementation backed by [SharedPreferences].
class SharedPrefsSyncScheduleStore implements SyncScheduleStore {
  static const _kSyncHourKey = 'health_sync_hour';

  @override
  Future<int> loadSyncHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kSyncHourKey) ?? 2;
  }

  @override
  Future<void> saveSyncHour(int hour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kSyncHourKey, hour);
  }
}
