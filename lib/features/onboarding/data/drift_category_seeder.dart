import 'package:private_statistics/features/categories/domain/models/category.dart';
import 'package:private_statistics/features/categories/domain/models/field.dart';
import 'package:private_statistics/features/categories/domain/repositories/category_repository.dart';
import 'package:private_statistics/features/onboarding/domain/category_seeder.dart';
import 'package:private_statistics/features/onboarding/domain/seed_spec.dart';

/// [CategorySeeder] implementation backed by [CategoryRepository].
///
/// Walks each [SeedSpec] tree depth-first. A node whose [SeedSpec.uid] already
/// exists in the repository is skipped together with its entire subtree,
/// providing idempotency across multiple seed calls.
class DriftCategorySeeder implements CategorySeeder {
  /// Creates a [DriftCategorySeeder] backed by [repository].
  const DriftCategorySeeder({required this.repository});

  /// The repository used to check for existing categories and persist new ones.
  final CategoryRepository repository;

  @override
  Future<void> seed(List<SeedSpec> specs) async {
    for (final spec in specs) {
      await _seedNode(spec);
    }
  }

  Future<void> _seedNode(SeedSpec spec) async {
    final existing = await repository.findByUid(spec.uid);
    if (existing != null) return;

    final fields = [
      for (var i = 0; i < spec.fields.length; i++)
        Field(
          uid: spec.fields[i].uid,
          categoryUid: spec.uid,
          name: spec.fields[i].name,
          fieldType: spec.fields[i].type,
          sortOrder: i,
          unit: spec.fields[i].unit,
        ),
    ];

    await repository.save(
      Category(
        uid: spec.uid,
        name: spec.name,
        parentUid: spec.parentUid,
        timeModel: spec.timeModel,
        ownFields: fields,
      ),
    );

    for (final child in spec.children) {
      await _seedNode(child);
    }
  }
}
