/// The computed temporal proximity relationship between a source `Category`
/// and a candidate `Category` within an `AnalysisWindow` and `TimeWindow`.
///
/// The [score] is the fraction of source events that are followed by at least
/// one candidate event within the configured time window (mode A, ADR-0017):
/// `count(events_A where ∃ event_B within [t_A, t_A + window]) / count(events_A)`
final class TemporalProximityResult {
  /// Creates a [TemporalProximityResult].
  const TemporalProximityResult({
    required this.candidateCategoryUid,
    required this.candidateCategoryName,
    required this.followCount,
    required this.sourceEventCount,
    required this.score,
    required this.hasLimitedData,
  });

  /// UID of the candidate (non-source) category.
  final String candidateCategoryUid;

  /// Human-readable name of the candidate category.
  final String candidateCategoryName;

  /// Number of source events followed by at least one candidate event within
  /// the time window.
  final int followCount;

  /// Total number of source events in the analysis window.
  final int sourceEventCount;

  /// Temporal proximity score in the range [0.0, 1.0].
  final double score;

  /// `true` when either category has fewer than 5 events in the window,
  /// indicating the result may not be statistically significant (ADR-0017).
  final bool hasLimitedData;
}
