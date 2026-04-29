# 8. WorkManager for Health Connect Background Sync

Date: 2026-04-09
Status: accepted

## Context

Health Connect data must be synced once per day automatically, even when the app is not in the foreground. We need a mechanism to schedule and execute background work on Android that:
- Survives device reboots
- Respects Android's battery optimisation (Doze mode)
- Does not require a persistent foreground service
- Is configurable by the user (sync time)

## Decision

We will use **WorkManager** via the `flutter_workmanager` package for the daily Health Connect sync. The task is registered as a periodic task at app start. The user-configured sync time is used as the initial delay; WorkManager has an execution tolerance of approximately ±15 minutes, which is acceptable for a daily data sync.

## Alternatives Considered

### Foreground Service
- ✅ Precise timing, always running
- ❌ Permanent notification required (bad UX)
- ❌ High battery consumption
- ❌ Unnecessary for a once-daily sync

### AlarmManager (exact)
- ✅ Precise timing
- ❌ Severely restricted since Android 12 (requires special permission `SCHEDULE_EXACT_ALARM`)
- ❌ Does not survive Doze mode

### Manual sync only (no background)
- ✅ Simplest implementation
- ❌ User must remember to sync manually — reduces value of Health Connect integration

## Consequences

### Positive
- Android-standard approach for background tasks
- Survives reboots and Doze mode
- No permanent notification required
- Battery-friendly

### Negative
- Execution time is approximate (±15 min) — not suitable for time-critical tasks, but fine for daily health data sync
- WorkManager tasks can be deferred further by the OS under extreme battery constraints

### Risks
- On some heavily customised Android skins (MIUI, OxygenOS), WorkManager tasks may be aggressively killed — documented as a known limitation

## References

- [flutter_workmanager package](https://pub.dev/packages/flutter_workmanager)
- [Android WorkManager documentation](https://developer.android.com/topic/libraries/architecture/workmanager)
- DESIGN.md — Health Connect Integration
- GitHub issue #9 (Slice 8: Health Connect Integration)
