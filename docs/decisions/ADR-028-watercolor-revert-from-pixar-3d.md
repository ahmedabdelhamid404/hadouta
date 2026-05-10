# ADR-028 — Watercolor revert from Pixar-3D brand register

**Date:** 2026-05-10
**Status:** Locked
**Supersedes:** ADR-027 (Watercolor → Pixar-3D brand pivot, 2026-05-06) — the Pixar-3D brand portion only. ADR-026's illustration architecture (Nano Banana 2 + multi-image identity reference) stands.
**Restores:** ADR-005's original watercolor brand register (with face-fidelity caveats noted below).

## Context

ADR-027 (locked 2026-05-06) pivoted Hadouta's brand register from soft watercolor (per ADR-005) to Pixar-3D animated. The justification was Phase 1's "wtf it's him" face-fidelity verdict — Nano Banana 2 + Pixar-3D prompt overlay produced strong identity preservation in iteration 6 testing.

Three days later (2026-05-08 → 2026-05-10), full 16-page production tests on real customer data exposed two failure modes that ADR-027 didn't anticipate:

1. **Pixar-trained models bias toward "youthful-cute" facial geometry** regardless of explicit age cues. On scenes with adult supporting characters (mothers, teachers), the Pixar register pulled even adults toward the protagonist's child-face geometry. Documented across multiple iterations on the Hana 16-page book — first run produced "trash" output per founder.

2. **The Pixar register amplified face-geometry rigidity.** When Nano Banana 2 was already struggling with identity preservation across action scenes (Phase 1 acknowledged ceiling), the Pixar style's strong rendered-3D look made misalignments more obvious. Watercolor's softer edges and brush-stroke texture forgive small geometry drifts that Pixar-3D rendering exposes.

Founder's direct call (2026-05-09): "we keep this for now" → switch back to watercolor.

## Decision

**Revert Hadouta's locked brand register from Pixar-3D back to soft watercolor children's-book illustration.** Specifically:

- `bible-system-prompt.ts` styleBible defaults restore to watercolor (visible brush strokes, wet-on-wet bleeds, cold-press paper texture, warm cream paper backgrounds, terracotta/ochre/sage palette, golden afternoon light)
- Reference artists in the system prompt: **Tomie dePaola's _Strega Nona_** and **Helen Oxenbury's _We're Going on a Bear Hunt_** (these are Google's recommended named-work pattern for style transfer)
- `negativeStyle` reverts: "NOT photorealistic, NOT 3D-rendered, NOT digital-glossy, NOT vector-flat, NOT sharp digital lines"
- Brand brief, customer copy, marketing collateral all return to watercolor framing
- The Pixar-style helper `appendPixarStyleAnchor()` in `build-illustration-prompt.ts` is dead code; removed in Sprint 3 cleanup

## What ADR-026 still preserves

The illustration **model and architectural pattern** stay locked per ADR-026:

- Model: `gemini-3.1-flash-image-preview` (Nano Banana 2) — formerly via fal.ai's `fal-ai/nano-banana-2/edit`, now via Google direct API
- Multi-image identity reference: 1-3 customer photos passed as `image_urls`
- Bible-driven prompt construction with locked character/setting/style/cultural anchors

The brand-register pivot doesn't touch the illustration pipeline architecture. It only changes the styleBible content fed into that pipeline.

## What changed in iter 7 prompt structure (separate from brand)

Beyond the watercolor revert, this same period (2026-05-08 → 2026-05-10) introduced a deeper prompt-architecture restructure that's adjacent to ADR-028 but architectural rather than brand:

- **Image 1 = IDENTITY REFERENCE only** (face/skin/hair, ignore expression/pose)
- **Image 2 = STYLE REFERENCE only** (watercolor medium, ignore character/expression/composition)
- **Task framing = "render fresh, do NOT copy any input"** (generate-from-scratch, not edit)
- **Single narrative paragraph for scene** (no bullet lists, no NOT-negatives)
- **Per-page emotional pose narrative** that explicitly forbids the smile-and-camera default

These prompt-engineering improvements are independent of the brand register and are documented in `2026-05-10-face-fidelity-marathon.md` session note + the `_iter7_full_book.ts` reference script.

## Consequences

### Positive
- **Restores ADR-002 cultural-specificity moat alignment**: Egyptian children's-book watercolor is what Egyptian parents associate with childhood book-reading; Pixar-3D was a Western export.
- **Face-fidelity ceiling becomes less visible**: watercolor's softer edges absorb geometry imperfections that Pixar exposed.
- **Existing brand brief, illustrator commission spec, ad creative direction all already align**: the Pixar pivot was 4 days old; nothing significant had been redesigned around it yet.
- **Per-customer LoRA training (deferred Sprint 5+) is more compatible with watercolor**: existing watercolor LoRAs are abundant on civitai/HF; Pixar-style LoRAs are mostly Disney-IP-encumbered.

### Negative
- **ADR-027 work is partially wasted**: the Pixar-prompt overlay code (`appendPixarStyleAnchor`) and the iteration scripts that produced ADR-027's verdict are dead. Sprint 3 cleanup work item.
- **The Sprint 3 #1+#2 commit `919b846`** shipped Pixar-3D defaults to `bible-system-prompt.ts`. This needs to be reverted in a follow-up commit before pushing to origin. The Sprint 3 audit work (commits `5ef4690` + `d5de204`) is brand-agnostic and stays.
- **Reference iter 7 generation** at https://hadouta-admin.vercel.app/orders/22563851-2047-4f9e-ac47-ad27e036d4ea is the architectural reference but uses the iter 7 script (uncommitted) that already has the watercolor revert.

### Neutral
- **No customer-facing impact yet**: ADR-027 was 4 days old, no customer orders shipped on Pixar-3D.
- **No vendor / commission impact yet**: no commissioned illustrator work, no marketing creative, no customer copy was rebuilt around Pixar-3D in those 4 days.

## Implementation tasks (Sprint 3)

1. Revert `bible-system-prompt.ts` style anchor section to watercolor (concrete content per `_iter7_full_book.ts` `buildPrompt` function — `medium`, `palette`, `light`, `negativeStyle`, `compositionAnchors`).
2. Remove `appendPixarStyleAnchor` helper from `build-illustration-prompt.ts`.
3. Remove `flux-kontext-pixar` provider code path from `illustration-generator.ts` (alt-provider for Pixar; not needed under watercolor).
4. Remove `PIXAR_STYLE_LORA_URL` env var documentation.
5. Update `docs/brand/brand-brief.md` to revert watercolor language.
6. Update landing page hero, wizard step copy, order-confirmation email, WhatsApp delivery template.
7. Audit story system prompt + few-shot examples for any leftover Pixar-style scene language. Should be minimal since the audit examples were brand-agnostic.

## Cross-references

- **ADR-002** — Egyptian cultural specificity is the moat
- **ADR-005** — L3 photo upload + watercolor style (the original brand lock; this ADR restores it)
- **ADR-024** — Bible-driven illustration pipeline with Nano Banana Pro Edit
- **ADR-026** — Phase 1 character-fidelity verdict (illustration model + multi-image; still stands)
- **ADR-027** — Watercolor → Pixar-3D brand pivot (this ADR supersedes)
- **`docs/session-notes/2026-05-10-face-fidelity-marathon.md`** — full session log

## Open considerations for ADR-029

A separate ADR (ADR-029, not yet written) will document the production retry-queue architecture surfaced during this session. The retry-queue work is orthogonal to brand register and can land independently.
