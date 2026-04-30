import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_statistics/core/database/app_database.dart';

/// Provides the singleton [AppDatabase] instance.
///
/// Must be overridden at the root [ProviderScope] before any consumer accesses
/// it. In tests, override with an in-memory database via
/// `AppDatabase.forTesting(NativeDatabase.memory())`.
final appDatabaseProvider = Provider<AppDatabase>(
  (_) => throw UnimplementedError(
    'appDatabaseProvider must be overridden at the ProviderScope root',
  ),
);
