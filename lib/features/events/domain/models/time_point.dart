/// A moment in time, consisting of a calendar [date] and an optional clock
/// time.
///
/// When [clockTime] is `null` the event is considered day-precision only and
/// the [date] carries the full time-point information.
class TimePoint {
  /// Creates a [TimePoint] with a mandatory [date] and optional [clockTime].
  const TimePoint({required this.date, this.clockTime});

  /// The calendar date of this time point (year, month, day; time portion is
  /// ignored).
  final DateTime date;

  /// The optional time-of-day component; `null` means day-precision only.
  final DateTime? clockTime;
}
