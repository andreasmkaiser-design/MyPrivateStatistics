import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:private_statistics/core/logging/app_logger.dart';
import 'package:private_statistics/features/categories/domain/models/category_node.dart';
import 'package:private_statistics/features/categories/providers/category_providers.dart';
import 'package:private_statistics/features/events/domain/models/event.dart';
import 'package:private_statistics/features/events/domain/models/event_time.dart';
import 'package:private_statistics/features/events/presentation/event_form_screen.dart';
import 'package:private_statistics/features/events/providers/event_providers.dart';

/// Shows all events recorded on a single calendar [day].
///
/// Each event is displayed as a tile with its category name and optional time.
/// Tapping the FAB opens [EventFormScreen] to create a new event for this day.
/// Each tile offers popup actions to edit or delete the event.
class DayDetailScreen extends ConsumerWidget {
  /// Creates a [DayDetailScreen] for the given [day].
  const DayDetailScreen({required this.day, super.key});

  /// The calendar day whose events are shown (only date components are used).
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsByDayProvider(day));
    final treeAsync = ref.watch(categoryTreeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(DateFormat.yMMMd().format(day))),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          AppLogger.error('Failed to load events for day', error);
          return const Center(child: Text('Failed to load events'));
        },
        data: (events) {
          final categoryNames = _buildCategoryNameMap(
            treeAsync.valueOrNull ?? [],
          );
          if (events.isEmpty) {
            return const _DayEmptyState();
          }
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (_, i) {
              final event = events[i];
              final node = _findNode(
                treeAsync.valueOrNull ?? [],
                event.categoryUid,
              );
              return _EventTile(
                event: event,
                categoryName:
                    categoryNames[event.categoryUid] ?? 'Unknown category',
                onEdit: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => EventFormScreen.fromEvent(
                      event: event,
                      categoryNode: node,
                    ),
                  ),
                ),
                onDelete: () => _confirmDelete(context, ref, event),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => EventFormScreen.createNew(defaultDay: day),
          ),
        ),
        tooltip: 'New event',
        child: const Icon(Icons.add),
      ),
    );
  }

  Map<String, String> _buildCategoryNameMap(List<CategoryNode> roots) {
    final map = <String, String>{};
    _flattenInto(roots, map);
    return map;
  }

  void _flattenInto(List<CategoryNode> nodes, Map<String, String> map) {
    for (final node in nodes) {
      map[node.category.uid] = node.category.name;
      _flattenInto(node.children, map);
    }
  }

  CategoryNode? _findNode(List<CategoryNode> roots, String uid) {
    for (final node in roots) {
      if (node.category.uid == uid) return node;
      final found = _findNode(node.children, uid);
      if (found != null) return found;
    }
    return null;
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Event event,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteEventDialog(),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      await ref.read(eventRepositoryProvider).delete(event.uid);
      AppLogger.info('Event deleted: ${event.uid}');
    } on Object catch (e, st) {
      AppLogger.error('Failed to delete event', e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to delete event')));
      }
    }
  }
}

// ── Private widgets ───────────────────────────────────────────────────────

enum _EventAction { edit, delete }

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.event,
    required this.categoryName,
    required this.onEdit,
    required this.onDelete,
  });

  final Event event;
  final String categoryName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subtitle = switch (event.occurredAt) {
      TimePoint(:final clockTime) when clockTime != null =>
        DateFormat.jm().format(clockTime),
      DayPreciseRange(:final from, :final to) =>
        '${DateFormat.MMMd().format(from)} – ${DateFormat.MMMd().format(to)}',
      DatetimePreciseRange(:final from, :final to) =>
        '${DateFormat.MMMd().add_jm().format(from)}'
            ' – ${DateFormat.MMMd().add_jm().format(to)}',
      _ => null,
    };
    return ListTile(
      title: Text(categoryName),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: PopupMenuButton<_EventAction>(
        onSelected: (action) {
          if (action == _EventAction.edit) onEdit();
          if (action == _EventAction.delete) onDelete();
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: _EventAction.edit, child: Text('Edit')),
          PopupMenuItem(value: _EventAction.delete, child: Text('Delete')),
        ],
      ),
    );
  }
}

class _DayEmptyState extends StatelessWidget {
  const _DayEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No events on this day',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to record an event',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _DeleteEventDialog extends StatelessWidget {
  const _DeleteEventDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete event'),
      content: const Text('Delete this event? This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
