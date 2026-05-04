import 'package:private_statistics/core/exceptions.dart';

/// Thrown when an event with the requested UID cannot be found.
class EventNotFoundException extends AppException {
  /// Creates an [EventNotFoundException] for the event with [uid].
  const EventNotFoundException(String uid) : super('Event not found: $uid');
}

/// Thrown when a `FieldValue` in an `Event` violates the owning field's
/// numeric constraint or contains an invalid enum option.
class EventFieldConstraintViolationException extends AppException {
  /// Creates an [EventFieldConstraintViolationException] with [message].
  const EventFieldConstraintViolationException(super.message);
}
