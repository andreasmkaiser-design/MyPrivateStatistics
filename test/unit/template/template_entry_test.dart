import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/features/categories/domain/models/field.dart';
import 'package:private_statistics/features/categories/domain/models/field_constraint.dart';
import 'package:private_statistics/features/categories/domain/models/field_type.dart';
import 'package:private_statistics/features/categories/domain/models/time_model.dart';
import 'package:private_statistics/features/template/domain/models/template_entry.dart';

void main() {
  group('TemplateEntry serialisation', () {
    test('round-trip: 3-level hierarchy serialises and deserialises to '
        'structurally identical entries', () {
      // A → B → C, with A having a float field and C an enum field.
      const fieldA = Field(
        uid: 'f-a',
        categoryUid: 'cat-a',
        name: 'Weight',
        fieldType: FieldType.float,
        sortOrder: 0,
        unit: 'kg',
        constraint: FieldConstraint(min: 0, max: 300),
      );
      const fieldC = Field(
        uid: 'f-c',
        categoryUid: 'cat-c',
        name: 'Mood',
        fieldType: FieldType.enumeration,
        sortOrder: 0,
        enumOptions: ['good', 'bad'],
      );

      final entries = [
        TemplateEntry(
          uid: 'cat-a',
          name: 'Root A',
          parentUid: null,
          timeModelIndex: TimeModel.timePoint.index,
          fields: [TemplateFieldEntry.fromField(fieldA)],
        ),
        TemplateEntry(
          uid: 'cat-b',
          name: 'Child B',
          parentUid: 'cat-a',
          timeModelIndex: TimeModel.dayPreciseRange.index,
          fields: const [],
        ),
        TemplateEntry(
          uid: 'cat-c',
          name: 'Grandchild C',
          parentUid: 'cat-b',
          timeModelIndex: TimeModel.timePoint.index,
          fields: [TemplateFieldEntry.fromField(fieldC)],
        ),
      ];

      final json = jsonEncode(entries.map((e) => e.toJson()).toList());
      final decoded = (jsonDecode(json) as List<dynamic>)
          .map((e) => TemplateEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(decoded.length, 3);

      expect(decoded[0].uid, 'cat-a');
      expect(decoded[0].name, 'Root A');
      expect(decoded[0].parentUid, isNull);
      expect(decoded[0].timeModelIndex, TimeModel.timePoint.index);
      expect(decoded[0].fields.length, 1);
      expect(decoded[0].fields[0].name, 'Weight');
      expect(decoded[0].fields[0].fieldTypeIndex, FieldType.float.index);
      expect(decoded[0].fields[0].unit, 'kg');
      expect(decoded[0].fields[0].constraintMin, 0);
      expect(decoded[0].fields[0].constraintMax, 300);

      expect(decoded[1].uid, 'cat-b');
      expect(decoded[1].parentUid, 'cat-a');
      expect(decoded[1].fields, isEmpty);

      expect(decoded[2].uid, 'cat-c');
      expect(decoded[2].parentUid, 'cat-b');
      expect(decoded[2].fields[0].enumOptions, ['good', 'bad']);
    });

    test('exported JSON contains source_uid as null for locally-created '
        'categories', () {
      const entry = TemplateEntry(
        uid: 'cat-x',
        name: 'X',
        parentUid: null,
        timeModelIndex: 0,
        fields: [],
      );
      final map = entry.toJson();
      expect(map['source_uid'], isNull);
    });
  });
}
