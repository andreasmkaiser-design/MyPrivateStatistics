import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Static logging facade for the app.
///
/// Wraps the `logger` package and suppresses debug/verbose output in release
/// builds. Use the appropriate level method instead of `print`.
/// Never log personally identifiable information (PII).
abstract final class AppLogger {
  static final Logger _logger = Logger(
    level: kReleaseMode ? Level.info : Level.trace,
    printer: PrettyPrinter(methodCount: 0),
  );

  /// Logs a verbose (trace) message; suppressed in release builds.
  static void verbose(String message) => _logger.t(message);

  /// Logs a debug message; suppressed in release builds.
  static void debug(String message) => _logger.d(message);

  /// Logs an informational message.
  static void info(String message) => _logger.i(message);

  /// Logs a warning with an optional [error] object and [stackTrace].
  static void warning(
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) => _logger.w(message, error: error, stackTrace: stackTrace);

  /// Logs a non-fatal error with an optional [error] object and [stackTrace].
  static void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);

  /// Logs a fatal error with an optional [error] object and [stackTrace].
  static void fatal(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.f(message, error: error, stackTrace: stackTrace);
}
