# 9. On-Demand Statistics Computation

Date: 2026-04-09
Status: accepted

## Context

The app computes statistical correlations (Co-Occurrence, Temporal Proximity) between event categories. We need to decide when these computations run:
- Pre-computed and stored (background job updates results)
- On-demand when the user opens the Statistics view

## Decision

Correlation computations run **on-demand** when the user opens the Statistics tab or changes the source category or analysis window. Results are not persisted; they are held in Riverpod provider state for the lifetime of the Statistics screen.

## Alternatives Considered

### Pre-computed in background (WorkManager)
- ✅ Instant display on opening the Statistics view
- ❌ Results may be stale if the user just added events
- ❌ Requires storing computed results in the database (extra schema complexity)
- ❌ Harder to invalidate cache correctly when new events are added

### Real-time reactive computation (recompute on every new event)
- ✅ Always up to date
- ❌ Expensive for large datasets — runs on every event write
- ❌ Unnecessary when the user is not viewing Statistics

## Consequences

### Positive
- Results always reflect the latest data
- No caching invalidation logic needed
- Simple implementation — pure functions over Drift query results

### Negative
- Small computation delay when opening Statistics (acceptable for typical dataset sizes)
- If datasets grow very large (years of data), computation time may increase

### Risks
- May need background pre-computation in V2 if datasets grow large enough to cause noticeable delays

## References

- DESIGN.md — Statistische Analyse
- UBIQUITOUS_LANGUAGE.md — Analysis, Correlation
- GitHub issue #6 (Slice 5: Statistics — Co-Occurrence)
