# ADR-003: MVP Anchored to "First Day of School," Sept 2026

**Status**: Accepted
**Date**: 2026-04-30
**Decision-makers**: Ahmed, Claude

## Context

MVP must launch with a single theme to keep validator training focused, marketing sharp, and content production manageable for solo dev. Multiple theme options were evaluated (Eid Al-Adha, New Sibling, Birthday, First Day of School).

## Decision

Launch v1 with a single theme: **First Day of School (المدرسة الأولى)**, anchored to early September 2026 when Egyptian school year begins.

## Rationale

- Universal Egyptian milestone — every parent of a 3–5yr feels it intensely
- Sept timing gives ~22 weeks build window from 2026-04-30 (achievable for solo dev)
- Pre-launch marketing window: August (parents already thinking about school start)
- Concrete + emotional + giftable: passes the "what would Manar buy?" test
- Single theme = better validator training data (200 books in same domain)
- Cultural framing already explored: anxiety + reassurance + pride arc

## Consequences

- Must launch by ~Sept 1 to capture school-start window — slipping forfeits the marketing moment until 2027
- Other themes (Eid, Birthday, New Sibling) are explicitly v1.5 — not in MVP
- Architecture must be theme-agnostic (per ADR-012 / ADR-007 implementations) to enable future themes without refactor

## References

- Design doc § 3: Target Users; § 12: Roadmap
- Brainstorming Q4 (theme scope)
