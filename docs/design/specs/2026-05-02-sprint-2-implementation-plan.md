# Hadouta Sprint 2 Implementation Plan — AI generation pipeline + admin review

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the AI-generated story + illustration pipeline that turns a paid order (Sprint 1 deliverable) into a 16-page book PDF, gated by Egyptian human review (ADR-013), delivered to the customer via WhatsApp + email.

**Architecture:**
- AI providers per ADR-006: **Anthropic Claude Sonnet 4.6** (story text), **fal.ai → Nano Banana Pro** (illustrations), **GPT Image 2** as illustration fallback.
- Async execution via simple in-process job pattern (Sprint 2 MVP); upgrade to **Trigger.dev v3** (per ADR-010) in Sprint 3 once we need durable retries + dashboards.
- New schema: `generations` (top-level workflow record per order) + `book_pages` (per-page story text + illustration URL).
- Manual review gate: separate Next.js admin app (`hadouta-admin/`, deployed to Vercel). Default shadcn neutral theme; no Hadouta brand chrome.
- Wizard step 7 confirmation re-renders against real generation status — customer sees "in production" → "in review" → "delivered" progression.
- Validators framework (per ADR-012): cultural authenticity + age appropriateness + religious neutrality + theme alignment. Sprint 2 ships v1 with rule-based checks; Sprint 3 adds embedding-based active learning loop.

**Tech Stack additions:**
- `@ai-sdk/anthropic` + `ai` (already in package.json from Sprint 1, unused)
- `@fal-ai/client` (NEW — fal.ai SDK for Nano Banana access)
- `pdf-lib` or `puppeteer` (PDF assembly — TBD by Task 2.6)
- Admin app: Next.js 16 + shadcn/ui (default theme) + AG Grid (per master design spec §8.1) + TanStack Query (or just openapi-fetch like wizard)

