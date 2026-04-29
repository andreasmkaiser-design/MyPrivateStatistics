# 11. GPL v3 License

Date: 2026-04-09
Status: accepted

## Context

The app will be open source (GitHub) and monetised via a Freemium model on Google Play. We need a license that:
- Makes the source code publicly readable and contribuable
- Prevents third parties from taking the code and publishing an identical commercial app without contributing back
- Is compatible with GPL-licensed dependencies

## Decision

We will license the project under **GNU General Public License v3 (GPL v3)**.

## Alternatives Considered

### MIT
- ✅ Maximum permissiveness, large contributor base
- ❌ Anyone can fork, close-source, and publish a competing commercial app
- ❌ Undermines the Freemium business model

### Apache 2.0
- ✅ Permissive, includes patent protection clause
- ❌ Same problem as MIT for commercial forks

### Business Source License (BUSL)
- ✅ Restricts commercial use for a defined period, then goes open source
- ❌ Not a recognised OSI open source license — may deter contributors
- ❌ More complex to communicate to users

## Consequences

### Positive
- Source code is fully open and auditable (trust signal for a privacy-first app)
- Third parties cannot publish a closed-source fork without GPL compliance
- Protects the Freemium business model from direct copying

### Negative
- Contributions from companies with legal sensitivity to GPL may be limited
- Any app that links to this codebase must also be GPL (copyleft effect)

### Risks
- Must ensure all dependencies are GPL-compatible

## References

- [GNU GPL v3](https://www.gnu.org/licenses/gpl-3.0.en.html)
- DESIGN.md — Lizenz, Freemium-Modell
