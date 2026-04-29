# 12. Full Test Pyramid from Day One

Date: 2026-04-09
Status: accepted

## Context

The app has complex domain logic (schema inheritance, correlation algorithms, UID remapping on import) that is hard to verify manually. We need to decide on a testing strategy that:
- Catches regressions early
- Is maintainable as the codebase grows
- Does not slow down the development loop unnecessarily

## Decision

We will implement a **full test pyramid from the start**: unit tests, widget tests, and integration tests. Pre-commit hooks (via `lefthook`) run unit and widget tests before every commit. Integration tests run in GitHub Actions CI only (too slow for pre-commit).

| Level | Scope | Tool |
|---|---|---|
| Unit | Algorithms, Repositories, Providers | flutter_test, mocktail |
| Widget | Calendar, Category Tree, KPI Card | flutter_test |
| Integration | End-to-end flows | integration_test |

Tests verify **observable external behaviour**, not implementation details. A test must survive refactors that do not change behaviour.

## Alternatives Considered

### Unit tests only
- ✅ Fast, easy to write
- ❌ No confidence that the layers integrate correctly
- ❌ Widget and flow regressions go undetected

### No automated tests
- ✅ Fastest initial development
- ❌ Regressions accumulate silently
- ❌ Adding tests later is significantly more expensive

## Consequences

### Positive
- Regressions in correlation algorithms caught before commit
- UI regressions in core widgets caught before commit
- End-to-end flows verified in CI before merge
- Foundation is in place; adding new tests follows established patterns

### Negative
- Initial setup time for lefthook, CI, and test infrastructure
- Developers must maintain tests as the codebase evolves

### Risks
- Flaky integration tests can erode trust in CI — must be addressed immediately when they appear

## References

- DESIGN.md — Testing
- GitHub issue #2 (Slice 1: Project Scaffold + CI/CD)
- [flutter_workmanager](https://pub.dev/packages/flutter_workmanager)
- [lefthook](https://github.com/evilmartians/lefthook)
