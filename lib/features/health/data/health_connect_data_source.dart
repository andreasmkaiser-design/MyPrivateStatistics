import 'package:health/health.dart';
import 'package:private_statistics/features/health/domain/exceptions.dart';
import 'package:private_statistics/features/health/domain/health_data_source.dart';
import 'package:private_statistics/features/health/domain/models/health_record_type.dart';
import 'package:private_statistics/features/health/domain/models/raw_health_record.dart';

/// `HealthDataSource` implementation backed by the `health` Flutter package.
///
/// Reads `HealthDataType.STEPS`, `HealthDataType.SLEEP_SESSION`, and
/// `HealthDataType.WORKOUT` (exercise sessions) from Android Health Connect.
///
/// Call `Health().configure()` at app start before any method on this class.
class HealthConnectDataSource implements HealthDataSource {
  static final _types = [
    HealthDataType.STEPS,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.WORKOUT,
  ];

  @override
  Future<bool> isAvailable() async {
    await Health().configure();
    return Health().isHealthConnectAvailable();
  }

  @override
  Future<List<RawHealthRecord>> fetchSince(DateTime from, DateTime to) async {
    final granted = await Health().requestAuthorization(_types);
    if (!granted) throw const HealthConnectPermissionDeniedException();

    final points = await Health().getHealthDataFromTypes(
      types: _types,
      startTime: from,
      endTime: to,
    );

    return points.map(_toRecord).whereType<RawHealthRecord>().toList();
  }

  RawHealthRecord? _toRecord(HealthDataPoint point) {
    final type = switch (point.type) {
      HealthDataType.STEPS => HealthRecordType.steps,
      HealthDataType.SLEEP_SESSION => HealthRecordType.sleepSession,
      HealthDataType.WORKOUT => HealthRecordType.exerciseSession,
      // ignore: no_default_cases — intentionally drop unsupported types
      _ => null,
    };
    if (type == null) return null;

    final double value;
    final String unit;
    switch (type) {
      case HealthRecordType.steps:
        value = (point.value as NumericHealthValue).numericValue.toDouble();
        unit = 'steps';
      case HealthRecordType.sleepSession:
      case HealthRecordType.exerciseSession:
        value = point.dateTo.difference(point.dateFrom).inMinutes.toDouble();
        unit = 'min';
    }

    return RawHealthRecord(
      id: point.uuid,
      type: type,
      value: value,
      unit: unit,
      startTime: point.dateFrom,
      endTime: point.dateTo,
    );
  }
}
