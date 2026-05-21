import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:private_statistics/features/statistics/domain/models/calendar_data.dart';
import 'package:private_statistics/features/statistics/domain/models/calendar_day_state.dart';

/// A custom month-grid calendar that colour-codes days by co-occurrence state.
///
/// Renders every calendar month that overlaps [CalendarData.windowFrom] to
/// [CalendarData.windowTo]. Each in-window day cell is coloured by its
/// [CalendarDayState]:
/// - [CalendarDayState.both] → `primaryContainer`
/// - [CalendarDayState.sourceOnly] → `secondaryContainer`
/// - [CalendarDayState.candidateOnly] → `tertiaryContainer`
/// - [CalendarDayState.neither] → no fill
///
/// Days outside the analysis window are rendered as grey day-number labels
/// with no key, no fill, and no tap affordance.
///
/// Tapping any highlighted (non-[CalendarDayState.neither]) day fires
/// [onDayTapped] with the midnight-normalised [DateTime] for that day.
class CoOccurrenceCalendar extends StatelessWidget {
  /// Creates a [CoOccurrenceCalendar].
  const CoOccurrenceCalendar({
    required this.data,
    required this.onDayTapped,
    super.key,
  });

  /// Pre-computed calendar data produced by
  /// `CoOccurrenceCalculator.buildCalendarData`.
  final CalendarData data;

  /// Called when the user taps a day with a non-[CalendarDayState.neither]
  /// state. Receives the midnight-normalised [DateTime] for the tapped day.
  final void Function(DateTime date) onDayTapped;

  @override
  Widget build(BuildContext context) {
    final months = _monthsInWindow(data.windowFrom, data.windowTo);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: months
          .map(
            (month) => _MonthSection(
              month: month,
              data: data,
              onDayTapped: onDayTapped,
            ),
          )
          .toList(),
    );
  }

  static List<DateTime> _monthsInWindow(DateTime from, DateTime to) {
    final months = <DateTime>[];
    var cursor = DateTime(from.year, from.month);
    final last = DateTime(to.year, to.month);
    while (!cursor.isAfter(last)) {
      months.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return months;
  }
}

class _MonthSection extends StatelessWidget {
  const _MonthSection({
    required this.month,
    required this.data,
    required this.onDayTapped,
  });

  final DateTime month;
  final CalendarData data;
  final void Function(DateTime) onDayTapped;

  static const _weekLabels = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final locale = Localizations.localeOf(context);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    // weekday of the 1st: 1=Monday … 7=Sunday → leading blank cells
    final leadingBlanks = DateTime(month.year, month.month).weekday - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            DateFormat('MMMM y', locale.languageCode).format(month),
            style: theme.textTheme.titleSmall,
          ),
        ),
        Row(
          children: _weekLabels
              .map(
                (label) => Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 7,
          children: <Widget>[
            for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
            for (var d = 1; d <= daysInMonth; d++)
              _buildDayCell(context, d, cs),
          ],
        ),
      ],
    );
  }

  Widget _buildDayCell(BuildContext context, int dayNumber, ColorScheme cs) {
    final date = DateTime(month.year, month.month, dayNumber);
    final state = data.stateByDay[date];

    // Day outside the analysis window — grey label, no key, no tap.
    if (state == null) {
      return Center(
        child: Text(
          '$dayNumber',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.3),
          ),
        ),
      );
    }

    final color = _colorForState(state, cs);
    final isHighlighted = state != CalendarDayState.neither;

    return GestureDetector(
      onTap: isHighlighted ? () => onDayTapped(date) : null,
      child: Container(
        key: Key('cal_day_${date.year}_${date.month}_${date.day}'),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Center(
          child: Text(
            '$dayNumber',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
    );
  }

  static Color? _colorForState(CalendarDayState state, ColorScheme cs) =>
      switch (state) {
        CalendarDayState.both => cs.primaryContainer,
        CalendarDayState.sourceOnly => cs.secondaryContainer,
        CalendarDayState.candidateOnly => cs.tertiaryContainer,
        CalendarDayState.neither => null,
      };
}
