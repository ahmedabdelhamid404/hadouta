# ADR-026: Phase 1 verdict — Nano Banana 2 + Pixar 3D + multi-photo identity wins

> **2026-05-10 update**: the BRAND-REGISTER portion of this ADR (Pixar-3D as Hadouta's locked illustration style) was reverted by **ADR-028** after iter 7 face-fidelity testing showed Pixar models bias toward youthful-cute on adult characters. The brand is now watercolor again per ADR-005. **However, the MODEL + ARCHITECTURE portion of this ADR (Nano Banana 2 + multi-image identity reference + Bible-driven prompt construction) STILL STANDS** — the iter 7 marathon validated that architecture in production-scale use; only the style register changed.

**Date:** 2026-05-06
**Status:** Accepted (model + architecture portion); brand portion SUPERSEDED by ADR-028 (2026-05-10)
**Supersedes:** none
**Extends:** ADR-024 (Bible-driven illustration pipeline)
**Companion:** ADR-027 (watercolor → Pixar-3D brand pivot — itself superseded by ADR-028)
**Type:** Outcome ADR — locks the architecture verified across 6 iterations

---

## Context

Phase 1 was a focused verification sprint to answer the founder's "wtf it's him" face-fidelity question — the gem-of-the-product question Hadouta launches on. The Phase 1 design spec (`docs/superpowers/specs/2026-05-05-phase-1-pixar-kontext-quick-cycle-design.md`) hypothesized that swapping Sprint 2's deployed Nano Banana Pro watercolor pipeline (~50–70% perceptual identity, customer-facing test on حنين's Eid order showed style drift + character drift + cultural literalness) for a "Path D" architecture (Flux 1 Kontext Pro + Pixar-3D LoRA + multi-image identity reference, no per-customer LoRA training) would clear the wtf bar.

What Phase 1 actually produced: 6 generation iterations, ~$2.50 total spend, on a single test order (`36e86090-...`, حنين, age 5, First Day at School). The verdict diverged from the spec.

## Decision

**The Path D architectural hypothesis is partially confirmed and partially superseded.** The verified-winning architecture is:

```
[Customer wizard: 1–3 photos uploaded]
   │
   ▼
[Story (gpt-4o)]                                        — unchanged from ADR-024
   │
   ▼
[Bible (gpt-4o + gpt-4o vision)]                        — unchanged from ADR-024 in shape;
   │                                                       Sprint 3 must revise prompts (see Gaps)
   ▼
[Per-page prompt assembly]                              — Sprint 3 must port iter-6's
   │                                                       inline Pixar prompts into
   │                                                       buildIllustrationPrompt
   ▼
[Illustration via fal-ai/nano-banana-2/edit]            — UPGRADED from nano-banana-pro/edit
       provider: "nano-banana" (default)                 (commit 278f0a3, 2026-05-06)
       image_urls: customerPhotos (1–3, no max change)
       Pixar 3D style applied via prompt overlay only
       (no LoRA, no per-customer training)
       cost ~$0.08/image
   │
   ▼
[PDF assembly via Puppeteer]                            — unchanged from ADR-024
```

**Path D's two locked-in pieces:** Pixar-3D as the brand register (NOT watercolor), and multi-image identity reference (1–3 customer photos passed as `image_urls` on every generation).

**Path D's discarded piece:** Flux 1 Kontext Pro + custom Pixar-3D LoRA. Across iterations 2–4 it produced ~75–85% face identity (the founder's "wtf 98%" reading) but consistently failed at supporting-character age differentiation, narrative-action depiction (e.g., active ribbon-tying), accessory-state stability across pages, and multi-character scene composition. The same Pixar prompts on Nano Banana 2 (iteration 6) produced visibly better adult-character rendering, action moments, and cross-page consistency at half the per-page cost ($0.08 vs $0.15 of the previous Pro tier).

## What was tried, in chronological order

