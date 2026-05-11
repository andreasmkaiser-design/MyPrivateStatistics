import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/features/categories/domain/models/category.dart';
import 'package:private_statistics/features/categories/domain/models/category_node.dart';
import 'package:private_statistics/features/categories/domain/repositories/category_repository.dart';
import 'package:private_statistics/features/onboarding/data/drift_category_seeder.dart';
import 'package:private_statistics/features/onboarding/domain/default_seed_specs.dart';
import 'package:private_statistics/features/onboarding/domain/seed_spec.dart';

// ---------------------------------------------------------------------------
// Fake repository — stores categories in memory.
// ---------------------------------------------------------------------------

class _FakeCategoryRepository implements CategoryRepository {
  final _store = <String, Category>{};

  @override
  Future<void> save(Category category) async => _store[category.uid] = category;

  @override
  Future<Category?> findByUid(String uid) async => _store[uid];

  @override
  Future<List<Category>> getAll() async => _store.values.toList();

  @override
  Stream<List<CategoryNode>> watchTree() => const Stream.empty();

  @override
  Future<void> rename(String uid, String newName) async {}

  @override
  Future<void> delete(String uid) async {}
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _FakeCategoryRepository repo;
  late DriftCategorySeeder seeder;

  setUp(() {
    repo = _FakeCategoryRepository();
    seeder = DriftCategorySeeder(repository: repo);
  });

  group('DriftCategorySeeder', () {
    // Cycle 2 — creates ≥2 root categories with ≥1 field each

    test('seeding kDefaultSeedSpecs creates at least 2 root categories '
        'with at least one field each', () async {
      await seeder.seed(kDefaultSeedSpecs);

      final roots = (await repo.getAll())
          .where((c) => c.isRoot && c.ownFields.isNotEmpty)
          .toList();

      expect(roots.length, greaterThanOrEqualTo(2));
    });

    // Cycle 3 — idempotency

    test('seeding twice does not duplicate root categories', () async {
      await seeder.seed(kDefaultSeedSpecs);
      await seeder.seed(kDefaultSeedSpecs);

      final allCategories = await repo.getAll();
      final rootUids = allCategories.where((c) => c.isRoot).map((c) => c.uid);

      // UIDs are unique — no duplicates in a Set vs the list
      expect(rootUids.toSet().length, equals(rootUids.length));

      // Same count after second seed as after first
      final rootCount = allCategories.where((c) => c.isRoot).length;
      expect(rootCount, equals(kDefaultSeedSpecs.length));
    });

    // Synthetic spec test — algorithm independent of production data

    test('seed creates categories matching the given specs', () async {
      const specs = [
        SeedSpec(
          uid: 'test-root',
          name: 'Test Root',
          fields: [FieldSpec(uid: 'test-field-1', name: 'Field 1')],
        ),
      ];

      await seeder.seed(specs);

      final saved = await repo.findByUid('test-root');
      expect(saved, isNotNull);
      expect(saved!.name, equals('Test Root'));
      expect(saved.ownFields, hasLength(1));
      expect(saved.ownFields.first.uid, equals('test-field-1'));
    });
  });
}
