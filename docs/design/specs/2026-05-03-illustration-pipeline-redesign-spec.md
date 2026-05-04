# Illustration pipeline redesign — design spec

**Date**: 2026-05-03
**Status**: Approved (brainstorming complete) — ready for implementation plan
**Sprint context**: Sprint 3 — story quality + illustration consistency
**Depends on**: ADR-005 (photo upload + watercolor), ADR-006 (AI stack), ADR-019 (multi-style architecture, watercolor MVP), ADR-020 (AI-only generation, human review only), ADR-022 (Sprint 2 AI pipeline architecture)
**Related ADR (to be written)**: ADR-024 — Bible-driven illustration pipeline with Flux + PuLID (decouple identity from generation)
**Research source**: `/home/ahmed/Downloads/searchReports.md` (Arabic, ~2026-05 industry survey)

---

## 1. Context

The Sprint 2 illustration pipeline produces visually inconsistent books. Four failure modes were observed in the first end-to-end review:

1. **Style drift** — illustrations are not watercolor; Gemini 2.5 Flash Image does not reliably honor style instructions in text prompts (known weakness, in our Sprint 2 followups).
2. **Character drift** — the child's appearance changes from page to page (different hair, different face, different proportions). Each of the 17 illustration calls is a fresh text-to-image generation with no shared visual memory.
3. **Setting drift** — the place changes between pages (different couches, different windows, different rooms even when the story stays in one location).
4. **Cultural literalness failures** — Egyptian terms get rendered as Western analogs ("makarona bashamel" → spaghetti with meatballs; "kahk" → chocolate-chip cookies). Gemini's training data is heavily Western and the prompts don't constrain enough.

In addition: **the customer's uploaded photo is currently dead-letter data**. The wizard collects a photo (per ADR-005) and stores it on Cloudinary, but the AI illustration pipeline never reads it. The "describe persona" path is also unimplemented — the wizard collects free-form description text but no persona library exists.

The structural root cause (per the research): each text-to-image generation in Sprint 2 starts from random Gaussian noise with no shared identity reference. The industry has moved entirely to **image-based conditioning** for character continuity. Hadouta's pipeline doesn't do this.

## 2. Scope

**In scope:**
- New top-level **Bible** generation step at story-creation time (locked character/setting/style/cultural descriptions)
- Switch image generator from **Gemini 2.5 Flash Image → Flux 1.1 Pro via Fal.ai**
- Add **PuLID identity injection** for face-faithful generation when customer uploads a photo
- Use cover image as **visual reference** for body-page generation (Edit-based pipeline pattern from research)
- New **persona library** (6–8 starter personas) for the no-photo flow
- Static **Egyptian cultural glossary** locked in code
- New illustration prompt assembly: every page's prompt = `Bible + scene addendum` rather than standalone prompt
- New `bible_json` column on `generations` table (separate from `story_json`)
- Admin reject/reroll: keep Bible, re-roll illustrations by default; escape hatch to regenerate Bible

**Out of scope (deferred):**
- **Multi-character region-aware prompting** — MVP is main child only. Supporting characters either dropped or text-only descriptions in the Bible. Region-aware prompting (TaleDiffusion / IdentityStory pattern from research) deferred to post-MVP.
- **LoRA training** — text-only Flux watercolor; no commissioned-illustrator-fine-tuned LoRA for MVP.
- **Backfill of existing delivered books** — dev mode only, no real customers; existing PDFs stay as-shipped.
- **ControlNet / pose-aware conditioning** — not needed for v1.
- **Multi-photo upload** (parents + siblings) — single photo only for MVP.
- **Style customization per customer** — locked watercolor for MVP per ADR-019.

## 3. Design decisions (locked)

