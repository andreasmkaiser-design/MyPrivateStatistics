/// The visual classification of a single calendar day in the co-occurrence
/// calendar.
///
/// Used by `CoOccurrenceCalendar` to determine cell colour. Computed by
/// `CoOccurrenceCalculator.buildCalendarData` from the source and candidate
/// day sets.
enum CalendarDayState {
  /// Both the source and candidate categories have at least one event on this
  /// day.
  both,

  /// Only the source category has at least one event on this day.
  sourceOnly,

  /// Only the candidate category has at least one event on this day.
  candidateOnly,

  /// Neither category has an event on this day (but the day is inside the
  /// analysis window).
  neither,
}
