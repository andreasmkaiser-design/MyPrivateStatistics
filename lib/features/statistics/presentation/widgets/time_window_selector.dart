import 'package:flutter/material.dart';
import 'package:private_statistics/features/statistics/domain/models/time_window.dart';

/// A segmented button that lets the user pick a [TimeWindow] for the Temporal
/// Proximity analysis.
///
/// Renders one segment per entry in [options], labelled with
/// [TimeWindow.label]. Fires [onChanged] with the newly selected window when
/// the user taps a segment.
class TimeWindowSelector extends StatelessWidget {
  /// Creates a [TimeWindowSelector].
  const TimeWindowSelector({
    required this.selected,
    required this.options,
    required this.onChanged,
    super.key,
  });

  /// The currently selected time window.
  final TimeWindow selected;

  /// The list of time windows to display as selectable segments.
  final List<TimeWindow> options;

  /// Called when the user selects a different time window.
  final ValueChanged<TimeWindow> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TimeWindow>(
      segments: options
          .map((w) => ButtonSegment<TimeWindow>(value: w, label: Text(w.label)))
          .toList(),
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
