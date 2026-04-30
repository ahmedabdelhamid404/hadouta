# ADR-015: Validation Parallel with Build (Lean Startup)

**Status**: Accepted
**Date**: 2026-04-30
**Decision-makers**: Ahmed, Claude

## Context

Three validation strategies were evaluated:
- A: Validate first, then build (4-week delay before code)
- B: Build first, validate at launch (high risk — typical solo founder failure mode)
- C: Validate while building (parallel tracks)

## Decision

**Strategy C — parallel validation tracks**. Landing page + ad campaign + waitlist begin Week 1. Core build runs in parallel.

## Rationale

- Build phase becomes informed execution, not blind gambling
- Waitlist of 1000+ Egyptian moms at launch = instant social proof + warm conversion audience
- Egypt-specific advantage: Facebook mom groups (200K+ member groups) + 5-10x cheaper FB ad CPM than US — validation is high-signal cheap-to-run
- Decisions like pricing, creative messaging, theme angle improve mid-build with real data
- Keeps Sept 2026 launch achievable (Strategy A's 4-week delay would push timeline tight)

## Consequences

- Week 1 must include landing page deploy + ad creative production + 3K EGP test budget
- Validation results feed back into design decisions (pricing, messaging, possibly even theme adjustments)
- Need analytics infrastructure (PostHog + UTM tracking) from Week 1
- Two parallel work tracks (Track A: Claude-led code; Track B: Ahmed-led validation/business)

## References

- Design doc § 15: Validation Plan
- Brainstorming Q11: validation timing
