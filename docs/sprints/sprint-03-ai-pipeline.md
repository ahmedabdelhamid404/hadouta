# Sprint 3 — AI Pipeline Foundation

**Window**: Weeks 5–8 of build
**Status**: 🟡 IN FLIGHT — Sprint 3 #1+#2 + audit committed (commits `919b846` / `5ef4690` / `d5de204`, local only). Iter 7 face-fidelity marathon SHIPPED reference book to admin (2026-05-10). Production migration is the remaining work.

> **Note**: this file's original "skeletoned" plan (validators-first focus, Claude Sonnet for story, Helicone observability) was written before Sprint 2. Real Sprint 3 became illustration-pipeline-rebuild + face-fidelity work after Phase 1 verdict closed. The original validators / Claude / Helicone items are deferred to Sprint 3+ followups OR may be retired entirely. **For real Sprint 3 status, read `docs/sprints/sprint-tracker.md` "Resume here" + `docs/session-notes/2026-05-10-face-fidelity-marathon.md`** — those are the live planning surface, not this file.

---

## Real Sprint 3 status (2026-05-10)

**Completed:**
- Sprint 3 #1+#2 (committed `919b846`): schema additions (`charactersOnPage` + `keyObjectOrDetail`) + Bible-gen rewrite + buildIllustrationPrompt rewrite + tests
- Sprint 3 audit quick wins (`5ef4690`): Arabic glossary triggers + describePhoto vision rewrite + sandwich-bottom re-anchors
- Sprint 3 audit followups (`d5de204`): age-matched few-shot shuffle + 4th example
- Iter 7 face-fidelity marathon: full 16-page Hana book reference at https://hadouta-admin.vercel.app/orders/22563851-2047-4f9e-ac47-ad27e036d4ea
- ADR-028 (watercolor revert from Pixar-3D)
- ADR-029 (production retry-queue architecture)

**In flight (next session priorities, ordered):**
1. Watercolor revert in `bible-system-prompt.ts` (undoes Pixar-3D defaults from `919b846` per ADR-028)
2. Iter 7 prompt structure into production `buildIllustrationPrompt` (role-assigned references, narrative paragraph, per-beat positive face/expression prose)
3. Switch `illustration-generator.ts` from fal.ai to Google direct API (`gemini-3.1-flash-image-preview` via `https.request`)
4. Multi-turn refinement (turn 1 + turn 2 + thought_signature pass-through)
5. Per-call retry-with-backoff (10s/30s/60s/120s, then unlimited 5-min on 503/429/500)
6. Schema migration: `failed_retry_pending` + `failed_human_review` + `next_retry_at` + `last_error` columns
7. Background retry worker (`jobs/retry-failed-generations.ts`)
8. Cloudinary upload retry (3-attempt)
9. 3:4 aspect ratio enforcement via `imageConfig.aspectRatio`
10. Tier 2 spending plan ($250+ over 3 days bumps Google AI Studio API key)
11. Trigger.dev v3 migration per ADR-010 (wraps the retry-queue)
12. Cleanup: remove `appendPixarStyleAnchor`, `flux-kontext-pixar` provider, `PIXAR_STYLE_LORA_URL` env, experimental scripts
13. Push the 3 backend commits to origin (after watercolor revert lands)

**Deferred to Sprint 3+ or retired:**
- Validators framework v1 — partly redundant given Phase 1 verdict bounded face-fidelity structurally; cultural/age/religious-neutrality validators still in scope per ADR-012/013 but lower priority than the production migration
- Story-quality tuning — iter 7 confirmed story is already strong; gap is illustration-side
- Helicone observability — superseded by Sentry + PostHog instrumentation (Sprint 3 followup)
- Active learning loop with pgvector — Sprint 4+

**Reference implementation** for production migration: `hadouta-backend/src/scripts/_iter7_full_book.ts`. Has every layer-1 and layer-2 fix from ADR-029 working end-to-end.

---

