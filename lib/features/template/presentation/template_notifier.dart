import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_statistics/features/categories/providers/category_providers.dart';
import 'package:private_statistics/features/template/data/template_file_repository_impl.dart';
import 'package:private_statistics/features/template/domain/exceptions.dart';
import 'package:private_statistics/features/template/domain/export_template_use_case.dart';
import 'package:private_statistics/features/template/domain/import_template_use_case.dart';
import 'package:private_statistics/features/template/domain/models/template_import_result.dart';
import 'package:private_statistics/features/template/presentation/template_state.dart';

/// Drives the Export / Import template actions on the Categories tab.
///
/// Use [templateNotifierProvider] to access this notifier.
/// Call [exportTemplate] to export, [startImport] to begin the import flow,
/// and [resolveAndImport] to complete it after the user resolves conflicts.
class TemplateNotifier extends AsyncNotifier<TemplateState> {
  @override
  Future<TemplateState> build() async => const TemplateIdle();

  /// Exports the category hierarchy to a user-chosen JSON file.
  ///
  /// Transitions to [TemplateBusy] during the operation, then back to
  /// [TemplateIdle] on success. Silently returns to [TemplateIdle] when the
  /// user cancels the picker. Other failures surface via [AsyncValue.error].
  Future<void> exportTemplate() async {
    state = const AsyncData(TemplateBusy());
    try {
      await ref.read(exportTemplateUseCaseProvider).call();
      state = const AsyncData(TemplateIdle());
    } on TemplateCancelledException {
      state = const AsyncData(TemplateIdle());
    } on TemplateException catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Opens the file-picker and begins the import flow.
  ///
  /// If the template contains no name conflicts the categories are persisted
  /// and state returns to [TemplateIdle]. When conflicts are found, state
  /// transitions to [TemplateConflictsFound] — call [resolveAndImport] after
  /// the user makes their choices.
  Future<void> startImport() async {
    state = const AsyncData(TemplateBusy());
    try {
      final result = await ref
          .read(importTemplateUseCaseProvider)
          .call(resolutions: const {});
      state = AsyncData(_stateFrom(result));
    } on TemplateCancelledException {
      state = const AsyncData(TemplateIdle());
    } on TemplateException catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Completes the import after the user has resolved all conflicts.
  ///
  /// [resolutions] maps the original template UID of each conflicting entry
  /// to the user's chosen [ConflictResolution].
  ///
  /// Returns the [TemplateImportResult] on success so the caller can show a
  /// count Snackbar, or `null` when an error is surfaced via
  /// [AsyncValue.error].
  ///
  /// Precondition: state is [TemplateConflictsFound].
  Future<TemplateImportResult?> resolveAndImport(
    Map<String, ConflictResolution> resolutions,
  ) async {
    state = const AsyncData(TemplateBusy());
    try {
      final result = await ref
          .read(importTemplateUseCaseProvider)
          .call(resolutions: resolutions);
      state = AsyncData(_stateFrom(result));
      return result;
    } on TemplateException catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  TemplateState _stateFrom(TemplateImportResult result) =>
      result.conflicts.isEmpty
      ? const TemplateIdle()
      : TemplateConflictsFound(result.conflicts);
}

/// Provides the [TemplateNotifier].
final templateNotifierProvider =
    AsyncNotifierProvider<TemplateNotifier, TemplateState>(
      TemplateNotifier.new,
    );

/// Provides [ExportTemplateUseCase] wired with the production repositories.
///
/// Overridden in tests with a fake use-case.
final exportTemplateUseCaseProvider = Provider<ExportTemplateUseCase>((ref) {
  return ExportTemplateUseCase(
    ref.watch(categoryRepositoryProvider),
    const TemplateFileRepositoryImpl(),
  );
});

/// Provides [ImportTemplateUseCase] wired with the production repositories.
///
/// Overridden in tests with a fake use-case.
final importTemplateUseCaseProvider = Provider<ImportTemplateUseCase>((ref) {
  return ImportTemplateUseCase(
    ref.watch(categoryRepositoryProvider),
    const TemplateFileRepositoryImpl(),
  );
});
