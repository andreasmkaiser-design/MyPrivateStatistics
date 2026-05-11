import 'package:drift/drift.dart';

/// Drift table definition for the `health_records` SQL table.
///
/// Each row is one health record imported from Health Connect. [id] is the
/// Health Connect record UUID and serves as both the primary key and the
/// deduplication key — inserting a row whose [id] already exists is a no-op
/// (insert-or-ignore semantics).
///
/// See ADR-0018 for the rationale for the generic schema shared across all
/// V1 record types.
@DataClassName('HealthRecordRow')
class HealthRecords extends Table {
  /// Health Connect record UUID — primary key and deduplication key.
  TextColumn get id => text()();

  /// Record type string.
  ///
  /// One of `"STEPS"`, `"SLEEP_SESSION"`, or `"EXERCISE_SESSION"`.
  TextColumn get type => text()();

  /// Numeric value; semantics depend on [type].
  ///
  /// For `"STEPS"`: step count. For session types: duration in minutes.
  RealColumn get value => real()();

  /// Unit string corresponding to [value].
  ///
  /// `"steps"` for step records; `"min"` for session records.
  TextColumn get unit => text()();

  /// Start of the time window, as a Unix timestamp in milliseconds.
  IntColumn get startTimeMs => integer()();

  /// End of the time window, as a Unix timestamp in milliseconds.
  IntColumn get endTimeMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
