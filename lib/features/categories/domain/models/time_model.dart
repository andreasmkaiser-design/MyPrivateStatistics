/// The time structure configured on a `Category`.
///
/// Determines whether Events in that Category are recorded as a single point
/// in time or as a duration with start and end.
enum TimeModel {
  /// A moment in time consisting of a date and an optional clock time.
  timePoint,

  /// A time range where start and end are dates only (no clock time).
  dayPreciseRange,

  /// A time range where start and end each include a date and a clock time.
  datetimePreciseRange,
}
