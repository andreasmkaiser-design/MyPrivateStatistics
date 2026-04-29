# 7. Schema Inheritance Resolved at Read Time

Date: 2026-04-09
Status: accepted

## Context

Subcategories inherit all fields from their parent category and can add their own. We need to decide where and how this inheritance is resolved:
- At write time (denormalise fields into each subcategory's table row)
- At read time (walk the ancestor chain and merge field lists in code)

The UI always needs the full merged field list when rendering an event creation form or displaying category details.

## Decision

Schema inheritance is resolved **at read time** in the domain layer. Fields are stored only on the category that defines them. When a category's full schema is requested, the domain layer walks the ancestor chain (via parent_id), collects all fields bottom-up, and returns the merged list. Inherited fields are marked as read-only in the UI.

Subcategories may only **add** fields — they cannot override or remove inherited fields.

## Alternatives Considered

### Denormalise at write time (copy fields into subcategory rows)
- ✅ Single query to get all fields for a category
- ❌ Changing a parent field requires updating all descendant rows
- ❌ Risk of inconsistency between parent and child definitions

## Consequences

### Positive
- Single source of truth: each field definition lives in exactly one place
- Changing a parent field automatically propagates to all subcategories
- No data consistency issues

### Negative
- Requires walking up to 5 levels of ancestors to build the merged schema (max 5 queries)
- Domain layer carries the merging logic (must be well-tested)

### Risks
- None significant at max depth 5; would require optimisation at greater depth

## References

- DESIGN.md — Schema-Vererbung
- UBIQUITOUS_LANGUAGE.md — Schema Inheritance
- GitHub issue #3 (Slice 2: Category Management)
