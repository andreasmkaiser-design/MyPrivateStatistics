import 'package:flutter/material.dart';
import 'package:private_statistics/features/statistics/domain/models/temporal_proximity_result.dart';
import 'package:private_statistics/l10n/app_localizations.dart';

/// A card displaying the plain-language temporal proximity summary for a
/// single candidate category (ADR-0017, mode A).
///
/// Shows the candidate category name, the score as a percentage, and the text
/// "{candidateName} followed {sourceName} within {timeWindowLabel} in {score}%
/// of cases". When [TemporalProximityResult.hasLimitedData] is `true`, a soft
/// warning is appended.
class TemporalProximityKpiCard extends StatelessWidget {
  /// Creates a [TemporalProximityKpiCard].
  const TemporalProximityKpiCard({
    required this.sourceCategoryName,
    required this.result,
    required this.timeWindowLabel,
    super.key,
  });

  /// Human-readable name of the source (selected) category.
  final String sourceCategoryName;

  /// The temporal proximity result to display.
  final TemporalProximityResult result;

  /// Human-readable label of the active time window (e.g. `"24 h"`).
  final String timeWindowLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
              l10n.statisticsProximitySummary(
                result.candidateCategoryName,
                sourceCategoryName,
                timeWindowLabel,
                (result.score * 100).toStringAsFixed(0),
              ),
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
                      l10n.statisticsLimitedData,
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
