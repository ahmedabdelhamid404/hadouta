# ADR-014: Pricing — A/B Test 250 vs 300 EGP Digital (TENTATIVE)

**Status**: Tentative — pending real Cairo print quotes + ad campaign data
**Date**: 2026-04-30
**Decision-makers**: Ahmed, Claude

## Context

Three pricing tiers were evaluated:
- Tier 1 (150 EGP digital / 350 EGP print): Print upgrade LOSES money at this price
- Tier 2 (250 EGP digital / 550 EGP print): Mid-market, healthy digital margin (~73%), thin print margin (~13%)
- Tier 3 (300 EGP digital / 600 EGP print): Premium, best margins (~77% digital, ~14% print)

Egyptian price sensitivity for unproven brand year-1 makes "go premium directly" risky.

## Decision

**A/B test 250 EGP and 300 EGP digital** in week-1 Facebook ad campaign. Print upgrade tentatively at +300 EGP additional (550-600 EGP total). Final pricing locked after 2 weeks of conversion data.

Cost basis confirmed: ~70 EGP per digital book at 300 books/month volume.

## Rationale

- Tier 1 dropped (print economics infeasible)
- Both Tier 2 and Tier 3 maintain healthy unit economics; market chooses optimal
- Premium tier 3 hits 50K EGP/mo profit at lower volume (~240 books/mo) than Tier 2 (~415 books/mo)
- Real Cairo print quotes (week 1) may shift print pricing math
- Egyptian middle-class anchors against 50 EGP traditional books at Diwan, not Amazon — pricing must justify cultural value, not technical novelty

## Consequences

- Marketing creatives must work for both 250 and 300 price points
- Final pricing decision deferred until Sprint 1 ad data is in
- Sprint 1 explicitly includes "lock final pricing" deliverable based on A/B results
- Post-launch promotional discounts (Eid, Mother's Day) work better from higher anchor (300 → 250 promo) than starting at 250

## References

- Design doc § 13: Cost Model
- Cost research fork (2026-04-30): unit economics by tier
