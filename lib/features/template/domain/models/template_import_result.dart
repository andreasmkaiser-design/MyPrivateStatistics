import 'package:private_statistics/features/categories/domain/models/category.dart';

/// How the user wants to resolve a name conflict during template import.
enum ConflictResolution {
  /// Import the category even though a sibling with the same name exists.
  ///
  /// The `CategoryRepository.save` bypass path is used so the normal
  /// uniqueness guard is skipped for this specific import.
  keepBoth,

  /// Skip importing the conflicting category entirely.
  discard,
}

/// The outcome of a single `ImportTemplateUseCase.call` invocation.
///
/// When [conflicts] is non-empty the caller should present the conflict dialog
/// and call `ImportTemplateUseCase.call` again with `resolutions` filled in.
/// When [conflicts] is empty the [imported] list contains every category that
/// was persisted to the repository.
class TemplateImportResult {
  /// Creates a [TemplateImportResult].
  const TemplateImportResult({required this.imported, required this.conflicts});

  /// Categories that were persisted during this invocation.
  final List<Category> imported;

  /// Name conflicts that still need user resolution.
  ///
  /// Empty when the import completed (either all clean or all resolved).
  final List<TemplateNameConflict> conflicts;
}

/// A single name conflict detected during template import.
///
/// The [importedUid] is the **original** UID from the template (before
/// remapping) and is used as the key in the `resolutions` map passed back to
/// `ImportTemplateUseCase.call`.
class TemplateNameConflict {
  /// Creates a [TemplateNameConflict].
  const TemplateNameConflict({
    required this.importedUid,
    required this.importedName,
  });

  /// Original UID of the conflicting entry in the imported template.
  final String importedUid;

  /// The name that already exists in the database.
  final String importedName;
}