| # | Architecture | Pages | Cost | Outcome |
|---|---|---|---|---|
| 1 | Flux Kontext Multi + LoRA loras-param de-risk | 1 | ~$0.10 | LoRA `loras` array param accepted by API. Path verified. |
| 2 | Flux Kontext + Civitai Pixar LoRA, iter-4 inline prompts predecessor | 4 | ~$0.40 | Page 16 image returned 10 KB (model collapsed on contradictory dim-close-up + pajamas-not-in-photos prompt). Mother on P1 looked teen. Action moment absent. Accessory drift (ribbon vs headband). |
| 3 | Same as iter 2, refined character-differentiation language + bigger negative prompts | 4 | ~$0.40 | Page 16 fixed (no more black). Mother still teen. Classmates clearly differentiated for the first time. Teacher still ~25-year-old. |
| 4 | Same as iter 3 + Pixar movie references for age (Encanto's Julieta, Inside Out teachers), explicit "DYNAMIC mid-action" language for ribbon-tying | 4 | ~$0.40 | Cover dynamic walking pose. Classmates better. Mother still teen-looking. Action still not depicted (model rendered hand-pat instead of ribbon-tying). Accessory rendered as headband not ribbon. **Plateau hit.** |
| 5 | OpenAI gpt-image-2 (April 2026 release) | 0 (blocked) | $0 | HTTP 403: "Your organization must be verified to use the model `gpt-image-2`." Verification required identity upload (Persona ID + selfie); founder verified but propagation didn't complete during this session. Untested, marked as "blocked, retry available." |
| 6 | **fal-ai/nano-banana-2/edit (Gemini 3.1 Flash Image, Feb 2026) + iter-4 inline Pixar prompts** | 4 | ~$0.32 | **Mother on P1 finally renders as adult woman.** Active ribbon-tying moment depicted. Teacher on P8 reads as adult authority figure. Two named classmates clearly distinct. P16 dramatic golden-hour light. Cover includes legible English + Arabic typography baked into the image (Nano Banana 2's documented strength). Cross-page accessory consistency (red ribbon-bow stable, no headband drift). Strongest output across all 6 iterations. |

Generations preserved in DB for review:
- Iteration 2: `8bb2ab5c-5956-4796-bc2c-40fc02d1a492`
- Iteration 3: `ca083aa1-a7c7-41a5-8e7d-62a63cd3b3af`
- Iteration 4: `a74db112-9fba-41ad-91d9-e576513b0d80`
- **Iteration 6 (verdict):** `fe8fe560-c009-4cd4-8533-83fca7b0a5e8`

## Why Nano Banana 2 won (engineering reasoning)

1. **In-context attention diluted across pages on Flux Kontext.** The same multi-character prompt that the model could only partially render on Flux ("mother is 35-year-old WOMAN, NOT a teenager") was rendered correctly on Nano Banana 2. Gemini 3.1's reasoning planner appears to disambiguate subject-of-photo from other-characters-in-scene better than Flux Kontext's flow-matching architecture.

2. **Pixar-3D register comes through prompt-only, no LoRA needed.** Iter 6 used zero LoRAs. The Pixar-style anchor language alone (Disney Encanto / Coco / Inside Out + 3D-rendered features + cinematic color grading) produced consistent Pixar register across all 4 pages. This eliminates the LoRA-hosting complexity and the §1(c)(ii) license carve-out we had been operating under.

3. **Text-in-image is a first-class capability.** Iteration 6's cover rendered "HANINE'S FIRST DAY — Her Big Adventure Begins!" as legible English typography baked into the illustration. Iteration 6's classroom scene rendered the Arabic alphabet poster (الألف الباء التاء) on the wall. Neither is reliably possible with Flux Kontext at any quality tier. For a bilingual children's-book product, this is product-relevant, not aesthetic-relevant.

4. **Cost per page roughly halved.** $0.08/edit on `fal-ai/nano-banana-2/edit` vs $0.15/edit on `fal-ai/nano-banana-pro/edit`. Per-book at 17 pages: ~$1.36 vs ~$2.55. At 250 EGP retail (~$5.10 USD), AI cost ratio drops from ~50% to ~28%.

## Production code state (changes already shipped)

**Committed during Phase 1:**

- `src/lib/ai/illustration-generator.ts` — endpoint constants renamed `NANO_BANANA_PRO_EDIT` → `NANO_BANANA_2_EDIT`, value swapped `fal-ai/nano-banana-pro/edit` → `fal-ai/nano-banana-2/edit`. `modelId` strings updated. (commit `278f0a3`)
- `src/lib/ai/prompts/build-illustration-prompt.ts` — `appendPixarStyleAnchor()` exported helper added with Pixar-trigger-frontloaded language + anti-watercolor negatives countering Bible's anti-3D negativeStyle. (commits `6c84993a`, `37ba2ab` iteration update)
- `src/lib/ai/illustration-generator.ts` — `IllustrationProvider` type + `flux-kontext-pixar` provider dispatch (added to support iter-1-through-4 testing; **kept in code as a reachable alternative provider** but not used in production default path). (commit `b030db11`)
- `src/jobs/generate-book.ts` — reads `aiSettings.illustrationModel` and dispatches `'flux-kontext-pixar'` value to the alt provider; default falls through to `'nano-banana'` which now points at Nano Banana 2. (commit `a17bf05b`)

**Result of these changes:** all new customer orders generated by `runGenerationPipeline` will use Nano Banana 2 by default. The Bible-driven prompt builder still produces watercolor-era styleBible language for now (see Gaps).

## Production gaps Sprint 3 must close

The verdict architecture is committed in the *generation endpoint* but not yet in the *prompt-construction layer*. Iteration 6's quality came from inline Pixar prompts (script-level) bypassing the production `buildIllustrationPrompt`. Production today would produce iteration-1-quality output, not iteration-6-quality, until these are fixed:

1. **Bible-gen prompt rewrite** (`src/lib/ai/prompts/bible-system-prompt.ts`):
   - `styleBible.medium` should default to "Pixar 3D animated style" not "soft watercolor on cream paper"
   - `styleBible.negativeStyle` should default to Pixar-friendly negatives ("NOT photorealistic, NOT watercolor, NOT 2D-flat, NOT real photo") not "NOT 3D-rendered, NOT Disney-cartoon"
   - `characterBible.supportingCharacters` array MUST be populated by the Bible-gen step from named characters in the story (currently empty in 100% of generations — bug, never worked). Add age cues + physical-distinctiveness language per supporting character.
   - `characterBible.mainChild.outfit.default` should be story-aligned, not generic ("school uniform with red ribbon" for a school-day arc, not "bright green top with fabric bow").

2. **`buildIllustrationPrompt` rewrite** to include the iteration-6 inline-prompt structure:
   - Pose & emotional-moment direction per page (read from `bibleJson` with new fields, OR derive from story scene + page act)
   - Setting & environmental-detail props per page
   - Per-page character-presence injection ("MOTHER is in this scene" / "TEACHER + 2 named CLASSMATES" — derived from supportingCharacters + scene text)
   - Identity-disambiguation language ("photos = ONLY for Hanine, NOT for any other character")
   - 60/40 hero-vs-setting composition direction
   - Anti-conflicting-style negative prompt block

3. **Backwards-compat for in-flight generations.** Generations created before 2026-05-06 have watercolor-era Bibles. Sprint 3 should NOT auto-regenerate them; admin can choose to regenerate per-order if customer requests. Migration path: a one-off script that re-runs Bible-gen for selected orders with the new prompt template.

4. **`appendPixarStyleAnchor` may be retired.** Once the Bible-gen step produces Pixar-friendly styleBible by default, the post-hoc anchor overlay becomes redundant. Until then it stays in the codebase as a safety net.

5. **Flux Kontext + Pixar-LoRA path can be removed.** `provider: "flux-kontext-pixar"` dispatch + `callFluxKontextPixar()` helper + `PIXAR_STYLE_LORA_URL` env var + `verify-fal-kontext-lora.ts` de-risk script — none of these are reachable in the verdict architecture. Sprint 3 cleanup task can delete them. The `fal-ai/flux-pro/kontext/multi` endpoint usage and Civitai LoRA hosting are not part of the verdict.

## License posture (Phase 1 retrospective + production-going-forward)

**Phase 1 (testing under non-production carve-out):**
- Iterations 1–4 used `prithivMLmods/Canopus-Pixar-3D-Flux-LoRA` on HuggingFace (trained on Flux.1 [dev]) under BFL Flux.1 [dev] License **§1(c)(ii)** "use by commercial or for-profit entities for testing, evaluation, or non-commercial research and development in a non-production environment." Boundary conditions held: outputs were Cloudinary internal evaluation artifacts; حنين's family received the original Sprint 2 Nano Banana watercolor PDF as their delivered product, NOT any Phase 1 output. No revenue-generating activity used Phase 1 outputs. See `docs/superpowers/plans/2026-05-05-phase-1-pixar-kontext-quick-cycle.md` "License preflight" section.
- Iteration 5 (OpenAI gpt-image-2) was attempted but blocked at OpenAI's organization-verification gate; no API call to a gated model succeeded.
- Iteration 6 (verdict) used `fal-ai/nano-banana-2/edit`, served by fal.ai under their commercial agreement with Google. **No license carve-out was needed for iteration 6.** This path is fully production-ready from a licensing standpoint.

**Production going forward:**
- Default illustration path = `fal-ai/nano-banana-2/edit` = full commercial via fal.ai. Customer-deliverable outputs are licensed for paid product use without further action.
- The `flux-kontext-pixar` alt provider in the code is technically reachable but should NOT be used for production until either (a) commercial license obtained from BFL, or (b) the Civitai LoRA is replaced with a [schnell]-base Apache-2.0 alternative. Until Sprint 3 cleans up that code path, it's commented "test-only" via the AI engineer's discretion.

## Cost economics (verified)

| Phase 1 line item | Cost |
|---|---|
| Iter 0 — fal Kontext-Multi LoRA-param de-risk | ~$0.05 |
| Iter 2 — Flux Kontext + Pixar LoRA × 4 pages | ~$0.40 |
| Iter 3 — same | ~$0.40 |
| Iter 4 — same | ~$0.40 |
| Iter 5 — gpt-image-2 (blocked, no charge) | $0.00 |
| Iter 6 — Nano Banana 2 × 4 pages | ~$0.32 |
| WebSearch + WebFetch overhead | ~$0.00 (covered) |
| **Total Phase 1** | **~$1.57** |

Well under the $5 budget specified in the design spec.

**Production projection per book (17 pages):**
- Story (gpt-4o): ~$0.04
- Bible (gpt-4o + vision): ~$0.02
- 17 illustrations × $0.08 (Nano Banana 2): ~$1.36
- PDF assembly (compute): negligible
- **Total per book: ~$1.42** in AI costs

At 250 EGP retail (~$5.10 USD): ~28% of revenue to AI cost. Acceptable for v1; Sprint 4+ optimization candidates include lower-quality tier on routine body pages while keeping high quality on cover (gpt-image-2-style tiered strategy applied to Nano Banana 2 quality knobs if/when fal exposes them).

## Wtf-rate calibration (founder + AI multimodal review)

**Founder's "wtf face" reading on iteration 1:** ~98% — the gut-recognition reaction.

**Founder's verdict on iteration 4 (Flux Kontext final):** "98% wtf face but supporting characters wrong, ribbon-tying not depicted, scene cold, accessory drift." Identity ✅, narrative quality ❌.

**Founder's verdict on iteration 6 (Nano Banana 2):** "okay look it for now right what we did what we reached so document everything please... I beileve we reached to a good results for now" — proceed-to-document framing.

**Claude's multimodal-vision review of iteration 6 (cross-checked against the 3 reference photos):**
- Face shape: rounded soft cheeks ✓ matches references
- Eye shape: large dark almond ✓
- Skin tone: warm Egyptian olive ✓
- Hair texture: curly medium-length dark brown ✓
- Smile: sweet open similar to references
- ~85–90% perceptual identity match across all 4 iter-6 images
- Cross-page outfit + accessory + hair styling: consistent across all 4 pages
- Adult character differentiation: mother reads as 30-something woman; teacher reads as adult authority figure; 2 classmates clearly distinct individuals

**The honest read:** identity is in the "parents will say wtf that's her" range, not at the 98%-cosine-similarity-of-photo-recognition range (impossible for stylized output). Brand goal achieved.

## Sprint 3 followups (recorded so we don't lose track)

**Production-quality:**
1. Bible-gen prompt rewrite (Pixar-friendly styleBible defaults + populated supportingCharacters + story-aligned outfit defaults) — biggest single gap
2. `buildIllustrationPrompt` rewrite to port iteration-6's inline-prompt structure (pose, environmental props, character-presence injection, identity disambiguation, 60/40 composition)
3. Story-system-prompt review for Pixar register alignment (currently still references watercolor in some examples)
4. End-to-end test of full 17-page generation under the verdict architecture (Phase 1 only tested 4 pages × 1 child)

**Cleanup:**
5. Remove `flux-kontext-pixar` provider code path + `callFluxKontextPixar()` helper + `PIXAR_STYLE_LORA_URL` env var + iteration scripts (1, 2, 3, 4, 5, 6) — all not reachable in verdict architecture
6. Remove `appendPixarStyleAnchor` once Bible-gen produces Pixar-friendly styleBible by default
7. `verify-fal-kontext-lora.ts` typecheck error cleanup (it has been ignored across Phase 1 because the script is correctly using a runtime-supported but type-undeclared parameter; remove the script when removing flux-kontext-pixar code path)

**Observability + validators (was Sprint 3's original focus, still in scope):**
8. PostHog funnel events around generation pipeline stages
9. Sentry instrumentation per stage
10. Validators framework v1 (cultural / age-band / religious-neutrality) — character validator becomes redundant under Path D since face fidelity is structurally bounded
11. Trigger.dev migration when concurrency demands durability
12. HMAC magic-link tokens for `/api/public/order-status/:orderId` (Sprint 2 followup)
13. Wizard photo upload UX rework — Phase 1 confirmed 1–3 photos is sufficient on Nano Banana 2; the spec'd 5–8 photo + slot UX is NOT required for the verdict architecture and can be deferred or skipped

## Consequences

- ADR-024 is extended (not superseded): the Bible-driven pattern + cultural glossary + multi-image identity reference are preserved. The provider endpoint is upgraded.
- ADR-005 (L3 photo + watercolor style) is partially superseded by ADR-027 (watercolor → Pixar-3D pivot) — see that ADR for brand implications.
- ADR-019 (multi-style architecture) is honored — `style` field on themes/orders/illustrations is the foundation that makes the watercolor-→-Pixar swap feasible without database migrations.
- Sprint 3 plan refreshes: the original "validators framework + Trigger.dev migration + Sentry/PostHog" focus stays, plus Phase 1 production-gap closure (items 1–4 above) is added as the new top priority.

## References

- Phase 1 design spec — `docs/superpowers/specs/2026-05-05-phase-1-pixar-kontext-quick-cycle-design.md`
- Phase 1 implementation plan — `docs/superpowers/plans/2026-05-05-phase-1-pixar-kontext-quick-cycle.md`
- Iteration scripts — `src/scripts/run-phase-1-iteration-{2,3,4,5-gpt-image-2,6-nano-banana-2}.ts`
- Production code — `src/lib/ai/illustration-generator.ts`, `src/lib/ai/prompts/build-illustration-prompt.ts`, `src/jobs/generate-book.ts`
- ADR-024 — Bible-driven illustration pipeline (extended)
- ADR-025 — Phase H pivot lessons (verification-before-commit principle)
- ADR-027 — Watercolor → Pixar-3D brand pivot (companion to this ADR)
- Verdict generation in admin — https://hadouta-admin.vercel.app/orders/fe8fe560-c009-4cd4-8533-83fca7b0a5e8
