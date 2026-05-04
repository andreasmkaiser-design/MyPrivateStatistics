import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/core/database/app_database.dart';
import 'package:private_statistics/features/categories/data/category_repository_impl.dart';
import 'package:private_statistics/features/categories/domain/models/category.dart';
import 'package:private_statistics/features/categories/domain/models/field.dart';
import 'package:private_statistics/features/categories/domain/models/field_constraint.dart';
import 'package:private_statistics/features/categories/domain/models/field_type.dart';
import 'package:private_statistics/features/categories/domain/models/time_model.dart';
import 'package:private_statistics/features/events/data/event_repository_impl.dart';
import 'package:private_statistics/features/events/domain/exceptions.dart';
import 'package:private_statistics/features/events/domain/models/event.dart';
import 'package:private_statistics/features/events/domain/models/field_value.dart';
import 'package:private_statistics/features/events/domain/models/time_point.dart';

void main() {
  late AppDatabase db;
  late EventRepositoryImpl repo;
  late CategoryRepositoryImpl categoryRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = EventRepositoryImpl(db);
    categoryRepo = CategoryRepositoryImpl(db);
  });

  tearDown(() async => db.close());

  Future<void> seedCategory({
    String uid = 'cat1',
    List<Field> fields = const [],
  }) async {
    await categoryRepo.save(
      Category(
        uid: uid,
        name: 'Test Category',
        timeModel: TimeModel.timePoint,
        ownFields: fields,
      ),
    );
  }

  Field makeField({
    required String uid,
    required String categoryUid,
    required FieldType fieldType,
    int sortOrder = 0,
    FieldConstraint? constraint,
    List<String> enumOptions = const [],
  }) => Field(
    uid: uid,
    categoryUid: categoryUid,
    name: uid,
    fieldType: fieldType,
    sortOrder: sortOrder,
    constraint: constraint,
    enumOptions: enumOptions,
  );

  test(
    'create event with all four field types and read back correctly',
    () async {
      await seedCategory(
        fields: [
          makeField(
            uid: 'f-int',
            categoryUid: 'cat1',
            fieldType: FieldType.integer,
          ),
          makeField(
            uid: 'f-float',
            categoryUid: 'cat1',
            fieldType: FieldType.float,
            sortOrder: 1,
          ),
          makeField(
            uid: 'f-bool',
            categoryUid: 'cat1',
            fieldType: FieldType.boolean,
            sortOrder: 2,
          ),
          makeField(
            uid: 'f-enum',
            categoryUid: 'cat1',
            fieldType: FieldType.enumeration,
            sortOrder: 3,
            enumOptions: ['a', 'b'],
          ),
        ],
      );

      await repo.save(
        Event(
          uid: 'e1',
          categoryUid: 'cat1',
          occurredAt: TimePoint(date: DateTime(2026, 5, 4)),
          fieldValues: const [
            IntFieldValue(fieldUid: 'f-int', value: 42),
            FloatFieldValue(fieldUid: 'f-float', value: 3.14),
            BoolFieldValue(fieldUid: 'f-bool', value: true),
            EnumFieldValue(fieldUid: 'f-enum', value: 'a'),
          ],
        ),
      );

      final found = await repo.findByUid('e1');

      expect(found, isNotNull);
      expect(found!.uid, equals('e1'));
      expect(found.categoryUid, equals('cat1'));
      expect(found.fieldValues, hasLength(4));
      expect(
        found.fieldValues.whereType<IntFieldValue>().first.value,
        equals(42),
      );
      expect(
        found.fieldValues.whereType<FloatFieldValue>().first.value,
        closeTo(3.14, 1e-9),
      );
      expect(found.fieldValues.whereType<BoolFieldValue>().first.value, isTrue);
      expect(
        found.fieldValues.whereType<EnumFieldValue>().first.value,
        equals('a'),
      );
    },
  );

  test('query by day returns events on that day and excludes others', () async {
    await seedCategory();

    await repo.save(
      Event(
        uid: 'e-day1',
        categoryUid: 'cat1',
        occurredAt: TimePoint(date: DateTime(2026, 5, 4)),
        fieldValues: const [],
      ),
    );
    await repo.save(
      Event(
        uid: 'e-day2',
        categoryUid: 'cat1',
        occurredAt: TimePoint(date: DateTime(2026, 5, 5)),
        fieldValues: const [],
      ),
    );

    final day1Events = await repo.watchByDay(DateTime(2026, 5, 4)).first;
    expect(day1Events, hasLength(1));
    expect(day1Events.first.uid, equals('e-day1'));
  });

  test('update event persists all field value changes', () async {
    await seedCategory(
      fields: [
        makeField(
          uid: 'f-int',
          categoryUid: 'cat1',
          fieldType: FieldType.integer,
        ),
        makeField(
          uid: 'f-bool',
          categoryUid: 'cat1',
          fieldType: FieldType.boolean,
          sortOrder: 1,
        ),
      ],
    );

    await repo.save(
      Event(
        uid: 'e1',
        categoryUid: 'cat1',
        occurredAt: TimePoint(date: DateTime(2026, 5, 4)),
        fieldValues: const [
          IntFieldValue(fieldUid: 'f-int', value: 10),
          BoolFieldValue(fieldUid: 'f-bool', value: false),
        ],
      ),
    );

    await repo.save(
      Event(
        uid: 'e1',
        categoryUid: 'cat1',
        occurredAt: TimePoint(
          date: DateTime(2026, 5, 4),
          clockTime: DateTime(2026, 5, 4, 14),
        ),
        fieldValues: const [
          IntFieldValue(fieldUid: 'f-int', value: 99),
          BoolFieldValue(fieldUid: 'f-bool', value: true),
        ],
      ),
    );

    final found = await repo.findByUid('e1');
    expect(found!.occurredAt.clockTime, isNotNull);
    expect(
      found.fieldValues.whereType<IntFieldValue>().first.value,
      equals(99),
    );
    expect(found.fieldValues.whereType<BoolFieldValue>().first.value, isTrue);
  });

  test('delete removes event from subsequent day queries', () async {
    await seedCategory();

    await repo.save(
      Event(
        uid: 'e1',
        categoryUid: 'cat1',
        occurredAt: TimePoint(date: DateTime(2026, 5, 4)),
        fieldValues: const [],
      ),
    );

    await repo.delete('e1');

    final events = await repo.watchByDay(DateTime(2026, 5, 4)).first;
    expect(events, isEmpty);
  });

  test('integer field rejects value below min constraint', () async {
    await seedCategory(
      fields: [
        makeField(
          uid: 'f-int',
          categoryUid: 'cat1',
          fieldType: FieldType.integer,
          constraint: const FieldConstraint(min: 0, max: 10),
        ),
      ],
    );

    await expectLater(
      repo.save(
        Event(
          uid: 'e1',
          categoryUid: 'cat1',
          occurredAt: TimePoint(date: DateTime(2026, 5, 4)),
          fieldValues: const [IntFieldValue(fieldUid: 'f-int', value: -1)],
        ),
      ),
      throwsA(isA<EventFieldConstraintViolationException>()),
    );
  });

  test('integer field rejects value above max constraint', () async {
    await seedCategory(
      fields: [
        makeField(
          uid: 'f-int',
          categoryUid: 'cat1',
          fieldType: FieldType.integer,
          constraint: const FieldConstraint(min: 0, max: 10),
        ),
      ],
    );

    await expectLater(
      repo.save(
        Event(
          uid: 'e1',
          categoryUid: 'cat1',
          occurredAt: TimePoint(date: DateTime(2026, 5, 4)),
          fieldValues: const [IntFieldValue(fieldUid: 'f-int', value: 11)],
        ),
      ),
      throwsA(isA<EventFieldConstraintViolationException>()),
    );
  });

  test('float field rejects out-of-range value', () async {
    await seedCategory(
      fields: [
        makeField(
          uid: 'f-float',
          categoryUid: 'cat1',
          fieldType: FieldType.float,
          constraint: const FieldConstraint(min: 0, max: 100),
        ),
      ],
    );

    await expectLater(
      repo.save(
        Event(
          uid: 'e1',
          categoryUid: 'cat1',
          occurredAt: TimePoint(date: DateTime(2026, 5, 4)),
          fieldValues: const [
            FloatFieldValue(fieldUid: 'f-float', value: 150.5),
          ],
        ),
      ),
      throwsA(isA<EventFieldConstraintViolationException>()),
    );
  });
}