| Decision | Outcome | Rationale |
|---|---|---|
| Image generator | Flux 1.1 Pro via Fal.ai | Research consensus best-in-class May 2026; reliable style adherence; Fal.ai already a `package.json` dependency. |
| Identity injection | PuLID via Fal.ai (when photo uploaded) | Best face-fidelity-with-style-preservation per research; one-call API integration. |
| Body-page conditioning | Generated cover image as reference for all 16 body pages | Edit-based pipeline pattern; locks character once on cover, every body page is a contextual edit. |
| Style approach | Flux native watercolor (text prompt) | No LoRA training for MVP. Flux's prompt adherence is strong enough. |
| Photo flow | When uploaded → gpt-4o-vision describes into Bible AND PuLID injects face. When absent → persona library entry → text description in Bible. | Both flows produce a Bible. PuLID skipped when no photo. |
| Persona | Starter library of 6–8 personas (Arabic-named) covering common hair/skin combinations | Avoid freeform-description failures from non-technical parents. |
| Cultural glossary | Static code file; NOT regenerated per story | Requires curation, not generation. Locks Egyptian-specific terms. |
| Bible storage | New `bible_json` column on `generations` table | Separate lifecycle from `story_json`; admin can re-roll Bible independently. |
| Reject + reroll | Default: keep Bible, re-roll illustrations. Escape hatch: admin checkbox "regenerate Bible too." | Most failures are illustration-side; keeping Bible is faster + cheaper. |
| Cost ceiling | Accept ~$0.68–1.00 per book illustration cost | Up from ~$0.02 (Gemini); ~13–20% margin hit at 250 EGP price point; pricing review later. |

## 4. Architecture

```
[Order placed via wizard]
   │
   ▼
[Step 1] Story generation — gpt-4o-mini (existing, unchanged)
            output: storyJson with title, dedication, moralStatement,
                    16 pages each with a SCENE description (was: full prompt)
   │
   ▼
[Step 2] Bible generation — gpt-4o-mini (NEW)
            input:  wizard data + storyJson + uploaded photo URL (if any)
            output: bibleJson — character/setting/style/cultural locks
            ┌─ if photo uploaded: gpt-4o-VISION call describes
            │    actual child's features into characterBible.appearance
            └─ if no photo: persona library entry → text description
   │
   ▼
[Step 3] Illustration prompt assembly (NEW)
            cover prompt:  bible.character + bible.style + cover_scene
            page_N prompt: bible.character + bible.style + page_N.scene
   │
   ▼
[Step 4] Illustration generation — Flux 1.1 Pro via Fal.ai (REPLACES Gemini)
            cover: Flux only (no reference yet)
            pages 1-16: Flux + (optional) PuLID conditioned on:
                        - face_image_url = customer's uploaded photo (if any)
                        - reference_image_url = generated cover image
   │
   ▼
[Step 5] PDF assembly (existing — already redesigned per
         2026-05-03-pdf-redesign-spec.md)
```

## 5. Detailed specifications

### 5.1 Bible Zod schema

New file: `src/lib/ai/schemas/bible.ts`

```ts
export const bibleSchema = z.object({
  characterBible: z.object({
    mainChild: z.object({
      name: z.string().min(1),
      age: z.number().int().min(2).max(10),
      gender: z.enum(["boy", "girl"]),
      appearance: z.object({
        hair: z.string().min(20).describe(
          "Detailed locked description: type, length, color, style. e.g. 'dark curly hair pulled into two pigtails with red ribbons, shoulder length'"
        ),
        skin: z.string().min(10),
        eyes: z.string().min(10),
        distinguishing: z.string().describe(
          "Distinguishing features that anchor identity across pages — gap teeth, dimple, freckles, glasses, etc. Empty string OK."
        ),
      }),
      outfit: z.object({
        default: z.string().min(20).describe(
          "Default outfit on all pages unless story changes it. Specific colors + items."
        ),
        variations: z.array(z.object({
          pageNumbers: z.array(z.number().int()),
          description: z.string(),
        })).describe("Story-driven outfit changes. Most stories have 0-2."),
      }),
      personalityVisual: z.string().describe(
        "Body language, posture cues. e.g. 'energetic posture, often mid-motion, expressive eyebrows'"
      ),
    }),
    supportingCharacters: z.array(z.object({
      name: z.string(),
      relationship: z.string(),  // "mother", "best friend", "teacher"
      appearance: z.string(),
    })).describe("MVP: empty array. Future: regional prompting per character."),
  }),
  settingBible: z.object({
    primaryLocation: z.string().min(20).describe(
      "Where the story is mostly set. e.g. 'Hena's family apartment in Maadi, Cairo'"
    ),
    primaryLocationDetails: z.string().min(50).describe(
      "Locked visual details that recur — wall colors, furniture, recurring decor"
    ),
    secondaryLocations: z.array(z.object({
      name: z.string(),
      description: z.string(),
    })),
  }),
  styleBible: z.object({
    medium: z.string().describe(
      "e.g. 'soft watercolor on cream paper, visible brush strokes, gentle wet-edge bleeds'"
    ),
    palette: z.string().describe(
      "e.g. 'warm cream backgrounds, terracotta accents, soft sage greens, golden afternoon light'"
    ),
    light: z.string().describe(
      "Default lighting register — 'golden hour' / 'soft afternoon' / 'morning sun'"
    ),
    negativeStyle: z.string().describe(
      "What this is NOT. 'NOT photorealistic, NOT 3D, NOT Disney-cartoon, NOT anime, NOT vector-flat'"
    ),
    compositionAnchors: z.string().describe(
      "Composition rules that apply per page. 'subject in upper two-thirds; neutral lower third; no embedded text or signage in scene'"
    ),
  }),
  culturalNotes: z.array(z.string()).describe(
    "Story-specific cultural callouts the AI should remember. e.g. ['Story takes place during Eid el-Fitr — kahk biscuits on table, NOT chocolate chip cookies']. References the static cultural glossary."
  ),
});

export type Bible = z.infer<typeof bibleSchema>;
```

