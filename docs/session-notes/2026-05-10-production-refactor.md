# Session: Production refactor — port iter 8 wins into `src/lib/ai/*`, kill recursive AI feedback, V7 retry queue, end-state validation

**Date:** 2026-05-10 (continuation of the same day's face-fidelity marathon)
**Status:** Production code refactored end-to-end; typecheck clean; 99 tests pass; production probe rendered successful cover + page 1 with iter-8-quality face fidelity.
**Outcome:** All iter 7/8 wins are now in `src/lib/ai/*` (the source of truth). Iter scripts are no longer load-bearing. Architecture validated against 10 customer use cases by AI Engineer with explicit pushback.
**Key shift this session:** stopped editing iter scripts; updated production code so any future iteration runs FROM production, not bypasses it.

---

## 🔖 TL;DR for the next engineer

1. **Production code is the source of truth.** All AI-pipeline behavior lives in `src/lib/ai/illustration-generator.ts` + `src/lib/ai/prompts/build-illustration-prompt.ts` + `src/lib/ai/prompts/bible-system-prompt.ts`. Iter scripts (`_iter*_*.ts`) are research artifacts only.

2. **Image order is locked: `image_urls = [customerPhotos..., staticAnchor]`.** Customer photos are Image 1..N (identity); the Beatrix Potter watercolor anchor is the FINAL image (style). This is iter 8's empirically-proven pattern. Putting the anchor first regresses face fidelity — we tried it tonight and the cover demoted Hena to background. Don't repeat.

3. **Static watercolor anchor URL is in `STATIC_WATERCOLOR_ANCHOR_URL` env var.** Locally set in `.env`. **Production Railway env still needs setting** (`pnpm tsx src/scripts/_upload_static_watercolor.ts` produces the URL; founder-set on Railway).

4. **V7 retry queue is fully wired** (schema + worker + resume). **Migration 0008 needs to be applied to Railway prod** (was applied to dev tonight via `_apply_0008.ts` workaround because Drizzle's journal stops at 0004).

5. **Customer photo upload is MANDATORY.** Wizard must enforce. Backend throws cleanly if absent.

6. **Multi-turn refinement is on for cover + every body page.** ~$0.08 per illustration, ~$1.45 per book. Tier-1 throttling tonight produced 5-17 min waits per illustration; the retry-forever-on-503 policy absorbs these but makes the pipeline slow until Tier-2 ($250+ cumulative spend) lands.

---

## What happened (chronological)

### 1. Diagnosed the recursive-AI-feedback bug

Iter 7/8 architecture used Image 1 = customer photo + Image 2 = AI-generated watercolor baseline (`SOURCE_GEN_ID = 68d5add6-...`) + Image 3 = AI-generated cover-as-wardrobe-anchor. Founder identified this is recursive AI — using AI output as authoritative reference for new AI output. Architecturally unsound; can compound artifacts across iterations.

Resolution: replace Image 2's recursive AI baseline with a STATIC public-domain watercolor reference (Beatrix Potter, _The Tale of Peter Rabbit_, 1902, PD since 2014). Remove Image 3 entirely (the cover-as-anchor pattern). Wardrobe consistency moves to text-only via the `[WARDROBE LOCK]` block at prompt end.

### 2. Picked the static anchor (Beatrix Potter PD)

Searched Wikimedia Commons. Five candidate plates downloaded to `/tmp/peter_rabbit_*.jpg` and reviewed visually. Founder picked **`PeterRabbit18.jpg`** — rabbit knocking over flower pots, terracotta accents, multi-element composition with strong watercolor brushwork. Saved to `hadouta-backend/src/assets/style-references/watercolor-anchor.jpg` (45 KB, 469×530, 300 DPI).

URL: `https://upload.wikimedia.org/wikipedia/commons/e/eb/PeterRabbit18.jpg`
License page: `https://commons.wikimedia.org/wiki/File:PeterRabbit18.jpg`
Public Domain Review backgrounder: `https://publicdomainreview.org/essay/the-tale-of-beatrix-potter`

### 3. Refactored production code (`src/lib/ai/*`)

Applied iter 8's architectural wins directly into production. Scope of changes:

- **`build-illustration-prompt.ts`**: added `[WARDROBE LOCK]` (verbatim outfit at prompt end), `[SCALE]` (peer-locked + off-center protagonist), `[EXPRESSION CALIBRATION]` (peer-matched intensity, eye-led restraint), `[STYLE LOCK]` (named-work watercolor anchors at prompt end). Restructured block order: REFERENCE IMAGES → STYLE → SUBJECT → COMPOSITION → SCALE → EXPRESSION → ACTION → SETTING → OTHER CHARACTERS → IDENTITY PRESERVATION → CONSTRAINTS → WARDROBE LOCK → STYLE LOCK. Added `resolveLocation` helper that picks `primaryLocation` vs `secondaryLocations[]` per page based on `story.pages[].locationName` (UC6 fix). Added outfit-variation continuity logic (UC2/UC3 fix). Stripped Pixar-3D `appendPixarStyleAnchor` legacy.

- **`illustration-generator.ts`**: rewritten for Google direct API (`gemini-3.1-flash-image-preview` via `https.request`, NOT fal.ai). Added multi-turn refinement (turn 1 + turn 2 with thought_signature pass-through), comprehensive error taxonomy (18+ Gemini categories with retry policy keyed off label), per-category retry executor (forever-1min on 503, honor-retryDelay on 429-throttle, no-retry on 429-billing, etc.). Added `getStaticWatercolorUrl()` reading from env var. Added `MultiTurnStats` telemetry. Added skip-and-continue orchestrator (`generateAllIllustrations` returns `BatchResult` with `coverFailure` + `pageFailures`). Removed `pulidFaceCropUrl`, `callFluxKontextPixar`, `flux-kontext-pixar` provider, `NANO_BANANA_2` text-to-image endpoint.

- **`bible-system-prompt.ts`**: reverted to watercolor register (per ADR-028). Added secondaryLocations name-matching guidance.

- **`story-system-prompt.ts`**: added `locationName`, `coverLocationName`, `coverCharactersOnPage` instructions to story-gen.

- **`schemas/story.ts`**: added optional `locationName` (per page), `coverLocationName`, `coverCharactersOnPage` fields.

- **`generate-book.ts`** (orchestrator): mandatory photo validation; resume logic (skip story+bible if already done; skip pages with existing illustrationUrl); per-failure terminal-status decision tree (`failed_retry_pending` for retryable / `failed_human_review` for permanent / `awaiting_review` for clean); aggregated multi-turn telemetry with >20% fallback warning; cover charactersOnPage falls back to page 1's; per-page outfit resolved via `resolveOutfit(pageNumber)`.

- **`db/schema.ts`**: added enum values `failed_retry_pending` + `failed_human_review`; added columns `next_retry_at` + `last_error` + `failure_summary`.

- **`db/migrations/0008_retry_queue.sql`**: enum extensions + ALTER TABLE for new columns + partial index on `(next_retry_at) WHERE status = 'failed_retry_pending'`.

- **`jobs/retry-failed-generations.ts`** (NEW): cron worker — picks up `failed_retry_pending` rows where `next_retry_at <= NOW()`, calls `runGenerationPipeline` in resume mode. 20-attempt cap then escalates to `failed_human_review`. Backoff: 5/15/30/60min then 5min cap.

- **`scripts/run-retry-worker.ts`** (NEW): Railway cron CLI entry.

- **`scripts/_upload_static_watercolor.ts`** (NEW): one-shot uploads `src/assets/style-references/watercolor-anchor.jpg` to Cloudinary, prints URL for env-var setup.

- **`scripts/_probe_production.ts`** (NEW): production smoke test — renders 1 cover + page 1 of Hena's order via the production code path. Useful for any future verification.

- **`scripts/_apply_0008.ts`** (NEW): workaround for orphaned migrations 0005-0008 (Drizzle's `_journal.json` stops at 0004; raw SQL files exist but aren't registered). Applies 0008 directly via raw SQL.

- **Tests**: refreshed `tests/unit/build-illustration-prompt.test.ts` + `tests/unit/illustration-generator.test.ts` for the new architecture. Added V2/UC6/V12 tests. Total: 99 tests passing across 12 files.

- **Deletions**: 12 legacy throwaway iter scripts removed (`run-phase-1-iteration-2/3/4.ts`, `run-phase-1-iteration-6-nano-banana-2.ts`, `run-phase-1-test-generation.ts`, `test-generate-illustration.ts`, `test-generate-story.ts`, `test-hana-friendship-16.ts`, `test-pixar-3-page-birthday.ts`, `_recover-hana-16.ts`, `_recover-hana-sequential.ts`, `_qwen-trial-hana.ts`, `_qwen-dual-ref-trial.ts`, `_probe-and-recover.ts`, `_watercolor-trial-hana.ts`).

### 4. AI Engineer end-state validation (10 customer use cases)

After the refactor, dispatched a comprehensive validation across UC1-UC10 + V1-V12 architectural concerns. Agent pushed back hard. Findings:

| | Use case | Verdict |
|---|---|---|
| UC1 | standard 0-variation | PASS |
| UC2 | single outfit variation (pajamas) | GAP → fixed via [IDENTITY PRESERVATION] outfit-continuity |
| UC3 | multi-segment Eid | FAIL → fixed via same |
| UC4 | multi-supporting-character (mom-as-teen risk) | PASS-WITH-RESIDUAL-RISK → V3 turn-2 anti-blend added |
| UC5 | cultural-anchor heavy (kahk/fanous) | GAP → deferred to launch+1 (cultural image library) |
| UC6 | multi-setting (apartment → mosque → apartment) | FAIL → fixed via secondaryLocations resolution |
| UC7 | traditional clothing photo | PASS |
| UC8 | single-photo customer | PASS |
| UC9 | multi-photo (2-3) | PASS |
| UC10 | layer-2 safety on a single page | FAIL → fixed via skip-and-continue orchestrator |

Plus three production-blocker bugs identified and fixed:
- V3 — turn-2 AXIS 1 was re-blending supporting characters' faces toward customer photos. Fixed: explicit "supporting characters keep their turn-1 face" clause.
- V7 — retry queue specified in ADR-029 but never implemented. Fixed: full Layer 3-4 implementation (resume logic + cron worker + schema migration + ADR-029 addendum).
- V12 — photos > 3 not validated; whitespace-only `distinguishing` field leaked "Distinguishing features:  ." into prompt; probe script banner said fal.ai. All cleaned up.

### 5. Initial probe attempt with anchor-first order — face fidelity REGRESSED

First probe rendered with `image_urls = [staticAnchor, ...customerPhotos]` (anchor LEADING per the validation agent's theoretical argument that "Image 1 = primary"). Cover came out: Hena demoted to background, another character (peer) holding the trowel as the focal subject. Face less detailed than iter 8.

Founder feedback: "the previous results were better in face details."

### 6. Image-order flip back to iter 8 pattern

Diagnosed: iter 7/8's empirical evidence shows Image 1 = customer photo (identity) is what produces "wtf it's him" face fidelity. The validation agent's theoretical argument (style first) didn't survive contact with reality.

Fixed: flipped `image_urls = [...customerPhotos, staticAnchor]`. Customer photo → Image 1 (primary identity); static anchor → final image (style). Updated all prompt language to match: `[REFERENCE IMAGES]` block now labels "Image 1..N = customer photos = IDENTITY", "the FINAL image = STATIC WATERCOLOR REFERENCE = STYLE". Turn-2 critique AXIS 1 references "Images 1..N, the customer photos" for face checking.

### 7. Re-probe + verification

Re-ran probe (~25-35 min total due to Tier-1 throttling — multi-turn pushes 2 calls per illustration so capacity pressure feels doubled).

**Cover**: Hena centered as iconic protagonist, watercolor register lands, no Beatrix Potter leakage, full body, Cairo street setting, 4 children gardening together.

**Page 1**: Hena's face recognizable from customer photo, Mama rendered as adult woman (not teen-Hena — Phase 1 anti-bias works), wardrobe locked (green top + bow + dark leggings + sunflower backpack), full body with terracotta tile floor visible, watercolor warmth preserved, expression restraint applied (no over-acting).

URLs:
- Cover: `https://res.cloudinary.com/dvewybhzv/image/upload/v1778426208/hadouta/orders/76e6226a-452e-47d6-9209-b53717d6d1cd/illustration_cover/nolu5cx6vmaulsj0h4hi.jpg`
- Page 1: `https://res.cloudinary.com/dvewybhzv/image/upload/v1778427262/hadouta/orders/76e6226a-452e-47d6-9209-b53717d6d1cd/illustration_page_1/vqxxexs1wyvgfzm3w09j.jpg`

End-to-end architecture verified.

---

## Current production architecture (post-refactor, locked)

### Reference image stack (per illustration)

```
image_urls = [
  customerPhoto1,      // Image 1 — IDENTITY (primary)
  customerPhoto2?,     // Image 2 — IDENTITY (optional, multi-photo)
  customerPhoto3?,     // Image 3 — IDENTITY (optional)
  staticWatercolorURL  // Image N+1 — STYLE (always FINAL)
]
```

Static watercolor URL pinned via `STATIC_WATERCOLOR_ANCHOR_URL` env var. Customer photos clamped to 3 (`MAX_CUSTOMER_PHOTOS`).

### Prompt structure (`buildIllustrationPrompt` output, in order)

1. `[REFERENCE IMAGES]` — role-locked language (Image 1..N = IDENTITY for protagonist; FINAL = STYLE; do not blend)
2. `[STYLE]` — `bible.styleBible.medium` + palette + lighting (watercolor activator words)
3. `[SUBJECT]` — protagonist + outfit string + body language
4. `[COMPOSITION & CAMERA]` — full-body anti-crop for body pages, upper-two-thirds for cover
5. `[SCALE]` — peer-locked, off-center protagonist for body pages; iconic central for cover (5.5 heads tall, no chibi)
6. `[EXPRESSION CALIBRATION]` — picture-book restraint, peer-matched intensity (no shocked-delight wide-eyes-open-mouth)
7. `[ACTION & EMOTION]` (or `[COVER SCENE]`) — story scene description
8. `[SETTING & PROPS]` — resolved location (primary OR secondary) + cultural anchors
9. `[OTHER CHARACTERS]` — Bible's supportingCharacters appearance verbatim per page
10. `[IDENTITY PRESERVATION]` (body pages only) — outfit continuity OR explicit variation override
11. `[CONSTRAINTS]` — Bible's negativeStyle + Beatrix Potter exclusion
12. `[WARDROBE LOCK]` — verbatim outfit string (END-position planner attention)
13. `[STYLE LOCK]` — named-work anchors (Strega Nona + Bear Hunt) + watercolor activator + no-rabbits negative

### Multi-turn refinement (`multiTurnRefine`)

Turn 1: prompt + Image 1..N (photos) + Image N+1 (anchor) → generate

Turn 2: replay turn-1 contents + model's raw response parts (preserves `thought_signature`) + 5-axis critique:
- AXIS 1 — FACE (compare to customer photos; supporting characters keep distinct turn-1 faces)
- AXIS 2 — WARDROBE (verbatim outfit; do NOT use static anchor for wardrobe)
- AXIS 3 — SCALE & EYE-LINE LOCK (peers' eyes/top-of-head/feet aligned at same horizontal position)
- AXIS 4 — FULL BODY ANTI-CROP (every child head-to-toe, ground margin below shoes)
- AXIS 5 — EXPRESSION RESTRAINT (peer-matched intensity, eye-led warmth, no shocked-delight)

Turn 2 fallback: if turn 2 fails (content block, network error, etc.), return turn 1's image. Telemetry tracks fallback rate; >20% triggers warn log.

### Error taxonomy

`categorizeError(err)` returns `{ label, retry, severity, action }`. 18+ Gemini categories + 11 Cloudinary + network + DB. Critical disambiguation: 429 has 4 sub-types (throttle / daily-quota / billing-depleted / tier-misconfigured) distinguished by message body, not status code alone.

### Retry policies

- `forever-1min` — only for 503 capacity (Tier-1 throttling)
- `honor-retryDelay` — for 429 throttle (parses `retryDelay` from Google's RetryInfo)
- `3x-backoff` — Cloudinary 5xx, Gemini 500/502, network timeouts
- `1x-then-alert` — Gemini STOP-no-image (model returned text)
- `retry-after-midnight-PT` — daily quota exhausted (orchestrator schedules)
- `no-retry` — billing depleted, auth, content blocks, region blocks

### Skip-and-continue orchestrator

`generateAllIllustrations` returns `BatchResult { cover, pages, coverFailure, pageFailures, totalDurationMs }`. Cover failure does NOT block body pages; per-page failures do not block other pages. Generate-book.ts decides terminal status from failure mix:
- 0 failures → `awaiting_review`
- All retryable → `failed_retry_pending` (cron worker picks up)
- Any non-retryable → `failed_human_review`

### Resume logic (V7)

`runGenerationPipeline(generationId, orderId)` checks for existing state:
- If `bibleJson` already present → skip story+bible generation
- If `bookPages.illustrationUrl` set → skip those pages
- Renders only what's missing

Cron worker (`retry-failed-generations.ts`) every 5 min picks up `failed_retry_pending` where `next_retry_at <= NOW()` and `retry_count < 20`. After 20 attempts → escalate to `failed_human_review`.

### Static watercolor anchor

- File: `src/assets/style-references/watercolor-anchor.jpg` (Beatrix Potter, 1902, PD)
- Cloudinary URL: pinned via `STATIC_WATERCOLOR_ANCHOR_URL` env var
- Pre-uploaded once via `src/scripts/_upload_static_watercolor.ts`
- Beatrix Potter subject leakage suppressed via triple-anchor exclusion (REFERENCE IMAGES + CONSTRAINTS + STYLE LOCK)

### Mandatory photo upload

- Wizard layer is the gate (founder lock-in 2026-05-10)
- Backend orchestrator + generators throw if absent (defensive)
- Photo count clamped to MAX_CUSTOMER_PHOTOS = 3

---

## Open items for the next engineer

### Ops (your auth/accounts required, not code changes)

1. **Apply migration 0008 to Railway prod** — was applied to dev tonight via `_apply_0008.ts` (Drizzle journal workaround). Same script works against prod DATABASE_URL. Or run migration 0008's SQL directly via psql.

2. **Set `STATIC_WATERCOLOR_ANCHOR_URL` on Railway production env** — value is `https://res.cloudinary.com/dvewybhzv/image/upload/v1778417017/hadouta/orders/_static_assets/style-reference/watercolor-anchor/onqvmdytpgzh6b5iixm4.jpg` (also in local `.env`).

3. **Wire Railway cron to `pnpm tsx src/scripts/run-retry-worker.ts` every 5 minutes** — Railway dashboard config.

4. **Verify wizard mandates photo upload on `hadouta-web`** — backend will throw cleanly if no photos arrive, but wizard should be the user-facing gate.

5. **Bump Google AI Studio API key to Tier 2** (>$250 cumulative spend) — Tier-1 throttling tonight produced 5-17 min waits per illustration. Tier-2 would cut these dramatically.

### Sprint 4+ work (deferred per validation)

1. **Cultural-element image library (V5 / UC5)** — kahk biscuits, fanous lantern, mashrabiya patterns, traditional Eid dress. Real photos (no AI provenance). Each becomes a small static asset that can be passed as additional image when culturalNotes triggers fire on a page. Sprint 4-5 work.

2. **Outfit-variation cards (3.C synthetic mannequin)** — for stories with `outfit.variations[]` non-empty, generate a single mannequin card per unique outfit and use as additional reference. Currently text-only; works for default outfits, weak on variations. Trigger this if production drift complaints emerge.

3. **Setting reference cards** — real photographs of Cairo apartment / school / mosque / playground / courtyard. Same pattern as cultural items.

4. **Supporting character archetype cards** — Egyptian Mama 30s/40s, Baba 30s/40s, Teacher, Best Friend 5yo, etc. Either commissioned art (cost + ADR-020 conflict) OR AI-generated pinned cards (AI-purity tradeoff to confront).

5. **Trigger.dev v3 migration** (ADR-029 Layer 5) — wraps the cron worker with durable jobs. Cron worker is sufficient for Sept launch.

6. **Admin UI for retry queue** — `hadouta-admin` repo needs to render `failed_retry_pending` and `failed_human_review` statuses with `failure_summary` per-page table + retry button.

7. **Drizzle migration journal repair** — migrations 0005-0008 are orphaned (raw SQL exists but `_journal.json` stops at 0004). Either regenerate via `drizzle-kit generate` from current schema (creates a single big migration that supersedes them) OR manually add journal entries with proper SHAs. `_apply_0008.ts` is a tactical workaround tonight; long-term the journal should match disk.

### Cost & operational notes

- Cost per book (multi-turn): ~$1.45 — $1.36 illustration + $0.04 Bible-gen + $0.02 vision + ~5% partial-success surcharge
- Failed Gemini API calls don't bill — only successful image generations cost
- Cloudinary 3-attempt retry costs nothing extra (Cloudinary doesn't bill failures)
- Tier-1 capacity 503s are expected on Google direct API; the retry-forever-1min policy handles them transparently but slowly

### Test running

- `pnpm typecheck` — clean as of 2026-05-10
- `pnpm test` — 99 tests pass across 12 files
- `pnpm tsx src/scripts/_probe_production.ts` — runs cover + page 1 of Hena's order through full production pipeline (~$0.16, 5-30 min depending on Tier-1)

---

## Key decisions locked tonight (don't relitigate)

1. **No recursive AI references.** Image 1..N = real customer photos, FINAL image = real PD watercolor. Nothing AI-generated is used as authoritative reference for new generations.

2. **Customer photo upload is mandatory.** Wizard is the gate; backend rejects no-photo orders.

3. **Image 1 = identity (customer photo), FINAL = style (Beatrix Potter PD)**. Reversing this regresses face fidelity (verified empirically 2026-05-10 evening).

4. **Multi-turn refinement is on for cover + every body page.** Worth the 2x cost for the face-fidelity + wardrobe + scale + expression critique payoff.

5. **Wardrobe consistency is text-only via 4-layer enforcement** (`[SUBJECT]` + `[IDENTITY PRESERVATION]` + `[WARDROBE LOCK]` + turn-2 AXIS 2 critique). Image 3 wardrobe anchor was rejected as recursive AI. Synthetic mannequin cards (3.C) deferred until production drift complaints arise.

6. **Skip-and-continue orchestration** — single-page failure does NOT kill the whole book.

7. **5-axis turn-2 critique** — face / wardrobe / scale / full-body / expression. Don't fragment into more axes (planner truncates past ~5-6).

8. **Pixar-3D legacy code REMOVED** per ADR-028. `flux-kontext-pixar` provider, `appendPixarStyleAnchor` helper, `callFluxKontextPixar` function, `PIXAR_STYLE_LORA_URL` env var — all deleted.

9. **No iter scripts edited going forward.** Production code is the source of truth. Iter scripts are research artifacts; if a future iter is needed, write it as a thin wrapper calling production functions.

---

## Files changed this session

### Modified
- `src/db/schema.ts`
- `src/jobs/generate-book.ts`
- `src/lib/ai/illustration-generator.ts`
- `src/lib/ai/prompts/bible-system-prompt.ts`
- `src/lib/ai/prompts/build-illustration-prompt.ts`
- `src/lib/ai/prompts/story-system-prompt.ts`
- `src/lib/ai/schemas/story.ts`
- `src/lib/cloudinary.ts`
- `tests/unit/build-illustration-prompt.test.ts`
- `tests/unit/illustration-generator.test.ts`

### Created
- `src/assets/style-references/watercolor-anchor.jpg` (Beatrix Potter PD plate)
- `src/db/migrations/0008_retry_queue.sql`
- `src/jobs/retry-failed-generations.ts`
- `src/scripts/_apply_0008.ts`
- `src/scripts/_delete_page.ts`
- `src/scripts/_fix_bible_variations.ts`
- `src/scripts/_force_awaiting_review.ts`
- `src/scripts/_iter8_full_book.ts` (research harness; preserved per validation agent recommendation)
- `src/scripts/_probe_production.ts`
- `src/scripts/_upload_static_watercolor.ts`
- `src/scripts/run-retry-worker.ts`

### Deleted (legacy iter throwaways)
- `src/scripts/_probe-and-recover.ts`
- `src/scripts/_qwen-dual-ref-trial.ts`
- `src/scripts/_qwen-trial-hana.ts`
- `src/scripts/_recover-hana-16.ts`
- `src/scripts/_recover-hana-sequential.ts`
- `src/scripts/_watercolor-trial-hana.ts`
- `src/scripts/run-phase-1-iteration-2.ts`
- `src/scripts/run-phase-1-iteration-3.ts`
- `src/scripts/run-phase-1-iteration-4.ts`
- `src/scripts/run-phase-1-iteration-6-nano-banana-2.ts`
- `src/scripts/run-phase-1-test-generation.ts`
- `src/scripts/test-generate-illustration.ts`
- `src/scripts/test-generate-story.ts`
- `src/scripts/test-hana-friendship-16.ts`
- `src/scripts/test-pixar-3-page-birthday.ts`

---

## Resume protocol for next session

1. **Read this file FIRST.**
2. **Check `STATIC_WATERCOLOR_ANCHOR_URL` is set on Railway** (and migration 0008 applied to prod).
3. **Wire Railway cron** for retry worker.
4. **Verify wizard mandates photo upload** on hadouta-web frontend.
5. **Run a fresh end-to-end test** by triggering a real order through the wizard once everything's deployed.
6. **Don't re-litigate the locked decisions** above — read the rationale, accept the conclusion, build forward.

---

**End of session note. The architecture is shipping-ready. Remaining work is ops (deploy steps) + Sprint 4+ enhancements (cultural cards, admin UI, Trigger.dev migration).**
