import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/features/categories/domain/models/category.dart';
import 'package:private_statistics/features/categories/domain/models/category_node.dart';
import 'package:private_statistics/features/categories/domain/models/time_model.dart';
import 'package:private_statistics/features/categories/domain/repositories/category_repository.dart';
import 'package:private_statistics/features/template/domain/exceptions.dart';
import 'package:private_statistics/features/template/domain/import_template_use_case.dart';
import 'package:private_statistics/features/template/domain/models/template_entry.dart';
import 'package:private_statistics/features/template/domain/models/template_import_result.dart';
import 'package:private_statistics/features/template/domain/template_file_repository.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _encodeEntries(List<TemplateEntry> entries) =>
    jsonEncode(entries.map((e) => e.toJson()).toList());

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeCategoryRepo implements CategoryRepository {
  _FakeCategoryRepo({List<Category>? initial}) : _initial = initial ?? [];

  final _saved = <Category>[];
  final List<Category> _initial;

  List<Category> get saved => List.unmodifiable(_saved);

  @override
  Future<List<Category>> getAll() async => List.of(_initial);

  @override
  Future<void> save(Category category) async => _saved.add(category);

  // Unused in import tests.
  @override
  Stream<List<CategoryNode>> watchTree() => const Stream.empty();
  @override
  Future<Category?> findByUid(String uid) async => null;
  @override
  Future<void> rename(String uid, String newName) async {}
  @override
  Future<void> delete(String uid) async {}
}

class _FakeFileRepo implements TemplateFileRepository {
  _FakeFileRepo(this._content);

  final String _content;

  @override
  Future<String> pickAndReadTemplateFile() async => _content;

  @override
  Future<String> saveTemplateFile(String json) async => '';
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ImportTemplateUseCase — UID remapping', () {
    test(
      'imported categories receive new UIDs different from source UIDs',
      () async {
        final json = _encodeEntries([
          TemplateEntry(
            uid: 'orig-a',
            name: 'Alpha',
            parentUid: null,
            timeModelIndex: TimeModel.timePoint.index,
            fields: const [],
          ),
        ]);
        final result = await ImportTemplateUseCase(
          _FakeCategoryRepo(),
          _FakeFileRepo(json),
        ).call(resolutions: const {});

        expect(result.imported.length, 1);
        expect(result.imported[0].uid, isNot('orig-a'));
      },
    );

    test(
      'source_uid of imported category equals uid from exported JSON',
      () async {
        final json = _encodeEntries([
          TemplateEntry(
            uid: 'orig-a',
            name: 'Alpha',
            parentUid: null,
            timeModelIndex: TimeModel.timePoint.index,
            fields: const [],
          ),
        ]);
        final result = await ImportTemplateUseCase(
          _FakeCategoryRepo(),
          _FakeFileRepo(json),
        ).call(resolutions: const {});

        expect(result.imported[0].sourceUid, 'orig-a');
      },
    );

    test('parent_uid references are remapped to new UIDs', () async {
      final json = _encodeEntries([
        TemplateEntry(
          uid: 'orig-parent',
          name: 'Parent',
          parentUid: null,
          timeModelIndex: TimeModel.timePoint.index,
          fields: const [],
        ),
        TemplateEntry(
          uid: 'orig-child',
          name: 'Child',
          parentUid: 'orig-parent',
          timeModelIndex: TimeModel.timePoint.index,
          fields: const [],
        ),
      ]);
      final result = await ImportTemplateUseCase(
        _FakeCategoryRepo(),
        _FakeFileRepo(json),
      ).call(resolutions: const {});

      final parent = result.imported.firstWhere((c) => c.name == 'Parent');
      final child = result.imported.firstWhere((c) => c.name == 'Child');
      expect(child.parentUid, parent.uid);
    });
  });

  group('ImportTemplateUseCase — conflict detection', () {
    test(
      'returns conflicts when imported name matches an existing category',
      () async {
        const existing = Category(
          uid: 'existing-1',
          name: 'Existing',
          timeModel: TimeModel.timePoint,
          ownFields: [],
        );
        final json = _encodeEntries([
          TemplateEntry(
            uid: 'new-1',
            name: 'Existing',
            parentUid: null,
            timeModelIndex: TimeModel.timePoint.index,
            fields: const [],
          ),
        ]);
        final result = await ImportTemplateUseCase(
          _FakeCategoryRepo(initial: [existing]),
          _FakeFileRepo(json),
        ).call(resolutions: const {});

        expect(result.conflicts.length, 1);
        expect(result.conflicts[0].importedName, 'Existing');
        expect(result.imported, isEmpty);
      },
    );

    test('"keep both" inserts the imported category even though the name '
        'already exists', () async {
      const existing = Category(
        uid: 'existing-1',
        name: 'Existing',
        timeModel: TimeModel.timePoint,
        ownFields: [],
      );
      final json = _encodeEntries([
        TemplateEntry(
          uid: 'new-1',
          name: 'Existing',
          parentUid: null,
          timeModelIndex: TimeModel.timePoint.index,
          fields: const [],
        ),
      ]);
      final result = await ImportTemplateUseCase(
        _FakeCategoryRepo(initial: [existing]),
        _FakeFileRepo(json),
      ).call(resolutions: const {'new-1': ConflictResolution.keepBoth});

      expect(result.imported.length, 1);
      expect(result.imported[0].name, 'Existing');
      expect(result.conflicts, isEmpty);
    });

    test('"discard import" skips the conflicting category', () async {
      const existing = Category(
        uid: 'existing-1',
        name: 'Existing',
        timeModel: TimeModel.timePoint,
        ownFields: [],
      );
      final json = _encodeEntries([
        TemplateEntry(
          uid: 'new-1',
          name: 'Existing',
          parentUid: null,
          timeModelIndex: TimeModel.timePoint.index,
          fields: const [],
        ),
        TemplateEntry(
          uid: 'new-2',
          name: 'Unique',
          parentUid: null,
          timeModelIndex: TimeModel.timePoint.index,
          fields: const [],
        ),
      ]);
      final result = await ImportTemplateUseCase(
        _FakeCategoryRepo(initial: [existing]),
        _FakeFileRepo(json),
      ).call(resolutions: const {'new-1': ConflictResolution.discard});

      expect(result.imported.length, 1);
      expect(result.imported[0].name, 'Unique');
      expect(result.conflicts, isEmpty);
    });
  });

  group('ImportTemplateUseCase — malformed JSON', () {
    test('throws MalformedTemplateException for invalid JSON', () async {
      await expectLater(
        ImportTemplateUseCase(
          _FakeCategoryRepo(),
          _FakeFileRepo('not json at all'),
        ).call(resolutions: const {}),
        throwsA(isA<MalformedTemplateException>()),
      );
    });

    test(
      'throws MalformedTemplateException when root is not a JSON array',
      () async {
        await expectLater(
          ImportTemplateUseCase(
            _FakeCategoryRepo(),
            _FakeFileRepo('{"uid": "x"}'),
          ).call(resolutions: const {}),
          throwsA(isA<MalformedTemplateException>()),
        );
      },
    );
  });
}
