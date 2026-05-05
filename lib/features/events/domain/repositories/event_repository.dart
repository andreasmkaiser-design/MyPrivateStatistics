import 'package:private_statistics/features/events/domain/models/event.dart';

/// Contract for persisting and querying [Event] data.
///
/// All `FieldValue` entries are validated against the owning field's
/// constraint at the repository boundary before any write reaches the
/// database. Constraint violations throw
/// `EventFieldConstraintViolationException`.
abstract class EventRepository {
  /// Emits all events whose occurrence date matches [day], re-emitting
  /// whenever any event on that day is created, updated, or deleted.
  Stream<List<Event>> watchByDay(DateTime day);

  /// Returns the event identified by [uid], or `null` if it does not exist.
  Future<Event?> findByUid(String uid);

  /// Persists [event] as an upsert (insert or replace by [Event.uid]).
  ///
  /// Validates every `FieldValue` in [Event.fieldValues] against the merged
  /// schema of [Event.categoryUid] before writing. Throws
  /// `EventFieldConstraintViolationException` on the first violation found.
  Future<void> save(Event event);

  /// Deletes the event with [uid]. No-op if the event does not exist.
  Future<void> delete(String uid);

  /// Emits the set of days (midnight [DateTime] values) within [month] that
  /// have at least one event, re-emitting on any event change.
  ///
  /// The [month] argument needs only [DateTime.year] and [DateTime.month] to
  /// be meaningful; day and sub-day components are ignored.
  Stream<Set<DateTime>> watchDaysWithEventsInMonth(DateTime month);

  /// Returns all events whose occurrence overlaps the calendar window
  /// [[from], [to]] (both endpoints inclusive, day-precision).
  ///
  /// Range events are included when their interval overlaps the window.
  /// [from] and [to] need only carry year/month/day; time components are
  /// ignored.
  Future<List<Event>> findInWindow(DateTime from, DateTime to);
}
