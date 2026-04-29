import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_statistics/core/database/app_database.dart';

final appDatabaseProvider = Provider<AppDatabase>(
  (_) => throw UnimplementedError(
    'appDatabaseProvider must be overridden at the ProviderScope root',
  ),
);
