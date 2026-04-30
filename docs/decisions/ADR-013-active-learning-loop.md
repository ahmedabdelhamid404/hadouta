# ADR-013: Active Learning Loop with Manual Approval Gate

**Status**: Accepted
**Date**: 2026-04-30
**Decision-makers**: Ahmed, Claude

## Context

Ahmed wants the system to be "fully automated" eventually. But day-1 full automation risks: cultural blind spots, religious sensitivity violations, and refund disasters. Need a path from "manual review every book" → "validator handles 95% autonomously" without compromising launch quality.

## Decision

**Phased automation via active learning loop**:

- **Phase 1 (MVP, Sept 2026 + first ~200 books)**: Full AI generation → validator passes → **manual approval gate** (admin reviews every book pre-delivery). Rejections capture structured categories + free-text feedback.
- **Phase 2 (after ~200 books, ~Q1 2027)**: Validator prompts updated with real rejection examples; manual gate switches to "borderline scores only"; threshold-based auto-approval.
- **Phase 3 (after ~1000 books)**: Full auto with periodic spot-check.

## Rationale

- Manual review during early operation builds the training corpus the validator needs
- Categorized rejections (Religious / Cultural / Age / Pacing / Language / Format / Visual / Other) are the raw data for active learning
- Helicone Request Datasets feature auto-aggregates tagged rejections — no custom infra needed
- pgvector embeddings store rejected vs approved patterns for similarity search
- 20+ hrs/week makes manual review of first 200 books feasible
- Validator quality is path-dependent: you can't write good validators upfront; you discover failure modes by reviewing real data

## Consequences

- Admin panel must include structured rejection capture from day 1 (categories + free-text + regen flow)
- Trigger.dev waitpoint pauses workflow indefinitely (up to 7 days) while admin reviews
- "Resume here" pointer must include current automation phase
- Validator regression test suite grows with every rejection (active learning compounds)

## References

- Design doc § 6.6: Active learning loop
- Brainstorming Q7 (revised): phased automation with manual gate
