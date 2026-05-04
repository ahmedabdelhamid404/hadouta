# ADR-024: Bible-driven illustration pipeline with Nano Banana Pro Edit

**Date:** 2026-05-05
**Status:** Accepted (in production)
**Extends:** ADR-006 (AI stack), ADR-019 (multi-style architecture, watercolor MVP), ADR-022 (Sprint 2 AI pipeline architecture)
**Supersedes (in spirit):** ADR-006's Sprint 2 illustration provider choice (Gemini direct → Nano Banana Pro Edit via Fal.ai)
**Related spec:** `docs/design/specs/2026-05-03-illustration-pipeline-redesign-spec.md`
**Related ADR:** ADR-025 (Phase H pivot — why Flux+PuLID was rejected)

## Context

Sprint 2's illustration pipeline (Gemini 2.5 Flash Image direct, single-image text-to-image per page, no shared visual context across pages) produced four orthogonal failure modes observable in the first end-to-end customer test (2026-05-04, Fady's book):

1. **Style drift** — illustrations weren't watercolor; Gemini didn't reliably honor style instructions in text prompts
2. **Character drift** — child appeared as different avatars across pages (no shared identity reference)
3. **Setting drift** — place changed page-to-page even when story stayed in one location
4. **Cultural literalness failures** — "makarona bashamel" rendered as spaghetti meatballs, "kahk" as chocolate-chip cookies

In addition: customer-uploaded photos were dead-letter data (stored on Cloudinary, never used in illustration generation).

The brainstorm + spec (`docs/design/specs/2026-05-03-illustration-pipeline-redesign-spec.md`) identified the structural root cause as "each text-to-image call starts from random noise with no shared visual memory" and proposed a structured Bible (locked character/setting/style/cultural anchors generated once per story) + image-conditioning + identity injection. The spec'd implementation called for Flux 1.1 Pro + PuLID. Phase H verification (see ADR-025) showed PuLID has a portrait-only ceiling that fundamentally cannot render character-in-scene illustrations. Pipeline was pivoted to Nano Banana Pro Edit during verification.

## Decision

The shipped illustration pipeline architecture, as deployed `2026-05-05`:

### 1. Story → Bible → Prompts → Illustrations → PDF

Five-step pipeline, each step produces a structured artifact consumed by the next:

```
[Order placed via wizard with 1-3 photos uploaded]
   │
   ▼
[1] Story (gpt-4o, never gpt-4o-mini per ADR-025)
       output: storyJson with title, dedication, moralStatement, 16 pages
       each page has: number, act, emotionalBeat, moralMoment, text, scene
   │
   ▼
[2] Bible (gpt-4o + gpt-4o vision when photo present)
       generated AFTER story so it can reference story-specific cultural anchors
       output: bibleJson (persisted to generations.bible_json — separate column
       from story_json so admin can re-roll Bible without regenerating story)
       Bible contains:
         - characterBible.mainChild (locked appearance + outfit + persona)
         - settingBible (locked primary location with 50+ char detail)
         - styleBible (medium / palette / negativeStyle / composition)
         - culturalNotes (auto-detected from cultural-glossary.ts triggers)
   │
   ▼
[3] Per-page illustration prompts assembled by build-illustration-prompt.ts
       cover prompt:  Bible + cover scene
       page N prompt: Bible + page N scene + identity-preservation language
   │
   ▼
[4] Illustrations via fal-ai/nano-banana-pro/edit
       Cover: image_urls = all customer photos (or text-only when no photo)
       Body pages: image_urls = all customer photos (NOT cover; see Phase H §6)
       17 generations total per book (1 cover + 16 body)
       Concurrency cap: 5 parallel calls
   │
   ▼
[5] PDF assembly (Puppeteer + Cairo Arabic shaping)
       cover (poster register) → 16 body pages (framed-island register)
       → end-page (mirrors cover, with moralStatement + النهاية stamp)
```

### 2. Multi-photo identity reference

`customerPhotoUrls: string[]` flows from the photos table (ownerType='main_child') through the orchestrator to Nano Banana's `image_urls` parameter. Customers upload 1–3 photos in the wizard; all of them are passed as references on every illustration call. Multi-angle photos give Gemini's multimodal vision richer 3D face geometry → stronger identity preservation across pages than a single photo could provide.

### 3. Bible-driven structured prompts (NOT free-form text)

Per-page illustration prompt is built deterministically from Bible + scene by `build-illustration-prompt.ts`:
- Style block (from styleBible.medium + palette + light)
- Setting block (from settingBible.primaryLocation + primaryLocationDetails)
- Character block (from characterBible.mainChild — full appearance + outfit + personalityVisual)
- Scene block — explicitly emphasized: "PAGE N SCENE — this specific page MUST depict [scene]. The action, framing, and visible elements must communicate THIS moment specifically — different from any other page in the book."
- Cultural notes block (from bibleJson.culturalNotes, e.g. "During Eid el-Fitr — kahk biscuits on table, NOT chocolate chip cookies")
- Composition anchors (from styleBible.compositionAnchors)

For body pages only, the scene block ALSO includes an identity-preservation directive: "the child's face must EXACTLY match the reference photo — same face shape, same eye shape and color, same hair texture and length, same distinguishing features (dimples, gap teeth, freckles, etc.)."

