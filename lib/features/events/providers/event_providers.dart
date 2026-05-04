import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_statistics/core/database/database_provider.dart';
import 'package:private_statistics/features/events/data/event_repository_impl.dart';
import 'package:private_statistics/features/events/domain/models/event.dart';
import 'package:private_statistics/features/events/domain/repositories/event_repository.dart';

/// Provides the [EventRepository] backed by the app's Drift database.
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepositoryImpl(ref.watch(appDatabaseProvider));
});

/// Reactive stream of events whose occurrence date matches `day`.
///
/// Re-emits whenever any event on that day is created, updated, or deleted.
/// Backed by [EventRepository.watchByDay].
final eventsByDayProvider = StreamProvider.family<List<Event>, DateTime>((
  ref,
  day,
) {
  return ref.watch(eventRepositoryProvider).watchByDay(day);
});

/// Resolves a single [Event] by UID; `null` if not found.
///
/// Backed by [EventRepository.findByUid].
final eventProvider = FutureProvider.family<Event?, String>((ref, uid) {
  return ref.watch(eventRepositoryProvider).findByUid(uid);
});
