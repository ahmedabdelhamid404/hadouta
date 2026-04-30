# ADR-005: L3 Photo Upload + Watercolor Style (Path B)

**Status**: Accepted
**Date**: 2026-04-30
**Decision-makers**: Ahmed, Claude

## Context

Three personalization tiers were evaluated:
- L1: name + role only (generic illustrations)
- L2: name + avatar customization (no photo)
- L3: name + uploaded photo (real face in book)

And visual styles: cartoon vs watercolor/storybook vs Pixar 3D photoreal.

Ahmed strongly preferred the magicalchildrensbook.com aesthetic (photo upload + warm illustration). However, true "Pixar 3D + photoreal" requires DreamBooth fine-tuning per child (research-confirmed) — too expensive and complex for v1.

## Decision

**Path B**: L3 (photo upload) + **watercolor/storybook style** (NOT photoreal 3D).

## Rationale

- L3 captures emotional differentiator (kid's actual face in story)
- Watercolor is achievable with Nano Banana 2 + careful prompting (no DreamBooth needed)
- Watercolor culturally aligns with traditional Arabic kids' books (nostalgia for parents)
- Watercolor pairs better with Arabic typography than Western Pixar 3D
- Cost-controllable: ~$0.92/book (digital 1K) vs $3+ for photoreal approaches
- Pixar 3D + photoreal deferred to v2 as luxury upgrade tier

## Consequences

- Multi-character handling required from day 1 (kid + up to 2 supporting characters)
- Photo upload UX needs strong privacy framing for Egyptian market (auto-delete after 30 days, parental consent)
- Style consistency across 16 pages requires careful prompt engineering + reference images library
- Refund risk on poor face matches → mandatory 1-free-regen-in-7-days policy

## References

- Design doc § 6: Architecture (image generation)
- Image-model research fork (2026-04-30): Nano Banana 2 best for watercolor + multi-character L3
- Magicalchildrensbook.com as visual benchmark
