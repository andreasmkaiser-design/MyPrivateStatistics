/// Base class for all application-specific exceptions.
///
/// Extend this class to define domain-level errors that the app handles
/// explicitly — e.g. to show inline validation messages or to propagate
/// typed errors via Riverpod's `AsyncValue.error`.
abstract class AppException implements Exception {
  /// Creates an [AppException] with the given human-readable [message].
  const AppException(this.message);

  /// A human-readable description of the error.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}
