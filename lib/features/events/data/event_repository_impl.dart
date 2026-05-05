import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:private_statistics/core/database/app_database.dart';
import 'package:private_statistics/core/logging/app_logger.dart';
import 'package:private_statistics/features/categories/domain/models/field.dart';
import 'package:private_statistics/features/categories/domain/models/field_constraint.dart';
import 'package:private_statistics/features/categories/domain/models/field_type.dart';
import 'package:private_statistics/features/events/domain/exceptions.dart';
import 'package:private_statistics/features/events/domain/models/event.dart';
import 'package:private_statistics/features/events/domain/models/field_value.dart';
import 'package:private_statistics/features/events/domain/models/time_point.dart';
import 'package:private_statistics/features/events/domain/repositories/event_repository.dart';

/// Drift-backed implementation of [EventRepository].
///
/// Stores each event as a row in the `events` table with its typed field
/// values in the `event_field_values` table. Constraint validation is
/// performed against the category's merged schema before any write.
class EventRepositoryImpl implements EventRepository {
  /// Creates an [EventRepositoryImpl] backed by the given [AppDatabase].
  EventRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Event>> watchByDay(DateTime day) {
    return _db
        .customSelect('SELECT 1', readsFrom: {_db.events, _db.eventFieldValues})
        .watch()
        .asyncMap((_) => _queryByDay(day));
  }

  @override
  Future<Event?> findByUid(String uid) async {
    final row = await (_db.select(
      _db.events,
    )..where((t) => t.uid.equals(uid))).getSingleOrNull();
    if (row == null) return null;
    return _toEvent(row);
  }

  @override
  Future<void> save(Event event) async {
    await _validateFieldValues(event);
    AppLogger.debug('EventRepository: saving ${event.uid}');
    await _db.transaction(() async {
      await _db
          .into(_db.events)
          .insertOnConflictUpdate(
            EventsCompanion(
              uid: Value(event.uid),
              categoryUid: Value(event.categoryUid),
              occurredAtMs: Value(_timePointToMs(event.occurredAt)),
              hasClockTime: Value(event.occurredAt.clockTime != null),
            ),
          );
      await (_db.delete(
        _db.eventFieldValues,
      )..where((t) => t.eventUid.equals(event.uid))).go();
      for (final fv in event.fieldValues) {
        await _db
            .into(_db.eventFieldValues)
            .insert(_toFieldValueCompanion(event.uid, fv));
      }
    });
  }

  @override
  Future<void> delete(String uid) async {
    AppLogger.debug('EventRepository: deleting $uid');
    await (_db.delete(_db.events)..where((t) => t.uid.equals(uid))).go();
  }

  @override
  Stream<Set<DateTime>> watchDaysWithEventsInMonth(DateTime month) {
    return _db
        .customSelect('SELECT 1', readsFrom: {_db.events})
        .watch()
        .asyncMap((_) => _queryDaysInMonth(month));
  }

  Future<Set<DateTime>> _queryDaysInMonth(DateTime month) async {
    final startMs = DateTime(month.year, month.month).millisecondsSinceEpoch;
    final endMs = DateTime(month.year, month.month + 1).millisecondsSinceEpoch;
    final rows =
        await (_db.select(_db.events)..where(
              (t) =>
                  t.occurredAtMs.isBiggerOrEqualValue(startMs) &
                  t.occurredAtMs.isSmallerThanValue(endMs),
            ))
            .get();
    final days = <DateTime>{};
    for (final row in rows) {
      final dt = DateTime.fromMillisecondsSinceEpoch(row.occurredAtMs);
      days.add(DateTime(dt.year, dt.month, dt.day));
    }
    return days;
  }

  Future<List<Event>> _queryByDay(DateTime day) async {
    final startMs = DateTime(
      day.year,
      day.month,
      day.day,
    ).millisecondsSinceEpoch;
    final endMs = DateTime(
      day.year,
      day.month,
      day.day + 1,
    ).millisecondsSinceEpoch;
    final rows =
        await (_db.select(_db.events)..where(
              (t) =>
                  t.occurredAtMs.isBiggerOrEqualValue(startMs) &
                  t.occurredAtMs.isSmallerThanValue(endMs),
            ))
            .get();
    return Future.wait(rows.map(_toEvent));
  }

  Future<Event> _toEvent(EventRow row) async {
    final valueRows = await (_db.select(
      _db.eventFieldValues,
    )..where((t) => t.eventUid.equals(row.uid))).get();
    return Event(
      uid: row.uid,
      categoryUid: row.categoryUid,
      occurredAt: _toTimePoint(row),
      fieldValues: valueRows.map(_toFieldValue).toList(),
    );
  }

  TimePoint _toTimePoint(EventRow row) {
    final dt = DateTime.fromMillisecondsSinceEpoch(row.occurredAtMs);
    if (row.hasClockTime) {
      return TimePoint(
        date: DateTime(dt.year, dt.month, dt.day),
        clockTime: dt,
      );
    }
    return TimePoint(date: DateTime(dt.year, dt.month, dt.day));
  }