### 5.2 Persona library

New file: `src/lib/ai/personas.ts`

Starter library of 6 personas. Each persona is a complete `mainChild.appearance` block plus default outfit. The wizard offers persona-picker; selected persona seeds the Bible's `mainChild` (gpt-4o then refines based on age/name/wizard inputs).

```ts
export const PERSONAS = [
  {
    id: "curly-girl-young",
    label: "بنت بشعر مجعد، 3-5 سنوات",
    ageBand: "3-5",
    appearance: {
      hair: "dark curly hair shoulder-length pulled into two pigtails with colorful ribbons",
      skin: "warm medium-olive skin",
      eyes: "large round dark-brown eyes",
      distinguishing: "small dimple on left cheek, slight gap between front teeth",
    },
    outfit: "yellow cotton dress with white daisy print, white short-sleeved cardigan, brown leather sandals",
  },
  {
    id: "straight-girl-young",
    label: "بنت بشعر طويل ناعم، 3-5 سنوات",
    // ...
  },
  // 4 more personas covering: hijab girl 6-8, glasses boy 5-7,
  // short-hair boy 6-8, curly-hair boy 3-5
] as const;
```

Final persona content drafted during implementation; the spec locks the *shape*, not the exact descriptions.

### 5.3 Cultural glossary

New file: `src/lib/ai/cultural-glossary.ts`

Static curated list. Each entry has the Arabic term, Latin transliteration, an English description, and explicit *negative* examples (what it is NOT). The Bible generator includes relevant entries based on story theme/setting.

```ts
export const CULTURAL_GLOSSARY = [
  {
    ar: "كحك",
    latin: "kahk",
    description: "Round Egyptian Eid biscuits dusted with powdered sugar; pale yellow color; sometimes filled with dates or nuts; served on round metal trays at family gatherings during Eid el-Fitr",
    notExamples: ["NOT chocolate chip cookies", "NOT macarons", "NOT shortbread"],
    triggerKeywords: ["eid", "kahk", "biscuit", "celebration food"],
  },
  {
    ar: "مكرونة بشاميل",
    latin: "makarona bashamel",
    description: "Egyptian baked layered pasta with white béchamel sauce; looks like lasagna's Egyptian cousin; served from a square casserole dish; pale beige top with golden-brown crust; hot family dinner staple",
    notExamples: ["NOT spaghetti with meatballs", "NOT carbonara", "NOT plain pasta", "NOT lasagna with red sauce"],
    triggerKeywords: ["pasta", "makarona", "family dinner", "casserole"],
  },
  {
    ar: "كشري",
    latin: "koshari",
    description: "Egyptian street food: stacked layers of rice + brown lentils + small pasta + chickpeas, topped with crispy fried onions and red tomato-vinegar sauce, served in a takeaway bowl",
    notExamples: ["NOT plain rice", "NOT biryani"],
    triggerKeywords: ["street food", "koshari", "lunch"],
  },
  // Target: 15–20 starter entries covering: kahk, makarona bashamel, koshari,
  // fateer, molokhia, ful, aish baladi, shay, galabeya, gama' (mosque),
  // shari' (Cairo street), Eid markers, sukkar malawan, mawlid sweets,
  // Ramadan lanterns, suhoor/iftar table.
] as const;
```

The Bible generator scans the storyJson + wizard inputs for trigger keywords and includes matching glossary entries in `bibleJson.culturalNotes` so the illustration prompts reference them concretely.

### 5.4 Illustration prompt assembly

