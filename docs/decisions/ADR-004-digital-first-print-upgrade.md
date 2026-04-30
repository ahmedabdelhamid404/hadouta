# ADR-004: Digital-First MVP, Print Upgrade in v1.5

**Status**: Accepted
**Date**: 2026-04-30
**Decision-makers**: Ahmed, Claude

## Context

Egyptian gift culture strongly prefers physical objects. But print logistics in Egypt are slow + complex for solo dev (no Lulu/Blurb-equivalent; need to negotiate with local printers + manage shipping). Pure-digital launches faster but risks lower perceived gift value.

## Decision

Launch v1 as **digital-only** (PDF + responsive web reader). Add **optional print upgrade** in v1.5 (~Q4 2026 / Q1 2027) at +300 EGP additional, fulfilled via Cairo print partner.

## Rationale

- Magicalchildrensbook.com runs the same model successfully ($7.99 eBook → $34.99 hardcover upgrade) — validated business pattern
- Digital ships in 4–8 weeks vs ~16 weeks for physical-first
- Print upgrade as post-purchase upsell converts at 30–50%, raising effective AOV
- Validates demand before committing to physical fulfillment infrastructure
- Once validated with paying customers, print partner negotiation is far easier (real volume in hand)

## Consequences

- Marketing must overcome Egyptian gift-culture preference for physical via strong emotional copy + future "print available later" promise
- v1.5 print partnership requires: signed Cairo printer + Bosta integration + refund-on-damaged-print flow + 4K image regeneration via Nano Banana Pro
- Pricing structure must support both digital-only and digital+print conversion paths

## References

- Design doc § 12: Roadmap
- Cost research fork (2026-04-30): print costs ~80 EGP/copy at 100/mo batch
- Magicalchildrensbook.com pricing model
