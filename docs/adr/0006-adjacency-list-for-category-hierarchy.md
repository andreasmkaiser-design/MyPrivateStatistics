# 6. Adjacency List for Category Hierarchy

Date: 2026-04-09
Status: accepted

## Context

Categories can be nested up to 5 levels deep. We need to choose a database model for storing this tree structure in SQLite (via Drift). The model must support:
- Reading the full tree efficiently
- Creating, renaming, and deleting nodes (with cascade)
- Max depth enforcement
- Querying all ancestors of a node (for schema inheritance)

## Decision

We will use an **adjacency list**: each category row has a nullable `parent_id` foreign key referencing another category. The tree is assembled in Dart from multiple simple queries. Riverpod caches the assembled tree.

## Alternatives Considered

### Closure Table
- ✅ Very efficient for deep tree queries (all ancestors/descendants in one query)
- ❌ Write operations are complex (must update many rows on insert/move)
- ❌ Overkill for max depth 5

### Materialized Path (e.g. `sport.laufen.intervall`)
- ✅ Simple prefix queries for subtrees
- ❌ Renaming a parent node requires updating all descendant paths
- ❌ Path strings are brittle

### Nested Sets
- ✅ Fast subtree reads
- ❌ Very expensive writes (reorders entire tree on insert)
- ❌ Complex to implement correctly

## Consequences

### Positive
- Simple schema — one extra column (`parent_id`)
- Easy to implement in Drift
- Sufficient for max 5 levels: at most 5 sequential queries to walk a path
- Tree assembly in Dart is straightforward and well-tested

### Negative
- No single-query full-tree fetch — requires multiple queries or recursive CTE (not reliably supported by Drift across all platforms)
- Tree assembly logic must live in the domain layer, not the database

### Risks
- If max depth constraint is ever lifted significantly, this model becomes inefficient

## References

- DESIGN.md — Datenbankmodell (Kategoriehierarchie)
- UBIQUITOUS_LANGUAGE.md — Category Hierarchy
