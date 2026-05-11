/// Port: file-system and SAF operations for JSON template export and import.
///
/// The production implementation uses `file_picker` for SAF-based destination
/// and source picking. Substitute a fake in tests.
abstract interface class TemplateFileRepository {
  /// Opens the Android SAF save-picker and writes [json] to the chosen file.
  ///
  /// Returns the destination path written to.
  /// Throws `TemplateCancelledException` if the user dismissed the picker.
  Future<String> saveTemplateFile(String json);

  /// Opens the Android SAF open-picker and returns the content of the chosen
  /// JSON file as a [String].
  ///
  /// Throws `TemplateCancelledException` if the user dismissed the picker.
  Future<String> pickAndReadTemplateFile();
}
