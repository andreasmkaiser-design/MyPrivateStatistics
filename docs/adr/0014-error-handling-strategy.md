# 14. Error Handling Strategy

Date: 2026-04-28
Status: accepted

## Context

The app has multiple error sources: Drift database operations, Health Connect sync, file I/O (backup/restore, JSON import), and user input validation. Without a consistent strategy, each screen invents its own error handling, leading to inconsistent UX and duplicated boilerplate.

## Decision

We will use **typed Dart exceptions** propagated via **Riverpod's `AsyncValue.error`**, with a **split between inline and central error handling** based on whether the error is within the user's control.

### Exception hierarchy

All app-specific exceptions inherit from `AppException` defined in `core/exceptions.dart`. Features add subclasses as needed (e.g. `CategoryNotFoundException`, `SyncFailedException`, `BackupRestoreException`).

### Inline error handling (in the screen/widget)

Used when the error is caused directly by the user's input and can be corrected immediately:
- Form validation (constraint violations, required fields empty, to-date before from-date)
- Name already taken (category creation, import conflict)
- Empty states (no events, no categories)

### Central error handling (ProviderObserver + Snackbar)

Used when the error is outside the user's direct control:
- Database errors (Drift read/write failures)
- Health Connect unavailable or permission denied
- Sync failures (WorkManager task errors)
- Backup/restore errors (file unreadable, incompatible schema)
- JSON import errors (malformed JSON)
- Any unhandled exception that is not a known `AppException` subtype

A global `ProviderObserver` watches for `AsyncError` states on providers and triggers a Snackbar with a localised error message.

## Alternatives Considered

### Result type (`Result<T, E>`)
- ✅ Explicit error handling, no hidden control flow
- ❌ Unusual in Flutter/Riverpod ecosystem — adds boilerplate without matching benefit
- ❌ Riverpod's `AsyncValue` already provides the same data/loading/error triad

### No central handler (all inline)
- ✅ Errors are always contextual
- ❌ 20+ screens each implementing the same Drift error Snackbar

## Consequences

### Positive
- Consistent UX: validation errors appear inline where the user can fix them; infrastructure errors appear as non-blocking Snackbars
- Single location to update error message wording for central errors
- Riverpod `AsyncValue.when(data:, loading:, error:)` works naturally with this pattern

### Negative
- Developers must consciously classify new errors as inline or central
- `AppException` hierarchy must be kept up to date as new features are added

### Risks
- Overly broad `catch (e)` blocks could swallow unexpected exceptions — lint rule `avoid_catches_without_on_clauses` from `very_good_analysis` mitigates this

## References

- ADR-0004 (Riverpod for State Management)
- ADR-0013 (Dart Linting — `avoid_catches_without_on_clauses`)
- UBIQUITOUS_LANGUAGE.md — Error classifications
