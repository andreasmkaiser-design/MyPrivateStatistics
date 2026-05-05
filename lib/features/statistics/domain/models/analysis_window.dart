/// Sealed class representing the time window used for statistical analysis.
///
/// Two concrete variants are provided:
/// - [LastNDaysWindow]: a rolling window of [LastNDaysWindow.days] calendar
///   days ending today.
/// - [CustomWindow]: an explicit user-supplied date range.
sealed class AnalysisWindow {
  /// Creates an [AnalysisWindow].
  const AnalysisWindow();

  /// The first calendar day (midnight) of the window, inclusive.
  DateTime get from;

  /// The last calendar day (midnight) of the window, inclusive.
  DateTime get to;
}

/// A rolling [AnalysisWindow] spanning [days] calendar days and ending today.
///
/// Both [from] and [to] are recomputed on each access so they always reflect
/// "today" at the moment of use.
final class LastNDaysWindow extends AnalysisWindow {
  /// Creates a [LastNDaysWindow] of [days] calendar days, ending today.
  const LastNDaysWindow(this.days);

  /// The number of calendar days in the window (e.g. 30, 60, 90).
  final int days;

  @override
  DateTime get from {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: days - 1));
  }

  @override
  DateTime get to {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}

/// An [AnalysisWindow] with explicit calendar date bounds.
final class CustomWindow extends AnalysisWindow {
  /// Creates a [CustomWindow] spanning [[from], [to]], inclusive.
  const CustomWindow({required DateTime from, required DateTime to})
    : _from = from,
      _to = to;

  final DateTime _from;
  final DateTime _to;

  @override
  DateTime get from => _from;

  @override
  DateTime get to => _to;
}
