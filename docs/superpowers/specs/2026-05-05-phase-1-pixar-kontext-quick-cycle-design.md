# Phase 1 — Pixar-Kontext Quick-Cycle Design

**Date:** 2026-05-05
**Status:** Draft — awaiting founder approval
**Scope:** Engineering experiment, ~1 day work. Lean-Startup verification of zero-shot identity preservation on Pixar-3D style register *before* committing to the per-customer-LoRA infrastructure that Phase 2 would require.
**Supersedes:** none yet
**Extends:** ADR-024 (Bible-driven illustration pipeline)

---

## 1. Background

Sprint 2 shipped the AI generation pipeline with `fal-ai/nano-banana-pro/edit` (Gemini 2.5 Flash Image with multi-image conditioning, ADR-024). Real-world results are ~70% perceptual identity match — the founder's "wtf it's him" gut-punch test fails on most pages because (a) Nano Banana is an in-context model with no fine-tune path (the 70% ceiling is in its weights — Google's docs explicitly say "may not always get it right"), and (b) the watercolor style register actively destroys fine facial features.

Industry convergence (Magic Story, Little Hero, Lullaby.ink, TinyTeller) is on **per-customer face LoRA training** for character consistency, paired with **Pixar-3D / 3D-stylized** registers that preserve face geometry.

Before committing to that full LoRA + async-fulfillment + 5–8-photo-wizard infrastructure (Phase 2), we run a **fast cheap A/B** to see how much the *style* swap and the *model* swap alone can move the wtf needle. If "Pixar-3D + Flux Kontext zero-shot" already hits the bar, we ship that and skip Phase 2 entirely. If it doesn't, we have empirical proof that the LoRA investment is necessary.

This is the Phase H lesson applied prospectively: **verify the cheap path before committing to the expensive one.**

---

## 2. Goal & success criteria

**Goal:** Side-by-side comparison — same customer order, same Bible, same prompts — generate 3 pages with the existing Nano Banana pipeline (control) and the new Flux.1 Kontext + Pixar-3D style pipeline (test). Founder inspects, decides direction.

**Success (Phase 1 itself):**

- Test path generates 3 pages successfully without database migrations, wizard changes, or any non-illustration-pipeline file edits
- Side-by-side render readable by founder in the existing admin queue UI (no new admin features needed)
- Decision data captured: founder annotation per test page — `wtf` / `better-not-wtf` / `no-improvement` / `worse`
- Total API spend ≤ $5
- Implementation time ≤ 1 working day

---

## 3. Non-goals (explicitly deferred)

These are intentionally out of scope for Phase 1. Some are Phase 2 work; some are Sprint 3 work that hasn't been touched yet.

- Wizard photo upload rework (5–8 photos / video frame extraction) — Phase 2 only if needed
- fal.ai per-customer LoRA training pipeline (`flux-lora-portrait-trainer`) — Phase 2 only
- ArcFace embedding service — Phase 2 only
- Auto-quality gate (post-train portrait check) — Phase 2 only
- 20-child verification cohort + parent rating protocol — Phase 2 only
- Async fulfillment SLA rewrite (24h Storyteller framing) — Phase 2 only
- ADR-005 supersede + brand brief watercolor → Pixar amendment — written when Phase 1 picks the path
- Custom Hadouta-Egyptian-Pixar style LoRA commissioning — Sprint 4+

---

## 4. Architectural change

### 4.1 Single-file impact

`hadouta-backend/src/lib/ai/illustration-generator.ts` gains a parallel code path. Existing Nano Banana code stays. Selection by an `ai_settings.illustration_provider` value: `'nano-banana' | 'flux-kontext-pixar'`. Default stays `'nano-banana'`. Admin manually flips to `'flux-kontext-pixar'` to run the Phase 1 test, then back.

### 4.2 New code path (test arm)

