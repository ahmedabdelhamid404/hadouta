# Session: Face-fidelity marathon — full 16-page Hana book on Nano Banana 2 + multi-turn refinement (Google direct)

**Date:** 2026-05-08 → 2026-05-10 (multi-day session)
**Status:** Full 16-page book SHIPPED to admin. Production code NOT yet migrated — iter 7 prompt architecture lives in scratch script only.
**Outcome:** Iter 7 architectural pattern proven on a real customer order. Production migration is the top Sprint 3 priority.
**Total session spend:** ~$8-12 across all iterations (rough estimate; failed Google calls = $0; successful Pro calls = $0.15; successful Flash calls = $0.04).

---

## 🔖 TL;DR for next session

1. **Iter 7 is the reference architecture.** Full 16-page book at https://hadouta-admin.vercel.app/orders/22563851-2047-4f9e-ac47-ad27e036d4ea — open it before doing anything else. Generation ID `22563851-2047-4f9e-ac47-ad27e036d4ea`.

2. **The iter 7 prompt structure must be migrated into production code.** Currently it lives in `hadouta-backend/src/scripts/_iter7_full_book.ts`. Needs to land in `bible-system-prompt.ts` + `buildIllustrationPrompt` + `illustration-generator.ts`. See "Production migration tasks" section.

3. **Brand: watercolor (per ADR-005), NOT Pixar-3D (ADR-027 superseded informally).** This session reverted the brand. ADR-028 should be written next session to formalize.

4. **Production model: `gemini-3.1-flash-image-preview` via Google direct API**, NOT fal.ai. Only Google direct supports multi-turn refinement (the killer feature). Tradeoff: Tier 1 throttling pain vs fal.ai's middleware capacity buffer.

5. **Retry-queue architecture is mandatory for production.** Synchronous fail-and-die is unacceptable when calling Google direct. See ADR-029 design (not written yet).

6. **NEVER call Nano Banana 2 directly in production code without retry-with-backoff + thought_signature multi-turn + 3:4 aspect ratio + role-assigned input images.** All four are non-negotiable per this session's findings.

---

## What happened (chronological)

### Day 1 (2026-05-08): Sprint 3 #1+#2 commits + LoRA misconception cleared

**Committed work** (in `hadouta-backend` repo):
- `919b846` — Sprint 3 #1+#2: Pixar-3D Bible-gen + buildIllustrationPrompt rewrite
- `5ef4690` — Audit quick wins: glossary triggers + vision + sandwich anchors
- `d5de204` — Audit followups: age-matched few-shot shuffle + 4th example

These shipped to backend `main` branch (NOT pushed to origin yet).

**Then the founder asked about pre-trained LoRAs from Hugging Face for face fidelity.**

Three independent research dispatches confirmed:
- **No "general face fidelity LoRA" exists on HF** — the category is a misconception. LoRAs either bake a specific person or a specific style.
- **Nano Banana 2 cannot accept LoRAs** — it's Gemini 3.1 Flash Image (autoregressive multimodal), not Stable Diffusion / Flux. fal.ai's API silently ignores the `loras` field on this endpoint.
- **What the community calls "Nano Banana + LoRA"** is Pattern A: Nano Banana as TEACHER for training data → LoRA on a different base model (Qwen-Image-Edit, Flux). Nano Banana is never in the inference loop.
- **Empirical proof**: ran a test that POSTed `loras` field to `fal-ai/nano-banana-2/edit`. API silently accepted but ignored — the 'before' and 'after' images were essentially identical. See `_probe-nano-banana-loras.ts` script.

**Founder accepted the conceptual gap.** Pivoted to "use Qwen-Image-Edit-2511 with face-fidelity Pixar LoRA" which IS architecturally real on Replicate.

### Day 2 (2026-05-09): Watercolor revert + Qwen trial + multi-Hena bleed + AI Engineer architectural restructure

