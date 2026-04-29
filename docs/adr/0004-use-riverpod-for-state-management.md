# 4. Use Riverpod for State Management

Date: 2026-04-09
Status: accepted

## Context

We need a state management solution for Flutter that:
- Handles async data well (database streams, Health Connect sync status)
- Is testable without a widget tree
- Scales across multiple features without global singletons
- Works reactively with Drift's stream-based queries

## Decision

We will use Riverpod for state management. Providers live close to the widgets they serve, within each feature folder.

## Alternatives Considered

### Provider (package)
- ✅ Simple, well-known
- ❌ Requires BuildContext, harder to test outside widget tree
- ❌ Less composable for complex async logic

### BLoC / Cubit
- ✅ Strong separation of concerns, well-established pattern
- ❌ More boilerplate than Riverpod
- ❌ Less ergonomic for simple reactive data from Drift

### GetX
- ✅ Low boilerplate
- ❌ Magic globals, poor testability
- ❌ Anti-pattern for large, maintainable codebases

## Consequences

### Positive
- Providers are testable in isolation without a widget tree
- AsyncValue handles loading/error/data states cleanly
- Composable: providers can depend on other providers
- Works naturally with Drift's stream-based reactive queries

### Negative
- Riverpod has a learning curve (codegen vs. manual declarations)
- Overusing providers can lead to complex dependency graphs

### Risks
- API changes between Riverpod major versions (currently stable on v2)

## References

- [Riverpod documentation](https://riverpod.dev)
- DESIGN.md — Technology Stack