New file: `src/lib/ai/prompts/build-illustration-prompt.ts`

Each per-page prompt is built deterministically by concatenating:

```
[STYLE block from styleBible]
+ [CHARACTER block from characterBible.mainChild]
+ [SETTING block — primary or relevant secondary location]
+ [SCENE block — page-specific scene addendum from storyJson.pages[N].scene]
+ [CULTURAL NOTES — relevant entries from glossary]
+ [NEGATIVE PROMPT — bible.styleBible.negativeStyle + locked anti-patterns]
```

Concrete shape:

```ts
function buildIllustrationPrompt(
  bible: Bible,
  pageScene: string,
  pageNumber: number,
): { positive: string; negative: string } {
  const character = renderCharacterBlock(bible.characterBible.mainChild);
  const style = renderStyleBlock(bible.styleBible);
  const setting = renderSettingBlock(bible.settingBible, pageNumber);
  const culture = bible.culturalNotes.join(". ");

  return {
    positive: [
      style.medium,
      character,
      setting,
      pageScene,           // e.g. "she gathers kahk from a round metal tray on a teal coffee table"
      culture,
      style.compositionAnchors,
    ].join(". "),
    negative: bible.styleBible.negativeStyle,
  };
}
```

Two important behavioral changes from Sprint 2:
- Story system prompt's `pages[].illustrationPrompt` becomes `pages[].scene` — a 1–2 sentence scene addendum, NOT a full standalone prompt. The Bible owns character/setting/style.
- The `coverDescription` field similarly shortens — it's a *scene-level* description, not a full prompt.

This requires updating:
- `storyOutputSchema` — rename `illustrationPrompt` → `scene`, shrink min length, update description field
- `coverDescription` description to clarify scope
- All 3 few-shot examples — rewrite their `pages[].illustrationPrompt` (now `scene`) to be 1–2 scene-only sentences

### 5.5 Fal.ai integration — Flux 1.1 Pro + PuLID

New file: `src/lib/ai/illustration-generator.ts` (rewrite of existing)

Uses `@fal-ai/client` (already in `package.json`, currently unused). Two endpoints:

**Cover (no reference image):**
```ts
fal.subscribe("fal-ai/flux-pro/v1.1", {
  input: {
    prompt: positive,
    negative_prompt: negative,
    image_size: "portrait_4_3",  // or custom: 750x1000
    num_inference_steps: 28,
    guidance_scale: 3.5,
  },
});
```

**Body pages with cover-as-reference + optional photo-as-identity:**
```ts
fal.subscribe("fal-ai/flux-pulid", {     // exact endpoint per Fal.ai docs
  input: {
    prompt: positive,
    negative_prompt: negative,
    reference_image_url: coverImageUrl,  // Edit-based pipeline anchor
    face_image_url: customerPhotoUrl,    // PuLID identity injection (optional)
    image_size: "portrait_4_3",
    num_inference_steps: 28,
    guidance_scale: 3.5,
    pulid_weight: 0.75,                  // identity strength sweet spot per research
    pulid_start: 0.0,
    pulid_end: 0.65,                     // inject during middle steps; let last 35% polish style
  },
});
```

**Implementer note:** exact Fal.ai endpoint names + parameter shapes must be verified via `mcp__plugin_context7_context7__query-docs` or fal.ai docs at implementation time. The above is the *design intent*; small parameter renames per their actual API are expected.

Errors:
- If Fal.ai returns NSFW/safety reject → fail loud (admin gets error log, retries from queue)
- If face_image_url quality is too poor for face-vector extraction (low resolution, no face detected) → fall back to no-PuLID generation, log the fallback
- Concurrency cap: 5 (Fal.ai is more permissive than Google direct; 5 keeps within typical rate limits)

### 5.6 Database schema change

New migration: `0006_add_bible_json.sql`

```sql
ALTER TABLE generations
  ADD COLUMN bible_json jsonb;

-- Allow null for backward compatibility with pre-migration generations
-- (they fall through to the no-Bible code path which produces inferior
-- illustrations — acceptable since they predate this feature).

CREATE INDEX IF NOT EXISTS idx_generations_bible_present
  ON generations ((bible_json IS NOT NULL));
```

Schema TS update in `src/db/schema.ts`:
```ts
export const generations = pgTable("generations", {
  // ... existing fields ...
  bibleJson: jsonb("bible_json"),
  bibleRegeneratedAt: timestamp("bible_regenerated_at"),  // for admin re-roll tracking
});
```

