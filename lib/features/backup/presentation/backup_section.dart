import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_statistics/features/backup/domain/models/backup_validation_result.dart';
import 'package:private_statistics/features/backup/presentation/backup_notifier.dart';
import 'package:private_statistics/features/backup/presentation/restore_state.dart';
import 'package:private_statistics/l10n/app_localizations.dart';

/// Settings section that exposes Export and Restore backup actions.
///
/// Listens to [backupNotifierProvider] and shows the restore confirmation
/// dialog via `ref.listen` when state transitions to
/// [RestoreAwaitingConfirmation].
class BackupSection extends ConsumerWidget {
  /// Creates a [BackupSection].
  const BackupSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncState = ref.watch(backupNotifierProvider);
    final isBusy = asyncState.valueOrNull is RestoreBusy;

    ref.listen<AsyncValue<RestoreState>>(backupNotifierProvider, (_, next) {
      if (!context.mounted) return;
      final value = next.valueOrNull;
      if (value is RestoreAwaitingConfirmation) {
        _showConfirmDialog(context, ref, l10n, value.result);
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(l10n.backupExportButton),
          trailing: isBusy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload),
          onTap: isBusy ? null : () => _export(context, ref, l10n),
        ),
        ListTile(
          title: Text(l10n.backupRestoreButton),
          trailing: const Icon(Icons.download),
          onTap: isBusy
              ? null
              : () =>
                    ref.read(backupNotifierProvider.notifier).pickAndValidate(),
        ),
      ],
    );
  }

  Future<void> _export(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    await ref.read(backupNotifierProvider.notifier).exportBackup();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.backupExportSuccess)));
  }

  Future<void> _showConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    BackupValidationResult result,
  ) async {
    final body = result is ValidationOkOlderSchema
        ? l10n.backupRestoreConfirmBodyMigration
        : l10n.backupRestoreConfirmBody;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(l10n.backupRestoreConfirmTitle),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.backupRestoreConfirmCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.backupRestoreConfirmProceed),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(backupNotifierProvider.notifier).confirmRestore(result);
    } else {
      ref.read(backupNotifierProvider.notifier).cancelRestore();
    }
  }
}
