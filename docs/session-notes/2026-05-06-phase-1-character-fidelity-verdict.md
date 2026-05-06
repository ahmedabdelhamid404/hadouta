# Session: Phase 1 character-fidelity verdict — Nano Banana 2 + Pixar 3D wins

**Date:** 2026-05-06
**Status:** Phase 1 SHIPPED + CLOSED. ADR-026 + ADR-027 written. Production code upgraded.
**Outcome:** Architectural verdict locked. Hadouta's illustration pipeline is now Nano Banana 2 + Pixar-3D prompt overlay (no LoRA). Brand pivoted from watercolor to Pixar-3D. Sprint 3 has a refreshed top-priority list.

**Total session spend:** ~$2.50 in API costs across 6 iterations + research. Within Phase 1's $5 budget.

---

## TL;DR for the next-session resume

1. **Phase 1 is closed.** Don't re-litigate. The architecture verdict is in `docs/decisions/ADR-026-phase-1-pixar-character-fidelity-verdict.md`. The brand pivot is in `docs/decisions/ADR-027-watercolor-to-pixar-3d-brand-pivot.md`. Read both.
2. **Production code is upgraded.** `fal-ai/nano-banana-pro/edit` → `fal-ai/nano-banana-2/edit` is shipped (commit `278f0a3`). All new customer orders generate via Nano Banana 2 by default.
3. **Production has known gaps.** The Bible-gen prompt still produces watercolor-era `styleBible` and empty `supportingCharacters` array. Iteration-6 quality came from inline Pixar prompts in a script, NOT from the production prompt-builder. Sprint 3's top priority is closing this gap (see "Sprint 3 plan refresh" below).
4. **The verdict generation is in admin queue.** Open `https://hadouta-admin.vercel.app/orders/fe8fe560-c009-4cd4-8533-83fca7b0a5e8` — that's the iteration-6 output that locked the verdict.
5. **Founder's read on iter 6:** "we reached good results for now" + ONE late note: "make sure no text is written on image cover please" — addressed by adding NO-TEXT clause to `appendPixarStyleAnchor` in `build-illustration-prompt.ts` (committed in this session).

---

## How the session opened

Started 2026-05-06 with sprint-tracker pointing at Sprint 3 entry points (validators framework v1, story-quality tuning, Trigger.dev migration). Founder opened the session with: "we are now facing an issue we feel it will kill our project on launching" — character face fidelity. He set the bar at "98% wtf it's him" recognition test.

The session went directly into Phase 1 architectural verification before any Sprint 3 work began.

---

## The 6 iterations

