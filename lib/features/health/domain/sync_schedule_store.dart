/// Port: persists the user-configured daily sync hour.
///
/// The production implementation (`SharedPrefsSyncScheduleStore`) writes to
/// `SharedPreferences`. Substitute a fake in unit tests.
abstract interface class SyncScheduleStore {
  /// Returns the stored daily sync hour (0–23).
  ///
  /// Defaults to `2` (02:00) when no value has been saved yet.
  Future<int> loadSyncHour();

  /// Persists [hour] as the daily sync hour.
  ///
  /// [hour] must be in the range 0–23.
  Future<void> saveSyncHour(int hour);
}
