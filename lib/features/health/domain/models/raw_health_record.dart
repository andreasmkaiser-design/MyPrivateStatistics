import 'package:private_statistics/features/health/domain/models/health_record_type.dart';

/// A health record read from Health Connect and awaiting local persistence.
///
/// Instances are produced by `HealthDataSource.fetchSince` and consumed by
/// `HealthRecordRepository.insertAll`. The [id] field is the Health Connect
/// record UUID and drives deduplication.
class RawHealthRecord {
  /// Creates a [RawHealthRecord].
  const RawHealthRecord({
    required this.id,
    required this.type,
    required this.value,
    required this.unit,
    required this.startTime,
    required this.endTime,
  });

  /// The Health Connect record UUID used for deduplication.
  final String id;

  /// The category of health data this record represents.
  final HealthRecordType type;

  /// The numeric value; semantics depend on [type].
  ///
  /// For [HealthRecordType.steps]: step count.
  /// For [HealthRecordType.sleepSession] and
  /// [HealthRecordType.exerciseSession]: duration in minutes.
  final double value;

  /// Unit string corresponding to [value].
  ///
  /// `"steps"` for step records; `"min"` for session records.
  final String unit;

  /// Start of the time window this record covers.
  final DateTime startTime;

  /// End of the time window this record covers.
  final DateTime endTime;
}