**Key strategic context — ADR-020 (2026-05-02):** AI-only generation, Egyptian human review only. NO Egyptian writers/illustrators commissioned for MVP. Cultural-specificity moat now lives in:
1. Egyptian-tuned system prompts (this sprint's biggest deliverable after the pipeline mechanics)
2. Validators framework
3. Manual review gate (ADR-013)

**Sequencing for time pressure:**
- **Part 1 (backend AI core)** — schema + Anthropic SDK + story generator + fal.ai SDK + illustration generator + validators v1. Can run independently of admin app.
- **Part 2 (orchestration)** — book-generation job that runs story → validate → illustrations → validate → ready-for-review → wait. Wires Paymob webhook → kicks off generation.
- **Part 3 (admin app)** — bootstrap separate Next.js project. CRUD pages: order list, order detail with story + illustration preview, approve/reject buttons.
- **Part 4 (delivery)** — PDF assembly + WhatsApp/email delivery. Triggered post-approval.
- **Part 5 (customer-facing status)** — wizard step 7 re-renders status; "Track your order" page.

Estimated 4-6 weeks solo. Subagent-driven dispatch can compress to 2-3 weeks if Parts 1+3 run in parallel.

---

## Pre-flight checklist

- [ ] On a clean branch: `git checkout -b feat/sprint-2-ai-pipeline`
- [ ] `hadouta-backend`: `pnpm typecheck && pnpm test` clean
- [ ] Anthropic API key obtained (Ahmed → fill in `.env.local` via the same `scripts/<service>/sync-to-railway.sh` pattern; SDK already in package.json)
- [ ] fal.ai API key obtained (Ahmed → free tier, no card needed; same pattern)
- [ ] `hadouta-admin` repo created (will be done by Task 3.1)

---

# Part 1 — Backend AI core

## Task 1.1 — Anthropic API key entry points + sync scripts

**Files:**
- Modify: `/home/ahmed/Desktop/hadouta/.env.local` — add `ANTHROPIC_API_KEY` placeholder
- Modify: `/home/ahmed/Desktop/hadouta/.env.example` — same
- Create: `scripts/anthropic/verify-creds.sh` — auth probe to `/v1/messages`
- Create: `scripts/anthropic/sync-to-railway.sh` — push to Railway prod env

Pattern matches existing `scripts/{cloudinary,paymob,twilio}/`. After Ahmed fills `.env.local`:
1. `bash scripts/anthropic/verify-creds.sh` → confirms HTTP 200 from `/v1/messages` test prompt
2. `bash scripts/anthropic/sync-to-railway.sh` → push to backend prod env

## Task 1.2 — fal.ai API key entry points + sync scripts

Same pattern as Task 1.1. Entry points: `FAL_API_KEY` (already exists in backend `.env.example`).
- `scripts/fal/verify-creds.sh` — auth probe to fal.ai `/queue/submit/` (small text-to-image test)
- `scripts/fal/sync-to-railway.sh`

## Task 1.3 — Schema migration 0004: generations + book_pages tables

**Files:**
- Modify: `hadouta-backend/src/db/schema.ts`
- Create: `hadouta-backend/src/db/migrations/0004_ai_pipeline_schema.sql` (hand-written per recurring drizzle-kit interactive issue)

```typescript
// Add to schema.ts
export const generationStatusEnum = pgEnum('generation_status', [
  'queued',
  'generating_story',
  'story_done',
  'generating_illustrations',
  'illustrations_done',
  'awaiting_review',
  'approved',
  'rejected',
  'assembling_pdf',
  'delivering',
  'delivered',
  'failed',
]);

export const generations = pgTable('generations', {
  id: uuid('id').primaryKey().defaultRandom(),
  orderId: uuid('order_id').notNull().references(() => orders.id, { onDelete: 'cascade' }),
  status: generationStatusEnum('status').notNull().default('queued'),
  storyJson: jsonb('story_json'),  // full story metadata (title, intro, pages array)
  coverUrl: text('cover_url'),
  pdfUrl: text('pdf_url'),
  rejectionCategory: text('rejection_category'),  // 'religious'/'cultural'/'age'/'pacing'/'language'/'format'/'visual'/'other' per ADR-013
  rejectionReason: text('rejection_reason'),  // free-text reviewer note
  retryCount: integer('retry_count').notNull().default(0),
  errorLog: text('error_log'),
  startedAt: timestamp('started_at', { withTimezone: true }),
  completedAt: timestamp('completed_at', { withTimezone: true }),
  reviewedAt: timestamp('reviewed_at', { withTimezone: true }),
  reviewedByUserId: text('reviewed_by_user_id').references(() => user.id),
  deliveredAt: timestamp('delivered_at', { withTimezone: true }),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const bookPages = pgTable('book_pages', {
  id: uuid('id').primaryKey().defaultRandom(),
  generationId: uuid('generation_id').notNull().references(() => generations.id, { onDelete: 'cascade' }),
  pageNumber: integer('page_number').notNull(),  // 0 = cover, 1-16 = body
  storyText: text('story_text').notNull(),
  illustrationUrl: text('illustration_url'),
  illustrationPrompt: text('illustration_prompt').notNull(),
  illustrationProvider: varchar('illustration_provider', { length: 30 }),  // 'nano-banana' | 'gpt-image-2'
  illustrationGeneratedAt: timestamp('illustration_generated_at', { withTimezone: true }),
  validationFlags: jsonb('validation_flags'),  // array of {validator, severity, message}
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});
```

Indexes: `idx_generations_order_id`, `idx_generations_status`, `idx_book_pages_generation_id`, unique constraint on (generation_id, page_number).

Hand-write migration SQL since drizzle-kit's interactive prompt blocks (recurring issue; flagged Sprint 2 followup as `validate-drizzle-migration` skill candidate).

## Task 1.4 — Egyptian-tuned story system prompt

**Files:**
- Create: `hadouta-backend/src/lib/ai/prompts/story-system-prompt.ts`

The cultural-specificity moat lives here per ADR-020. System prompt includes:

1. **Egyptian-context anchors** — Cairo apartments, Egyptian Arabic register (مش "مَا", بس "زي ما", إلخ), brand brief's three-worlds image set (Cairo Muslim middle-class, Coptic family, Aswan/Alex coastal), religion-neutral pan-Egyptian theme palette, anti-tourist/anti-Gulf/anti-Western-imported stance
2. **Age-band narrative tier** — vocab, sentence length, plot turns scaled by `child_age_band` (3-5 / 5-7 / 6-8)
3. **Theme spine** — derived from `themes` table catalog
4. **Moral teaching** — derived from `moral_values` table catalog (must teach the value naturally through story events, NOT via on-the-nose "and the moral is...")
5. **Personalization** — child name (used 5-10 times in 16 pages, naturally), gender, hobbies, fav food/color, special traits
6. **Supporting characters** — when present, each plays a meaningful role (sibling/friend/grandparent/etc.)
7. **Custom scene** — if customer provided one, weave it into the narrative
8. **Special occasion** — if provided, frame the story around it
9. **Output format** — strict JSON: `{title, dedication, pages: [{number, text, illustration_brief}]}` — illustration_brief is per-page guide for the illustration AI

Few-shot examples: 3 hand-curated examples by Claude (you, in this prompt-design phase) showing target output for different theme×value×age combinations. These few-shots ARE the human-curation that ADR-020 retains — it's just done in prompt engineering, not via separate writer hires.

## Task 1.5 — Story generator implementation

**Files:**
- Create: `hadouta-backend/src/lib/ai/story-generator.ts`

```typescript
import Anthropic from '@anthropic-ai/sdk';
import type { Order } from '../../db/schema';
import { storyOutputSchema } from './schemas/story';

const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

export async function generateStory(order: Order, theme: Theme, moralValue: MoralValue, supportingCharacters: SupportingCharacter[]): Promise<StoryOutput> {
  const systemPrompt = buildStorySystemPrompt({ ageBand: order.childAgeBand!, ... });
  const userPrompt = buildStoryUserPrompt({ order, theme, moralValue, supportingCharacters });

  const response = await anthropic.messages.create({
    model: 'claude-sonnet-4-5-20250929',  // or claude-haiku for cost-sensitive paths
    max_tokens: 8000,
    system: systemPrompt,
    messages: [{ role: 'user', content: userPrompt }],
  });

  const rawText = response.content[0].type === 'text' ? response.content[0].text : '';
  const parsed = storyOutputSchema.parse(JSON.parse(rawText));

  return parsed;
}
```

Returns 16-page story + cover prompt + dedication. Fails fast on validation errors (Zod parse).

## Task 1.6 — Egyptian-tuned illustration prompt builder

**Files:**
- Create: `hadouta-backend/src/lib/ai/prompts/illustration-prompt-builder.ts`

Per-page illustration prompt combines:
1. **Page's `illustration_brief`** from story output
2. **Child appearance** — from photo (when ADR-005 photo path) OR from description (when description path: skin tone hex + hair text + clothing style + eye color)
3. **Watercolor style anchor** — Beatrix Potter / E.H. Shepard tradition, soft outlines, gentle painted color, vintage-feel
4. **Egyptian visual heritage** — Cairo apartments, Egyptian textile motifs in margins (drawing from shared Coptic/Islamic/folk geometric vocab), no tourist clichés (no pyramids, no sphinx, no Gulf aesthetic)
5. **Color palette** — Hadouta brand palette in scenes (terracotta, ochre, teal, brown, cream, blush)
6. **Negative prompts** — no Crayola primary colors, no Disney-Junior big-eyes faces, no plasticky 3D, no glossy gradients

## Task 1.7 — Illustration generator (fal.ai for Nano Banana)

**Files:**
- Create: `hadouta-backend/src/lib/ai/illustration-generator.ts`
- Install: `pnpm add @fal-ai/client`

Async per-page generation. Each page submits a fal.ai job, awaits completion, returns image URL. Stored in Cloudinary (re-use Task 1.9 from Sprint 1) so we own the hosting and can apply transformations.

For 16 pages: parallelize submission (fal.ai handles concurrent), await all. ~30-90 seconds wall-clock for full book.

GPT Image 2 fallback: if fal.ai returns error or quality-validator rejects, retry with OpenAI Image API.

## Task 1.8 — Validators framework v1 (rule-based)

**Files:**
- Create: `hadouta-backend/src/lib/ai/validators/cultural.ts`
- Create: `hadouta-backend/src/lib/ai/validators/age-appropriate.ts`
- Create: `hadouta-backend/src/lib/ai/validators/religious-neutrality.ts`
- Create: `hadouta-backend/src/lib/ai/validators/theme-alignment.ts`
- Create: `hadouta-backend/src/lib/ai/validators/index.ts`

Each validator is a function `(story: StoryOutput, order: Order) => ValidationResult[]`. ValidationResult is `{validator, severity: 'info'|'warn'|'error', message}`.

V1 rules (non-LLM, fast):
- Cultural: contains banned terms (pyramids, hieroglyphs, sphinx, faux-mystical phrases like "magical journey")
- Age-appropriate: vocab complexity check (avg word length, sentence length per age band)
- Religious-neutrality: chrome content stays neutral (book interior can have religious content if theme demanded — Eid, Christmas — but cross-religion contamination flagged)
- Theme-alignment: theme keywords appear in story (not just title)

V2 (Sprint 3): LLM-based critic that reviews the full story and flags subtle issues.

Validators run after story generation; their output is stored in `book_pages.validation_flags` and surfaced in admin review queue.

## Task 1.9 — Sync API key entry points + run

End-to-end test: with anthropic + fal.ai keys synced to Railway, hit a debug endpoint `/api/admin/test-generate` that runs the full pipeline against a fake order and prints the resulting story JSON + 16 fal.ai image URLs.

---

# Part 2 — Workflow orchestration

## Task 2.1 — generation kick-off endpoint

**Files:**
- Create: `hadouta-backend/src/jobs/generate-book.ts`
- Modify: `hadouta-backend/src/routes/payments.ts` — webhook fires generation job

When Paymob webhook posts `success=true`, after marking `orders.status='paid'`:
1. Insert `generations` row with `status='queued'`
2. `setImmediate(() => generateBook(generationId))` — fire-and-forget
3. Webhook responds 200 immediately (Paymob expects fast ack)

`generateBook(generationId)`:
1. Update status → `generating_story`
2. Run `generateStory()`. Update `storyJson`, status → `story_done`
3. Run validators on story. Persist flags. If any 'error' severity, status → `failed` (admin can retry)
4. For each page, call `generateIllustration()` in parallel. Persist URLs in `book_pages` rows. Update status → `generating_illustrations` then `illustrations_done`
5. Status → `awaiting_review`. Stop. Manual review queue takes over.

Errors at any step → status → `failed`, errorLog populated, retryCount++. Admin can manually retry from admin UI.

## Task 2.2 — generations API (read endpoints for admin + customer status)

**Files:**
- Create: `hadouta-backend/src/routes/generations.ts`

```
GET /api/generations/:id — full generation + book_pages array
GET /api/orders/:id/generations — list generations for an order (usually 1, but retries create more)
GET /api/admin/generations?status=awaiting_review — list pending review (admin only)
POST /api/admin/generations/:id/approve — approve, kicks off Part 4 delivery
POST /api/admin/generations/:id/reject — reject with category + reason; status='rejected'; admin can retry
POST /api/admin/generations/:id/retry — re-run the generation (status='queued', runs Task 2.1 again)
```

Admin endpoints require Better-Auth session with `role='admin'`.

## Task 2.3 — Wire wizard step 7 to real status

**Files:**
- Modify: `hadouta-web/src/components/wizard/step-7-confirmation.tsx`

Currently step 7 shows "بدأنا في إعداد حدوتة" — static. Wire it to `GET /api/generations/:id` (latest generation for the order) and render different states:

- `queued` / `generating_story` / `generating_illustrations` → "بنحضّر حدوتة طفلك" + spinner
- `awaiting_review` → "حدوتتك جاهزة للمراجعة. فريقنا المصري بيراجعها دلوقتي."
- `approved` / `delivering` → "حدوتتك معتمدة! بنبعتها على واتساب دلوقتي."
- `delivered` → "حدوتتك وصلت! [download PDF link]"
- `rejected` / `failed` → "في مشكلة. فريقنا بيتعامل معها — هنبعتلك تحديث."

Poll every 5s OR use Server-Sent Events for real-time push (Sprint 3).

---

# Part 3 — hadouta-admin (separate Next.js app)

## Task 3.1 — Bootstrap hadouta-admin repo

**Files:**
- Create: `/home/ahmed/Desktop/hadouta/hadouta-admin/` (new sub-repo, separate git history)

```bash
cd /home/ahmed/Desktop/hadouta
npx create-next-app@latest hadouta-admin --typescript --tailwind --app --src-dir --import-alias "@/*"
cd hadouta-admin
git init
git remote add origin git@github.com:ahmedabdelhamid404/hadouta-admin.git
pnpm dlx shadcn@latest init  # default neutral theme, NOT Hadouta
pnpm dlx shadcn@latest add button card input label table accordion dropdown-menu
pnpm add @tanstack/react-table  # AG Grid is heavy + paid; tanstack/react-table is enough for MVP
pnpm add openapi-fetch
```

`hadouta-admin/.env.local`:
```
NEXT_PUBLIC_API_URL=http://localhost:3001
NEXT_PUBLIC_BETTER_AUTH_URL=http://localhost:3001
```

Update `hadouta-admin/.gitignore`. First commit: scaffold + `git push -u origin main`.

Vercel project: link via `vercel link`. Deploy preview from `main`.

## Task 3.2 — Auth gate (admin role only)

**Files:**
- Create: `hadouta-admin/src/middleware.ts` — checks `role='admin'` on every page request, redirects to `/login` if not
- Create: `hadouta-admin/src/app/login/page.tsx` — Better-Auth phone-OTP login (re-uses backend's existing endpoints)

## Task 3.3 — Order list page

**Files:**
- Create: `hadouta-admin/src/app/orders/page.tsx`

TanStack-React-Table grid showing:
| # | Customer | Child | Theme | Status | Created | Action |
|---|----------|-------|-------|--------|---------|--------|

Columns sortable + filterable. Status filter: `awaiting_review` selected by default (review queue is the primary admin task). Click row → `/orders/[id]`.

## Task 3.4 — Order detail page

**Files:**
- Create: `hadouta-admin/src/app/orders/[id]/page.tsx`

Split layout per master design spec §8.1:
- Left pane (60% width on desktop): full story scrollable (16 pages, RTL Arabic)
- Right pane (40%): page-by-page illustrations grid (4×4 thumbnails); click opens modal with full-size

Top bar: customer info + child info + theme + moral value + custom scene (if any).

Bottom action bar:
- ✓ Approve (large, terracotta — kicks off Part 4 delivery)
- ↻ Regenerate (with feedback modal: category dropdown + free-text)
- ✕ Refund (rare; opens Paymob refund flow per ADR-014)

Validators flags from `book_pages.validation_flags` rendered as warnings on each page (yellow if 'warn', red if 'error') — reviewer sees them at-a-glance.

## Task 3.5 — Approval action

**Files:**
- Modify: `hadouta-admin/src/app/orders/[id]/page.tsx`

Approve button → `POST /api/admin/generations/:id/approve` → backend kicks off Part 4 (PDF assembly + delivery).

Reject button → modal with category + reason → `POST /api/admin/generations/:id/reject` → backend marks rejected, admin can manually retry.

---

# Part 4 — Delivery

## Task 4.1 — PDF assembler

**Files:**
- Create: `hadouta-backend/src/lib/pdf/assemble-book.ts`

Approach options:
- **A**: HTML template + `puppeteer` → PDF — flexible, can re-use brand chrome CSS
- **B**: Programmatic with `pdf-lib` — leaner, no Chromium dependency

For MVP: option B (`pdf-lib`). 16 pages, each with image + text. Cover with title + child name + dedication.

Output: PDF uploaded to Cloudinary as a `raw` resource (Cloudinary supports PDFs). URL persisted in `generations.pdfUrl`.

## Task 4.2 — WhatsApp delivery template

**Files:**
- Create: Meta template submission spec at `docs/operations/whatsapp-templates/order-delivered.md`

Per brand brief WhatsApp spec: Utility category template "كتاب طفلكم وصل" includes child's name + PDF download link + 2-line message. Submit to Meta for approval (24-48h review).

Template body (Arabic primary):
```
{{1}}، حدوتة {{2}} وصلت! 🤍

كتاب طفلك جاهز — حمّل النسخة الكاملة:
{{3}}

شكراً إنك اخترتنا.
```

Implementation in `src/lib/notifications/whatsapp.ts`. Trigger from Part 4 post-PDF-assembly.

## Task 4.3 — Email fallback

**Files:**
- Create: `hadouta-backend/src/lib/notifications/email.ts`

If WhatsApp fails (or customer used email-OTP path per ADR-018 tier-3), email the PDF link via Resend.

---

# Part 5 — Status visibility

## Task 5.1 — Track-your-order page

**Files:**
- Create: `hadouta-web/src/app/account/orders/[id]/page.tsx`

Customer-facing page showing generation status timeline. Public — accessible via secure link (HMAC over orderId in URL); no Better-Auth session required since customer doesn't have credentials per ADR-018 invisible-accounts.

Renders the same status states as wizard step 7, but standalone (customer can return weeks later via the link).

## Task 5.2 — Wizard step 7 polling integration

(Already covered in Task 2.3 — listed here for completeness.)

---

# Validation + observability

## Task V.1 — Generation pipeline test fixtures

**Files:**
- Create: `hadouta-backend/tests/integration/generation-pipeline.test.ts`

E2E test creates a paid order, kicks off pipeline, waits for `awaiting_review`, asserts story + illustration count + validator flags shape. Skips fal.ai actual call (mocked) for cost/speed.

Hand-roll a few "golden output" stories per theme×value×age cell as regression test — if AI generates dramatically different shape, test fails.

## Task V.2 — Sentry instrumentation

**Files:**
- Modify: `hadouta-backend/src/jobs/generate-book.ts`

Wrap each pipeline stage in `Sentry.startSpan()`. Errors auto-capture per Sprint 1 setup.

## Task V.3 — PostHog event tracking

Events:
- `generation_started`
- `generation_failed` (with stage)
- `generation_awaiting_review`
- `generation_approved` (admin user)
- `generation_rejected` (admin user, category)
- `generation_delivered`

Funnel analysis: how many paid orders make it to delivered, average time per stage, rejection rate by category.

---

# Self-review checklist (run when plan complete)

- [ ] **Spec coverage**: ADR-006 + ADR-010 + ADR-012 + ADR-013 + ADR-019 + ADR-020 all cited in relevant tasks
- [ ] **No placeholders**: every step shows actual code or actual SQL
- [ ] **Type consistency**: Drizzle schema types match Zod schema types (story output, validation result)
- [ ] **AI-honesty rule applied**: customer-facing copy in step 7 / admin UI follows the post-ADR-020 rules
- [ ] **Sequence is correct**: generation can only run on paid orders; review can only happen after illustrations done; delivery only after approval
- [ ] **Failure modes handled**: every API call has a retry path; every validator has a flag persistence path; admin can manually intervene at any state

---

# Execution Handoff

After plan saved + reviewed, offer execution choice:

**1. Subagent-Driven (recommended for time pressure)** — I dispatch a fresh subagent per task or part-chunk, review between tasks, fast iteration. Best for parallelism: Part 1 backend + Part 3 admin app run in parallel (different repos).

**2. Inline Execution** — Execute tasks in this session using `superpowers:executing-plans`, batch with checkpoints.

Estimated:
- Part 1 backend AI core: 4-5 days solo
- Part 2 orchestration: 1-2 days
- Part 3 admin app: 3-4 days
- Part 4 delivery: 2-3 days
- Part 5 status: 1 day
- V testing: 2 days
- **Total: 13-17 days solo / 7-10 days with subagent dispatch parallelizing Parts 1+3**
