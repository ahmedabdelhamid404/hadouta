# ADR-012: Layered Validator Architecture (Universal + Theme-Specific)

**Status**: Accepted
**Date**: 2026-04-30
**Decision-makers**: Ahmed, Claude

## Context

AI-generated kid content has high cultural/religious safety requirements in Egyptian market. Need a validator system that: (a) catches universal ethics violations regardless of theme, (b) verifies theme-specific requirements, (c) doesn't require rewriting ethics validators every time we add a theme.

## Decision

**Two-layer validator architecture**:

- **Layer 1 — Universal validators** (theme-agnostic, run on EVERY story): 5 parallel Haiku 4.5 sub-validators (religious_safety, cultural_safety, age_appropriate, moral_correctness, language_safety). All must pass.
- **Layer 2 — Theme-specific validators** (per-theme, additive): theme adherence + theme-specific quality criteria.

Plus a **regression test suite** of 100+ hand-crafted test cases in `tests/validator-regression-suite/` that runs in CI on every validator prompt change.

## Rationale

- Layered design = adding a new theme touches ONLY layer 2; layer 1 (ethics) stays untouched and complete
- Universal validators are the "constitutional layer" — the inviolable rules of the platform
- Parallel sub-validators (instead of one megaprompt) keep each focused, debuggable, individually improvable
- Regression test suite catches drift on prompt changes
- Active learning loop (per ADR-013) feeds new examples into validator few-shot prompts

## Consequences

- Adding a theme post-MVP = data work only (story templates + theme rules + image references), no architectural change
- Validator prompt changes must pass full regression suite before deploy (CI gate)
- Test suite grows with every real rejection (each becomes a new test case)
- Future free-form custom story v2 inherits universal validators automatically

## References

- Design doc § 6: AI Pipeline; § 11: Validator Architecture
- Brainstorming Q9-Q10: validator architecture
