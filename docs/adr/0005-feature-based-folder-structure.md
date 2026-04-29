# 5. Feature-Based Folder Structure

Date: 2026-04-09
Status: accepted

## Context

We need to decide how to organise the `lib/` directory. The app has four clearly distinct domains (events, categories, statistics, health) plus shared infrastructure. The structure must scale as V2 features are added without requiring large reorganisations.

## Decision

We will use a feature-based folder structure:

```
lib/
  features/
    events/
      data/          (Drift DAOs, Repositories)
      domain/        (Models, Interfaces)
      presentation/  (Widgets, Riverpod Providers)
    categories/
    statistics/
    health/
  core/              (Database connection, shared widgets, theme)
```

## Alternatives Considered

### Layer-based structure (`lib/data/`, `lib/domain/`, `lib/presentation/`)
- ✅ Clear separation of architectural layers
- ❌ Related code for one feature is spread across three top-level folders
- ❌ Does not scale well when features are independent

### Flat structure (everything in `lib/`)
- ✅ Simple for very small apps
- ❌ Unnavigable at the scale of this app

## Consequences

### Positive
- All code for one feature lives together — easy to navigate and delete
- New features can be added as new folders without touching existing ones
- Matches the mental model of the slice-based development plan

### Negative
- Some shared code decisions are ambiguous (does it go in `core/` or a feature?)
- Requires discipline to avoid cross-feature coupling

### Risks
- Features that grow large may need sub-feature splits in the future

## References

- DESIGN.md — Architecture
- GitHub issue #2 (Slice 1: Project Scaffold)
