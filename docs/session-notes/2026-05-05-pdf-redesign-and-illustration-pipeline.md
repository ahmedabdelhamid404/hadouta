# Session: PDF redesign shipped + illustration pipeline rebuilt (2026-05-04 → 2026-05-05)

**Date span:** 2026-05-04 evening through 2026-05-05 early morning
**Status:** All work committed, pushed, deployed.
**Outcome:** Two complete Sprint 3 features shipped end-to-end: (1) PDF redesign (cover/body/end-page system with three-font hierarchy and watercolor washes), (2) illustration pipeline rebuilt around Nano Banana Pro Edit with multi-photo identity reference. Both verified end-to-end; one Phase-H test generation in admin queue for inspection.

---

## TL;DR

Two large feature blocks shipped this session, plus a hard architectural pivot driven by real-world API verification:

1. **PDF redesign** (Sprint 2 cleanup → shipped first). Replaced Sprint 2's generic Cairo-font-only PDF with a designed system: cover (poster register), 16 body pages (framed-island register), end-page (mirrors cover with moral statement). Three-font hierarchy (Aref Ruqaa decorative / El Messiri headers / Cairo body), paper texture, watercolor washes, ✦ ornament family. New `moralStatement` field on story schema; `parentDiscussionQuestion` removed from PDF (kept in storyJson, relocation deferred). PDF cropping fix (`object-position: center top`) so head crops happen from bottom (where watercolor fade hides them) not top.

2. **Illustration pipeline rebuilt** (Sprint 3). Brainstorm → spec → plan → execution → 8 verification iterations against real API. Started on the spec'd Flux+PuLID architecture; verified empirically over 4 iterations that PuLID has a portrait-only ceiling (cannot render character-in-scene illustrations regardless of param tuning). Pivoted to Nano Banana Pro Edit (`fal-ai/nano-banana-pro/edit`) — same model that produced rich Sprint-2 scenes — but now with: Bible-driven structured prompts, multi-image conditioning, multi-photo identity reference, gpt-4o (never mini) for story + Bible + vision.

3. **Hard rule locked: never `gpt-4o-mini` for Hadouta.** Three different Phase H generations exposed different mini failure modes (constraint violations, hallucinated wrong-theme content, missed traditional clothing in vision). Saved to `feedback_no_gpt4o_mini.md` so future sessions don't reach for it.

**Total Phase H verification cost:** ~$3.10 across 8 iterations.

---

## Part 1 — PDF redesign (shipped at start of session, pre-Phase-H)

### What landed

Three commits in `hadouta-backend`:
- `0214cf9` `refactor(ai): rename illustrationPrompt → scene on story pages`
- `46609d6` and prior commits — the whole PDF redesign per spec `docs/design/specs/2026-05-03-pdf-redesign-spec.md`
- Cropping fix later in session: `object-position: center top` on all three template img tags

Schema additions (visible in earlier commits):
- `storyOutputSchema.moralStatement` — required, 20–220 chars, Storyteller voice
- `storyPageSchema.scene` (renamed from `illustrationPrompt`) — 15–280 chars, scene-only

Render templates use the three-font hierarchy:
- **Aref Ruqaa** for "النهاية" stamp on end-page (max-1-per-page rule)
- **El Messiri** for cover title, page-number labels, ornament labels
- **Cairo** for body story text, dedications, brand wordmark

Style system locked in:
- A5 (148×210mm), watercolor washes in cover/end caption zones, paper-grain texture (cross-hatch stripes at ~1.5% opacity)
- Inner border + corner ✦ flourishes on body pages
- Symmetric `✦ صفحة ١٤ ✦` page numbering in Eastern Arabic numerals
- Cloudinary URL transforms `c_limit,w_750,f_jpg,q_70` to keep PDF size under 10 MB free-tier limit

### Brainstorm artifacts

Visual companion HTML mockups during brainstorming live at `.superpowers/brainstorm/223352-1777803759/content/01..14-*.html` (gitignored).

### Verified

End-to-end on Fady's existing generation (`f7d4e9eb-...`) — backfilled `moralStatement`, regenerated PDF. PDF inspected page-by-page: cover, body pages, end page all rendered correctly. Cropping fix verified visually.

---

## Part 2 — Illustration pipeline rebuild (Sprint 3 main work)

### Why this happened

After PDF redesign shipped, customer-side test generation (Fady — Eid theme, 2026-05-04) revealed that Sprint 2's illustrations had four orthogonal failure modes:

1. **Style drift** — illustrations weren't watercolor; Gemini 2.5 Flash Image didn't honor style instructions
2. **Character drift** — child appeared as different avatars across pages
3. **Setting drift** — place changed between pages with no continuity
4. **Cultural literalness failures** — "makarona bashamel" rendered as spaghetti meatballs, "kahk" as chocolate-chip cookies

