/// The health record types this app imports from Health Connect (V1 scope).
///
/// See ADR-0018 for the rationale for these three types and their storage
/// semantics.
enum HealthRecordType {
  /// Step-count records.
  ///
  /// Stored with `value` = step count and `unit` = `"steps"`.
  steps,

  /// Sleep-session records.
  ///
  /// Stored with `value` = duration in minutes and `unit` = `"min"`.
  sleepSession,

  /// Exercise-session records (maps to `HealthDataType.WORKOUT` in the
  /// `health` package).
  ///
  /// Stored with `value` = duration in minutes and `unit` = `"min"`.
  exerciseSession,
}
