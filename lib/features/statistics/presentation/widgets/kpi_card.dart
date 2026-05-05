import 'package:flutter/material.dart';
import 'package:private_statistics/features/statistics/domain/models/co_occurrence_result.dart';

/// A card displaying the plain-language co-occurrence summary for a single
/// candidate category (ADR-0017).
///
/// Shows the candidate category name, the Jaccard score as a percentage,
/// and the human-readable text
/// "{sourceCategoryName} and {candidate} co-occurred on {shared} of
/// {union} days". When [CoOccurrenceResult.hasLimitedData] is `true`, a
/// soft warning is appended.
class KpiCard extends StatelessWidget {
  /// Creates a [KpiCard].
  const KpiCard({
    required this.sourceCategoryName,
    required this.result,
    super.key,
  });

  /// Human-readable name of the source (selected) category.
  final String sourceCategoryName;

  /// The co-occurrence result to display.
  final CoOccurrenceResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scorePercent = '${(result.score * 100).toStringAsFixed(0)}%';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    result.candidateCategoryName,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  scorePercent,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$sourceCategoryName and '
              '${result.candidateCategoryName} co-occurred on '
              '${result.sharedDays} of ${result.unionDays} days',
              style: theme.textTheme.bodyMedium,
            ),
            if (result.hasLimitedData) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Limited data — result may not be statistically'
                      ' significant.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
