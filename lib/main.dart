import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_statistics/app.dart';
import 'package:private_statistics/core/database/app_database.dart';
import 'package:private_statistics/core/database/database_provider.dart';
import 'package:private_statistics/core/logging/app_logger.dart';

/// Application entry point.
///
/// Initialises the [AppDatabase] and injects it via [ProviderScope] before
/// running [App].
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  AppLogger.info('Database initialised');
  runApp(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const App(),
    ),
  );
}
