import 'dart:convert';
import 'dart:math';

import 'package:private_statistics/core/logging/app_logger.dart';
import 'package:private_statistics/features/categories/domain/models/category.dart';
import 'package:private_statistics/features/categories/domain/models/field.dart';
import 'package:private_statistics/features/categories/domain/models/field_constraint.dart';
import 'package:private_statistics/features/categories/domain/models/field_type.dart';
import 'package:private_statistics/features/categories/domain/models/time_model.dart';
import 'package:private_statistics/features/categories/domain/repositories/category_repository.dart';
import 'package:private_statistics/features/template/domain/exceptions.dart';
import 'package:private_statistics/features/template/domain/models/template_entry.dart';
import 'package:private_statistics/features/template/domain/models/template_import_result.dart';
import 'package:private_statistics/features/template/domain/template_file_repository.dart';

/// Imports a JSON template file, remapping UIDs and resolving name conflicts.
///
/// **Two-pass flow:**
/// 1. Call [call] with an empty `resolutions` map. If
///    `TemplateImportResult.conflicts` is non-empty, present the conflict
///    dialog to the user.
/// 2. Call [call] again with a filled-in `resolutions` map
///    (`importedUid → ConflictResolution`). The use-case re-reads the same
///    file and applies the resolutions.
///
/// Throws [MalformedTemplateException] if the file content is not a valid
/// template JSON array. Throws [TemplateCancelledException] if the user
/// dismisses the picker.
class ImportTemplateUseCase {
  /// Creates an [ImportTemplateUseCase].
  const ImportTemplateUseCase(this._categoryRepo, this._fileRepo);

  final CategoryRepository _categoryRepo;
  final TemplateFileRepository _fileRepo;

  static final _random = Random.secure();

  static String _newUid() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final suffix = _random.nextInt(999999).toString().padLeft(6, '0');
    return '$ts-$suffix';
  }

  /// Picks and imports a template file.
  ///
  /// [resolutions] maps the **original** UID of a conflicting entry to the
  /// user's chosen [ConflictResolution]. Pass an empty map on the first call.
  Future<TemplateImportResult> call({
    required Map<String, ConflictResolution> resolutions,
  }) async {
    final json = await _fileRepo.pickAndReadTemplateFile();
    final entries = _parse(json);

    final existing = await _categoryRepo.getAll();
    final existingNames = existing.map((c) => c.name.toLowerCase()).toSet();

    // ── UID remap table ──────────────────────────────────────────────────
    final uidMap = <String, String>{for (final e in entries) e.uid: _newUid()};

    // ── Conflict detection ───────────────────────────────────────────────
    final conflicts = <TemplateNameConflict>[];
    final discarded = <String>{};

    for (final entry in entries) {
      final resolution = resolutions[entry.uid];
      if (resolution != null) {
        if (resolution == ConflictResolution.discard) discarded.add(entry.uid);
        continue; // already resolved
      }
      if (existingNames.contains(entry.name.toLowerCase())) {
        conflicts.add(
          TemplateNameConflict(
            importedUid: entry.uid,
            importedName: entry.name,
          ),
        );
      }
    }

    if (conflicts.isNotEmpty) {
      return TemplateImportResult(imported: const [], conflicts: conflicts);
    }

    // ── Persist ──────────────────────────────────────────────────────────
    final imported = <Category>[];
    for (final entry in entries) {
      if (discarded.contains(entry.uid)) continue;

      final newUid = uidMap[entry.uid]!;
      final newParentUid = entry.parentUid != null
          ? uidMap[entry.parentUid]
          : null;

      final fields = _toFields(entry.fields, newUid);
      final category = Category(
        uid: newUid,
        name: entry.name,
        parentUid: newParentUid,
        sourceUid: entry.uid,
        timeModel: TimeModel.values[entry.timeModelIndex],
        ownFields: fields,
      );

      await _categoryRepo.save(category);
      imported.add(category);
    }

    AppLogger.info('Template imported: ${imported.length} categories');
    return TemplateImportResult(imported: imported, conflicts: const []);
  }

  List<TemplateEntry> _parse(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is! List) {
        throw MalformedTemplateException('expected a JSON array');
      }
      return decoded
          .map((e) => TemplateEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } on MalformedTemplateException {
      rethrow;
    } on Object catch (e) {
      throw MalformedTemplateException(e.toString());
    }
  }

  List<Field> _toFields(List<TemplateFieldEntry> entries, String categoryUid) =>
      entries.map((f) {
        final constraint = (f.constraintMin != null || f.constraintMax != null)
            ? FieldConstraint(min: f.constraintMin, max: f.constraintMax)
            : null;
        return Field(
          uid: _newUid(),
          categoryUid: categoryUid,
          name: f.name,
          fieldType: FieldType.values[f.fieldTypeIndex],
          sortOrder: f.sortOrder,
          unit: f.unit,
          constraint: constraint,
          enumOptions: f.enumOptions,
        );
      }).toList();
}