  int _timePointToMs(TimePoint tp) =>
      (tp.clockTime ?? tp.date).millisecondsSinceEpoch;

  FieldValue _toFieldValue(EventFieldValueRow row) {
    return switch (FieldType.values[row.valueTypeIndex]) {
      FieldType.integer => IntFieldValue(
        fieldUid: row.fieldUid,
        value: row.intValue!,
      ),
      FieldType.float => FloatFieldValue(
        fieldUid: row.fieldUid,
        value: row.floatValue!,
      ),
      FieldType.boolean => BoolFieldValue(
        fieldUid: row.fieldUid,
        value: row.boolValue!,
      ),
      FieldType.enumeration => EnumFieldValue(
        fieldUid: row.fieldUid,
        value: row.stringValue!,
      ),
    };
  }

  EventFieldValuesCompanion _toFieldValueCompanion(
    String eventUid,
    FieldValue fv,
  ) {
    if (fv is IntFieldValue) {
      return EventFieldValuesCompanion(
        eventUid: Value(eventUid),
        fieldUid: Value(fv.fieldUid),
        valueTypeIndex: Value(FieldType.integer.index),
        intValue: Value(fv.value),
      );
    } else if (fv is FloatFieldValue) {
      return EventFieldValuesCompanion(
        eventUid: Value(eventUid),
        fieldUid: Value(fv.fieldUid),
        valueTypeIndex: Value(FieldType.float.index),
        floatValue: Value(fv.value),
      );
    } else if (fv is BoolFieldValue) {
      return EventFieldValuesCompanion(
        eventUid: Value(eventUid),
        fieldUid: Value(fv.fieldUid),
        valueTypeIndex: Value(FieldType.boolean.index),
        boolValue: Value(fv.value),
      );
    } else if (fv is EnumFieldValue) {
      return EventFieldValuesCompanion(
        eventUid: Value(eventUid),
        fieldUid: Value(fv.fieldUid),
        valueTypeIndex: Value(FieldType.enumeration.index),
        stringValue: Value(fv.value),
      );
    }
    // ignore: only_throw_errors — sealed class guarantees exhaustion above
    throw StateError('Unhandled FieldValue subtype: ${fv.runtimeType}');
  }

  Future<void> _validateFieldValues(Event event) async {
    final mergedFields = await _mergedSchemaFor(event.categoryUid);
    final fieldsByUid = {for (final f in mergedFields) f.uid: f};
    for (final fv in event.fieldValues) {
      final field = fieldsByUid[fv.fieldUid];
      if (field == null) continue;
      if (fv is IntFieldValue) {
        _checkNumericConstraint(
          fv.fieldUid,
          fv.value.toDouble(),
          field.constraint,
        );
      } else if (fv is FloatFieldValue) {
        _checkNumericConstraint(fv.fieldUid, fv.value, field.constraint);
      } else if (fv is EnumFieldValue) {
        if (field.enumOptions.isNotEmpty &&
            !field.enumOptions.contains(fv.value)) {
          throw EventFieldConstraintViolationException(
            'Field ${fv.fieldUid}: "${fv.value}" is not a valid enum option',
          );
        }
      }
    }
  }

  void _checkNumericConstraint(
    String fieldUid,
    double value,
    FieldConstraint? constraint,
  ) {
    if (constraint == null) return;
    if (constraint.min != null && value < constraint.min!) {
      throw EventFieldConstraintViolationException(
        'Field $fieldUid: $value is below minimum ${constraint.min}',
      );
    }
    if (constraint.max != null && value > constraint.max!) {
      throw EventFieldConstraintViolationException(
        'Field $fieldUid: $value exceeds maximum ${constraint.max}',
      );
    }
  }

  Future<List<Field>> _mergedSchemaFor(String categoryUid) async {
    final ancestorUids = <String>[];
    String? currentUid = categoryUid;
    while (currentUid != null) {
      final uid = currentUid;
      ancestorUids.insert(0, uid);
      final row = await (_db.select(
        _db.categories,
      )..where((t) => t.uid.equals(uid))).getSingleOrNull();
      currentUid = row?.parentUid;
    }
    final fields = <Field>[];
    for (final uid in ancestorUids) {
      final fieldRows =
          await (_db.select(_db.fields)
                ..where((t) => t.categoryUid.equals(uid))
                ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
              .get();
      fields.addAll(fieldRows.map(_toField));
    }
    return fields;
  }

  Field _toField(FieldRow row) {
    final constraint = (row.constraintMin != null || row.constraintMax != null)
        ? FieldConstraint(min: row.constraintMin, max: row.constraintMax)
        : null;
    final enumOptions = row.enumOptionsJson != null
        ? List<String>.from(jsonDecode(row.enumOptionsJson!) as List<dynamic>)
        : <String>[];
    return Field(
      uid: row.uid,
      categoryUid: row.categoryUid,
      name: row.name,
      fieldType: FieldType.values[row.fieldTypeIndex],
      sortOrder: row.sortOrder,
      constraint: constraint,
      unit: row.unit,
      enumOptions: enumOptions,
    );
  }
}
