# 18. Health Connect Record Types in Scope

Date: 2026-04-28
Status: accepted

## Context

The `health` Flutter package supports many Google Health Connect record types. Syncing all available types would increase complexity, sync time, and storage requirements without clear benefit in V1. A scoped decision prevents scope creep and ensures the Drift schema for Health Records is stable.

## Decision

### V1 record types

| Type | Health Connect constant | Stored as |
|---|---|---|
| Steps | `HealthDataType.STEPS` | `value` = step count (integer), `unit` = "steps" |
| Sleep session | `HealthDataType.SLEEP_SESSION` | `value` = duration in minutes, `unit` = "min" |
| Exercise session | `HealthDataType.EXERCISE_SESSION` | `value` = duration in minutes, `unit` = "min" |

### Storage schema

All record types share a single generic `health_records` Drift table:

```
health_records(
  id         TEXT PRIMARY KEY,   -- Health Connect record ID (for deduplication)
  type       TEXT NOT NULL,      -- "STEPS" | "SLEEP_SESSION" | "EXERCISE_SESSION"
  value      REAL NOT NULL,      -- numeric value as defined per type above
  unit       TEXT NOT NULL,      -- unit string
  start_time INTEGER NOT NULL,   -- Unix timestamp ms
  end_time   INTEGER NOT NULL    -- Unix timestamp ms
)
```

### Criteria for adding new types in future versions

A new record type is in scope when:
1. It has a clear numeric representation that fits the generic schema
2. It is available on a significant share of Android devices (not device-specific sensors)
3. There is a plausible correlation use case with user-defined event categories

## Alternatives Considered

### Sync all available Health Connect types
- ❌ Many types (blood glucose, VO2 max) require specific hardware and have no clear V1 use case
- ❌ Increases sync time and storage without user-visible benefit

### Type-specific tables
- ✅ Enables richer type-specific queries (e.g. sleep stages)
- ❌ Unnecessary for V1 which only needs a numeric value per time window for correlation
- ❌ Each new type requires a schema migration

## Consequences

### Positive
- Minimal schema supports all three record types without migration
- Deduplication via Health Connect record ID works identically for all types
- Adding new types in V2 only requires extending the sync logic, not the schema

### Negative
- Type-specific metadata (sleep stages, exercise activity type) is not stored — acceptable for V1 correlation use cases

### Risks
- Health Connect API changes to record type constants require updating the `type` string values in existing records — mitigated by using the constant name as the stored string

## References

- ADR-0008 (WorkManager for Health Connect Sync)
- ADR-0003 (Drift for Local Database)
- GitHub issue #9 (Health Connect Integration)
- [health package documentation](https://pub.dev/packages/health)
