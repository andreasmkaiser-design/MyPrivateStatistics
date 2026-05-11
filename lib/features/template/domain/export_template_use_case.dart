import 'dart:convert';

import 'package:private_statistics/core/logging/app_logger.dart';
import 'package:private_statistics/features/categories/domain/models/category.dart';
import 'package:private_statistics/features/categories/domain/repositories/category_repository.dart';
import 'package:private_statistics/features/template/domain/models/template_entry.dart';
import 'package:private_statistics/features/template/domain/template_file_repository.dart';

/// Serialises the full category hierarchy to a flat JSON template file.
///
/// Throws `TemplateCancelledException` if the user dismisses the SAF picker.
/// Throws `TemplateException` on I/O failure.
class ExportTemplateUseCase {
  /// Creates an [ExportTemplateUseCase].
  const ExportTemplateUseCase(this._categoryRepo, this._fileRepo);

  final CategoryRepository _categoryRepo;
  final TemplateFileRepository _fileRepo;

  /// Exports the template and returns the destination path.
  Future<String> call() async {
    final categories = await _categoryRepo.getAll();
    final json = _encode(categories);
    final path = await _fileRepo.saveTemplateFile(json);
    AppLogger.info('Template exported: ${categories.length} categories');
    return path;
  }

  String _encode(List<Category> categories) {
    final entries = categories
        .map(
          (c) => TemplateEntry(
            uid: c.uid,
            name: c.name,
            parentUid: c.parentUid,
            sourceUid: c.sourceUid,
            timeModelIndex: c.timeModel.index,
            fields: c.ownFields.map(TemplateFieldEntry.fromField).toList(),
          ).toJson(),
        )
        .toList();
    return jsonEncode(entries);
  }
}
