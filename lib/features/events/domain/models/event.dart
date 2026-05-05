import 'package:private_statistics/features/events/domain/models/event_time.dart';
import 'package:private_statistics/features/events/domain/models/field_value.dart';

/// A single occurrence recorded by the user, belonging to one category and
/// anchored to an [EventTime].
///
/// Field values are stored as a list of [FieldValue] entries — one per field
/// the user filled in. Constraint validation is enforced by
/// `EventRepository.save` before any value reaches the database.
class Event {
  /// Creates an immutable [Event].
  const Event({
    required this.uid,
    required this.categoryUid,
    required this.occurredAt,
    required this.fieldValues,
  });

  /// Globally unique identifier for this event.
  final String uid;

  /// UID of the category this event belongs to.
  final String categoryUid;

  /// The temporal anchor of this event — a [TimePoint], [DayPreciseRange], or
  /// [DatetimePreciseRange] as configured by the owning category's time model.
  final EventTime occurredAt;

  /// Typed values for the fields the user filled in.
  final List<FieldValue> fieldValues;
}
