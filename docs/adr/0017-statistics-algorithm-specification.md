# 17. Statistics Algorithm Specification

Date: 2026-04-28
Status: accepted

## Context

Two correlation types are implemented in V1: Co-Occurrence and Temporal Proximity. Without precise algorithm specifications, two developers could implement different formulas and both would pass the acceptance criteria. This ADR pins the exact formulas to prevent ambiguity.

## Decision

### Co-Occurrence: Jaccard Index

**Formula:**

```
score = |days(A) ∩ days(B)| / |days(A) ∪ days(B)|
```

Where `days(X)` is the set of distinct calendar days within the Analysis Window on which category X has at least one event.

- Result range: 0.0 (no shared days) to 1.0 (all days are shared)
- KPI card text: *"A and B co-occurred on {shared} of {union} days"*

### Temporal Proximity: configurable counting mode

**Default mode (A — minimum one hit):**

```
score = count(events_A where ∃ event_B within [event_A.time, event_A.time + window]) / count(events_A)
```

**Mode B — all hits:**

```
score = sum(count(events_B within window after each event_A)) / count(events_A)
```

**Mode C — first hit only:**

```
score = count(events_A where ∃ event_B within window, counting only the first B) / count(events_A)
```

The counting mode is **user-configurable per source category**, defaulting to mode A. The selected mode is stored with the analysis configuration and persisted across sessions.

**Boundary inclusion:** an event B at exactly `event_A.time + window` is **included** in the count (closed interval).

**KPI card text (mode A):** *"B followed A within {window} in {score}% of cases"*

### Minimum data threshold

If either category has **fewer than 5 events** within the Analysis Window, the result is shown with a soft warning indicator: *"Limited data — result may not be statistically significant."* The result is not hidden.

## Alternatives Considered

### Co-Occurrence: Lift score
- ✅ More statistically rigorous (accounts for base rates)
- ❌ Harder to explain in plain language in KPI cards — "Lift = 2.3" is not user-friendly

### Temporal Proximity: hard minimum (hide results below threshold)
- ❌ Hides information the user may still find useful; soft warning is less paternalistic

## Consequences

### Positive
- Implementation is unambiguous — any developer reading this ADR produces the same algorithm
- Jaccard Index is intuitive and maps directly to plain-language KPI card text
- Soft warning preserves user information while flagging statistical limitations

### Negative
- Jaccard Index does not account for base rates — a category that occurs every day will appear to co-occur strongly with everything
- Mitigation: V2 Lift-based scoring can supersede this ADR when more sophisticated analysis is needed

### Risks
- Counting mode configurability adds UI surface area in the Statistics view — must be kept simple (dropdown, not a settings screen)

## References

- ADR-0009 (On-Demand Statistics Computation)
- GitHub issue #6 (Statistics — Co-Occurrence)
- GitHub issue #7 (Statistics — Temporal Proximity)
- UBIQUITOUS_LANGUAGE.md — Analysis Window, Correlation Strength, Co-Occurrence, Temporal Proximity
