# 20. Firebase Crashlytics for crash reporting

Date: 2026-05-18
Status: accepted

## Context

The app needs production crash reporting so regressions introduced by new releases are
detected without relying on users filing bug reports. Two options were evaluated:
Firebase Crashlytics and Sentry. The app is Android-only with no cross-platform
expansion planned.

## Decision

We will use Firebase Crashlytics (`firebase_crashlytics`) for production crash and
error reporting. Both uncaught Flutter framework errors (`FlutterError.onError`) and
uncaught async platform errors (`PlatformDispatcher.instance.onError`) are wired to
Crashlytics in `lib/main.dart`. Crashlytics is active in release builds only; debug
builds continue to use `AppLogger` (see ADR-0015).

## Alternatives Considered

### Alternative 1: Sentry

- ✅ Cross-platform (iOS, web) — single SDK if the app ever expands beyond Android
- ✅ More advanced features: breadcrumbs, performance monitoring, session replay
- ✅ Self-hostable
- ❌ Unnecessary complexity for an Android-only app
- ❌ Free tier has usage limits; paid tiers add operational cost
- ❌ No native Play Console integration

### Alternative 2: No crash reporting

- ✅ Zero dependencies, zero data leaves the device
- ❌ Regressions are invisible until a user reports them manually
- ❌ Unacceptable for a released app

## Consequences

### Positive

- Crashes are reported automatically in release builds with stack traces and device context
- Play Console and Firebase Console share the same Google account — crash data is
  visible alongside store ratings and ANR reports in one place
- Free at any scale; no operational cost

### Negative

- Adds `firebase_core` and `firebase_crashlytics` dependencies and the
  `google-services` Gradle plugin
- Requires a `google-services.json` file committed to the repo (contains no secrets —
  only project identifiers)
- Anonymous crash metadata (device model, OS version, stack trace) is transmitted to
  Google servers; no PII or event data is ever included

### Risks

- Firebase SDK version updates occasionally require coordinated upgrades of the Gradle
  plugin and `google-services.json`; pin versions and test after upgrades

## References

- [Firebase Crashlytics Flutter docs](https://firebase.flutter.dev/docs/crashlytics/overview)
- ADR-0015 — Logging approach (`AppLogger` — in-app logging, not replaced by Crashlytics)
