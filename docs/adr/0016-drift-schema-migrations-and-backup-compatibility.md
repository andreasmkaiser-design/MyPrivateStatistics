# 16. Drift Schema Migrations and Backup Compatibility

Date: 2026-04-28
Status: accepted

## Context

The app stores all data in a local Drift (SQLite) database. As features evolve (V2 statistics, additional Health Connect types, freemium limits), the database schema will change. Without a clear migration strategy:
- Production upgrades can corrupt or lose user data
- Restoring a backup from an older app version onto a newer schema can crash the app

## Decision

### Migration strategy

- **Production builds:** numbered manual migrations using Drift's `MigrationStrategy.onUpgrade`. Each schema version increment has a corresponding migration step written as Dart code.
- **Debug builds:** destructive migration (`MigrationStrategy.onUpgrade` with `recreateAllViews` + drop/recreate tables) to allow fast iteration during development. Controlled by `kDebugMode`.
- The current schema version is stored in Drift's built-in `schemaVersion` integer on `@DriftDatabase`.

### Backup compatibility on restore

When the user restores a backup:
1. The app reads the `schemaVersion` from the backup SQLite file's `user_version` pragma
2. If the backup version equals the current schema version → restore proceeds silently
3. If the backup version is **older** → the user sees a warning: *"This backup was created with an older version of the app and will be automatically updated."* After confirmation, the backup is restored and migrations run automatically
4. If the backup version is **newer** (backup from a future app version) → restore is rejected with an error message

### Testing

- **Per-migration unit tests:** each `onUpgrade` step has a test that creates a database at the previous schema version, runs the migration, and asserts the resulting schema is correct. Uses Drift's `SchemaVerifier`.
- **End-to-end chain test:** a single integration test opens a database at schema version 1 and runs all migrations to the current version, verifying no data loss on a known seed dataset.

## Alternatives Considered

### Destructive migration in production
- ❌ Unacceptable — user data loss on every app update

### Reject incompatible backups (no auto-migration)
- ❌ Users who haven't restored a backup in several versions lose access to their data

## Consequences

### Positive
- User data is never lost on app upgrade
- Backup restores work across versions with transparent user communication
- Migration tests catch breaking changes before they reach production

### Negative
- Each schema change requires a migration step — small overhead per feature
- Migration test suite grows over time and must be maintained

### Risks
- Complex migrations (column type changes, data transformations) are inherently risky — mitigated by per-migration tests and the end-to-end chain test

## References

- [Drift migrations documentation](https://drift.simonbinder.eu/docs/advanced-features/migrations/)
- ADR-0003 (Drift for Local Database)
- GitHub issue #11 (Backup & Restore)
