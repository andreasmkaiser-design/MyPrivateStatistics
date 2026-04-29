# 10. Flat JSON with UID / source_uid for Template Export

Date: 2026-04-09
Status: accepted

## Context

Users can export their category hierarchy as a JSON template to share with others. We need to decide:
- JSON structure: nested (mirrors the tree) vs. flat (array of objects with parent references)
- Identity: how to handle IDs across installations to avoid conflicts on import
- Update tracking: how to know if an imported template was updated by its original author

## Decision

We will use a **flat JSON array** where each category object contains its own UID, a nullable `parent_uid` reference, and a nullable `source_uid` field.

- **Export:** each category is serialised with its current `uid` as `source_uid`. The flat array contains all categories and fields — no event data.
- **Import:** new UIDs are generated for all imported categories. The exporting app's UID is stored as `source_uid`. If a category name conflicts with an existing one, the user is prompted (keep both / discard import).

## Alternatives Considered

### Nested JSON (tree structure)
- ✅ Human-readable, mirrors the visual hierarchy
- ❌ Harder to parse programmatically (recursive traversal)
- ❌ Harder to validate flat constraints (max depth)

### Use numeric auto-increment IDs across installations
- ❌ IDs will collide between different installations — not safe to import without remapping

### Overwrite on import (no conflict dialog)
- ❌ Risk of silent data loss if user has customised an imported template

## Consequences

### Positive
- Flat structure is easy to parse and validate
- New UIDs on import prevent all ID conflicts
- `source_uid` enables future "update from source" feature without breaking the current schema
- Conflict dialog gives the user explicit control

### Negative
- JSON is slightly more verbose than a nested structure (parent_uid on every node)
- Import logic must reconstruct the tree from flat data

### Risks
- `source_uid` semantics must be well-documented to avoid confusion if the field is used in a future update mechanism

## References

- DESIGN.md — JSON Export / Import
- UBIQUITOUS_LANGUAGE.md — Template, UID, Source UID
- GitHub issue #10 (Slice 9: JSON Template Export/Import)
