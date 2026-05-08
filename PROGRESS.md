# Implementation Progress

## Current

- **Issue:** #24 (impl: Inline subcategory chip list in CategoryFormScreen)
- **Branch:** feature/issue-24-inline-subcategory-chip-list
- **Started:** —
- **Status:** Not started
- **Resume from:** Read issue → /design-an-interface → /tdd

## Completed

| Issue | Title | PR | Date |
|---|---|---|---|
| #2 | Project Scaffold + CI/CD | (initial commit on main) | 2026-04-29 |
| #13 | Category Data Layer | feature/issue-13-category-data-layer | 2026-04-30 |
| #14 | Category UI | feature/issue-14-category-ui | 2026-05-03 |
| #15 | Event Data Layer | feature/issue-15-event-data-layer | 2026-05-04 |
| #16 | Calendar UI + Event Creation Flow | feature/issue-16-calendar-ui | 2026-05-05 |
| #5 | Event Capture — Time Ranges | feature/issue-5-time-ranges | 2026-05-05 |
| #6 | Statistics — Co-Occurrence + KPI + Bar Chart | feature/issue-6-statistics-co-occurrence | 2026-05-05 |
| #7 | Statistics — Temporal Proximity | feature/issue-7-statistics-temporal-proximity | 2026-05-05 |
| #26 | fix: TextEditingController lifecycle in CategoryFormScreen | feature/issue-26-fix-text-editing-controller | 2026-05-07 |
| #27 | fix: Category tree stream not reactive after writes | feature/issue-27-fix-watchTree-stream | 2026-05-07 |
| #22 | Repository uniqueness guard for sibling names | feature/issue-22-repository-uniqueness-guard | 2026-05-08 |
| #23 | Inline sibling-name validation (form + rename dialog) | feature/issue-23-inline-name-validation | 2026-05-08 |

## Pending (dependency order)

| Phase | Issue | Title | Blocked by | ADRs to load |
|---|---|---|---|---|
| 2 | #9 | Health Connect Integration | — | 0008, 0015, 0016, 0018 |
| 2 | #11 | Backup & Restore | — | 0014, 0015, 0016 |
| 4 | #10 | JSON Template Export / Import | — | 0010, 0012, 0014 |
| 5 | #12 | Onboarding | #9 | 0004, 0005, 0012 |
| 6 | #8 | Statistics — Calendar Visualisation | — | 0005, 0012 |
| 8 | #24 | Inline subcategory chip list in CategoryFormScreen | — | 0004, 0005, 0012, 0013 |
| 8 | #29 | fix: TextEditingController lifecycle in FieldEditorRow | — | 0013 |

## Blocked

| Issue | Title | Waiting for |
|---|---|---|
| #12 | Onboarding | #9 |

## Notes

- Issues use `/design-an-interface` before `/tdd`: #13, #15, #9, #6
- New ADR written during implementation → add to ADRs column for all affected pending issues
- Context > 70%: finish current red-green-refactor cycle → commit → update "Resume from" → new session
- Parent PRDs: #20 (Category name uniqueness → impl: #22 ✓, #23 ✓), #21 (Inline subcategory creation → impl: #24), #25 (Text input + reactive tree bugs → impl: #26 ✓, #27 ✓, #29)
