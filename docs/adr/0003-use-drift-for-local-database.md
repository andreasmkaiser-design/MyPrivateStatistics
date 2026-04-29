# 3. Use Drift for Local Database

Date: 2026-04-09
Status: accepted

## Context

All app data (categories, events, health records) must be stored locally on the device — no cloud backend. We need a local database solution for Flutter that:
- Supports complex relational queries (category hierarchy, event filtering, correlation computation)
- Is type-safe and generates Dart code
- Works well with Riverpod for reactive state
- Supports SQLite on Android

## Decision

We will use Drift (formerly Moor) as the local database layer.

## Alternatives Considered

### sqflite (raw SQLite)
- ✅ Lightweight, direct SQLite access
- ❌ No type safety, manual SQL strings
- ❌ No code generation, error-prone at scale

### Isar
- ✅ Very fast, NoSQL document store
- ✅ Good Flutter integration
- ❌ NoSQL model is a poor fit for relational category/event/field schema
- ❌ Harder to write relational correlation queries

### Hive
- ✅ Simple key-value store
- ❌ Not suitable for complex relational queries needed for statistics

## Consequences

### Positive
- Type-safe Dart queries via code generation
- Reactive streams integrate naturally with Riverpod
- Full SQL power for complex correlation queries
- SQLite file is portable (useful for backup/restore feature)

### Negative
- Build step required (code generation via `build_runner`)
- Schema migrations must be managed manually

### Risks
- Complex schema migrations when evolving the data model in V2

## References

- [Drift documentation](https://drift.simonbinder.eu)
- DESIGN.md — Technology Stack
