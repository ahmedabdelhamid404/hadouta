# Sprint 3 — AI Pipeline Foundation

**Window**: Weeks 5–8 of build
**Status**: ⏸️ Skeletoned (full detail when sprint starts)

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
