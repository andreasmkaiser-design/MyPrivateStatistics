/// Sealed class representing a configurable time window for the Temporal
/// Proximity analysis (ADR-0017).
///
/// Use one of the concrete subtypes ([HoursTimeWindow] or [DaysTimeWindow])
/// when constructing a window instance.
sealed class TimeWindow {
  /// Creates a [TimeWindow].
  const TimeWindow();

  /// The duration represented by this window.
  Duration get duration;

  /// Human-readable label shown in the UI selector (e.g. `"24 h"`, `"7 days"`).
  String get label;
}

/// A time window measured in hours.
final class HoursTimeWindow extends TimeWindow {
  /// Creates an [HoursTimeWindow] of [hours] hours.
  const HoursTimeWindow(this.hours);

  /// Number of hours in this window.
  final int hours;

  @override
  Duration get duration => Duration(hours: hours);

  @override
  String get label => '$hours h';
}

/// A time window measured in whole days.
final class DaysTimeWindow extends TimeWindow {
  /// Creates a [DaysTimeWindow] of [days] days.
  const DaysTimeWindow(this.days);

  /// Number of days in this window.
  final int days;

  @override
  Duration get duration => Duration(days: days);

  @override
  String get label => '$days days';
}
