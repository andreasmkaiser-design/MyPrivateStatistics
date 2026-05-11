import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/features/health/data/shared_prefs_sync_schedule_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('SharedPrefsSyncScheduleStore', () {
    test(
      'loadSyncHour returns default 2 when nothing has been saved',
      () async {
        final store = SharedPrefsSyncScheduleStore();
        expect(await store.loadSyncHour(), equals(2));
      },
    );

    test('saveSyncHour persists and loadSyncHour reads it back', () async {
      final store = SharedPrefsSyncScheduleStore();
      await store.saveSyncHour(7);
      expect(await store.loadSyncHour(), equals(7));
    });

    test('value persists across separate store instances', () async {
      await SharedPrefsSyncScheduleStore().saveSyncHour(21);
      expect(await SharedPrefsSyncScheduleStore().loadSyncHour(), equals(21));
    });
  });
}