### 5.7 Admin reject + reroll flow

Default behavior on reject:
- Admin clicks ✕ Reject → modal asks for category + reason
- Backend marks generation as `rejected`, increments `retry_count`
- A "Regenerate illustrations" button appears (default action — keeps Bible, re-runs Step 4)
- Below it: a "Regenerate Bible too" checkbox (escape hatch — re-runs Steps 2 + 3 + 4)
- "Regenerate everything" button below those — re-runs Steps 1 + 2 + 3 + 4 (rare path; for irrecoverable story-level issues)

Implementation surface:
- New endpoint: `POST /api/admin/generations/:id/reroll` with body `{ scope: "illustrations" | "bible" | "story" }`
- Existing admin UI gets the checkbox + buttons in the rejection modal
- Backend's reroll handler routes to the right step in the pipeline, persists new artifacts, transitions status to `awaiting_review` again

### 5.8 Wizard photo + persona flow

Wizard step 2 (per ADR-005):
- Existing: "Upload your child's photo" or "Describe your child" (free-form)
- New: Replace free-form with "Or pick a persona that matches your child" — persona-picker grid showing the 6 starter personas
- If no persona quite matches → "I'll describe my own" fallback to free-form (keeps existing path, flows into Bible as text)

Photo upload path (existing → reroute):
- Photo URL stored on order (`orders.main_child_photo_url` already exists per Phase 5 schema)
- Story orchestrator passes this URL into Bible generator (for vision-description step) AND into illustration generator (for PuLID face-injection step)

## 6. Implementation file map

| File | Action |
|---|---|
| `src/lib/ai/schemas/bible.ts` | NEW — Zod schema for Bible |
| `src/lib/ai/schemas/story.ts` | UPDATE — rename `illustrationPrompt` → `scene` on pages; shrink min lengths to reflect scene-only scope |
| `src/lib/ai/bible-generator.ts` | NEW — gpt-4o-mini (vision-conditional) call producing the Bible |
| `src/lib/ai/personas.ts` | NEW — 6 starter personas |
| `src/lib/ai/cultural-glossary.ts` | NEW — 15–20 Egyptian terms with negatives + triggers |
| `src/lib/ai/prompts/build-illustration-prompt.ts` | NEW — assemble Bible + scene per page |
| `src/lib/ai/prompts/build-bible-system-prompt.ts` | NEW — system prompt for Bible generator |
| `src/lib/ai/illustration-generator.ts` | REWRITE — drop Gemini, integrate Fal.ai (Flux + PuLID) |
| `src/lib/ai/router.ts` | UPDATE — add `flux-*` prefix routing for cost tracking |
| `src/lib/ai/prompts/story-system-prompt.ts` | UPDATE — instructions tell story gen to write *scene addendums*, not full prompts |
| `src/lib/ai/prompts/story-examples/01-friendship-3-5.ts` | UPDATE — convert page.illustrationPrompt to page.scene (shorter) |
| `src/lib/ai/prompts/story-examples/02-school-5-7.ts` | UPDATE — same |
| `src/lib/ai/prompts/story-examples/03-eid-6-8.ts` | UPDATE — same |
| `src/jobs/generate-book.ts` (or current orchestrator) | UPDATE — call Bible generator after story; thread Bible into illustration generator |
| `src/db/schema.ts` | UPDATE — add `bibleJson` + `bibleRegeneratedAt` to generations |
| `drizzle/0006_add_bible_json.sql` | NEW — migration |
| `src/routes/admin-generations.ts` | UPDATE — new POST `/admin/generations/:id/reroll` endpoint |
| `hadouta-admin/src/app/orders/[id]/_order-detail.tsx` | UPDATE — reject modal gains scope checkbox/buttons |
| `hadouta-web/src/app/wizard/2/...` | UPDATE — replace free-form description with persona picker (+ "describe my own" escape) |
| `tests/unit/bible-schema.test.ts` | NEW — schema validation tests |
| `tests/unit/build-illustration-prompt.test.ts` | NEW — verify prompts assemble correctly with/without optional pieces |
| `tests/unit/personas.test.ts` | NEW — verify all 6 personas validate against expected shape |
| `tests/unit/cultural-glossary.test.ts` | NEW — verify glossary entries have required fields + no duplicates |
| `tests/integration/illustration-generator.test.ts` | NEW — Fal.ai dry-run / mocked client test |
| `docs/decisions/ADR-024-bible-driven-illustration-pipeline.md` | NEW — captures the architectural shift |
| `docs/sprints/sprint-tracker.md` | UPDATE — Sprint 3 entry |

