# 21. Play Store release signing and CI/CD pipeline

Date: 2026-05-18
Status: accepted

## Context

The app needs a reproducible, low-friction process for delivering signed release builds
to the Google Play Store. Four decisions are bundled here because they form a single
coherent release strategy: signing approach, CI/CD automation, keystore secret
management, and version numbering.

## Decision

**Signing:** We use Google Play App Signing. The upload keystore is generated once and
never changes. Google re-signs the AAB with the delivery key before it reaches devices,
so the upload key can be reset via Play Console if ever lost.

**Secret management:** The upload keystore is base64-encoded and stored as a GitHub
Actions secret (`KEYSTORE_BASE64`), alongside `KEYSTORE_PASSWORD`, `KEY_ALIAS`, and
`KEY_PASSWORD`. The Google Play API service account JSON is stored as
`PLAY_STORE_JSON_KEY`. No secrets are committed to the repository.

**CI/CD pipeline:** Two separate GitHub Actions workflows:
- `ci.yml` — runs on every push to every branch: test, analyse, format check, build
  verification. Unchanged from the pre-release setup.
- `release.yml` — runs on push to `main` only: decodes the keystore, builds a signed
  AAB with R8 minification enabled, uploads to the Play Store internal track via
  `r0adkll/upload-google-play`.

**Version numbering:** `versionCode` and `versionName` are controlled manually via
`pubspec.yaml` (`version: X.Y.Z+N`). The developer is prompted for the new version
before every commit (enforced by the per-issue workflow in `CLAUDE.md`).

## Alternatives Considered

### Alternative 1: Self-managed signing (no Play App Signing)

- ✅ Google never holds any signing key
- ❌ If the keystore is lost, the app cannot be updated on the Play Store — ever
- ❌ No upload key reset mechanism

### Alternative 2: Auto-increment versionCode via CI run number

- ✅ No manual step required before releasing
- ❌ The live versionCode is not visible in the repository; checking CI history is
  required to know what is on the store
- ❌ Makes it hard to reason about which commit corresponds to which store version

### Alternative 3: Manual Play Console upload (no CI automation)

- ✅ Simpler setup — no service account, no GitHub secrets
- ❌ Every release requires a manual browser session in Play Console
- ❌ Signing step must also be done manually each time

## Consequences

### Positive

- `git push` to `main` is the complete, unambiguous release trigger
- Upload key loss is recoverable via Play Console key reset
- `pubspec.yaml` is the single source of truth for the current version

### Negative

- Initial setup requires several manual steps: keystore generation, Play App Signing
  enrolment (first upload must be done via Play Console web UI), service account
  creation
- The `release.yml` workflow fails silently if any secret is missing or expired

### Risks

- The Google Play API service account JSON must be rotated if compromised; this
  requires updating the `PLAY_STORE_JSON_KEY` secret and re-testing the pipeline
- `r0adkll/upload-google-play` is a third-party action; pin to a specific commit SHA
  in production to avoid supply-chain risk

## References

- [Google Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756)
- [r0adkll/upload-google-play GitHub Action](https://github.com/r0adkll/upload-google-play)
- ADR-0020 — Firebase Crashlytics (release build also enables crash reporting)
