/// Sealed class representing the temporal anchor of an `Event`.
///
/// Every event is anchored to exactly one of three time structures, determined
/// by the owning `Category`'s `TimeModel`:
/// - [TimePoint]: a single moment in time (date + optional clock time)
/// - [DayPreciseRange]: a span bounded by calendar dates only
/// - [DatetimePreciseRange]: a span where each endpoint includes a clock time
sealed class EventTime {
  /// Creates an [EventTime].
  const EventTime();
}

/// A moment in time consisting of a calendar [date] and an optional clock time.
///
/// When [clockTime] is `null` the event is day-precision only and [date]
/// carries the full temporal information.
final class TimePoint extends EventTime {
  /// Creates a [TimePoint] with a mandatory [date] and optional [clockTime].
  const TimePoint({required this.date, this.clockTime});

  /// The calendar date (year, month, day; time component is ignored).
  final DateTime date;

  /// Optional time-of-day; `null` means day-precision only.
  final DateTime? clockTime;
}

/// A time range where [from] and [to] are calendar dates with no clock time.
///
/// Both [from] and [to] are stored at midnight (local time). The range is
/// inclusive: the event spans every calendar day from [from] to [to].
final class DayPreciseRange extends EventTime {
  /// Creates a [DayPreciseRange] from [from] to [to] (inclusive).
  ///
  /// [to] must not be before [from]; this is enforced by the repository.
  const DayPreciseRange({required this.from, required this.to});

  /// The first calendar day of the range (time component is ignored).
  final DateTime from;

  /// The last calendar day of the range, inclusive (time component is ignored).
  final DateTime to;
}

/// A time range where [from] and [to] each carry a date and a clock time.
///
/// The range is inclusive of both endpoints. [to] must not be before [from];
/// this is enforced by the repository.
final class DatetimePreciseRange extends EventTime {
  /// Creates a [DatetimePreciseRange] from [from] to [to] (inclusive).
  const DatetimePreciseRange({required this.from, required this.to});

  /// The start of the range, including clock time.
  final DateTime from;

  /// The end of the range, including clock time.
  final DateTime to;
}
