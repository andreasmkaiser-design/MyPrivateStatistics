import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/core/database/app_database.dart';
import 'package:private_statistics/features/categories/data/category_repository_impl.dart';
import 'package:private_statistics/features/categories/domain/exceptions.dart';
import 'package:private_statistics/features/categories/domain/models/category.dart';
import 'package:private_statistics/features/categories/domain/models/field.dart';
import 'package:private_statistics/features/categories/domain/models/field_constraint.dart';
import 'package:private_statistics/features/categories/domain/models/field_type.dart';
import 'package:private_statistics/features/categories/domain/models/resolved_field.dart';
import 'package:private_statistics/features/categories/domain/models/time_model.dart';

void main() {
  late AppDatabase db;
  late CategoryRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = CategoryRepositoryImpl(db);
  });

  tearDown(() async => db.close());

  Category makeCategory({
    required String uid,
    required String name,
    String? parentUid,
    TimeModel timeModel = TimeModel.timePoint,
    List<Field> ownFields = const [],
  }) => Category(
    uid: uid,
    name: name,
    parentUid: parentUid,
    timeModel: timeModel,
    ownFields: ownFields,
  );

  Field makeField({
    required String uid,
    required String categoryUid,
    required FieldType fieldType,
    int sortOrder = 0,
    FieldConstraint? constraint,
    String? unit,
    List<String> enumOptions = const [],
  }) => Field(
    uid: uid,
    categoryUid: categoryUid,
    name: uid,
    fieldType: fieldType,
    sortOrder: sortOrder,
    constraint: constraint,
    unit: unit,
    enumOptions: enumOptions,
  );

  test(
    'create root category with all four field types and read back correctly',
    () async {
      final cat = makeCategory(
        uid: 'cat1',
        name: 'Sport',
        ownFields: [
          makeField(
            uid: 'f1',
            categoryUid: 'cat1',
            fieldType: FieldType.integer,
          ),
          makeField(
            uid: 'f2',
            categoryUid: 'cat1',
            fieldType: FieldType.float,
            sortOrder: 1,
            unit: 'km',
          ),
          makeField(
            uid: 'f3',
            categoryUid: 'cat1',
            fieldType: FieldType.boolean,
            sortOrder: 2,
          ),
          makeField(
            uid: 'f4',
            categoryUid: 'cat1',
            fieldType: FieldType.enumeration,
            sortOrder: 3,
            enumOptions: ['easy', 'hard'],
          ),
        ],
      );

      await repo.save(cat);
      final found = await repo.findByUid('cat1');

      expect(found, isNotNull);
      expect(found!.uid, equals('cat1'));
      expect(found.name, equals('Sport'));
      expect(found.ownFields, hasLength(4));
      expect(found.ownFields[0].fieldType, equals(FieldType.integer));
      expect(found.ownFields[1].fieldType, equals(FieldType.float));
      expect(found.ownFields[1].unit, equals('km'));
      expect(found.ownFields[2].fieldType, equals(FieldType.boolean));
      expect(found.ownFields[3].fieldType, equals(FieldType.enumeration));
      expect(found.ownFields[3].enumOptions, equals(['easy', 'hard']));
    },
  );

  test('watchTree emits root category', () async {
    await repo.save(makeCategory(uid: 'root', name: 'Root'));

    final nodes = await repo.watchTree().first;

    expect(nodes, hasLength(1));
    expect(nodes[0].category.uid, equals('root'));
    expect(nodes[0].category.name, equals('Root'));
  });

  test('subcategory appears as child with inherited + own schema', () async {
    final parent = makeCategory(
      uid: 'parent',
      name: 'Parent',
      ownFields: [
        makeField(
          uid: 'pf1',
          categoryUid: 'parent',
          fieldType: FieldType.integer,
        ),
      ],
    );
    final child = makeCategory(
      uid: 'child',
      name: 'Child',
      parentUid: 'parent',
      ownFields: [
        makeField(
          uid: 'cf1',
          categoryUid: 'child',
          fieldType: FieldType.boolean,
        ),
      ],
    );
    await repo.save(parent);
    await repo.save(child);

    final nodes = await repo.watchTree().first;

    expect(nodes, hasLength(1));
    final parentNode = nodes[0];
    expect(parentNode.children, hasLength(1));
    final childNode = parentNode.children[0];
    expect(childNode.mergedSchema, hasLength(2));
    expect(
      childNode.mergedSchema
          .firstWhere((ResolvedField r) => r.field.uid == 'pf1')
          .isInherited,
      isTrue,
    );
    expect(
      childNode.mergedSchema
          .firstWhere((ResolvedField r) => r.field.uid == 'cf1')
          .isInherited,
      isFalse,
    );
  });

  test('delete parent cascades to all descendants', () async {
    await repo.save(makeCategory(uid: 'p', name: 'Parent'));
    await repo.save(makeCategory(uid: 'c', name: 'Child', parentUid: 'p'));
    await repo.save(
      makeCategory(uid: 'gc', name: 'Grandchild', parentUid: 'c'),
    );

    await repo.delete('p');

    expect(await repo.findByUid('p'), isNull);
    expect(await repo.findByUid('c'), isNull);
    expect(await repo.findByUid('gc'), isNull);
  });

  test('rename persists correctly', () async {
    await repo.save(makeCategory(uid: 'cat1', name: 'Old Name'));
    await repo.rename('cat1', 'New Name');

    final found = await repo.findByUid('cat1');
    expect(found!.name, equals('New Name'));
  });

  test('float field constraint values stored with full precision', () async {
    final cat = makeCategory(
      uid: 'cat1',
      name: 'Cat',
      ownFields: [
        makeField(
          uid: 'f1',
          categoryUid: 'cat1',
          fieldType: FieldType.float,
          constraint: const FieldConstraint(
            min: 0.123456789,
            max: 99.987654321,
          ),
        ),
      ],
    );

    await repo.save(cat);
    final found = await repo.findByUid('cat1');

    expect(found!.ownFields[0].constraint!.min, closeTo(0.123456789, 1e-9));
    expect(found.ownFields[0].constraint!.max, closeTo(99.987654321, 1e-9));
  });

  test(
    'save throws CategoryDepthLimitExceededException for 6th level',
    () async {
      for (var i = 0; i < 5; i++) {
        await repo.save(
          makeCategory(
            uid: 'c$i',
            name: 'Level $i',
            parentUid: i == 0 ? null : 'c${i - 1}',
          ),
        );
      }

      await expectLater(
        repo.save(makeCategory(uid: 'c5', name: 'Level 5', parentUid: 'c4')),
        throwsA(isA<CategoryDepthLimitExceededException>()),
      );
    },
  );

  // ── watchTree reactivity ─────────────────────────────────────────────────

  test('watchTree re-emits after save()', () async {
    // Drain the initial empty-tree emission so the subscription's first query
    // completes before we write. Without this, the initial query and the
    // change notification race and skip(1) may consume the change emission.
    expect(await repo.watchTree().first, isEmpty);

    // Subscribe for the second emission, then write.
    final secondEmission = repo.watchTree().skip(1).first;
    await repo.save(makeCategory(uid: 'r1', name: 'Running'));

    final nodes = await secondEmission;
    expect(nodes, hasLength(1));
    expect(nodes.first.category.uid, equals('r1'));
  });

  test('watchTree re-emits after rename()', () async {
    await repo.save(makeCategory(uid: 'r1', name: 'Running'));

    // Subscribe after the initial save; skip the current-state emission.
    final secondEmission = repo.watchTree().skip(1).first;

    await repo.rename('r1', 'Yoga');

    final nodes = await secondEmission;
    expect(nodes.first.category.name, equals('Yoga'));
  });

  test('watchTree re-emits after delete()', () async {
    await repo.save(makeCategory(uid: 'r1', name: 'Running'));

    // Subscribe after the initial save; skip the current-state emission.
    final secondEmission = repo.watchTree().skip(1).first;

    await repo.delete('r1');

    final nodes = await secondEmission;
    expect(nodes, isEmpty);
  });
}
