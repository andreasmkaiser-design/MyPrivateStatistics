# 2. Use Flutter as Mobile Framework

Date: 2026-04-09
Status: accepted

## Context

We are building a personal event tracking and statistics app for Android. We need to choose a mobile development framework. Key requirements:
- Android as primary target platform (V1)
- Developer wants to reuse the technology for future applications
- Single developer, so productivity and ecosystem matter
- Offline-first: all data stays on device

## Decision

We will use Flutter as the mobile framework.

## Alternatives Considered

### Native Android (Kotlin)
- ✅ Full access to Android APIs, best performance
- ✅ Direct Health Connect integration
- ❌ Not reusable for iOS or other future apps
- ❌ Slower UI development compared to Flutter

### React Native
- ✅ Large ecosystem, JavaScript familiarity
- ✅ Cross-platform
- ❌ Bridge overhead, more complex native module integration
- ❌ Less consistent UI across platforms

## Consequences

### Positive
- Single codebase reusable for future apps (iOS, desktop)
- Fast UI development with hot reload
- Strong community, growing ecosystem
- Material Design 3 support out of the box
- Good integration with Drift, Riverpod, and Health Connect via `health` package

### Negative
- Flutter apps tend to have larger binary sizes than native apps
- Some Android-specific APIs require platform channels

### Risks
- Health Connect integration via the `health` package is a third-party wrapper; breaking changes possible on new Android versions

## References

- [Flutter documentation](https://docs.flutter.dev)
- DESIGN.md — Technology Stack
