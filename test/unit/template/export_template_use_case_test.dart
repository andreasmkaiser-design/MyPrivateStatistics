import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/features/categories/domain/models/category.dart';
import 'package:private_statistics/features/categories/domain/models/category_node.dart';
import 'package:private_statistics/features/categories/domain/models/field.dart';
import 'package:private_statistics/features/categories/domain/models/field_type.dart';
import 'package:private_statistics/features/categories/domain/models/time_model.dart';
import 'package:private_statistics/features/categories/domain/repositories/category_repository.dart';
import 'package:private_statistics/features/template/domain/export_template_use_case.dart';
import 'package:private_statistics/features/template/domain/template_file_repository.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeCategoryRepo implements CategoryRepository {
  _FakeCategoryRepo(this._all);

  final List<Category> _all;

  @override
  Future<List<Category>> getAll() async => _all;

  // Unused in export tests.
  @override
  Stream<List<CategoryNode>> watchTree() => const Stream.empty();
  @override
  Future<Category?> findByUid(String uid) async => null;
  @override
  Future<void> save(Category category) async {}
  @override
  Future<void> rename(String uid, String newName) async {}
  @override
  Future<void> delete(String uid) async {}
}

class _FakeFileRepo implements TemplateFileRepository {
  static const savedPath = '/sdcard/template.json';

  String? savedJson;

  @override
  Future<String> saveTemplateFile(String json) async {
    savedJson = json;
    return savedPath;
  }

  @override
  Future<String> pickAndReadTemplateFile() async => '';
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ExportTemplateUseCase', () {
    test('JSON contains uid, source_uid=null, parent_uid and fields '
        'for every category', () async {
      final categories = [
        const Category(
          uid: 'cat-a',
          name: 'Root',
          timeModel: TimeModel.timePoint,
          ownFields: [
            Field(
              uid: 'f-1',
              categoryUid: 'cat-a',
              name: 'Score',
              fieldType: FieldType.integer,
              sortOrder: 0,
            ),
          ],
        ),
        const Category(
          uid: 'cat-b',
          name: 'Child',
          parentUid: 'cat-a',
          timeModel: TimeModel.timePoint,
          ownFields: [],
        ),
      ];
      final fileRepo = _FakeFileRepo();
      await ExportTemplateUseCase(
        _FakeCategoryRepo(categories),
        fileRepo,
      ).call();

      final decoded = jsonDecode(fileRepo.savedJson!) as List<dynamic>;
      expect(decoded.length, 2);

      final rootMap =
          decoded.firstWhere((e) => (e as Map)['uid'] == 'cat-a')
              as Map<String, dynamic>;
      expect(rootMap['source_uid'], isNull);
      expect(rootMap['parent_uid'], isNull);
      expect((rootMap['fields'] as List<dynamic>).length, 1);
      expect(((rootMap['fields'] as List<dynamic>)[0] as Map)['name'], 'Score');

      final childMap =
          decoded.firstWhere((e) => (e as Map)['uid'] == 'cat-b')
              as Map<String, dynamic>;
      expect(childMap['parent_uid'], 'cat-a');
    });

    test('returns the destination path from the file repository', () async {
      final fileRepo = _FakeFileRepo();
      final path = await ExportTemplateUseCase(
        _FakeCategoryRepo([]),
        fileRepo,
      ).call();
      expect(path, _FakeFileRepo.savedPath);
    });
  });
}
