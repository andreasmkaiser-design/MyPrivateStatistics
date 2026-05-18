# Private Statistics — Claude Code Orientation

Personal event tracking and statistical correlation Android app. Flutter + Drift + Riverpod.

## First: Read Progress

**Always read `PROGRESS.md` first** to know the current issue, branch, and resume point before doing anything else.

## Key Documents

| Document | Purpose |
|---|---|
| `PROGRESS.md` | Current implementation state — which issue is active, what's done, where to resume |
| `DESIGN.md` | All architecture and technology decisions |
| `UBIQUITOUS_LANGUAGE.md` | Canonical domain terms — use these in all code identifiers |
| `docs/adr/` | 18 Architecture Decision Records — load only the ones listed for the current issue in PROGRESS.md |

## ADR Loading Rule

**Do not load all 18 ADRs.** PROGRESS.md lists exactly which ADRs are relevant for the current issue. Load only those.

## Non-Negotiable Rules

These apply to every session, every file, every commit:

- **Linting:** `very_good_analysis` ruleset — zero lint warnings before committing (ADR-0013)
- **Formatting:** `dart format` must pass — enforced by lefthook pre-commit hook (ADR-0013)
- **Ignore comments:** `// ignore: rule — reason` — reason is mandatory (ADR-0013)
- **Exceptions:** all app exceptions inherit from `AppException` in `core/` (ADR-0014)
- **Error display:** validation errors inline; infrastructure errors via central Snackbar (ADR-0014)
- **Logging:** use `AppLogger` — never log PII; use correct level; debug/verbose suppressed in release (ADR-0015)
- **Migrations:** every new Drift table or column change gets a numbered migration (ADR-0016)
- **Dartdoc:** every public API must have `///` dartdoc — classes, constructors, fields, methods, getters, enum values; `public_member_api_docs: true` is enforced by the linter; use backticks for cross-file references not imported in the current file
- **Terminology:** use domain terms from UBIQUITOUS_LANGUAGE.md in all identifiers (`Event` not `Entry`, `Template` not `Export`, `AnalysisWindow` not `Period`)

## Folder Structure

```
lib/
  features/
    events/        data/ domain/ presentation/
    categories/    data/ domain/ presentation/
    statistics/    data/ domain/ presentation/
    health/        data/ domain/ presentation/
  core/            (AppLogger, AppException, DB connection, shared widgets, theme)
```

## Per-Issue Workflow (brief)

1. Read PROGRESS.md → current issue + resume point
2. Read the GitHub issue → unchecked boxes = what remains
3. Load relevant ADRs (listed in PROGRESS.md)
4. `/design-an-interface` if the issue introduces a new module boundary
5. `/tdd` — tick GitHub issue checkboxes as each criterion passes
6. `/simplify` post-review
7. `/shared-adr` if a new architectural decision was made
8. Ask the user: "What should the version be? (current: `pubspec.yaml` → `version:` field, format `X.Y.Z+N`)" → update `pubspec.yaml` before committing
9. Commit + PR
10. Update PROGRESS.md — move issue to Completed table with branch and date; set next issue as Current
11. Close the GitHub issue — `gh issue close <N> --comment "Completed: merged on <date> (<branch>)"`; also close any parent PRD issue if all its children are now done