## Original Sprint 3 plan (HISTORICAL — may be outdated)

The content below was written pre-Sprint-2 and assumed validators-first + Claude Sonnet + Helicone. Kept for historical reference; live status is above.

---

## Sprint goal

Working end-to-end AI generation pipeline: customer parameters → Claude story generation → universal validators → theme validator → Nano Banana 2 image generation → Puppeteer PDF assembly → Trigger.dev waitpoint for manual approval → admin can approve and "deliver" (mock — real customer delivery is Sprint 4).

---

## Acceptance criteria

- ✅ Story generation works: given parameters (kid name, age, gender, photo references, interest tag, supporting characters), produces structured 16-page JSON story via Claude Sonnet 4.6 + Zod schema
- ✅ Story passes Zod validation 100% of time (no malformed outputs reach validators)
- ✅ All 5 universal validators run in parallel; each produces structured pass/fail with category + reason
- ✅ Theme validator (First Day of School) verifies story mentions school + teacher + appropriate moral arc
- ✅ Image generation runs in parallel for 17 images (16 pages + 1 cover) via fal.ai Nano Banana 2
- ✅ Multi-character consistency works: kid + 1 supporting character maintain identity across 16 pages (test on 5 sample books)
- ✅ Puppeteer PDF assembly produces print-ready 16-page Arabic RTL PDF with embedded illustrations
- ✅ Trigger.dev workflow runs all of the above as a durable job; uses waitpoint to pause for manual approval
- ✅ Admin can approve via simple admin endpoint (UI is Sprint 5)
- ✅ Active learning data captured: rejections store category + free-text + embeddings in pgvector
- ✅ Helicone observability shows full request traces with metadata
- ✅ Validator regression suite passes with ≥95% accuracy on 100+ test cases
- ✅ Cost per book matches predicted ~$0.92 USD (~45 EGP); flag if higher

---

## Key tasks

### Story generation
- System prompt for FDS theme (commissioned writer reference stories used as few-shot examples)
- Zod schema enforcing story structure
- Vercel AI SDK `generateObject()` integration
- Anthropic prompt caching configured

### Universal validators
- 5 sub-validators with focused system prompts (religious_safety, cultural_safety, age_appropriate, moral_correctness, language_safety)
- Test suite of 100+ regression cases
- LLM-as-judge runner with parallel execution
- Pass/fail aggregation logic

### Theme validator
- FDS-specific rules in `content/themes/first-day-school/validator-rules.json`
- Theme-specific Haiku 4.5 prompt

### Image generation
- fal.ai client setup
- Multi-character prompt construction (face references + scene description + style consistency)
- Retry logic for failed generations (20% budget)
- Watercolor style reference seeding

### PDF assembly
- HTML template using shadcn/ui components (rendered server-side via Puppeteer)
- Arabic RTL typography
- Embedded SVG layout for cover, dedication, page transitions

### Workflow orchestration
- Trigger.dev job definitions
- Waitpoint integration for manual approval
- Webhook handlers for approval/rejection from admin

### Active learning
- pgvector embeddings on every generation
- Rejection capture API
- Helicone Request Datasets configuration

---

## Manager delegation (heavy on AI Engineer)

| Task | Primary | Reviewer |
|---|---|---|
| Story prompt engineering | AI Engineer | Backend Architect |
| Validator architecture + LLM-as-judge | AI Engineer | Software Architect |
| Image generation orchestration | AI Engineer | Backend Architect |
| PDF assembly | Frontend Developer (Puppeteer + HTML) | Code Reviewer |
| Trigger.dev workflows | AI Engineer | Backend Architect |
| pgvector + embeddings | Database Optimizer | AI Engineer |
| Code review (all) | Code Reviewer | (manager) |

---

## Out of scope (defer to Sprint 4+)

- Customer-facing ordering UI
- Payment integration
- Photo upload UI
- Admin review queue UI
- Email/WhatsApp delivery (mock for now)

Full task breakdown to be expanded when Sprint 3 starts.
