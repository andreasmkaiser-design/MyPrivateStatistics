// Integration test: uses the real CategoryRepositoryImpl + AppDatabase
// to verify the full export → clear → import round-trip.
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/core/database/app_database.dart';
import 'package:private_statistics/features/categories/data/category_repository_impl.dart';
import 'package:private_statistics/features/categories/domain/models/category.dart';
import 'package:private_statistics/features/categories/domain/models/field.dart';
import 'package:private_statistics/features/categories/domain/models/field_type.dart';
import 'package:private_statistics/features/categories/domain/models/time_model.dart';
import 'package:private_statistics/features/template/domain/export_template_use_case.dart';
import 'package:private_statistics/features/template/domain/import_template_use_case.dart';
import 'package:private_statistics/features/template/domain/template_file_repository.dart';

// ---------------------------------------------------------------------------
// Fake file repository that passes JSON through memory
// ---------------------------------------------------------------------------

class _MemoryFileRepo implements TemplateFileRepository {
  String _stored = '';

  @override
  Future<String> saveTemplateFile(String json) async {
    _stored = json;
    return '/memory/template.json';
  }

  @override
  Future<String> pickAndReadTemplateFile() async => _stored;
}

// ---------------------------------------------------------------------------
// Integration test
// ---------------------------------------------------------------------------

void main() {
  late AppDatabase db;
  late CategoryRepositoryImpl repo;
  late _MemoryFileRepo fileRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = CategoryRepositoryImpl(db);
    fileRepo = _MemoryFileRepo();
  });

  tearDown(() async => db.close());

  test('export → clear → import restores full hierarchy with new UIDs and '
      'correct source_uids', () async {
    // ── Seed a 3-level hierarchy ─────────────────────────────────────────
    const root = Category(
      uid: 'uid-root',
      name: 'Root',
      timeModel: TimeModel.timePoint,
      ownFields: [
        Field(
          uid: 'uid-field-1',
          categoryUid: 'uid-root',
          name: 'Score',
          fieldType: FieldType.integer,
          sortOrder: 0,
        ),
      ],
    );
    const child = Category(
      uid: 'uid-child',
      name: 'Child',
      parentUid: 'uid-root',
      timeModel: TimeModel.dayPreciseRange,
      ownFields: [],
    );
    const grandchild = Category(
      uid: 'uid-grandchild',
      name: 'Grandchild',
      parentUid: 'uid-child',
      timeModel: TimeModel.timePoint,
      ownFields: [],
    );
    await repo.save(root);
    await repo.save(child);
    await repo.save(grandchild);

    // ── Export ───────────────────────────────────────────────────────────
    await ExportTemplateUseCase(repo, fileRepo).call();
    expect(fileRepo._stored, isNotEmpty);

    // Verify exported JSON structure
    final exported = (jsonDecode(fileRepo._stored) as List<dynamic>)
        .cast<Map<String, dynamic>>();
    expect(exported.length, 3);
    final exportedRoot = exported.firstWhere((e) => e['uid'] == 'uid-root');
    expect(exportedRoot['source_uid'], isNull);
    expect((exportedRoot['fields'] as List<dynamic>).length, 1);

    // ── Clear ────────────────────────────────────────────────────────────
    await repo.delete('uid-root'); // cascades to child + grandchild
    expect(await repo.getAll(), isEmpty);

    // ── Import ───────────────────────────────────────────────────────────
    final result = await ImportTemplateUseCase(
      repo,
      fileRepo,
    ).call(resolutions: const {});

    expect(result.conflicts, isEmpty);
    expect(result.imported.length, 3);

    // ── Verify: new UIDs, source_uid = original uid ──────────────────────
    final importedRoot = result.imported.firstWhere((c) => c.name == 'Root');
    final importedChild = result.imported.firstWhere((c) => c.name == 'Child');
    final importedGc = result.imported.firstWhere(
      (c) => c.name == 'Grandchild',
    );

    expect(importedRoot.uid, isNot('uid-root'));
    expect(importedRoot.sourceUid, 'uid-root');
    expect(importedRoot.ownFields.length, 1);
    expect(importedRoot.ownFields[0].name, 'Score');

    expect(importedChild.uid, isNot('uid-child'));
    expect(importedChild.sourceUid, 'uid-child');
    expect(importedChild.parentUid, importedRoot.uid);
    expect(importedChild.timeModel, TimeModel.dayPreciseRange);

    expect(importedGc.parentUid, importedChild.uid);
    expect(importedGc.sourceUid, 'uid-grandchild');

    // ── Verify persistence in DB ─────────────────────────────────────────
    final inDb = await repo.getAll();
    expect(inDb.length, 3);
    expect(inDb.map((c) => c.name).toSet(), {'Root', 'Child', 'Grandchild'});
  });
}
