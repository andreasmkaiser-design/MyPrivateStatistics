import 'package:private_statistics/core/exceptions.dart';

/// Base class for all template export / import failures.
///
/// Callers catch [TemplateException] centrally via the Riverpod
/// `ProviderObserver` Snackbar handler.
abstract class TemplateException extends AppException {
  /// Creates a [TemplateException] with [message].
  const TemplateException(super.message);
}

/// Thrown when the user dismisses the file-picker without selecting a file.
class TemplateCancelledException extends TemplateException {
  /// Creates a [TemplateCancelledException].
  const TemplateCancelledException()
    : super('Template operation was cancelled.');
}

/// Thrown when the selected file is not valid JSON or does not contain a
/// recognisable template array.
class MalformedTemplateException extends TemplateException {
  /// Creates a [MalformedTemplateException] with an optional [detail].
  MalformedTemplateException([String detail = ''])
    : super(
        detail.isEmpty
            ? 'Malformed template file.'
            : 'Malformed template file: $detail',
      );
}
