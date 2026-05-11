import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:private_statistics/features/template/domain/exceptions.dart';
import 'package:private_statistics/features/template/domain/template_file_repository.dart';

/// Production implementation of [TemplateFileRepository] using [FilePicker]
/// for Android SAF-based file save and open dialogs.
class TemplateFileRepositoryImpl implements TemplateFileRepository {
  /// Creates a [TemplateFileRepositoryImpl].
  const TemplateFileRepositoryImpl();

  @override
  Future<String> saveTemplateFile(String json) async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save template',
      fileName: 'categories_template.json',
      bytes: utf8.encode(json),
    );

    if (result == null) throw const TemplateCancelledException();
    return result;
  }

  @override
  Future<String> pickAndReadTemplateFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select template file',
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      throw const TemplateCancelledException();
    }

    final bytes = result.files.single.bytes;
    if (bytes == null) throw const TemplateCancelledException();

    return utf8.decode(bytes);
  }
}
