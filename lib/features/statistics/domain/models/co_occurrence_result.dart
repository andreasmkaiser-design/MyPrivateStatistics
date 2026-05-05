/// The computed co-occurrence relationship between a source `Category` and a
/// candidate `Category` within an `AnalysisWindow`.
///
/// The [score] is the Jaccard index:
/// `|days(A) ∩ days(B)| / |days(A) ∪ days(B)|` (ADR-0017).
final class CoOccurrenceResult {
  /// Creates a [CoOccurrenceResult].
  const CoOccurrenceResult({
    required this.candidateCategoryUid,
    required this.candidateCategoryName,
    required this.sharedDays,
    required this.unionDays,
    required this.score,
    required this.hasLimitedData,
  });

  /// UID of the candidate (non-source) category.
  final String candidateCategoryUid;

  /// Human-readable name of the candidate category.
  final String candidateCategoryName;

  /// Number of calendar days on which both categories had at least one event.
  final int sharedDays;

  /// Number of calendar days on which at least one category had an event
  /// (source ∪ candidate).
  final int unionDays;

  /// Jaccard co-occurrence score in the range [0.0, 1.0].
  final double score;

  /// `true` when either category has fewer than 5 events in the window,
  /// indicating the result may not be statistically significant (ADR-0017).
  final bool hasLimitedData;
}
