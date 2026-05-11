import 'package:drift/drift.dart';
import 'package:private_statistics/core/database/app_database.dart';
import 'package:private_statistics/features/health/domain/health_record_repository.dart';
import 'package:private_statistics/features/health/domain/models/health_record_type.dart';
import 'package:private_statistics/features/health/domain/models/raw_health_record.dart';

/// `HealthRecordRepository` implementation backed by the app's Drift database.
class DriftHealthRecordRepository implements HealthRecordRepository {
  /// Creates a [DriftHealthRecordRepository] using `db`.
  const DriftHealthRecordRepository(this._db);

  final AppDatabase _db;

  @override
  Future<Set<String>> loadStoredIds() async {
    final rows = await _db.select(_db.healthRecords).get();
    return rows.map((r) => r.id).toSet();
  }

  @override
  Future<void> insertAll(List<RawHealthRecord> records) async {
    if (records.isEmpty) return;
    await _db.batch((batch) {
      batch.insertAll(
        _db.healthRecords,
        records.map(_toRow).toList(),
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

  HealthRecordRow _toRow(RawHealthRecord r) => HealthRecordRow(
    id: r.id,
    type: _typeToString(r.type),
    value: r.value,
    unit: r.unit,
    startTimeMs: r.startTime.millisecondsSinceEpoch,
    endTimeMs: r.endTime.millisecondsSinceEpoch,
  );

  static String _typeToString(HealthRecordType type) => switch (type) {
    HealthRecordType.steps => 'STEPS',
    HealthRecordType.sleepSession => 'SLEEP_SESSION',
    HealthRecordType.exerciseSession => 'EXERCISE_SESSION',
  };
}