This identity-preservation prompt language was added in Phase H iteration 7 and verified in iteration 8 — it counterweights the "make scene different per page" pressure that would otherwise drain attention from identity preservation. Together with multi-photo references, it produces stable identity across the 16 body pages.

### 4. Cultural specificity moat

A static curated `cultural-glossary.ts` lists ~15 Egyptian terms (kahk, makarona bashamel, koshari, fateer, molokhia, ful, aish baladi, shay, galabeya, gama', shari', shaqqa, fanous ramadan, sukkar malawan, birthday party Cairo). Each entry has Arabic + Latin transliteration + English description + explicit *negative examples* (what it is NOT) + trigger keywords. The Bible generator scans the storyJson for trigger keywords and adds matched entries to `bibleJson.culturalNotes` so they appear in every per-page illustration prompt.

This file is the cultural-specificity moat from ADR-002 made concrete. A US team can reproduce the same Bible+Flux+Nano Banana stack — but not the curated glossary with its negative-example anchors that prevent kahk → chocolate cookies, makarona → spaghetti, etc.

### 5. PDF redesign

Cover (poster register, 75% image bleed-to-edge) + 16 body pages (framed-island register, inner border + corner ✦ flourishes + ornamental divider + symmetric Eastern-Arabic-numeral page numbers) + end-page (mirrors cover; moralStatement above "النهاية" stamp in Aref Ruqaa). Three-font hierarchy: Aref Ruqaa (decorative, max 1 word per page) / El Messiri (headers) / Cairo (body). Watercolor washes in cover + end-page caption zones; paper-grain texture across all pages; ✦ ornament family throughout.

Cropping fix: `object-position: center top` on all `<img>` tags so when the source aspect doesn't match the display aspect, cropping happens from the bottom (where watercolor fade hides it) not the top (where heads are).

PDF size kept under Cloudinary's 10MB free-tier raw-asset limit via Cloudinary URL transforms `c_limit,w_750,f_jpg,q_70` applied at render time only (no permanent re-upload).

### 6. Why body pages do NOT receive the cover as image reference

Phase H iteration 4 tested `image_urls: [cover, photo]` for body pages. Result: Gemini anchored on the cover image (the strongest visual signal) and produced near-duplicates of the cover scene across all body pages, ignoring per-page scene prompts. Iteration 6 tested `[photo, cover]` (photo first for primary identity weight); result was less duplication but still too-similar room reuse across pages.

Iteration 5 with `[photo only]` and emphasized scene block produced distinct scenes per page with acceptable identity continuity. Iteration 8 added multi-photo + identity-preservation prompt language and locked this as the production architecture.

**Lesson:** in Gemini's multi-image conditioning, references are weighted in attention; passing a richly-detailed scene image (the cover) drags subsequent generations toward replicating that scene regardless of prompt. For per-page scene variation, the photo is the right reference (it carries identity but no scene).

## Consequences

**Positive:**
- All four Sprint-2 failure modes addressed: style drift (Bible's styleBible + negativeStyle), character drift (multi-photo references + identity prompt), setting drift (Bible's settingBible + locked character on every page), cultural literalness (curated glossary with negative examples)
- Customer photos are now actually used (no longer dead-letter data) — both for vision-described Bible appearance AND as image references for illustration
- Bible separation from storyJson means admin can re-roll illustrations OR Bible OR story independently
- Per-customer cost economics jumped from ~$0.025/book to ~$0.74/book — 30× — but quality leap is dramatically larger; customer-facing 250 EGP price absorbs the increase comfortably (~14% margin to AI cost)
- Bible-as-structured-data unlocks future validators framework (Sprint 3+): cultural validator can check `bibleJson.culturalNotes` against expected entries, character validator can compare illustration outputs against `characterBible.mainChild.appearance`

**Negative / cost:**
- Real per-book cost is now ~$0.74 (no photo) / ~$0.75 (with photos) vs ~$0.025 in Sprint 2. Pricing review may be needed for sustainability if margins compress.
- Illustration pipeline duration is ~3 minutes per book (story 60s + Bible 5s + 17 illustrations at concurrency 5 ~= 100s + PDF 15s).

**Deferred (per ADR-025 + spec):**
- Per-customer character LoRA training — gold standard identity preservation but 15–90 min training per customer breaks the real-time wizard. Sprint 5+ premium tier with async fulfillment.
- Watercolor style LoRA — train on commissioned Egyptian illustrations (Track B). Sprint 4+. Would replace style-prompt-engineering with model-baked style.
- Egyptian-Arabic-voice text LoRA via OpenAI fine-tuning. Sprint 5+. Would simplify story-system-prompt.ts from 600 lines to ~50 by baking voice into model weights.
- Validators framework v1.

## Implementation

Architecture committed across these commits:
- `e041d6e` (2026-05-05) — pivot from Flux+PuLID to Nano Banana Pro Edit (5 iterations of empirical work landed)
- `b844f8b` (2026-05-05) — multi-photo support + gpt-4o + identity-preservation prompt + Bible system prompt hardening

Spec: `docs/design/specs/2026-05-03-illustration-pipeline-redesign-spec.md` (Bible-driven concept; the spec called Flux+PuLID — see ADR-025 for the implementation reality).

Plan: `docs/design/specs/2026-05-03-illustration-pipeline-implementation-plan.md`.

Session notes: `docs/session-notes/2026-05-05-pdf-redesign-and-illustration-pipeline.md` for the full Phase H journey.
