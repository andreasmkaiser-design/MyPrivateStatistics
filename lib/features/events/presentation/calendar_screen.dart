import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:private_statistics/features/events/presentation/day_detail_screen.dart';
import 'package:private_statistics/features/events/providers/event_providers.dart';

/// The Calendar tab — shows a month view with an event-indicator dot on each
/// day that has at least one event. Tapping any day opens [DayDetailScreen].
class CalendarScreen extends ConsumerStatefulWidget {
  /// Creates the [CalendarScreen].
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month);
  }

  void _prevMonth() => setState(() {
    _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
  });

  void _nextMonth() => setState(() {
    _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
  });

  @override
  Widget build(BuildContext context) {
    final daysAsync = ref.watch(eventDaysInMonthProvider(_displayMonth));
    final daysWithEvents = daysAsync.valueOrNull ?? const {};

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _MonthHeader(
                month: _displayMonth,
                onPrev: _prevMonth,
                onNext: _nextMonth,
              ),
              const _WeekdayRow(),
              _MonthGrid(
                month: _displayMonth,
                daysWithEvents: daysWithEvents,
                onDayTap: (day) => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => DayDetailScreen(day: day),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Private widgets ───────────────────────────────────────────────────────

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrev,
            tooltip: 'Previous month',
          ),
          Expanded(
            child: Text(
              DateFormat.yMMMM().format(month),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
            tooltip: 'Next month',
          ),
        ],
      ),
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow();

  static const _labels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: _labels
            .map(
              (label) => Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.daysWithEvents,
    required this.onDayTap,
  });

  final DateTime month;
  final Set<DateTime> daysWithEvents;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    // weekday: 1=Monday → offset 0, …, 7=Sunday → offset 6
    final offset = DateTime(month.year, month.month).weekday - 1;
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final cellCount = ((offset + daysInMonth) / 7).ceil() * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.85,
      ),
      itemCount: cellCount,
      itemBuilder: (context, index) {
        final dayNum = index - offset + 1;
        if (dayNum < 1 || dayNum > daysInMonth) {
          return const SizedBox.shrink();
        }
        final day = DateTime(month.year, month.month, dayNum);
        return _DayCell(
          day: day,
          hasEvents: daysWithEvents.contains(day),
          onTap: () => onDayTap(day),
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.hasEvents,
    required this.onTap,
  });

  final DateTime day;
  final bool hasEvents;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(day, DateTime.now());
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: isToday
                ? BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  )
                : null,
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: isToday
                  ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )
                  : Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 2),
          if (hasEvents)
            Semantics(
              label: 'Event indicator',
              child: Container(
                key: ValueKey('event_dot_${day.year}_${day.month}_${day.day}'),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            )
          else
            const SizedBox(width: 6, height: 6),
        ],
      ),
    );
  }
}