## 7. Migration / rollout

- New code applies to **all new generations** from Railway deploy time
- **No backfill** for existing dev-test generations (per locked decision — dev mode only)
- Existing `generations` rows with `bible_json IS NULL` continue to render via the legacy text-only Gemini path until they're rerolled or the row is deleted
- The legacy Gemini code path can be **kept** for one Sprint as a fallback (in case Fal.ai availability issues), then removed in Sprint 4 cleanup

## 8. Cost economics (per book)

| Step | Cost |
|---|---|
| Story generation (gpt-4o-mini, ~16 pages) | ~$0.0017 |
| Bible generation (gpt-4o-mini + optional vision) | ~$0.001 (no photo) / ~$0.003 (with vision) |
| Cover illustration (Flux 1.1 Pro) | $0.04 |
| 16 body illustrations (Flux 1.1 Pro + PuLID when photo) | ~$0.04 × 16 = $0.64 (+ PuLID overhead ~$0.16 if photo present) |
| PDF assembly (existing) | ~$0 |
| **Total per book** | **~$0.69** (no photo) — **~$0.85** (with photo) |

At 250 EGP price point (~$5.10), illustration is ~13–17% of revenue. Up from ~0.4% at Sprint 2. Pricing review deferred per locked decision.

Concurrency: 5 parallel Flux calls × ~6 seconds each = ~20s for all body illustrations. Plus ~6s for cover. Total ≈ **30 seconds** for the illustration phase (was ~60s with Gemini at concurrency 3). Net pipeline time ≈ same or slightly faster.

## 9. Open questions deferred (do not block this spec)

1. **Watermark / signature on illustrations** — should body-page illustrations carry a small "حدوتة" watermark? Not now; revisit when paid orders begin.
2. **Custom-style requests** (parent says "we want pencil sketch not watercolor") — per ADR-019, multi-style is a future feature, not MVP.
3. **Multi-character region-aware prompting** — when Sprint 4 brings supporting characters, we'll need TaleDiffusion-style isolation. Architecture is forward-compatible (Bible already has `supportingCharacters` array).
4. **Validators framework hooks** — Sprint 3+ validators can read Bible structure to detect "moral disconnect" / "cultural drift" without additional schema work.
5. **LoRA training upgrade path** — once we have ~50 commissioned reference illustrations from an Egyptian illustrator, training a watercolor LoRA on Replicate is a single-engineer week of work and would bump quality further. Sprint 5+.
6. **Persona library extension** — current 6 starter personas cover ~80% of expected Egyptian customer base. Customer feedback may indicate gaps (e.g. specific hair textures, mixed heritage). Easy to add — append to `personas.ts`.

## 10. Success criteria

| Criterion | How to verify |
|---|---|
| Character consistency across 17 illustrations | Visual review of 3+ generated books — same face, same hair, same outfit on every page |
| Setting consistency | Visual review — same primary location renders the same across pages |
| Watercolor style adherence | Visual review — output reads as watercolor, not 3D / digital / cartoon |
| Cultural literalness | "makarona bashamel" prompt → baked layered pasta with béchamel (not spaghetti meatballs); "kahk" prompt → Egyptian Eid biscuits (not chocolate chip cookies) |
| Photo-uploaded face fidelity | Visual review — child's actual face recognizable in illustrations (when photo provided) |
| No regression in story / PDF / cost ceiling | Existing 42 tests still pass; PDF assembly unchanged; per-book cost under $1.00 |
| Pipeline duration | End-to-end < 5 minutes (story + bible + 17 images + PDF) |

## 11. Related decisions / specs

- ADR-005 — Photo upload + watercolor (this spec implements the photo-actually-being-used promise)
- ADR-019 — Multi-style architecture, watercolor MVP
- ADR-022 — Sprint 2 AI pipeline architecture (multi-provider router) — extended here
- (Future) ADR-024 — Bible-driven illustration pipeline (will reference this spec)
- `docs/design/specs/2026-05-03-pdf-redesign-spec.md` — the rendering side of the same Sprint 3 work
- Research source: `/home/ahmed/Downloads/searchReports.md` — Arabic industry survey

---

**Brainstorm session artifacts** for traceability: this session's terminal conversation. Visual companion not used (was text-heavy discussion).
