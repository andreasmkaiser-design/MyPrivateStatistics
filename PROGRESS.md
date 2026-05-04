# Implementation Progress

## Current

- **Issue:** #16 Calendar UI + Event Creation Flow
- **Branch:** (open from feature/issue-15-event-data-layer)
- **Started:** —
- **Status:** Not started
- **Resume from:** Start fresh — read issue #16, run /design-an-interface for the UI, then /tdd.

## Completed

| Issue | Title | PR | Date |
|---|---|---|---|
| #2 | Project Scaffold + CI/CD | (initial commit on main) | 2026-04-29 |
| #13 | Category Data Layer | feature/issue-13-category-data-layer | 2026-04-30 |
| #14 | Category UI | feature/issue-14-category-ui | 2026-05-03 |
| #15 | Event Data Layer | feature/issue-15-event-data-layer | 2026-05-04 |

## Pending (dependency order)

| Phase | Issue | Title | Blocked by | ADRs to load |
|---|---|---|---|---|
| 1 | #2 | Project Scaffold + CI/CD | — | 0005, 0012, 0013 |
| 2 | #13 | Category Data Layer | #2 | 0003, 0006, 0007, 0012, 0014, 0015 |
| 2 | #9 | Health Connect Integration | #2 | 0008, 0015, 0016, 0018 |
| 2 | #11 | Backup & Restore | #2 | 0014, 0015, 0016 |
| 3 | #14 | Category UI | #13 | 0004, 0005, 0012, 0013 |
| 3 | #15 | Event Data Layer | #13 | 0003, 0006, 0007, 0012, 0014, 0015 |
| 4 | #16 | Calendar UI + Event Creation Flow | #14, #15 | 0004, 0005, 0012, 0013 |
| 4 | #10 | JSON Template Export / Import | #14 | 0010, 0012, 0014 |
| 5 | #5 | Event Capture — Time Ranges | #16 | 0003, 0007, 0012 |
| 5 | #6 | Statistics — Co-Occurrence + KPI + Bar Chart | #16 | 0009, 0012, 0017 |
| 5 | #12 | Onboarding | #14, #9 | 0004, 0005, 0012 |
| 6 | #7 | Statistics — Temporal Proximity | #6 | 0009, 0017 |
| 6 | #8 | Statistics — Calendar Visualisation | #6 | 0005, 0012 |

## Blocked

| Issue | Title | Waiting for |
|---|---|---|
| #9 | Health Connect Integration | #2 |
| #11 | Backup & Restore | #2 |
| #15 | Event Data Layer | #13 |
| #16 | Calendar UI + Event Creation Flow | #14, #15 |
| #10 | JSON Template Export / Import | #14 |
| #5 | Event Capture — Time Ranges | #16 |
| #6 | Statistics — Co-Occurrence + KPI + Bar Chart | #16 |
| #12 | Onboarding | #14, #9 |
| #7 | Statistics — Temporal Proximity | #6 |
| #8 | Statistics — Calendar Visualisation | #6 |

## Notes

- Issues use `/design-an-interface` before `/tdd`: #13, #15, #9, #6
- New ADR written during implementation → add to ADRs column for all affected pending issues
- Context > 70%: finish current red-green-refactor cycle → commit → update "Resume from" → new session
