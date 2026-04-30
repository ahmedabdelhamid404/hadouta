# ADR-006: AI Stack — Claude + Nano Banana 2

**Status**: Accepted
**Date**: 2026-04-30
**Decision-makers**: Ahmed, Claude

## Context

Need: best Arabic narrative LLM + best image model for face-consistent multi-character watercolor. Solo-dev cost-controllable.

## Decision

**Story narrative**: Claude Sonnet 4.6 (primary) + Claude Haiku 4.5 (3-layer validators in parallel). Backup: Gemini 2.5 Pro + Flash.

**Image generation**: Nano Banana 2 via fal.ai @ 1K for digital books (~$0.045/image). Nano Banana Pro @ 4K for v1.5 print upgrade (~$0.30/image). GPT Image 2 fallback for text-heavy cover pages only.

## Rationale

- Sonnet 4.6 has documented best Arabic narrative quality among reasonably-priced models
- Haiku 4.5 at $0.25/$1.25 per million tokens makes 3 validator passes effectively free (~0.5 EGP)
- Nano Banana 2 wins on face consistency (5★ benchmark vs GPT Image 2's 4★) and multi-character (5 characters supported)
- Nano Banana Pro at 4K essential for print quality; GPT Image 2 lacks 4K entirely
- Anthropic prompt caching saves 70-80% on cached system prompt + few-shot examples
- fal.ai aggregator simplifies operations (one billing relationship, retries, queueing)

## Consequences

- Total LLM cost per 16-page book: ~3 EGP (negligible)
- Total image cost per digital book: ~45 EGP (Nano Banana 2 1K × 17 images × 20% retry)
- Total image cost per print upgrade: +106 EGP additional (Nano Banana Pro 4K)
- Vendor lock-in to Anthropic + fal.ai mitigated by Vercel AI SDK abstraction (swap providers in 2 lines)
- Prompt caching must be wired from day 1 to capture savings

## References

- Design doc § 3.2: Component diagram
- Cost research fork (2026-04-30): per-book unit economics
- Image-model research fork (2026-04-30): Nano Banana wins consistency