Plus a critical product gap: customer-uploaded photos were dead-letter data (stored on Cloudinary, never used by AI pipeline).

### Architecture journey (compressed)

| Phase | Decision | Outcome |
|---|---|---|
| Brainstorm | Friend's research file recommended Flux + PuLID + Bible pattern. Spec'd accordingly. | Spec at `docs/design/specs/2026-05-03-illustration-pipeline-redesign-spec.md` |
| Plan | 16 tasks across 8 phases (A-H). | Plan at `docs/design/specs/2026-05-03-illustration-pipeline-implementation-plan.md` |
| Execute Phases A-G | Schema + library + Bible generator + Fal.ai integration + orchestrator + admin reroll + wizard persona picker. 14 tasks completed. **83/83 unit tests passing.** | All committed before Phase H started |
| Phase H verification | 8 real-API iterations against the deployed pipeline | Detailed below |

### The Phase H iteration log (educational)

| # | Setup | Cost | Result |
|---|---|---|---|
| 1 | Flux+PuLID per spec, Omar (boy) full-body photo, full 17 pages | ~$1.00 | Identity preservation broken (face didn't match photo); cover good but body pages all "boy standing alone" with no scene |
| 2 | Same architecture, gpt-4o vision (not mini) for Bible, face-cropped photo for PuLID, tuned PuLID params (id_weight 0.65, start_step 12), full 17 pages | ~$1.00 | Galabeya now captured by gpt-4o vision. Body pages STILL portrait-only. Even better PDF cropping fix verified. |
| 3 | Same Omar photo + face-crop, more aggressive PuLID tuning (id_weight 0.4, start_step 16), DEV MODE introduced (cover + 2 body pages = $0.17) | ~$0.17 | Body pages STILL portrait-only. **PuLID's portrait bias is fundamental — three rounds of param tuning all hit the same ceiling.** |
| 4 | Architecture pivot to **Nano Banana Pro Edit**. Cover via nano-banana-pro/edit, body via nano-banana-pro/edit with image_urls=[cover, photo]. Same girl photo (Hanin, close-up). | ~$0.20 | Cover scene rich and good. Body pages duplicated cover (Gemini anchored on the strongest visual ref). |
| 5 | Nano Banana, body image_urls=[photo only] (cover dropped), per-page scene block emphasized in prompt | ~$0.13 | **WORKS.** Body pages render distinct scenes; identity preserved; watercolor visible; cultural anchors (kahk, fanous lanterns) present. Slight identity drift across pages (single photo, varying interpretation). |
| 6 | Test of "best of both worlds": image_urls=[photo, cover] order swap (photo first for primary identity weight). Kept emphasized scene block. | ~$0.13 | Results not better — too-similar room reuse. User instinct correct. **Rolled back.** |
| 7 | Reverted to iteration-5 architecture + added explicit identity-preservation language in scene block ("the child's face must EXACTLY match the reference photo") | ~$0.13 | Better identity than iter 5 but still per-page interpretation variance |
| 8 | Same as 7 + multi-photo support (3 photos of same girl from different angles uploaded as image_urls). Theme switched to First Day at School + Courage moral. | ~$0.21 | Multi-photo gave Gemini richer 3D face geometry → stronger identity. **Architecture locked.** |

**Generation `fad8f418-6464-43df-9ce2-06488b58c8a5`** is in `awaiting_review` for inspection.

### Lessons that landed in code

- **Attention is a finite budget in multimodal models.** Strong scene prompts compete with strong identity refs. The fix is to give the model MORE INPUT (multi-photo) rather than ASKING IT TO TRY HARDER (more prompt tokens).
- **PuLID is photo→portrait, NOT photo→scene.** Bookmark this for any future identity-preservation work — PuLID is the wrong tool for character-in-scene illustrations.
- **`fal-ai/nano-banana-pro/edit` accepts `image_urls: Array<string>`.** Multi-image conditioning is the key feature; we underused it on iteration 4 (passed cover + photo and got cover-clones), then under-leveraged it on iteration 5 (single photo, identity drift), then finally got it right on iteration 8 (multiple angle photos = richer 3D understanding).
- **gpt-4o-mini is unreliable at structured output.** Locked as feedback memory.
- **Bible system prompt needed explicit four-top-level-keys example.** Even gpt-4o was dropping `styleBible` / `culturalNotes` until we added the structural example.

### Final architecture (as committed in `b844f8b`)

```
[Order placed via wizard with 1-3 photos]
   │
   ▼
[1] Story (gpt-4o, story-system-prompt.ts unchanged)
   │
   ▼
[2] Bible (gpt-4o + gpt-4o vision on first photo for clothing/feature description)
       — outputs structured Bible JSON with hardened prompt example
   │
   ▼
[3] Illustration prompts assembled per page (build-illustration-prompt.ts)
       — emphasized scene block + identity-preservation language for body pages
   │
   ▼
[4] Illustrations via fal-ai/nano-banana-pro/edit
       Cover: image_urls = all customer photos (photo-anchored cover)
       Body pages: image_urls = all customer photos (NOT cover; cover dropped to
                   prevent cover-clone duplication; identity from multi-photo,
                   scene from prompt)
   │
   ▼
[5] PDF assembly (existing redesigned templates with cropping fix)
```

---

## Part 3 — UX bug fixed along the way

**Wizard step 2 photo upload:** photos uploaded successfully but UI showed `🖼️` emoji placeholder instead of actual photo. Cause: store persisted only `photoIds`, discarding the URL returned by backend. Fixed in `c76a312` — added `photoUrls` array to wizard `Appearance` type, photo-upload component renders `<img src={url}>` in each slot. (hadouta-web repo.)

---

## Part 4 — Cost economics update

| Item | Sprint 2 cost | Current cost |
|---|---|---|
| Story | ~$0.002 (gpt-4o-mini) | ~$0.04 (gpt-4o) |
| Bible | n/a | ~$0.02 (gpt-4o) |
| Vision (when photo present) | n/a | ~$0.005 (gpt-4o) |
| Cover illustration | ~$0.001 (Gemini direct) | ~$0.04 (Nano Banana Pro Edit) |
| 16 body pages | ~$0.02 (Gemini × 16) | ~$0.64 (Nano Banana × 16) |
| **Total per book** | **~$0.025** | **~$0.74** (no photo) / **~$0.75** (with photos) |

Cost increase: ~30× for substantially better quality. At 250 EGP retail this is ~14% of revenue going to AI cost — acceptable margin.

---

## Part 5 — Deferred for Sprint 4+

These came up during the session and are notable but explicitly NOT in scope:

1. **LoRA training paths.** Discussed in detail near end of session. Three candidates: (a) watercolor style LoRA — train on commissioned Egyptian illustrations, plug into Fal.ai; (b) per-customer character-identity LoRA — gold standard but 15–90 min training conflicts with real-time wizard; (c) Egyptian-Arabic-voice LoRA — OpenAI fine-tuning of gpt-4o, simplifies system prompt. **Recommendation: watercolor LoRA in Sprint 4** (low operational complexity, high quality lift) once Track-B Egyptian illustrator commissioning lands. Character LoRA → Sprint 5+ premium tier with async fulfillment.

2. **Wizard persona picker** wired in earlier commit but not yet tested with real customer flows.

3. **Admin reroll endpoint** wired in earlier commit but not yet exercised end-to-end.

4. **`parentDiscussionQuestion` relocation** — kept in `storyJson`, removed from PDF. Decision deferred whether to ship as companion card / customer account section / post-delivery email.

5. **Story content quality issues** observed in Phase H:
   - gpt-4o-mini hallucinated "Christmas tree" in Eid story
   - One iteration produced 2 moralMoment pages
   - Both fixed by switching to gpt-4o, but story-system-prompt.ts could be hardened further with explicit theme-bleed guards

6. **Validators framework** (Sprint 3 original goal) — character / setting / cultural / moral validators that programmatically check AI output before admin sees it. Untouched this session.

7. **ADR-024** (Bible-driven illustration pipeline) — not yet written. Would document the brainstorm → spec → plan → real-world-pivot journey including the Flux+PuLID → Nano Banana shift. Worth writing before Sprint 4.

---

## Part 6 — What's deployed

- `hadouta-backend@b844f8b` pushed to GitHub + deployed to Railway production
- `hadouta-web@c76a312` pushed to GitHub (auto-deploys to Vercel)
- `hadouta-admin` — no changes this session
- Database: `ai_settings.story_model = 'gpt-4o'` (was `gpt-4o-mini`); `illustration_count = 16` (unchanged)

---

## Memory updates

- `feedback_no_gpt4o_mini.md` (new) — never use gpt-4o-mini for Hadouta tasks; cite Phase H failure modes

---

## Verification artifacts

Test generation in admin review queue:
- **Generation `fad8f418-6464-43df-9ce2-06488b58c8a5`** — order `36e86090-6f28-450a-8a61-812d5f610ed0` — حنين, age 5, First Day at School + Courage. Cover + 2 body pages with 3-photo multi-angle reference. Status: `awaiting_review`. Visit `https://hadouta-admin.vercel.app/orders/fad8f418-...`

Local visual artifacts (gitignored):
- `/tmp/e2e-eid/` — image samples from iterations 1, 2, 3, 4, 5 for visual comparison

---

## Open question for next session

Before Sprint 4 begins, decide on the path-forward question Ahmed and I were exploring at session end: **does Hadouta want to invest in a watercolor LoRA in Sprint 4** (~$5–10 training + 2–4 weeks Egyptian-illustrator commissioning) **or keep iterating on Nano Banana prompts**? The answer depends on whether the Track B illustrator commissioning is happening in time.