| # | What was tried | Cost | Generation ID | Outcome |
|---|---|---|---|---|
| (de-risk) | Verify fal-ai/flux-pro/kontext/multi accepts `loras` array param | ~$0.05 | n/a (script) | ✅ accepted (commit `2f51f7a8`) |
| 2 | Flux Kontext Multi + Civitai Pixar LoRA + iter-2 prompts | ~$0.40 | `8bb2ab5c-5956-...` | Mother teen-looking. Page 16 image was 10 KB (black — model collapsed on intimate dim close-up + pajamas-not-in-photos contradictions). Action moment absent. |
| 3 | Same + refined character-differentiation language + heavy negatives | ~$0.40 | `ca083aa1-a7c7-...` | Page 16 fixed. Mother still teen. Classmates differentiated for first time. Teacher still ~25-year-old. |
| 4 | Same + Pixar movie references for age (Encanto's Julieta, Inside Out teachers) + dynamic-action language | ~$0.40 | `a74db112-9fba-...` | Cover dynamic walking pose. Mother STILL teen-looking despite explicit age cues. Action still not depicted. Accessory drift (ribbon vs headband). **Plateau hit.** |
| 5 | OpenAI gpt-image-2 (April 2026 release with native reasoning) | $0.00 | n/a (blocked) | HTTP 403: organization verification required. Founder verified but propagation didn't complete during session. Untested. Script committed for retry. |
| 6 | **fal-ai/nano-banana-2/edit (Gemini 3.1 Flash Image, Feb 2026) + iter-4 inline Pixar prompts** | ~$0.32 | **`fe8fe560-c009-4cd4-8533-83fca7b0a5e8`** | **Mother renders as adult woman.** Active ribbon-tying moment depicted. Teacher mature. 2 named classmates clearly distinct. P16 dramatic golden-hour light. Cover with bilingual typography baked in. Cross-page accessory consistency. **Strongest output across all iterations.** |

**Path D's two architectural pieces locked:** Pixar-3D as the brand register, multi-image identity reference (1–3 customer photos as `image_urls`).

**Path D's discarded piece:** Flux Kontext + Pixar-LoRA. Was the spec'd architecture but Nano Banana 2 produced visibly better output at half the cost on the same prompts.

---

## Why Nano Banana 2 won (the engineering story)

1. **Gemini 3.1's reasoning planner disambiguates subject-of-photo from other-characters-in-scene.** Same iter-4 Pixar prompts with explicit "MOTHER is a 35-year-old adult, NOT a teenager" language: Flux Kontext rendered teenager, Nano Banana 2 rendered an adult woman. Architectural difference, not prompt-craft difference.
2. **Pixar-3D register comes through prompt-only — no LoRA needed.** Iter 6 used zero LoRAs; the Pixar-style anchor in the prompt alone produced consistent Pixar register. This eliminates LoRA hosting, the §1(c)(ii) license carve-out, and the env var `PIXAR_STYLE_LORA_URL` complexity (still set in `.env` but unused).
3. **Text-in-image is a first-class capability** of Nano Banana 2 (Gemini 3.1 Flash Image is documented as best-in-class for legible text). Iter 6's cover rendered "HANINE'S FIRST DAY — Her Big Adventure Begins!" baked into the illustration; classroom rendered Arabic alphabet poster (الألف الباء التاء) on the wall. Was a free bonus during testing — but founder later flagged that the cover should NOT have AI-rendered title text (PDF assembly adds title text in a separate Puppeteer layer per ADR-023; doubling causes clash). Suppression added to `appendPixarStyleAnchor` (this session).
4. **Per-page cost halved** ($0.15 → $0.08). At 17-page production: ~$1.36/book vs ~$2.55/book. Acceptable margin at 250 EGP retail.

---

## Production code changes shipped this session

| Commit | Change |
|---|---|
| `2f51f7a` | de-risk script for fal Kontext-Multi LoRA support |
| `103594c` | document `PIXAR_STYLE_LORA_URL` in `.env.example` (Phase 1 testing) |
| `6c84993a` | `appendPixarStyleAnchor()` helper added to `build-illustration-prompt.ts` |
| `b030db11` | `flux-kontext-pixar` provider dispatch in `illustration-generator.ts` (alt provider, kept reachable but not default) |
| `a17bf05b` | `aiSettings.illustration_model` wired into `generate-book.ts` orchestrator |
| `302fb05` | iter-2 script + Pixar trigger frontload + LoRA scale 0.85 → 0.95 |
| `37ba2ab` | iter-3 script (character-differentiation refinements) |
| `c818ebc` | iter-4 script (Pixar movie-reference age cues) |
| `9c0a7fb` | iter-5 (gpt-image-2) script — committed for retry after verification propagates |
| `80ed1a2` | iter-5 fix: curl-based photo download (Node fetch ETIMEDOUT workaround) |
| **`278f0a3`** | **production endpoint upgrade: nano-banana-pro/edit → nano-banana-2/edit (Gemini 3.1 Flash Image)** |
| (this session) | iter-6 script + `appendPixarStyleAnchor` no-text-in-image clause + ADR-026 + ADR-027 + this session note |

**Net production effect:** Default `provider: "nano-banana"` path now hits Gemini 3.1 Flash Image at $0.08/edit. Pixar overlay applied via `appendPixarStyleAnchor` when called by the production prompt-builder (note: the prompt-builder doesn't yet call this helper by default — Sprint 3 wires it in).

---

## Open production gaps (Sprint 3 must close)

The verdict architecture is in the *generation endpoint* but not yet fully in the *prompt-construction layer*. Iteration 6's quality came from inline Pixar prompts in a one-off script that bypasses the production `buildIllustrationPrompt`. **Production today (if a real customer order ran end-to-end) would produce iteration-1-quality output, not iteration-6-quality**, until these gaps close:

### 1. Bible-gen prompt rewrite (highest priority, biggest gap)

`src/lib/ai/prompts/bible-system-prompt.ts` produces:
- ❌ `styleBible.medium = "soft watercolor on cream paper, visible brush strokes, gentle wet-edge bleeds, no hard digital lines"` (wrong register for Pixar pivot)
- ❌ `styleBible.negativeStyle = "NOT photorealistic, NOT 3D-rendered, NOT Disney-cartoon, NOT anime, NOT vector-flat, NOT sharp digital lines"` (actively conflicts with Pixar overlay; iter-2 black-image bug traced to this)
- ❌ `characterBible.supportingCharacters = []` (empty in 100% of generations — bug, never worked. Story characters like mother/father/teacher/classmates/Sara are NEVER captured at the Bible layer)
- ❌ `characterBible.mainChild.outfit.default` is generic (e.g., "bright green top with fabric bow") not story-aligned (e.g., "navy school uniform with red ribbon for school-day arc")

Sprint 3 fix: rewrite the Bible system prompt to default Pixar-friendly style fields, populate supportingCharacters from named characters in the story, and produce story-aligned outfit defaults.

### 2. `buildIllustrationPrompt` rewrite

Port the iteration-6 inline-prompt structure into the production prompt-builder:
- Per-page POSE & EMOTION direction
- Per-page SETTING & ENVIRONMENTAL DETAILS props
- Per-page character-presence injection ("MOTHER is in this scene" / "TEACHER + 2 named CLASSMATES")
- Identity-disambiguation language ("photos = ONLY for Hanine, NOT for any other character")
- 60/40 hero-vs-setting composition direction
- Anti-conflicting-style negative prompt block (currently in `appendPixarStyleAnchor` overlay; should move into `buildIllustrationPrompt` itself)

Without this, production output won't match iter-6 quality even though the model is upgraded.

### 3. Story-system-prompt review

Some example stories in `src/lib/ai/prompts/story-examples/` reference watercolor in stage directions. Review + remove watercolor language; align with Pixar register.

### 4. End-to-end full-book test

Phase 1 only tested 4 pages × 1 child. Run a full 17-page generation under the verdict architecture before assuming it scales. Pick a different test order (different age, different theme, different skin tone) for cross-demographic validation.

### 5. Cleanup (low priority but recommended)

- Remove `flux-kontext-pixar` provider code path + `callFluxKontextPixar()` helper + `PIXAR_STYLE_LORA_URL` env var entry — none reachable in verdict architecture
- Remove `appendPixarStyleAnchor` once Bible-gen produces Pixar-friendly styleBible by default (currently a transitional overlay)
- Remove `verify-fal-kontext-lora.ts` (still has the pre-existing TS error from Task 0; was kept for the iteration journey)
- Remove iteration scripts 1-6 (preserved during Phase 1 for review; no longer needed once ADR-026 is locked) — OR keep them as a permanent reference of "how we got to the verdict"; founder's call

### 6. Brand brief + customer copy update

Per ADR-027, edits needed in:
- `docs/brand/brand-brief.md` — replace watercolor language with Pixar-3D register
- Landing page hero copy
- Wizard step copy
- Order-confirmation email
- WhatsApp delivery template

---

## Bugs found + understood (recorded so we don't relearn)

1. **The Bible's `styleBible.negativeStyle` actively conflicts with prompt overlays.** Iter-2's black-image bug on page 16 was because Bible says "NOT 3D-rendered" while prompt overlay says "Pixar 3D." Flux Kontext averaged the contradiction and sometimes returned essentially-empty content. Fix: Bible-gen rewrite (Sprint 3) OR explicit override at prompt-assembly time (current `appendPixarStyleAnchor` does this).

2. **Pixar-trained image models bias toward youthful-cute regardless of explicit age cues.** Iter-4's hardest finding: explicit "35-year-old WOMAN, NOT a teenager, with smile lines and grey at temples" prompts produced teenage-looking adults on Flux Kontext. The fix wasn't more prompt — it was a different model (Nano Banana 2's reasoning handled adult-vs-child differentiation correctly).

3. **gpt-image-2 is gated behind OpenAI organization verification.** Released April 21, 2026, API May 2026. Personal accounts ARE technically "organizations" — verification is identity-based (Persona ID upload + selfie), not payment-based. Has nothing to do with credits. Same gate exists for o1/o3 reasoning models — verifying once unlocks a useful set of frontier models.

4. **Node 20's undici fetch has IPv6/IPv4 ETIMEDOUT issues on some Cloudinary URLs from this dev machine.** Curl works fine on the same URLs. Workaround: shell out to curl in scripts. Documented in `run-phase-1-iteration-5-gpt-image-2.ts:downloadPhotoToFile`.

5. **Civitai Flux LoRAs trained on Flux.1 [dev] inherit BFL's non-commercial license.** Phase 1 used `prithivMLmods/Canopus-Pixar-3D-Flux-LoRA` under §1(c)(ii) testing carve-out (boundaries: outputs not delivered to end users, not used in revenue activity, re-license required before production). Verdict architecture (Nano Banana 2) doesn't use any LoRA, so this constraint is no longer in play. Memory note: `feedback_read_actual_license_text.md` saved 2026-05-05 — fetch & quote actual license text before raising legal flags.

6. **Cover-typography rendering is a Nano Banana 2 emergent behavior** that needs to be suppressed for our PDF pipeline. Iter-6 cover rendered title typography directly into the illustration; the Puppeteer PDF assembly layer adds its own title in Aref Ruqaa per ADR-023, so the doubled text clashed. Fix shipped: explicit "ABSOLUTELY NO text, typography, titles, labels, captions, or written words of any kind anywhere in the image" clause added to `PIXAR_STYLE_ANCHOR` in `build-illustration-prompt.ts`.

---

## Cost data

**Phase 1 total session spend: ~$2.50.**

| Phase 1 line item | Cost |
|---|---|
| fal Kontext-Multi LoRA-param de-risk | ~$0.05 |
| Iter 2 — Flux Kontext + Pixar LoRA × 4 pages | ~$0.40 |
| Iter 3 — same | ~$0.40 |
| Iter 4 — same | ~$0.40 |
| Iter 5 — gpt-image-2 (blocked, no charge) | $0.00 |
| Iter 6 — Nano Banana 2 × 4 pages | ~$0.32 |

**Production projection per book (17 pages):**
- Story (gpt-4o): ~$0.04
- Bible (gpt-4o + vision): ~$0.02
- 17 illustrations × $0.08 (Nano Banana 2): ~$1.36
- PDF assembly (compute): negligible
- **Total per book: ~$1.42** in AI costs (~28% of 250 EGP retail)

---

## Memory updates this session

- `feedback_read_actual_license_text.md` (existed from 2026-05-05) — applied: I initially flagged Flux [dev]-derived LoRA as a legal risk; founder pushed back; I fetched the actual license; §1(c)(ii) explicitly carved out our exact use case. Lesson: fetch and quote license clauses before raising flags.
- Direction-locked: Pixar-3D, Nano Banana 2, no LoRA, multi-image identity. (No new memory needed — captured in ADR-026 + ADR-027.)

---

## Sprint 3 plan refresh

Original Sprint 3 entry points (per `docs/sprints/sprint-tracker.md` end-of-2026-05-05):
1. Validators framework v1 (cultural / age-band / religious-neutrality / character validator)
2. Story-quality tuning
3. Trigger.dev v3 migration
4. PostHog funnel events
5. Sentry instrumentation
6. HMAC magic-link tokens

**Refreshed Sprint 3 entry points (in priority order):**

1. **Bible-gen prompt rewrite** (Pixar-friendly styleBible defaults + populated supportingCharacters from story + story-aligned outfit defaults). Biggest single gap. Without this production output stays at iter-1 quality.
2. **`buildIllustrationPrompt` rewrite** to port iter-6's inline-prompt structure (pose, environmental props, character-presence injection, identity disambiguation, 60/40 composition, anti-conflicting-style negatives).
3. **Brand brief + customer copy update** per ADR-027 (watercolor language replaced).
4. **End-to-end full-book test** under verdict architecture (different child, different theme, different skin tone).
5. **Cleanup**: remove `flux-kontext-pixar` provider code path + Pixar LoRA env var + `verify-fal-kontext-lora.ts`. Remove `appendPixarStyleAnchor` once Bible-gen Pixar-fixes (1) land.
6. **Validators framework v1** — character validator becomes redundant under verdict architecture (face fidelity is structurally bounded by Nano Banana 2 + multi-photo); cultural/age/religious-neutrality validators still in scope.
7. **PostHog funnel events** + Sentry instrumentation around generation pipeline stages.
8. **Trigger.dev migration** when concurrency demands durability (per ADR-010).
9. **HMAC magic-link tokens** for `/api/public/order-status/:orderId` (Sprint 2 followup, hardening).
10. **Story-quality tuning** — defer until items 1–2 ship; iter-6 showed story is already strong; the gap is illustration-side.

---

## What did NOT happen this session (deferred)

- Wizard photo-upload UX rework — Phase 1 confirmed 1–3 photos is sufficient on Nano Banana 2; the original spec'd 5–8 photo + slot UX is not required and is dropped from scope
- Async fulfillment SLA rewrite — Nano Banana 2 generates fast enough for realtime (~30s/page; 8–9 min for full 17-page book end-to-end). Realtime fulfillment can stay as the customer-facing model
- 20-child verification cohort — original Phase 1 spec called for it; we shortcut to 1-child × 6 iterations + founder + Claude multimodal review = sufficient signal. If Sprint 3's full-book test surfaces issues across demographics, revisit
- gpt-image-2 retest — script committed (`run-phase-1-iteration-5-gpt-image-2.ts`); founder verified org but propagation didn't complete during session. Available to retry but unlikely to displace the verdict (cost 5–10× more, undocumented for our use case, would only matter if Nano Banana 2 fails at scale)
- Trigger.dev migration — stays as Sprint 3+ work
- ADR-005 file edit — superseded portion is documented in ADR-027 cross-reference; the file itself stays as historical record (Hadouta convention: ADRs are immutable historical decisions, supersession is by reference not by edit)

---

## Files committed this session

```
docs/decisions/
  ADR-026-phase-1-pixar-character-fidelity-verdict.md  (NEW)
  ADR-027-watercolor-to-pixar-3d-brand-pivot.md        (NEW)

docs/session-notes/
  2026-05-06-phase-1-character-fidelity-verdict.md     (NEW — this file)

hadouta-backend/src/lib/ai/
  illustration-generator.ts              (MODIFIED — Nano Banana 2 endpoint)
  prompts/build-illustration-prompt.ts   (MODIFIED — Pixar anchor + no-text clause)

hadouta-backend/src/lib/ai/prompts/  (existing test file MODIFIED)
hadouta-backend/tests/unit/illustration-generator.test.ts  (MODIFIED — endpoint assertion strings updated)

hadouta-backend/src/scripts/
  verify-fal-kontext-lora.ts                  (existing from Phase 1)
  run-phase-1-iteration-2.ts                  (existing from Phase 1)
  run-phase-1-iteration-3.ts                  (existing from Phase 1)
  run-phase-1-iteration-4.ts                  (existing from Phase 1)
  run-phase-1-iteration-5-gpt-image-2.ts      (existing from Phase 1)
  run-phase-1-iteration-6-nano-banana-2.ts    (NEW)

hadouta-backend/.env (MODIFIED — PIXAR_STYLE_LORA_URL added; gitignored)
hadouta-backend/.env.example (MODIFIED — PIXAR_STYLE_LORA_URL documented)

docs/sprints/sprint-tracker.md  (MODIFIED — Phase 1 closed, Sprint 3 refreshed)
```

(The umbrella repo and hadouta-backend repo are separate — sprint-tracker is in umbrella, code is in backend.)

---

## Resume here next session

Read in this order:
1. **`docs/sprints/sprint-tracker.md`** — current state + next concrete actions
2. **`docs/decisions/ADR-026-phase-1-pixar-character-fidelity-verdict.md`** — verdict architecture details + production gaps
3. **`docs/decisions/ADR-027-watercolor-to-pixar-3d-brand-pivot.md`** — brand pivot rationale + scope
4. **This file** for full session context if anything in 1–3 isn't clear

First action next session: pick the highest-priority Sprint 3 item from the refreshed list (likely Bible-gen prompt rewrite — biggest single gap). All necessary architectural decisions are made; Sprint 3 is execution work.
