# 15. Logging Approach

Date: 2026-04-28
Status: accepted

## Context

The app runs background tasks (WorkManager Health Connect sync) and has complex data flows (schema inheritance, correlation computation). Without structured logging, debugging production issues and WorkManager failures is extremely difficult. `dart:developer`'s `log()` function lacks level filtering and structured output.

## Decision

We will use the **`logger`** package with a **global singleton `AppLogger`** in `core/`.

### Log levels and when to use them

| Level | When to use | Examples |
|---|---|---|
| `verbose` | Detailed internals, development only | Individual DB query parameters, each Health Record read |
| `debug` | Normal program flow useful for debugging | "Category tree loaded (12 nodes)", "Sync started" |
| `info` | Important app events relevant in production | "Sync completed: 47 new records", "Backup exported", "Onboarding completed" |
| `warning` | Expected problems, app continues | "Health Connect unavailable — skipping sync", "Import conflict: keep both selected" |
| `error` | Unexpected failures, `AppException` subclasses | "Database write failed", "Restore failed: incompatible schema" |
| `wtf` | Fatal errors that would crash the app | Drift initialisation failure on app start |

### Rules

- **No PII in logs** — event field values, category names entered by the user, and health record values must never appear in any log output at any level
- **Release mode filter** — in `kReleaseMode`, the logger is configured to output `info` level and above only; `verbose` and `debug` are never written to release builds
- **Singleton access** — `AppLogger.debug(...)`, `AppLogger.info(...)` etc. are static methods; no injection required

## Alternatives Considered

### `dart:developer` (built-in `log()`)
- ✅ No dependency
- ❌ No level filtering, no structured output, not suitable for production use

### `logging` (Dart official package)
- ✅ Hierarchical loggers, good for library code
- ❌ More boilerplate, less ergonomic in Flutter apps, less community adoption in Flutter

## Consequences

### Positive
- Level-based filtering makes WorkManager sync debugging tractable
- Release builds stay clean — no debug noise in production
- PII protection is enforced by convention and documented

### Negative
- Developers must remember the PII rule — no automated enforcement possible
- Static singleton is harder to mock in tests (mitigated by a `AppLogger.setOutput()` method for tests)

### Risks
- Accidental PII logging is a risk that cannot be caught by linting alone — code review discipline is required

## References

- [logger package](https://pub.dev/packages/logger)
- ADR-0014 (Error Handling Strategy) — error-level logs accompany central error handling
- ADR-0008 (WorkManager) — sync events logged at info/warning/error level
