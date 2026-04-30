import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/features/categories/domain/exceptions.dart';
import 'package:private_statistics/features/categories/domain/models/category.dart';
import 'package:private_statistics/features/categories/domain/models/field.dart';
import 'package:private_statistics/features/categories/domain/models/field_type.dart';
import 'package:private_statistics/features/categories/domain/models/time_model.dart';
import 'package:private_statistics/features/categories/domain/schema_inheritance_resolver.dart';

void main() {
  final resolver = SchemaInheritanceResolver();

  Category makeCategory(
    String uid, {
    String? parentUid,
    List<Field> fields = const [],
  }) => Category(
    uid: uid,
    parentUid: parentUid,
    name: uid,
    timeModel: TimeModel.timePoint,
    ownFields: fields,
  );

  Field makeField(String uid, {int sortOrder = 0}) => Field(
    uid: uid,
    categoryUid: 'unused',
    name: uid,
    fieldType: FieldType.integer,
    sortOrder: sortOrder,
  );

  group('resolveSchema', () {
    test('root category — all fields are own (not inherited)', () {
      final cat = makeCategory(
        'root',
        fields: [makeField('f1'), makeField('f2')],
      );
      final resolved = resolver.resolveSchema(cat, {'root': cat});

      expect(resolved, hasLength(2));
      expect(resolved.every((r) => !r.isInherited), isTrue);
    });

    test('subcategory — parent fields inherited, own fields not', () {
      final parent = makeCategory('parent', fields: [makeField('pf1')]);
      final child = makeCategory(
        'child',
        parentUid: 'parent',
        fields: [makeField('cf1')],
      );
      final resolved = resolver.resolveSchema(child, {
        'parent': parent,
        'child': child,
      });

      expect(resolved, hasLength(2));
      expect(
        resolved.firstWhere((r) => r.field.uid == 'pf1').isInherited,
        isTrue,
      );
      expect(
        resolved.firstWhere((r) => r.field.uid == 'cf1').isInherited,
        isFalse,
      );
    });

    test('3-level hierarchy — correct merge order: gp → p → child', () {
      final gp = makeCategory('gp', fields: [makeField('gf1')]);
      final p = makeCategory('p', parentUid: 'gp', fields: [makeField('pf1')]);
      final c = makeCategory('c', parentUid: 'p', fields: [makeField('cf1')]);
      final all = {'gp': gp, 'p': p, 'c': c};

      final resolved = resolver.resolveSchema(c, all);

      expect(resolved, hasLength(3));
      expect(resolved[0].field.uid, equals('gf1'));
      expect(resolved[0].isInherited, isTrue);
      expect(resolved[1].field.uid, equals('pf1'));
      expect(resolved[1].isInherited, isTrue);
      expect(resolved[2].field.uid, equals('cf1'));
      expect(resolved[2].isInherited, isFalse);
    });
  });

  group('validateDepth', () {
    Map<String, Category> makeChain(int depth) {
      final map = <String, Category>{};
      for (var i = 0; i < depth; i++) {
        final uid = 'c$i';
        map[uid] = makeCategory(uid, parentUid: i == 0 ? null : 'c${i - 1}');
      }
      return map;
    }

    test('5-level chain (max allowed) does not throw', () {
      final chain = makeChain(5);
      expect(
        () => resolver.validateDepth(chain['c4']!, chain),
        returnsNormally,
      );
    });

    test('6-level chain throws CategoryDepthLimitExceededException', () {
      final chain = makeChain(6);
      expect(
        () => resolver.validateDepth(chain['c5']!, chain),
        throwsA(isA<CategoryDepthLimitExceededException>()),
      );
    });
  });
}
