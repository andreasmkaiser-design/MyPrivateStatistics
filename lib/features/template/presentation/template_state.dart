import 'package:private_statistics/features/template/domain/models/template_import_result.dart';

/// The UI state for the template Export / Import section of the Categories tab.
sealed class TemplateState {
  /// Creates a [TemplateState].
  const TemplateState();
}

/// No template operation is in progress.
final class TemplateIdle extends TemplateState {
  /// Creates a [TemplateIdle] state.
  const TemplateIdle();
}

/// An export or import operation is executing.
final class TemplateBusy extends TemplateState {
  /// Creates a [TemplateBusy] state.
  const TemplateBusy();
}

/// Import detected name conflicts; waiting for the user to resolve them.
///
/// Present a dialog listing [conflicts] and call
/// `TemplateNotifier.resolveAndImport` with the user's choices.
final class TemplateConflictsFound extends TemplateState {
  /// Creates a [TemplateConflictsFound] state.
  const TemplateConflictsFound(this.conflicts);

  /// The list of conflicts the user must resolve before import can proceed.
  final List<TemplateNameConflict> conflicts;
}
