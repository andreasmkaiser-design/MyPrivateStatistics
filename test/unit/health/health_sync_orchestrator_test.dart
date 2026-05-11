import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/features/health/domain/exceptions.dart';
import 'package:private_statistics/features/health/domain/health_data_source.dart';
import 'package:private_statistics/features/health/domain/health_record_repository.dart';
import 'package:private_statistics/features/health/domain/health_sync_orchestrator.dart';
import 'package:private_statistics/features/health/domain/models/health_record_type.dart';
import 'package:private_statistics/features/health/domain/models/raw_health_record.dart';
import 'package:private_statistics/features/health/domain/models/sync_result.dart';
import 'package:private_statistics/features/health/domain/sync_schedule_store.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeDataSource implements HealthDataSource {
  _FakeDataSource({
    required this.records,
    this.available = true,
    this.denyPermission = false,
  });

  final List<RawHealthRecord> records;
  final bool available;
  final bool denyPermission;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<List<RawHealthRecord>> fetchSince(DateTime from, DateTime to) async {
    if (denyPermission) throw const HealthConnectPermissionDeniedException();
    return records;
  }
}

class _FakeRepository implements HealthRecordRepository {
  _FakeRepository({Set<String>? storedIds})
    : _storedIds = storedIds ?? <String>{},
      inserted = <RawHealthRecord>[];

  final Set<String> _storedIds;

  /// Records passed to [insertAll] during this test run.
  final List<RawHealthRecord> inserted;

  @override
  Future<Set<String>> loadStoredIds() async => Set<String>.of(_storedIds);

  @override
  Future<void> insertAll(List<RawHealthRecord> records) async {
    inserted.addAll(records);
    _storedIds.addAll(records.map((r) => r.id));
  }
}

class _FakeScheduleStore implements SyncScheduleStore {
  int _hour = 2;

  @override
  Future<int> loadSyncHour() async => _hour;

  @override
  Future<void> saveSyncHour(int hour) async => _hour = hour;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

RawHealthRecord _stepsRecord({
  String id = 'id-1',
  double steps = 1000,
  DateTime? start,
}) {
  final s = start ?? DateTime(2024, 3, 15, 8);
  return RawHealthRecord(
    id: id,
    type: HealthRecordType.steps,
    value: steps,
    unit: 'steps',
    startTime: s,
    endTime: s.add(const Duration(hours: 1)),
  );
}

HealthSyncOrchestrator _orchestrator({
  required List<RawHealthRecord> records,
  _FakeRepository? repo,
  bool available = true,
  bool denyPermission = false,
}) => HealthSyncOrchestrator(
  dataSource: _FakeDataSource(
    records: records,
    available: available,
    denyPermission: denyPermission,
  ),
  repository: repo ?? _FakeRepository(),
  scheduleStore: _FakeScheduleStore(),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('HealthSyncOrchestrator.syncNow', () {
    test('imports all new STEPS records and returns correct count', () async {
      final repo = _FakeRepository();
      final result = await _orchestrator(
        records: [
          _stepsRecord(id: 'a'),
          _stepsRecord(id: 'b'),
        ],
        repo: repo,
      ).syncNow();

      expect(result, isA<SyncSuccess>());
      expect((result as SyncSuccess).importedCount, equals(2));
      expect(repo.inserted, hasLength(2));
    });

    test('skips records already stored — deduplication by ID', () async {
      final repo = _FakeRepository(storedIds: {'id-1'});
      final result = await _orchestrator(
        records: [
          _stepsRecord(),
          _stepsRecord(id: 'id-2'),
        ],
        repo: repo,
      ).syncNow();

      expect((result as SyncSuccess).importedCount, equals(1));
      expect(repo.inserted, hasLength(1));
      expect(repo.inserted.single.id, equals('id-2'));
    });

    test('partial sync: imports only records not yet stored', () async {
      final repo = _FakeRepository(storedIds: {'id-1', 'id-3'});
      final result = await _orchestrator(
        records: [
          _stepsRecord(),
          _stepsRecord(id: 'id-2'),
          _stepsRecord(id: 'id-3'),
          _stepsRecord(id: 'id-4'),
        ],
        repo: repo,
      ).syncNow();

      expect((result as SyncSuccess).importedCount, equals(2));
      expect(
        repo.inserted.map((r) => r.id),
        containsAll(<String>['id-2', 'id-4']),
      );
    });

    test(
      'returns SyncUnavailable when Health Connect is not available',
      () async {
        final result = await _orchestrator(
          records: const [],
          available: false,
        ).syncNow();

        expect(result, isA<SyncUnavailable>());
      },
    );

    test('returns SyncPermissionDenied when permission is denied', () async {
      final result = await _orchestrator(
        records: const [],
        denyPermission: true,
      ).syncNow();

      expect(result, isA<SyncPermissionDenied>());
    });

    test(
      'STEPS record passed through with correct type, value, unit, times',
      () async {
        final start = DateTime(2024, 3, 15, 7, 30);
        final end = DateTime(2024, 3, 15, 8, 30);
        final repo = _FakeRepository();

        await HealthSyncOrchestrator(
          dataSource: _FakeDataSource(
            records: [
              RawHealthRecord(
                id: 'steps-1',
                type: HealthRecordType.steps,
                value: 8500,
                unit: 'steps',
                startTime: start,
                endTime: end,
              ),
            ],
          ),
          repository: repo,
          scheduleStore: _FakeScheduleStore(),
        ).syncNow();

        final stored = repo.inserted.single;
        expect(stored.id, equals('steps-1'));
        expect(stored.type, equals(HealthRecordType.steps));
        expect(stored.value, equals(8500));
        expect(stored.unit, equals('steps'));
        expect(stored.startTime, equals(start));
        expect(stored.endTime, equals(end));
      },
    );

    test(
      'SLEEP_SESSION record passed through with duration-in-minutes unit',
      () async {
        final repo = _FakeRepository();

        await HealthSyncOrchestrator(
          dataSource: _FakeDataSource(
            records: [
              RawHealthRecord(
                id: 'sleep-1',
                type: HealthRecordType.sleepSession,
                value: 480, // 8 h in minutes
                unit: 'min',
                startTime: DateTime(2024, 3, 15, 22),
                endTime: DateTime(2024, 3, 16, 6),
              ),
            ],
          ),
          repository: repo,
          scheduleStore: _FakeScheduleStore(),
        ).syncNow();

        final stored = repo.inserted.single;
        expect(stored.type, equals(HealthRecordType.sleepSession));
        expect(stored.value, equals(480));
        expect(stored.unit, equals('min'));
      },
    );

    test(
      'EXERCISE_SESSION record passed through with duration-in-minutes unit',
      () async {
        final repo = _FakeRepository();

        await HealthSyncOrchestrator(
          dataSource: _FakeDataSource(
            records: [
              RawHealthRecord(
                id: 'ex-1',
                type: HealthRecordType.exerciseSession,
                value: 45,
                unit: 'min',
                startTime: DateTime(2024, 3, 15, 9),
                endTime: DateTime(2024, 3, 15, 9, 45),
              ),
            ],
          ),
          repository: repo,
          scheduleStore: _FakeScheduleStore(),
        ).syncNow();

        final stored = repo.inserted.single;
        expect(stored.type, equals(HealthRecordType.exerciseSession));
        expect(stored.value, equals(45));
        expect(stored.unit, equals('min'));
      },
    );
  });
}