```
[input: customerPhotoUrls (1–3, existing), positivePrompt (existing)]
        │
        ▼
[append Pixar-3D style anchor language to prompt]
        │
        ▼
[fal-ai/flux-pro/kontext/multi]
   - prompt: enriched Bible-driven prompt
   - image_urls: customerPhotoUrls (up to 4 supported by Kontext multi)
   - loras: [{ path: PIXAR_STYLE_LORA_URL, scale: 0.85 }]    ← see §4.4 for fallback
   - aspect_ratio: '3:4'    (existing convention)
   - output_format: 'png'   (existing convention)
   - num_images: 1
        │
        ▼
[Cloudinary upload — existing path]
        │
        ▼
[IllustrationResult with modelId='flux-kontext-pixar']
```

### 4.3 Pixar-3D style anchor language

`build-illustration-prompt.ts` gets a single new function: `appendPixarStyleAnchor(prompt: string): string`. Called only when provider = `'flux-kontext-pixar'`. Appends:

> Render in Pixar 3D animated style — soft volumetric lighting, expressive facial features, warm cinematic color grading, smooth subsurface scattering on skin, in the visual register of Disney Encanto / Coco / Inside Out. Maintain Egyptian cultural specificity in costuming, setting, and props as described above.

The existing cultural-glossary negative examples (kahk-not-cookies, makarona-not-spaghetti, etc.) are orthogonal to render style and carry through unchanged.

### 4.4 Style LoRA selection (Phase 1 placeholder)

Top-rated Civitai Flux Pixar-3D LoRAs as of 2026-05-05:

- **LH Pixar 3D Style** — Civitai 928840 — single trigger word, strong consistency
- **FLUX Pixar Cartoon 3D Style by LH** — Civitai 1024253 — checkpoint, may not work as LoRA-loadable
- **3D Pixar Style (Jixar Character Design)** — Civitai 650251 — flagged as needing combination with base model

**Recommended for Phase 1:** *LH Pixar 3D Style (928840)* — pure Flux LoRA, single trigger, no base-model mixing required.

**License check required before commit** — Civitai LoRAs vary in commercial-use permissions. Implementation plan must verify the chosen LoRA's license is compatible with paid product use.

**Hosting:** fal.ai loads LoRAs from public URLs (Hugging Face, S3, etc.). The chosen Civitai LoRA must be either downloaded and re-hosted on fal.ai's storage, or mirrored to Hugging Face under a permitted license. This is one of the implementation steps in §6.

**Phase 1 placeholder, not the long-term answer.** Sprint 4+ commissions a custom Hadouta-Egyptian-Pixar LoRA from Egyptian illustrators (consistent with the cultural-specificity moat in ADR-002). Off-the-shelf is fine for "does the style register move the wtf needle" — that question doesn't depend on which Pixar LoRA we use.

### 4.5 Fallback if fal.ai Kontext endpoint doesn't accept LoRAs

The implementation step in §6 starts with verifying that `fal-ai/flux-pro/kontext/multi` supports the `loras` array parameter. If it doesn't:

- **Fallback A:** Use `fal-ai/flux-pro/kontext/multi` *without* the LoRA, with stronger Pixar-3D prompt language. Slightly weaker style consistency but valid Phase 1 test.
- **Fallback B:** Use `fal-ai/flux-lora` (text-to-image with LoRA) for cover only — but this drops multi-image conditioning, killing the identity reference. Probably not viable.

Decision: if no LoRA support, go with Fallback A (prompt-only Pixar) — still meaningfully tests the style + model swap. Document the limitation in the Phase 1 outcome ADR.

---

## 5. Test data + protocol

### 5.1 Reuse existing Cloudinary data

- **Order:** `36e86090-6f28-450a-8a61-812d5f610ed0`  (حنين, age 5 girl, First Day at School + Courage moral)
- **Generation:** `fad8f418-6464-43df-9ce2-06488b58c8a5`  (Phase H iteration 8 — has 3 multi-angle customer photos in Cloudinary, plus existing Nano Banana cover + 2 body pages already in admin queue → these are the **control**)

**No new wizard submission needed.** The verification reuses the photos and Bible already persisted from Phase H.

### 5.2 Pages to regenerate (test arm)