**Watercolor revert**: founder explicitly chose to switch the locked brand register from Pixar-3D back to watercolor (per ADR-005's original lock). Reason: Pixar models bias toward youthful-cute regardless of explicit age cues; watercolor is more forgiving on face geometry. The Sprint 3 #1+#2 Bible-gen rewrite (which shipped Pixar-3D defaults) was reverted in `bible-system-prompt.ts` to watercolor defaults — but only in scratch scripts, NOT yet committed.

**Qwen-Image-Edit-2511 trial** — `_qwen-trial-hana.ts` and `_qwen-dual-ref-trial.ts`:
- License: Apache 2.0 (commercial-clean per founder requirement)
- On fal.ai: yes (`fal-ai/qwen-image-edit-2511`)
- Multi-image edit pattern, native LoRA composition (but fal.ai endpoint doesn't expose loras param)
- Result: face fidelity better than Nano Banana 2's trash run, BUT severe **multi-Hena bleed** — every face in scenes (Mama, Sara) rendered as Hena's face. Diagnosed as: Qwen lacks reasoning planner to disambiguate "use this photo for protagonist only." Phase 1 verdict's reasoning advantage of Nano Banana 2 confirmed live.
- Dual-reference variant `[cover_url, photo_url]` tested — didn't fix multi-Hena.

**Cartoon-transfer website mystery solved**: founder mentioned websites that produce "wow" face fidelity from photos. AI Engineer dispatch revealed those use img2img with low denoising, preserving the photo's facial geometry while restyling. Hadouta's task is harder: generate NEW scenes with the customer's face, not just stylize one photo.

**Watercolor revert testing**:
- `_watercolor-trial-hana.ts` — generated cover + 3 pages on Nano Banana 2 with watercolor Bible (NEW Bible regenerated with watercolor styleBible defaults). Founder feedback: "trash" still + smile-on-camera issue + face-quality issue.

**THE BIG ARCHITECTURAL RESTRUCTURE (AI Engineer dispatch)**:

Founder rage at "smile on camera in every scene" triggered focused research. AI Engineer recommendation across 4 independent 2026 sources:

The watercolor illustration was doing TWO jobs (style anchor + character pose/expression) and the second job was fighting the prompt. **Fix: split the input image roles.**

| | Old approach | New approach (iter 5+) |
|---|---|---|
| Image 1 | reference photo | **IDENTITY REFERENCE only** (face/skin/hair, ignore expression/pose) |
| Image 2 | watercolor scene | **STYLE REFERENCE only** (medium/brushwork, ignore character/expression/composition) |
| Task framing | "edit image 2" | "render scene below as a fresh, original watercolor painting from scratch — do not copy any input image's pose or expression" |
| Scene description | bullet list of constraints | **single narrative paragraph** in positive prose, no NOT-negatives |
| Per-page expression | "MOUTH: lips slightly parted, no teeth showing — NOT smiling" | "Her lips are softly closed in a calm neutral line — she is contemplating, not posing for a viewer" (whole-face prose) |

The agent's research cited Google's official guidance: **"describe, don't list"** + **"use positive framing, not negation"** + **"explicit role assignment in prose, no token markup"**.

### Day 3 (2026-05-10): Iter 5 → 7 multi-turn + production-grade resilience + full 16-page book

**Iter 5 — Google direct + role-assigned prompts + multi-turn**:
- Switched from fal.ai to direct Google AI Studio API (`gemini-3.1-flash-image-preview`) because fal.ai credit was exhausted.
- Multi-turn turn 2 self-critique pattern.
- **`thought_signature` bug discovered**: Google's API rejects model-role messages without the `thought_signature` field. Fixed by capturing the raw response parts wholesale and replaying them in turn 2.
- **Direct https module**: bypassed Node's undici 5-min headers timeout (which fired even when the API call was working).
- **Unlimited 5-min retry on 503/429/500**: Google preview API on Tier 1 hits "high demand" 503s during peak hours. Retry-forever is the only viable production pattern.
- **Cloudinary upload retry (3 attempts)**: separate from Google retries, occasional Cloudinary timeouts.
- **Resumable**: script accepts existing generation ID and skips already-rendered pages.

**Iter 6 → 7 — full book + 3:4 aspect ratio + scale fix**:
- Founder feedback: images were too tall, characters were "monster-sized" on cover. Fixed:
  - Hard-locked aspect ratio via `generationConfig.imageConfig.aspectRatio: "3:4"` (portrait — fits A5 PDF without cropping).
  - Cover scale-fix: explicit "all characters at REALISTIC RELATIVE PROPORTIONS — protagonist not oversized vs background or other characters."

**Tier 1 throttling discovery**:
- Founder confirmed API key is on Google AI Studio Tier 1 (~$0-249 cumulative spend, basic priority).
- Tier 1 = better than free but capacity-constrained when global Gemini 3 demand spikes.
- Resolved: keep retrying until success. Going forward: spend $250+ to reach Tier 2 (substantially higher rate limits + fewer 503s + prompts not used for training).

**Brief Pro detour**: switched to `gemini-3-pro-image-preview` (Nano Banana Pro) thinking it might have separate, less-stressed capacity. Worked briefly (page 3 done in 40s vs Flash's 60-200s+) but founder reverted to Flash for cost reasons.

**Page 3-13 missing-source issue**: the watercolor baseline `_watercolor-trial-hana.ts` had only rendered cover + 3 pages, not all 16. So pages 4-16 had no watercolor source to refine FROM. Fix: fall back to the iter 7 cover (already in target watercolor style) as the style reference for missing pages.

**Final completion**: Iter 7 generation `22563851-2047-4f9e-ac47-ad27e036d4ea` — cover + all 16 pages rendered. Some absorbed multiple 503/500 retries transparently. Zero manual intervention after the script was fixed.

---

## What's in production code RIGHT NOW (committed)

**Backend repo** (`hadouta-backend`, branch `main`, NOT pushed):

| File | State |
|---|---|
| `src/lib/ai/prompts/bible-system-prompt.ts` | **PIXAR-3D** style anchor (Sprint 3 #1+#2 commit `919b846`). Watercolor revert NOT yet committed. ⚠️ CONFLICT WITH BRAND |
| `src/lib/ai/prompts/build-illustration-prompt.ts` | Pixar overlay + identity-disambiguation language (committed `919b846`). Multi-turn / role-assignment / face-visibility / pose-direction NOT yet in production. |
| `src/lib/ai/prompts/story-system-prompt.ts` | Has `charactersOnPage` + `keyObjectOrDetail` schema fields documented. Sprint 3 audit quick wins applied (committed `5ef4690`). |
| `src/lib/ai/illustration-generator.ts` | Calls `fal-ai/nano-banana-2/edit` (NOT Google direct). No retry logic. No multi-turn. No thought_signature handling. |
| `src/db/index.ts` | Bumped `idle_timeout: 300` and `connect_timeout: 30` in this session (committed earlier). |

**Production architecture HAS NOT been updated** with this session's findings. Iter 7 lives in scratch script only.

---

## Production migration tasks (Sprint 3 priority)

These need to land in production code before Hadouta can reliably ship the iter 7 quality:

### 1. Migrate Bible-gen prompt to watercolor (revert ADR-027's Pixar lock)
**File**: `hadouta-backend/src/lib/ai/prompts/bible-system-prompt.ts`
**Change**: revert the `## Style anchor` section from Pixar-3D defaults back to watercolor. The audit's recommended watercolor block (Tomie dePaola references, wet-on-wet keyword, cold-press paper, anti-Disney negatives) is the right target.
**Test**: regenerate Bible for a test order, verify styleBible.medium contains "watercolor" + "wet-on-wet".

### 2. Migrate iter 7 prompt structure into `buildIllustrationPrompt`
**File**: `hadouta-backend/src/lib/ai/prompts/build-illustration-prompt.ts`
**Change**: replace the current sectioned prompt with iter 7's narrative-paragraph structure:
- ROLE OF EACH INPUT IMAGE block (Image 1 = identity, Image 2 = style)
- "Render the scene below as a fresh, original watercolor painting from scratch — do NOT copy any input image's composition, pose, or expression"
- Per-beat narrative scene description (`sceneNarrativeFromBeat()`)
- Composition + lighting + style as positive prose blocks (no NOT-negatives in body)
- 3:4 aspect ratio mention
- Scale-fix language for cover

### 3. Switch illustration provider from fal.ai to Google direct
**File**: `hadouta-backend/src/lib/ai/illustration-generator.ts`
**Change**: replace `fal.subscribe(NANO_BANANA_2_EDIT, ...)` with direct Google API calls via `https.request()`. Use `gemini-3.1-flash-image-preview` (Nano Banana 2 on Google direct). Pass `imageConfig.aspectRatio: "3:4"`.
**Why**: only Google direct supports multi-turn refinement.

### 4. Add multi-turn refinement (turn 1 + turn 2 critique)
**File**: `hadouta-backend/src/lib/ai/illustration-generator.ts`
**Change**: after turn 1 generates an image, send a follow-up `model` role with the raw response parts (preserving `thought_signature`), then user role with critique prompt. See `_iter7_full_book.ts` for reference implementation.
**Cost impact**: ~2× per page (turn 1 + turn 2 = 2 successful calls). Per-book cost goes from ~$0.68 to ~$1.36 on Flash.

### 5. Implement retry-with-backoff
**File**: `hadouta-backend/src/lib/ai/illustration-generator.ts`
**Change**: wrap each Google API call with retry logic. Retry on 503/429/500. Exponential backoff (10s, 30s, 60s, 120s, then 5min repeating). Bail on 400/401/403 (permanent errors).
**This is non-negotiable** — Google preview API will 503 in production.

### 6. Implement queue-based retry at orchestrator level
**Files**: `hadouta-backend/src/jobs/generate-book.ts`, schema migration
**Change**:
- Add `failed_retry_pending` and `failed_human_review` to `generation_status` enum.
- Add `next_retry_at` and `last_error` columns to generations table.
- Background cron job (Railway cron OR Trigger.dev) every 5 min picks up `failed_retry_pending` generations whose retry window opened.
- After N retries (suggest 20), escalate to `failed_human_review` for admin intervention.

### 7. Cloudinary upload retry
**File**: `hadouta-backend/src/lib/cloudinary.ts` or wrapper
**Change**: 3-attempt retry with exponential backoff on Cloudinary upload failures (we hit timeout twice on iter 7 pages 13 and 16).

### 8. Get API key to Tier 2
**Action**: spend $250+ over 3 days on Gemini API. Tonight's iteration spend is probably $5-15. Budget for Sprint 3 testing OR run synthetic load to bump tier.
**Outcome**: Tier 2 drops 503 frequency dramatically + opt-out of training data use.

### 9. Write ADR-028 (Watercolor revert)
**File**: `docs/decisions/ADR-028-watercolor-revert-from-pixar-3d.md`
**Content**: supersede ADR-027's Pixar-3D pivot. Document rationale (face geometry forgiveness, Pixar youthful-cute bias, 503 throttle pain not worth model swap, brand consistency).

### 10. Write ADR-029 (Production retry-queue architecture)
**File**: `docs/decisions/ADR-029-production-retry-queue-architecture.md`
**Content**: document the queue-based retry pattern, Trigger.dev migration path, Cloudinary retry, multi-turn refinement, thought_signature handling, Tier 1 → Tier 2 path.

---

## Experimental scripts catalog (in `hadouta-backend/src/scripts/`)

All uncommitted. Keep for reference; do NOT ship to production.

| Script | Purpose | Status |
|---|---|---|
| `_probe-nano-banana-loras.ts` | Empirical test that fal.ai's `nano-banana-2/edit` silently ignores `loras` field | Test artifact — delete or move to docs |
| `_qwen-trial-hana.ts` | First Qwen-Image-Edit-2511 spike (cover + 3 pages) | Reference — multi-Hena bleed documented |
| `_qwen-dual-ref-trial.ts` | Qwen with `[cover, photo]` reference order | Reference — didn't fix multi-Hena |
| `_watercolor-trial-hana.ts` | First watercolor revert on Nano Banana 2 (cover + 3 pages) | Reference — only 3 pages exist as source |
| `_iter1_face_refine.ts` | Two-stage face refinement on Nano Banana 2 (fal.ai) | Superseded by iter 5+ |
| `_iter2_face_refine.ts` | Reversed reference order [photo, illustration] | Superseded |
| `_iter3_google_direct.ts` | First Google direct API switch | Superseded by iter 5+ |
| `_iter3_recover.ts` | Recovery for iter 3's varchar error | Throwaway |
| `_iter4_multiturn.ts` | First multi-turn attempt (failed at thought_signature) | Reference |
| `_iter5_final.ts` | Multi-turn + thought_signature fix + role-assigned prompts | Reference architecture |
| `_iter5_continue.ts` | Iter 5 continuation script | Throwaway |
| `_iter5_recover.ts` | Iter 5 recovery script | Throwaway |
| `_iter6_aspect.ts` | First 3:4 aspect ratio attempt | Superseded by iter 7 |
| **`_iter7_full_book.ts`** | **THE REFERENCE — full 16-page book on Google direct + multi-turn + 3:4 + scale-fix + face-visible + role-assignment + unlimited 1-min retry + resumable + Cloudinary retry** | **Migrate to production** |
| `_iter7_delete_page3.ts` | DB cleanup tool used during iter 7 | Throwaway |
| `_iter7_get_urls.ts` | Helper to list all page URLs of iter 7 generation | Useful — keep |
| `_neon-probe.ts` | Tests Neon connectivity via real driver (vs misleading bash TCP probe) | Useful debugging tool — keep |
| `_probe-google-api.ts` | Tests Google AI Studio API: list models, text gen, image gen | Useful debugging tool — keep |
| `_probe-and-recover.ts` | Earlier recovery script (different generation) | Throwaway |
| `_recover-hana-16.ts` / `_recover-hana-sequential.ts` | Earlier full-book recovery attempts | Throwaway |

**Recommended cleanup at end of Sprint 3**: keep `_iter7_full_book.ts`, `_neon-probe.ts`, `_probe-google-api.ts`, `_iter7_get_urls.ts`. Delete the rest after migrating their lessons into ADRs and production code.

---

## Generation IDs and admin URLs (this session)

The book of record:
- **Iter 7 (FINAL — 16 pages)**: `22563851-2047-4f9e-ac47-ad27e036d4ea` — https://hadouta-admin.vercel.app/orders/22563851-2047-4f9e-ac47-ad27e036d4ea

Earlier iterations (kept for comparison):
- Pixar trash baseline (Sprint 3 #1+#2 first run): `dfb7d9d5-7ff7-4a24-83ce-bd645251d17e`
- Watercolor baseline (3 pages only): `68d5add6-48da-4a3e-baf3-054ad2162326`
- Boy birthday test: `3c5ce810-a8a7-4086-8ae6-dacb8fcbd0a6`
- Qwen single-ref trial: `6522f0d5-4915-4882-b984-147cd78fc872`
- Qwen dual-ref trial: `e54f9061-b41c-42cf-9feb-fceb66329f06`
- Iter 1 fal.ai face refine: `c90aceae-63a0-4de1-9251-6330cc9e9718`
- Iter 3 Google direct: `69611877-d4b6-4f80-999b-0ab008bb22c5`
- Iter 5 multi-turn: `f3bb13cb-d5bd-4b58-9a42-3cf2cd2cc10c`
- Iter 5 fixed (5-min retry): `d3591a2e-6b6f-4797-b8c5-0b042e856354`

Order ID (Hana, friendship + cooperation theme): `76e6226a-452e-47d6-9209-b53717d6d1cd`

---

## Cost data

Per-call costs (rough estimates):
- `gemini-3.1-flash-image-preview` (Flash) on Google direct: ~$0.04/successful call
- `gemini-3-pro-image-preview` (Pro) on Google direct: ~$0.15/successful call
- `fal-ai/nano-banana-2/edit` on fal.ai: ~$0.08/successful call (middleware markup)

Failed calls (503/429/500): **$0** — Google + fal.ai don't bill failures.

Per-book cost projections (for production planning):
- Single-pass (no multi-turn) on Flash: 17 calls × $0.04 = ~$0.68/book
- Multi-turn (turn 1 + turn 2) on Flash: 34 calls × $0.04 = ~$1.36/book
- Multi-turn on Pro: 34 calls × $0.15 = ~$5.10/book

This session's actual spend: ~$8-12 estimated (multiple full-book attempts + experiments).

---

## Open architectural questions (next-session decisions)

1. **Multi-turn or single-turn for production?** Multi-turn doubles cost ($1.36 vs $0.68/book). Iter 7 used multi-turn but visual quality difference vs single-turn unclear without A/B test.

2. **Tier 2 spending plan**. $250 over 3 days = ~6 books × $40 of test traffic, or 250 books × $1.36 normal traffic. Pre-launch: deliberate test runs. Post-launch: natural growth.

3. **Trigger.dev migration timing.** ADR-010 deferred to "Sprint 3+". This session proves it's mandatory. Question: ship Hadouta MVP with naive cron-based retry first, then migrate to Trigger.dev? Or do Trigger.dev now?

4. **Per-customer LoRA training (Sprint 5+)**. ADR-024's deferred section. Iter 7's identity quality is a known ceiling — better identity preservation requires per-customer fine-tuning. Realistic only for premium tier.

5. **Brand: ADR-028 to formalize watercolor revert?** Founder verbally reverted Pixar-3D back to watercolor in this session, but no ADR is written yet. Sprint 3 followup.

6. **Watercolor sources for body pages**. Iter 7 used iter cover as fallback for pages 4-16 because watercolor baseline only had 3 pages. Production: each customer's first generation needs to render all 17 watercolor sources before face-refinement turn 2. Or: skip the "refinement" architecture entirely and just do single-turn from-scratch on Google direct with role-assigned references.

---

## What did NOT happen this session (deferred)

- ADR-028 / ADR-029 not written yet
- Sprint tracker not updated yet (this session note + ADRs needed first)
- Production code migration (items 1-7 above) not done
- The 3 committed Sprint 3 commits NOT pushed to origin yet (still local)
- The 13 experimental scripts NOT cleaned up
- Iter 7 PDF assembly NOT triggered (book is in admin queue but no PDF rendered)
- Tier 2 spending not initiated

---

## Resume protocol for next session

1. **Read this file FIRST** before anything else.
2. **Open the iter 7 admin URL**: https://hadouta-admin.vercel.app/orders/22563851-2047-4f9e-ac47-ad27e036d4ea — this is the architectural reference output.
3. **Read `hadouta-backend/src/scripts/_iter7_full_book.ts`** — the script that produced the reference. Understand the prompt structure, retry logic, multi-turn pattern, thought_signature handling.
4. **Decide** which migration task (1-10 above) is highest priority for the remaining Sprint 3 budget.
5. **Don't re-litigate** decisions made tonight: watercolor brand, Google direct, multi-turn, role-assigned references, 3:4 aspect, unlimited retry, resumable scripts. These are locked.

---

## Files committed to backend repo (this session — local only, not pushed)

```
919b846  feat(ai): Sprint 3 #1+#2 — Pixar-3D Bible-gen + buildIllustrationPrompt rewrite
5ef4690  feat(ai): Sprint 3 audit quick wins — glossary triggers + vision + sandwich anchors
d5de204  feat(ai): Sprint 3 audit followups — age-matched few-shot shuffle + 4th example
```

**Note**: the Pixar-3D defaults shipped in `919b846` need to be reverted to watercolor in next session. Don't push these to origin until that revert is committed too.

---

**End of session note. Next session: read this, then read `_iter7_full_book.ts`, then start migration.**
