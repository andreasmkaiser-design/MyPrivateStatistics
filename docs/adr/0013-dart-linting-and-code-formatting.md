# 13. Dart Linting and Code Formatting

Date: 2026-04-28
Status: accepted

## Context

Before the first line of production code is written, a consistent code style and lint ruleset must be in place. Without enforced standards, code reviews become style discussions, and subtle bugs caused by implicit types or missing null checks accumulate silently.

## Decision

We will use **`very_good_analysis`** as the lint ruleset and enforce **`dart format`** in both pre-commit and CI.

Specifics:
- `very_good_analysis` is added as a dev dependency; its rules are activated via `analysis_options.yaml`
- `directives_ordering` (import ordering: dart → flutter → packages → relative, alphabetically within groups) is adopted as-is from the ruleset
- `dart format --set-exit-if-changed .` runs in `lefthook` pre-commit hook and in GitHub Actions CI
- `// ignore: rule_name` comments are permitted but **must** include a reason: `// ignore: rule_name — reason`
- Generated code (Drift, Riverpod codegen) is exempted at file level via `// ignore_for_file:` — this is self-documenting and legitimate

## Alternatives Considered

### `flutter_lints`
- ✅ Official Flutter package, minimal friction
- ❌ Too permissive — allows implicit types, missing return type annotations, and other patterns that reduce testability

### `lint` (community package)
- ✅ Middle ground between flutter_lints and very_good_analysis
- ❌ Less actively maintained, smaller community

## Consequences

### Positive
- Consistent code style across all features from day one
- `very_good_analysis` enforces patterns (explicit return types, no `dynamic`) that improve testability
- `dart format` enforcement eliminates formatting discussions in code reviews
- Strict rules are cheapest to enforce at project start

### Negative
- Higher initial friction — more lint violations to fix during scaffolding
- Developers unfamiliar with `very_good_analysis` need a short ramp-up

### Risks
- Some third-party generated code may require `ignore_for_file` — acceptable and documented

## References

- [very_good_analysis](https://pub.dev/packages/very_good_analysis)
- [dart format documentation](https://dart.dev/tools/dart-format)
- ADR-0012 (Full Test Pyramid) — lint enforcement is part of the same pre-commit hook
- GitHub issue #2 (Project Scaffold)