- **Cover** — highest identity load, full face, character-first composition
- **Body page with face prominent** — pick whichever body page in the order's Bible has the highest face-coverage scene (e.g., the moralMoment page where حنين is the visual focus)
- **One additional body page** — preferably a different scene class (action/wide-shot) for cross-page consistency check

These three are generated under `flux-kontext-pixar` provider; the existing `nano-banana` outputs for the same three pages are the control.

### 5.3 Side-by-side rendering

Admin queue page already shows generated images in a list. Phase 1 leaves this UI alone. Founder opens the order in the admin app twice (one tab per provider), or screenshots the control pages and views them adjacent to the new test pages. **No new admin UI features for Phase 1.**

(If side-by-side becomes too painful, a 30-minute Phase 1.5 task can add a `?provider=` query param to the admin order page that swaps which generation is shown. Reserved as a soft requirement.)

### 5.4 Founder annotation

For each of the 3 test pages, founder records one of:

- 🟢 **wtf** — clearly the child, gut-punch recognition
- 🟡 **better-not-wtf** — meaningfully improved over control but not wtf
- ⚪ **no-improvement** — comparable to control
- 🔴 **worse** — degraded vs control

Annotations captured in a quick markdown note (no schema changes).

### 5.5 Decision tree

| Annotation pattern (across 3 pages) | Direction | Next step |
|---|---|---|
| ≥ 2 × 🟢 wtf | Ship Path D | Sprint 3 plan: lock provider as `flux-kontext-pixar`, supersede ADR-005 (Pixar-3D adopted), update brand brief, update wizard step-7 copy, ship to production |
| ≥ 2 × 🟡 better-not-wtf | Ship Path D as interim, plan Phase 2 | Lock provider for production now, kick off Phase 2 design spec (LoRA + video upload) for Sprint 4 |
| ≥ 2 × ⚪ no-improvement OR 🔴 worse | Kill Path D | Treat Phase 1 as the verification that proved zero-shot isn't enough. Fast-track Phase 2 design + execution into Sprint 3. Pixar-3D **style decision still locks** — the data showed style alone wasn't enough but the brand pivot is independently justified by the industry signal. |

Result captured as ADR-026 ("Phase 1 outcome — Path D verdict") in the same session.

---

## 6. Implementation steps (rough — `writing-plans` skill expands these)

1. **Verify fal.ai `flux-pro/kontext/multi` LoRA support** — single API ping with `loras: [...]` parameter, check response for unknown-parameter error or accepted. ~30 min.
2. **Pick + license-check + host the Civitai LoRA** — recommended *LH Pixar 3D Style* (Civitai 928840). Download `.safetensors`, verify commercial-use license, mirror to fal.ai storage or Hugging Face, capture URL into env var `PIXAR_STYLE_LORA_URL`. ~1 hour.
3. **Add `ai_settings.illustration_provider` enum + default** — single Drizzle migration `0006_illustration_provider.sql`, values `'nano-banana' | 'flux-kontext-pixar'`, default `'nano-banana'`. ~45 min.
4. **Extend `illustration-generator.ts`** — provider switch, `flux-pro/kontext/multi` code path mirroring the existing `generateBodyIllustration` shape, modelId reporting. ~3 hours.
5. **Extend `build-illustration-prompt.ts`** — `appendPixarStyleAnchor()` function, conditional invocation by provider. ~45 min.
6. **Run test generation against order `36e86090-...`** — flip `ai_settings.illustration_provider` to `'flux-kontext-pixar'`, trigger illustration regeneration on the 3 selected pages via the existing admin reroll endpoint. **Note:** the reroll endpoint was wired in Phase G but not exercised end-to-end (per session-note 2026-05-05) — if it errors, fall back to a one-off script that calls `generateBodyIllustration` directly with the new provider. Confirm Cloudinary uploads land. ~30 min (or +1 hour with reroll-endpoint debugging).
7. **Founder side-by-side review + annotation + decision** — open admin queue, compare control vs test, annotate. ~30 min.
8. **Write ADR-026 with the verdict** — short, 1 page, captures decision + the 3 page comparisons. ~30 min.

