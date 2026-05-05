import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:private_statistics/core/database/app_database.dart';
import 'package:private_statistics/core/logging/app_logger.dart';
import 'package:private_statistics/features/categories/domain/models/field.dart';
import 'package:private_statistics/features/categories/domain/models/field_constraint.dart';
import 'package:private_statistics/features/categories/domain/models/field_type.dart';
import 'package:private_statistics/features/events/domain/exceptions.dart';
import 'package:private_statistics/features/events/domain/models/event.dart';
import 'package:private_statistics/features/events/domain/models/event_time.dart';
import 'package:private_statistics/features/events/domain/models/field_value.dart';
import 'package:private_statistics/features/events/domain/repositories/event_repository.dart';

/// Drift-backed implementation of [EventRepository].
///
/// Stores each event as a row in the `events` table with its typed field
/// values in the `event_field_values` table. Constraint validation is
/// performed against the category's merged schema before any write.
///
/// Time model encoding in the database (see also `events_table.dart`):
/// - `range_end_ms IS NULL` → [TimePoint] event
/// - `range_end_ms IS NOT NULL AND has_clock_time = 0` → [DayPreciseRange]
/// - `range_end_ms IS NOT NULL AND has_clock_time = 1` → [DatetimePreciseRange]
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
    _validateTimeRange(event.occurredAt);
    AppLogger.debug('EventRepository: saving ${event.uid}');
    await _db.transaction(() async {
      await _db
          .into(_db.events)
          .insertOnConflictUpdate(
            EventsCompanion(
              uid: Value(event.uid),
              categoryUid: Value(event.categoryUid),
              occurredAtMs: Value(_startMs(event.occurredAt)),
              hasClockTime: Value(_clockTimeFlag(event.occurredAt)),
              rangeEndMs: Value(_endMs(event.occurredAt)),
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

  // ── Time model helpers ────────────────────────────────────────────────────

  /// Returns the start timestamp in milliseconds for [time].
  int _startMs(EventTime time) => switch (time) {
    TimePoint(:final clockTime, :final date) =>
      (clockTime ?? date).millisecondsSinceEpoch,
    DayPreciseRange(:final from) => from.millisecondsSinceEpoch,
    DatetimePreciseRange(:final from) => from.millisecondsSinceEpoch,
  };

  /// Returns `true` when [time] carries clock-time precision.
  bool _clockTimeFlag(EventTime time) => switch (time) {
    TimePoint(:final clockTime) => clockTime != null,
    DayPreciseRange() => false,
    DatetimePreciseRange() => true,
  };

  /// Returns the end timestamp in milliseconds, or `null` for [TimePoint].
  int? _endMs(EventTime time) => switch (time) {
    TimePoint() => null,
    DayPreciseRange(:final to) => to.millisecondsSinceEpoch,
    DatetimePreciseRange(:final to) => to.millisecondsSinceEpoch,
  };

  /// Throws [EventRangeInvalidException] when the range end is before start.
  void _validateTimeRange(EventTime time) {
    switch (time) {
      case DayPreciseRange(:final from, :final to):
        if (to.isBefore(from)) {
          throw const EventRangeInvalidException(
            'Range end date must not be before start date',
          );
        }
      case DatetimePreciseRange(:final from, :final to):
        if (to.isBefore(from)) {
          throw const EventRangeInvalidException(
            'Range end datetime must not be before start datetime',
          );
        }
      case TimePoint():
        break;
    }
  }

  /// Reconstructs an [EventTime] from a database row.
  EventTime _toEventTime(EventRow row) {
    final startDt = DateTime.fromMillisecondsSinceEpoch(row.occurredAtMs);
    if (row.rangeEndMs == null) {
      if (row.hasClockTime) {
        return TimePoint(
          date: DateTime(startDt.year, startDt.month, startDt.day),
          clockTime: startDt,
        );
      }
      return TimePoint(
        date: DateTime(startDt.year, startDt.month, startDt.day),
      );
    }
    final endDt = DateTime.fromMillisecondsSinceEpoch(row.rangeEndMs!);
    if (row.hasClockTime) {
      return DatetimePreciseRange(from: startDt, to: endDt);
    }
    return DayPreciseRange(
      from: DateTime(startDt.year, startDt.month, startDt.day),
      to: DateTime(endDt.year, endDt.month, endDt.day),
    );
  }

  // ── Query helpers ─────────────────────────────────────────────────────────

  Future<Set<DateTime>> _queryDaysInMonth(DateTime month) async {
    final startMs = DateTime(month.year, month.month).millisecondsSinceEpoch;
    final endMs = DateTime(month.year, month.month + 1).millisecondsSinceEpoch;

    // Include time-point events in [startMs, endMs) and range events that
    // overlap with this month.
    final rows =
        await (_db.select(_db.events)..where(
              (t) =>
                  (t.rangeEndMs.isNull() &
                      t.occurredAtMs.isBiggerOrEqualValue(startMs) &
                      t.occurredAtMs.isSmallerThanValue(endMs)) |
                  (t.rangeEndMs.isNotNull() &
                      t.occurredAtMs.isSmallerThanValue(endMs) &
                      t.rangeEndMs.isBiggerOrEqualValue(startMs)),
            ))
            .get();

    final days = <DateTime>{};
    for (final row in rows) {
      if (row.rangeEndMs == null) {
        final dt = DateTime.fromMillisecondsSinceEpoch(row.occurredAtMs);
        days.add(DateTime(dt.year, dt.month, dt.day));
      } else {
        // Expand every calendar day spanned by the range that falls in month.
        final fromDt = DateTime.fromMillisecondsSinceEpoch(row.occurredAtMs);
        final toDt = DateTime.fromMillisecondsSinceEpoch(row.rangeEndMs!);
        var current = DateTime(fromDt.year, fromDt.month, fromDt.day);
        final lastDay = DateTime(toDt.year, toDt.month, toDt.day);
        while (!current.isAfter(lastDay)) {
          if (current.year == month.year && current.month == month.month) {
            days.add(current);
          }
          current = DateTime(current.year, current.month, current.day + 1);
        }
      }
    }
    return days;
  }

  Future<List<Event>> _queryByDay(DateTime day) async {
    final dayStart = DateTime(
      day.year,
      day.month,
      day.day,
    ).millisecondsSinceEpoch;
    final dayEnd = DateTime(
      day.year,
      day.month,
      day.day + 1,
    ).millisecondsSinceEpoch;

    // A time-point event falls on [day] when its timestamp is in [dayStart,
    // dayEnd). A range event spans [day] when its interval overlaps the day.
    final rows =
        await (_db.select(_db.events)..where(
              (t) =>
                  (t.rangeEndMs.isNull() &
                      t.occurredAtMs.isBiggerOrEqualValue(dayStart) &
                      t.occurredAtMs.isSmallerThanValue(dayEnd)) |
                  (t.rangeEndMs.isNotNull() &
                      t.occurredAtMs.isSmallerThanValue(dayEnd) &
                      t.rangeEndMs.isBiggerOrEqualValue(dayStart)),
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
      occurredAt: _toEventTime(row),
      fieldValues: valueRows.map(_toFieldValue).toList(),
    );
  }

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
