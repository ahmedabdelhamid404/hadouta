# ADR-030 — Production illustration architecture (post-validation)

**Date:** 2026-05-10 (later same day after iter 7 face-fidelity marathon + production refactor session)
**Status:** Locked. Ships in `src/lib/ai/*` as of this date.
**Companion to:** ADR-024 (Bible-driven illustration pipeline), ADR-026 (Phase 1 model verdict — Nano Banana 2), ADR-028 (watercolor revert from Pixar-3D), ADR-029 (production retry-queue architecture). This ADR documents what was actually shipped.

## Context

ADRs 024, 026, 028, 029 each locked one slice of the production AI illustration pipeline. By 2026-05-10 evening the iter-7/iter-8 architecture had been validated empirically on a real customer order (Hena's 16-page friendship+cooperation book) but lived only in scratch scripts (`_iter7_full_book.ts`, `_iter8_full_book.ts`). Production code (`src/lib/ai/illustration-generator.ts`, `build-illustration-prompt.ts`) had not received those wins.

Founder directive (2026-05-10): port iter 8 wins into production code. Stop editing scratch iter scripts; future iters should be thin wrappers calling production functions.

After the port, an AI Engineer end-state validation across 10 customer use cases identified 3 production-blocker bugs (V3 turn-2 face-blend, V6/UC10 single-page failure killing the book, V7 retry queue not implemented despite ADR-029's spec) plus 5 quick wins. All were fixed the same night. A separate empirical regression — anchor-first image order regressing face fidelity — was identified and reversed mid-session.

This ADR records the locked architecture that resulted, so the next engineer can pick it up without re-deriving every decision.

## Decision

The Hadouta production illustration pipeline is locked at the architecture below. Iter scripts are no longer load-bearing; production code (`src/lib/ai/*`) is the single source of truth.

### 1. API: Google direct, NOT fal.ai

`gemini-3.1-flash-image-preview` via raw `https.request` to `generativelanguage.googleapis.com/v1beta/models/.../generateContent`.

Why Google direct over fal.ai: only Google direct supports multi-turn refinement (turn 1 + turn 2 self-critique with `thought_signature` pass-through). fal.ai's `nano-banana-2/edit` endpoint is single-shot. Multi-turn is the killer feature that justified migrating off fal.ai per ADR-029.

Implementation note: 20-minute socket timeout is set explicitly to bypass Node's undici 5-min headers timeout (which fires unpredictably mid-call).

### 2. Reference image stack: customer photos lead, static watercolor anchor LAST

```
image_urls = [
  customerPhoto1,   // Image 1 — IDENTITY (primary)
  customerPhoto2?,  // Image 2 — IDENTITY (optional, multi-photo)
  customerPhoto3?,  // Image 3 — IDENTITY (optional)
  staticAnchor,     // Image N+1 — STYLE (always FINAL)
]
```

**Why customer photos lead (not the anchor):** iter 7/8's empirically-proven pattern. Putting the static anchor at Image 1 (briefly attempted 2026-05-10 evening on theoretical grounds) regressed face fidelity — Gemini's planner gives Image 1 ordinal priority, so identity must be Image 1.

**Why a STATIC anchor (not AI-generated):** Beatrix Potter, _The Tale of Peter Rabbit_, 1902 first edition, public domain since 2014. Replaces iter 7/8's recursive AI baseline (`SOURCE_GEN_ID = 68d5add6-...`, a previous AI-generated test generation used as authoritative style reference). Recursive AI feedback compounds artifacts across iterations and is architecturally unsound.

Source asset: `src/assets/style-references/watercolor-anchor.jpg` (45 KB, 469×530, 300 DPI). Pre-uploaded to Cloudinary once via `src/scripts/_upload_static_watercolor.ts`; URL pinned via `STATIC_WATERCOLOR_ANCHOR_URL` env var. No runtime upload (Railway doesn't ship `src/assets/` to the runtime container by default).

**Why a non-recursive REAL reference instead of a synthetic-card style anchor:** founder lock-in 2026-05-10 — "no AI-generated images as authoritative reference, only real-world inputs." Synthetic cards (option 3.C from earlier validation) remain on the Sprint 4+ roadmap for outfit-variation cases where text-only proves insufficient, but tonight's primary architecture has zero AI provenance in the reference chain.

**Why Beatrix Potter despite her cultural-English subjects:** the prompt's role-locked language ("STYLE ANCHOR ONLY: extract medium/brushwork/wet-on-wet/paper-texture/palette; IGNORE its subjects entirely; do NOT render rabbits/English garden/blue jackets") + triple-anchor exclusion in `[REFERENCE IMAGES]` + `[CONSTRAINTS]` + `[STYLE LOCK]` reliably suppresses subject leakage. Empirical residual leakage rate: <5% per page.

### 3. Customer photo upload is MANDATORY

Wizard layer is the gate. Backend (orchestrator + cover generator + body generator) throws cleanly if no photos arrive — defensive. Photo count clamped to MAX_CUSTOMER_PHOTOS=3 (excess silently dropped with warn log).

Why mandatory: the protagonist's face fidelity is Hadouta's #1 brand promise ("wtf it's him"). Without the customer photo, identity has no anchor and quality is gambling on Bible's text-described features.

### 4. Multi-turn refinement on cover + every body page

Turn 1: prompt + Image 1..N (photos) + Image N+1 (anchor) → generate

Turn 2: replay turn-1 contents (preserves `thought_signature` via raw model parts) + 5-axis self-critique:
- AXIS 1 — FACE (compare to customer photos; supporting characters keep distinct turn-1 faces)
- AXIS 2 — WARDROBE (verbatim outfit string; do NOT use static anchor for wardrobe inspiration)
- AXIS 3 — SCALE & EYE-LINE LOCK (peers' eyes/top-of-head/feet aligned at same horizontal position)
- AXIS 4 — FULL BODY ANTI-CROP (every child head-to-toe, ground margin below shoes)
- AXIS 5 — EXPRESSION RESTRAINT (peer-matched intensity, eye-led warmth, no shocked-delight wide-eyes-open-mouth-lifted-brows)

If turn 2 fails (content block, network error, exhausted retry), fall back to turn 1's image. `MultiTurnStats` telemetry tracks fallback rate per generation; >20% triggers warn log.

Cost impact: 2 successful billable calls per illustration vs 1. Per-illustration: ~$0.08. Per-book (17 pages): ~$1.36 illustration + ~$0.06 Bible/vision = ~$1.45 all-in.

### 5. Prompt structure (block order in `buildIllustrationPrompt`)

1. `[REFERENCE IMAGES]` — role-locked image labels
2. `[STYLE]` — `bible.styleBible.medium` + palette + lighting (watercolor activator words)
3. `[SUBJECT]` — protagonist + outfit + body language
4. `[COMPOSITION & CAMERA]` — full-body anti-crop for body pages, upper-two-thirds for cover
5. `[SCALE]` — peer-locked, off-center protagonist for body pages; iconic central for cover
6. `[EXPRESSION CALIBRATION]` — picture-book restraint, peer-matched
7. `[ACTION & EMOTION]` (or `[COVER SCENE]`) — story scene
8. `[SETTING & PROPS]` — resolved primary OR secondary location + cultural anchors
9. `[OTHER CHARACTERS]` — Bible's supportingCharacters appearance verbatim
10. `[IDENTITY PRESERVATION]` (body pages only) — outfit continuity OR variation override
11. `[CONSTRAINTS]` — bible.negativeStyle + Beatrix Potter exclusion
12. `[WARDROBE LOCK]` — verbatim outfit at END (planner end-pass attention)
13. `[STYLE LOCK]` — named-work anchors (Strega Nona + Bear Hunt) + watercolor activators + no-rabbits negatives

Block-order rationale: Gemini 3's reasoning planner weights early-prompt + late-prompt blocks heaviest. REFERENCE IMAGES first to assign roles before any other block invokes them. STYLE second to set rendering intent. WARDROBE LOCK + STYLE LOCK at very end captures the planner's last-pass attention (the same end-position trick that anchors wardrobe).

### 6. Wardrobe consistency: text-only, 4-layer enforcement

No image-based wardrobe anchor (Image 3 in iter 8 was the recursive cover, removed entirely). Outfit consistency is enforced via 4 separate text mechanisms:

1. `[SUBJECT]` block: `Wearing: ${outfit}`
2. `[IDENTITY PRESERVATION]` block: `OUTFIT CONTINUITY: render the SAME outfit listed in [SUBJECT] above ("${outfit}")` (with explicit override for variation pages)
3. `[WARDROBE LOCK]` block (END of prompt): `${child.name} wears EXACTLY: ${outfit}.`
4. Turn-2 AXIS 2 critique: `${childName} must wear EXACTLY: ${outfit}. Regenerate any garment, color, or accessory that differs.`

Empirically validated for default outfits. Known weaker on outfit-VARIATION pages (Bible's `outfit.variations[]` non-empty); synthetic outfit cards (option 3.C) remain available as Sprint 4+ contingency if production drift complaints emerge.

### 7. Multi-setting story support

Bible has `settingBible.primaryLocation` + `secondaryLocations[]`. Story has per-page `locationName` + cover `coverLocationName` (optional fields, undefined for single-setting stories). `buildIllustrationPrompt`'s new `resolveLocation()` helper picks primary OR a matching secondary based on `locationName` (case-insensitive equality OR substring).

This was UC6 — previously `secondaryLocations` was dead code; multi-setting stories rendered every page as the apartment.

### 8. Skip-and-continue orchestration

`generateAllIllustrations` returns `BatchResult { cover, pages, coverFailure, pageFailures, totalDurationMs }`. Cover failure does NOT block body pages; per-page failure does not block other pages. Successful pages are persisted regardless.

Terminal status decision tree (in `runGenerationPipeline`):
- 0 failures → `awaiting_review` (normal happy path)
- All failures retryable → `failed_retry_pending` (cron worker picks up)
- Any non-retryable failure → `failed_human_review` (admin queue)

Single-page safety blocks no longer waste 16/17 already-rendered illustrations.

### 9. Comprehensive error taxonomy

`categorizeError(err)` returns `ErrorCategory { label, retry, severity, action }`. 18+ Gemini-direct categories + 11+ Cloudinary categories + network + DB. Ships in `src/lib/ai/illustration-generator.ts`.

Critical disambiguation: 429 has 4 sub-types distinguished by message body, not status code:
- `prepayment credits.*depleted` → `Gemini Billing - Credits Depleted` (no-retry, alert)
- `monthly spending cap` → `Gemini Billing - Spending Cap` (no-retry, alert)
- `per day` / `RPD` → `Gemini Quota - Daily Exhausted` (retry-after-midnight-PT)
- (default fallthrough) → `Gemini Rate Limit - Throttle` (honor-retryDelay)

The 429 silent-retry-forever bug from ADR-029's addendum is fixed by this disambiguation: billing-depleted no longer retries forever.

Per-category retry policies:
- `forever-1min` — 503 capacity (Tier-1 throttling); only category that retries indefinitely
- `honor-retryDelay` — 429 transient throttle (parses Google's RetryInfo)
- `3x-backoff` — Cloudinary 5xx, Gemini 500/502, network blips
- `1x-then-alert` — Gemini STOP-no-image (model returned text)
- `retry-after-midnight-PT` — daily quota exhausted (orchestrator schedules)
- `no-retry` — billing depleted, auth, content blocks, region blocks

### 10. Retry queue (V7, ADR-029 Layer 3-4 implementation)

Schema migration `0008_retry_queue.sql`: enum values `failed_retry_pending` + `failed_human_review`; columns `next_retry_at` + `last_error` + `failure_summary`; partial index on `(next_retry_at) WHERE status = 'failed_retry_pending'`.

Cron worker `src/jobs/retry-failed-generations.ts`: every 5 min picks up `failed_retry_pending` rows where `next_retry_at <= NOW()` and `retry_count < 20`. After 20 attempts → escalate to `failed_human_review`. Backoff: 5/15/30/60min then 5min cap.

Resume logic in `runGenerationPipeline`: skips story+bible if already done; skips pages with existing `illustrationUrl`. Network blip on page 16 of 17 → resume costs only that page (~$0.08), not the whole book ($1.45).

Railway cron entry: `src/scripts/run-retry-worker.ts`.

### 11. Mandatory photo enforcement layer

- Wizard: must require photo (frontend gate, separate `hadouta-web` repo)
- Orchestrator (`generate-book.ts`): throws if `customerPhotoUrls.length === 0` with explicit error message
- Cover generator + body generator: throws defensively (defense in depth)

### 12. Pixar-3D legacy code REMOVED (per ADR-028)

All deleted:
- `appendPixarStyleAnchor` helper + `PIXAR_STYLE_ANCHOR` constant
- `callFluxKontextPixar` function
- `flux-kontext-pixar` provider type union (now literal `"nano-banana"`)
- `PIXAR_STYLE_LORA_URL` env var dependency
- 12 legacy iter scripts that referenced the removed provider

## Consequences

### Positive
- Zero AI-on-AI feedback. All references are real-world inputs.
- Iter scripts no longer load-bearing; production code is the source of truth.
- Skip-and-continue + retry queue mean a single transient blip doesn't waste $1.45.
- Resume logic means retry only re-renders missing pages (~$0.08 per missing page, not $1.45 for whole book).
- Multi-turn refinement on every illustration; 5-axis turn-2 critique catches face/wardrobe/scale/full-body/expression issues.
- Customer photo as Image 1 produces strong face fidelity ("wtf it's him") empirically.
- Beatrix Potter PD anchor produces watercolor register without subject leakage (triple-anchored exclusion).

### Negative
- Tier-1 throttling on Google direct API produces 5-17 min per illustration during peak hours. Multi-turn doubles capacity pressure. Acceptable; mitigated by retry-forever-1min policy. Tier-2 (>$250 spend) cuts this dramatically.
- Wardrobe variation pages have a documented quality risk (text-only enforcement weaker than image anchor would be). Synthetic cards remain a Sprint 4+ contingency.
- Drizzle migration journal is out of sync with disk (migrations 0005-0008 are orphaned). Tactical workaround `_apply_0008.ts` for tonight; long-term either regenerate migrations or fix the journal manually.

### Neutral
- Customer photo upload became mandatory at the wizard layer. Backend rejects no-photo orders.
- All architecture decisions are research-grounded (ADRs 005, 020, 024, 026, 028, 029) + AI-Engineer-validated (V1-V12 across UC1-UC10).

## Open items (not in this ADR's scope)

1. **Tier-2 spending plan** for Google AI Studio (>$250 cumulative). Reduces Tier-1 503 frequency dramatically.
2. **Cultural element image library (V5)** — kahk biscuits, fanous lantern, mashrabiya patterns, traditional Eid dress. Real photos. Sprint 4-5.
3. **Synthetic outfit cards (3.C)** — for outfit-variation pages, generate one mannequin per unique outfit. Contingent on production drift complaints.
4. **Setting reference cards** — real photographs of Cairo apartment / school / mosque / playground. Sprint 4-5.
5. **Supporting character archetype cards** — Egyptian Mama 30s/40s, Baba 30s/40s, Teacher, peer 5yo. AI-purity tradeoff (Sprint 5+ if at all).
6. **Trigger.dev v3 migration (ADR-029 Layer 5)** — wraps the cron worker with durable jobs. Sprint 4+; cron worker is sufficient for September launch.
7. **Admin UI for `failed_human_review` queue** — `hadouta-admin` repo work; renders `failure_summary` per-page table + retry button.
8. **Drizzle migration journal repair** — regenerate via `drizzle-kit generate` from current schema OR manually add SHA entries for 0005-0008.
9. **Wizard photo-upload enforcement check** — `hadouta-web` repo; verify wizard cannot submit without a photo.

## Cross-references

- **ADR-005** — L3 photo upload + watercolor style (the original brand register lock; ADR-027's Pixar pivot was reverted in ADR-028).
- **ADR-020** — AI-only generation, Egyptian human review only — no commissioned art for MVP. Bears on cultural-element + character-archetype card decisions.
- **ADR-022** — Sprint 2 AI pipeline architecture (in-process orchestration that this ADR's retry queue extends).
- **ADR-024** — Bible-driven illustration pipeline (data + prompt layer). This ADR is the orchestration + API + reference-image layer that consumes that.
- **ADR-026** — Phase 1 character-fidelity verdict (Nano Banana 2 = locked model). Stands.
- **ADR-028** — Watercolor revert from Pixar-3D. Style register source-of-truth.
- **ADR-029** — Production retry-queue architecture. This ADR is the implementation; ADR-029's addendum is the canonical error taxonomy.

## Reference implementation

- Production source of truth: `hadouta-backend/src/lib/ai/illustration-generator.ts` + `build-illustration-prompt.ts` + `bible-system-prompt.ts` + `story-system-prompt.ts`.
- Orchestrator: `hadouta-backend/src/jobs/generate-book.ts`.
- Retry worker: `hadouta-backend/src/jobs/retry-failed-generations.ts` + Railway cron via `hadouta-backend/src/scripts/run-retry-worker.ts`.
- Schema: `hadouta-backend/src/db/schema.ts` + `src/db/migrations/0008_retry_queue.sql`.
- Static asset: `hadouta-backend/src/assets/style-references/watercolor-anchor.jpg`.
- Production smoke test: `hadouta-backend/src/scripts/_probe_production.ts`.
- Session note: `docs/session-notes/2026-05-10-production-refactor.md`.