**Total: ~7 hours engineering + ~30 min founder review = within the 1-day budget.**

---

## 7. Open questions / risks

1. **Kontext-Multi LoRA support is unverified.** Step 1 of §6 derisks this in 30 min. If unsupported, Fallback A (prompt-only Pixar) still produces a valid Phase 1 test.
2. **Civitai LoRA license risk.** Some Civitai models prohibit commercial use. License check before download (step 2 of §6) is non-negotiable.
3. **Single-customer N=1 test.** حنين is age 5, light-skinned. Phase 1 won't catch demographic-fairness issues, especially the Flux-LoRA-on-darker-skin gap flagged by the AI Engineer specialist. **This is a known limitation accepted for Phase 1's gut-check purpose.** Phase 2 verification cohort (20 children, 4–6 darker-skin) handles the wider validation when triggered.
4. **Bible was generated for watercolor style.** The existing Bible JSON references watercolor in `styleBible`. Style anchor in the prompt may conflict with Bible's `styleBible.medium`. Resolution: in the test arm, override `styleBible.medium` to "Pixar 3D animated" at prompt-assembly time without rewriting the persisted Bible. Cleaner than regenerating the Bible.
5. **Prompt length budget.** Kontext models have prompt-length limits. Adding the Pixar-3D anchor (~50 words) on top of the existing Bible-driven prompt may push past the limit on long scenes. Verify in step 4 of §6.
6. **No regression test on Nano Banana.** Phase 1 doesn't break the production path because `'nano-banana'` stays the default. Manual verification post-deploy: run a single Nano Banana generation to confirm the existing path still works.

---

## 8. Files touched

**Modified:**
- `hadouta-backend/src/lib/ai/illustration-generator.ts` — provider switch, new code path
- `hadouta-backend/src/lib/ai/prompts/build-illustration-prompt.ts` — Pixar-3D anchor
- `hadouta-backend/src/db/schema.ts` — `aiSettings.illustrationProvider` field
- `hadouta-backend/drizzle/0006_illustration_provider.sql` — new migration
- `hadouta-backend/.env.example` — document `PIXAR_STYLE_LORA_URL`

**Not modified:**
- Wizard frontend (no UX changes)
- Customer-facing copy
- Admin frontend (we visually compare in existing queue UI)
- Bible generator (style override happens at prompt assembly, not persistence)
- Story generator
- PDF assembly
- Database schema beyond the single new column

---

## 9. Outcome documents written *after* Phase 1

- **ADR-026** — Phase 1 verdict (`docs/decisions/ADR-026-phase-1-pixar-kontext-outcome.md`). Records the 3-page comparison, founder's annotation, the picked direction.
- **If 🟢 wtf:** ADR-005 supersede + brand brief watercolor → Pixar amendment (single commit, same session).
- **If 🟡 better-not-wtf:** Phase 2 design spec (`docs/superpowers/specs/2026-05-MM-phase-2-lora-video-upload-design.md`).
- **If ⚪ / 🔴:** Phase 2 design spec, accelerated into Sprint 3.

---

## 10. References

- ADR-024 — Bible-driven illustration pipeline (extended, not replaced)
- ADR-025 — Phase H pivot lessons (verification-before-commit principle drives this whole spec)
- ADR-005 — L3 photo upload + watercolor style (the file Phase 1 may supersede)
- `docs/sprints/sprint-tracker.md` — Sprint 3 entry points
- `docs/session-notes/2026-05-05-pdf-redesign-and-illustration-pipeline.md` — Phase H journey log
- AI Engineer specialist agent recommendation — see brainstorming session 2026-05-05 (this spec's parent conversation)
- [fal.ai FLUX.1 Kontext Multi endpoint](https://wavespeed.ai/models/wavespeed-ai/flux-kontext-dev/multi)
- [Civitai — LH Pixar 3D Style Flux LoRA](https://civitai.com/models/928840/lh-pixar-3d-style)
- [FLUX.1 Kontext announcement (BFL)](https://bfl.ai/announcements/flux-1-kontext)
