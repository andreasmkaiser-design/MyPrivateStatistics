import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_statistics/features/health/domain/models/sync_result.dart';
import 'package:private_statistics/features/health/providers/health_providers.dart';
import 'package:private_statistics/l10n/app_localizations.dart';

/// Full-page settings screen, accessible via the toolbar icon in `AppShell`.
class SettingsScreen extends ConsumerWidget {
  /// Creates the [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final syncHourAsync = ref.watch(syncHourProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          _SectionHeader(title: l10n.healthSyncSectionTitle),
          ListTile(
            title: Text(l10n.healthSyncNowButton),
            trailing: const Icon(Icons.sync),
            onTap: () => _runSync(context, ref, l10n),
          ),
          syncHourAsync.when(
            data: (hour) => ListTile(
              title: Text(l10n.healthSyncDailyTimeLabel),
              trailing: Text(
                '${hour.toString().padLeft(2, '0')}:00',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              onTap: () => _pickSyncTime(context, ref, hour),
            ),
            loading: () => const ListTile(
              trailing: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Future<void> _runSync(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final result = await ref.read(healthSyncOrchestratorProvider).syncNow();
    ref.read(lastSyncResultProvider.notifier).state = result;

    if (!context.mounted) return;
    final message = switch (result) {
      SyncSuccess(:final importedCount) when importedCount == 0 =>
        l10n.healthSyncNoNewRecords,
      SyncSuccess(:final importedCount) => l10n.healthSyncSuccess(
        importedCount,
      ),
      SyncPermissionDenied() => l10n.healthSyncPermissionDenied,
      SyncUnavailable() => l10n.healthSyncUnavailable,
      SyncPartialFailure(:final importedCount) => l10n.healthSyncSuccess(
        importedCount,
      ),
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickSyncTime(
    BuildContext context,
    WidgetRef ref,
    int currentHour,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: 0),
    );
    if (picked == null) return;

    await ref.read(syncScheduleStoreProvider).saveSyncHour(picked.hour);
    ref.invalidate(syncHourProvider);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
