import 'package:private_statistics/features/onboarding/domain/seed_spec.dart';

/// Contract for seeding pre-built example categories into the database.
///
/// Implementations must be idempotent: calling [seed] twice with the same
/// specs must not create duplicate categories.
// ignore: one_member_abstracts — DI boundary; implementations are swapped in tests.
abstract interface class CategorySeeder {
  /// Seeds the given [specs] into the database.
  ///
  /// Each [SeedSpec] is identified by its [SeedSpec.uid]. If a category with
  /// that UID already exists the spec (and its subtree) is skipped.
  Future<void> seed(List<SeedSpec> specs);
}
