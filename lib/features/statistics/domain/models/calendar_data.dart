import 'package:private_statistics/features/statistics/domain/models/calendar_day_state.dart';

/// Fully computed, renderer-ready data for a `CoOccurrenceCalendar`.
///
/// Built by `CoOccurrenceCalculator.buildCalendarData`. The widget knows
/// nothing about categories or events — it renders [stateByDay] directly.
///
/// [stateByDay] keys are midnight-normalised [DateTime] values covering every
/// calendar day from [windowFrom] to [windowTo] inclusive.
final class CalendarData {
  /// Creates a [CalendarData].
  const CalendarData({
    required this.windowFrom,
    required this.windowTo,
    required this.sourceCategoryUid,
    required this.sourceCategoryName,
    required this.candidateCategoryUid,
    required this.candidateCategoryName,
    required this.stateByDay,
  });

  /// First day of the analysis window (midnight, inclusive).
  final DateTime windowFrom;

  /// Last day of the analysis window (midnight, inclusive).
  final DateTime windowTo;

  /// UID of the source `Category`.
  final String sourceCategoryUid;

  /// Human-readable name of the source category — used in the bottom sheet.
  final String sourceCategoryName;

  /// UID of the selected candidate `Category`.
  final String candidateCategoryUid;

  /// Human-readable name of the selected candidate category.
  final String candidateCategoryName;

  /// Maps every day in [[windowFrom]..[windowTo]] to its [CalendarDayState].
  ///
  /// Keys are midnight-normalised [DateTime] values. Every day in the window
  /// is present exactly once; days outside the window are absent.
  final Map<DateTime, CalendarDayState> stateByDay;
}
