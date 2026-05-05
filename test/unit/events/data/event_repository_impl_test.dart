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
import 'package:private_statistics/features/events/domain/models/event_time.dart';
import 'package:private_statistics/features/events/domain/models/field_value.dart';

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
    TimeModel timeModel = TimeModel.timePoint,
    List<Field> fields = const [],
  }) async {
    await categoryRepo.save(
      Category(
        uid: uid,
        name: 'Test Category',
        timeModel: timeModel,
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

  // ── Time-point tests (existing) ───────────────────────────────────────────

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
    expect((found!.occurredAt as TimePoint).clockTime, isNotNull);
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

  // ── Day-precise range tests ───────────────────────────────────────────────

  test('day-precise range event stored and read back correctly', () async {
    await seedCategory(timeModel: TimeModel.dayPreciseRange);

    await repo.save(
      Event(
        uid: 'r1',
        categoryUid: 'cat1',
        occurredAt: DayPreciseRange(
          from: DateTime(2026, 5, 4),
          to: DateTime(2026, 5, 6),
        ),
        fieldValues: const [],
      ),
    );

    final found = await repo.findByUid('r1');
    expect(found, isNotNull);
    final range = found!.occurredAt as DayPreciseRange;
    expect(range.from, equals(DateTime(2026, 5, 4)));
    expect(range.to, equals(DateTime(2026, 5, 6)));
  });

  test(
    'day-precise range spanning 3 days appears in all 3 day queries',
    () async {
      await seedCategory(timeModel: TimeModel.dayPreciseRange);

      await repo.save(
        Event(
          uid: 'r1',
          categoryUid: 'cat1',
          occurredAt: DayPreciseRange(
            from: DateTime(2026, 5, 4),
            to: DateTime(2026, 5, 6),
          ),
          fieldValues: const [],
        ),
      );

      for (final day in [
        DateTime(2026, 5, 4),
        DateTime(2026, 5, 5),
        DateTime(2026, 5, 6),
      ]) {
        final events = await repo.watchByDay(day).first;
        expect(events, hasLength(1), reason: 'Expected event on ${day.day}');
        expect(events.first.uid, equals('r1'));
      }

      // Day outside the range must not contain the event.
      final outside = await repo.watchByDay(DateTime(2026, 5, 7)).first;
      expect(outside, isEmpty);
    },
  );

  test(
    'watchDaysWithEventsInMonth returns all days spanned by range event',
    () async {
      await seedCategory(timeModel: TimeModel.dayPreciseRange);

      await repo.save(
        Event(
          uid: 'r1',
          categoryUid: 'cat1',
          occurredAt: DayPreciseRange(
            from: DateTime(2026, 5, 4),
            to: DateTime(2026, 5, 6),
          ),
          fieldValues: const [],
        ),
      );

      final days = await repo
          .watchDaysWithEventsInMonth(DateTime(2026, 5))
          .first;
      expect(
        days,
        containsAll([
          DateTime(2026, 5, 4),
          DateTime(2026, 5, 5),
          DateTime(2026, 5, 6),
        ]),
      );
      expect(days, hasLength(3));
    },
  );

  test('day-precise range: to-date before from-date is rejected', () async {
    await seedCategory(timeModel: TimeModel.dayPreciseRange);

    await expectLater(
      repo.save(
        Event(
          uid: 'r-bad',
          categoryUid: 'cat1',
          occurredAt: DayPreciseRange(
            from: DateTime(2026, 5, 6),
            to: DateTime(2026, 5, 4),
          ),
          fieldValues: const [],
        ),
      ),
      throwsA(isA<EventRangeInvalidException>()),
    );
  });

  // ── Datetime-precise range tests ──────────────────────────────────────────

  test('datetime-precise range event stored and read back correctly', () async {
    await seedCategory(timeModel: TimeModel.datetimePreciseRange);

    await repo.save(
      Event(
        uid: 'dt1',
        categoryUid: 'cat1',
        occurredAt: DatetimePreciseRange(
          from: DateTime(2026, 5, 4, 10),
          to: DateTime(2026, 5, 4, 14, 30),
        ),
        fieldValues: const [],
      ),
    );

    final found = await repo.findByUid('dt1');
    expect(found, isNotNull);
    final range = found!.occurredAt as DatetimePreciseRange;
    expect(range.from, equals(DateTime(2026, 5, 4, 10)));
    expect(range.to, equals(DateTime(2026, 5, 4, 14, 30)));
  });

  test(
    'datetime-precise range spanning 2 days appears in both day queries',
    () async {
      await seedCategory(timeModel: TimeModel.datetimePreciseRange);

      await repo.save(
        Event(
          uid: 'dt1',
          categoryUid: 'cat1',
          occurredAt: DatetimePreciseRange(
            from: DateTime(2026, 5, 4, 22),
            to: DateTime(2026, 5, 5, 6),
          ),
          fieldValues: const [],
        ),
      );

      final day4 = await repo.watchByDay(DateTime(2026, 5, 4)).first;
      expect(day4, hasLength(1));

      final day5 = await repo.watchByDay(DateTime(2026, 5, 5)).first;
      expect(day5, hasLength(1));

      final day6 = await repo.watchByDay(DateTime(2026, 5, 6)).first;
      expect(day6, isEmpty);
    },
  );

  test('datetime-precise range: to before from is rejected', () async {
    await seedCategory(timeModel: TimeModel.datetimePreciseRange);

    await expectLater(
      repo.save(
        Event(
          uid: 'dt-bad',
          categoryUid: 'cat1',
          occurredAt: DatetimePreciseRange(
            from: DateTime(2026, 5, 4, 14),
            to: DateTime(2026, 5, 4, 10),
          ),
          fieldValues: const [],
        ),
      ),
      throwsA(isA<EventRangeInvalidException>()),
    );
  });
}
