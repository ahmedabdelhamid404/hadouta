# ADR-022: Sprint 2 AI pipeline architecture — multi-provider router, admin-controlled cost knobs, Puppeteer PDF

**Date:** 2026-05-03 (session 9)
**Status:** Accepted
**Extends:** ADR-006 (AI stack: Claude + Nano Banana + GPT Image fallback), ADR-010 (Trigger.dev v3 with waitpoints), ADR-020 (AI-only generation, human review only)

## Context

Sprint 2 ships the AI generation pipeline that turns a paid order into a 16-page Arabic children's book. ADR-006 fixed the prod model targets (Claude Sonnet 4.6 for story; Nano Banana Pro for illustrations; GPT Image 2 fallback). ADR-010 fixed the future durability layer (Trigger.dev). For the **first cycle dev iteration**, several pragmatic decisions shape implementation:

1. **Story model for dev:** Ahmed has OpenAI credits; gpt-4o-mini is ~$0.0017 per 16-page story (vs Claude Sonnet at ~$0.04). Letting dev run cheap means we can iterate on prompt + few-shots without watching token cost.
2. **Illustration provider for dev:** Ahmed has Google AI Studio Pro with billing enabled. Going **direct** to Google for `gemini-2.5-flash-image` (Nano Banana) skips the fal.ai middleman.
3. **Page count:** ADR-006 says 16 body pages; for the very first iteration I shipped 8 to keep illustration cost down ($0.16 vs $0.34). Quickly bumped back to 16 once Ahmed flagged "story feels short."
4. **PDF assembly:** Arabic + RTL + bidi shaping in PDF is non-trivial. `pdf-lib` doesn't shape Arabic letters; Puppeteer + Chromium handles it natively.
5. **Cost-control surface:** Ahmed wants every cost-related knob (story model, illustration model, max retries, page count, max tokens) tunable from the admin UI without code changes.

## Decision

### 1. Multi-provider AI router (model-string prefix routing)

`src/lib/ai/router.ts` exposes `resolveTextModel(modelString)` that returns a Vercel AI SDK `LanguageModelV1`:

| Prefix | Provider | SDK |
|---|---|---|
| `gpt-*`, `o1-*` | OpenAI | `@ai-sdk/openai` |
| `claude-*` | Anthropic | `@ai-sdk/anthropic` |
| `gemini-*` | Google | `@ai-sdk/google` |

Cost-per-million-token rates are captured in a static `COST_TABLE` keyed by model id. `estimateCostCents()` returns the actual $ spent per generation, persisted in `generations.estimated_cost_cents` so the admin queue shows $ per book.

For illustrations, `gemini-*` only is supported in v1 via `@google/genai` direct (the AI SDK doesn't yet do image-output `generateObject` cleanly). fal.ai/OpenAI Image fallbacks are deferred to Sprint 3 when admin can flip via `ai_settings.illustrationModel`.

### 2. `ai_settings` singleton row — admin-tunable cost knobs

A single-row table `ai_settings` (`id='singleton'`) owns every runtime knob:

```
storyModel               default 'gpt-4o-mini' (dev) → 'claude-sonnet-4-5' (prod)
storyMaxTokens           default 8000
illustrationModel        default 'gemini-2.5-flash-image'
illustrationCount        default 16 (was 8 during first iteration; bumped same day)
maxRetries               default 1 (dev) → 3 (prod) per Ahmed's Q5 lock
allowIllustrationFallback default true
autoApproveThreshold     default null (always review per ADR-013)
```

All AI code paths read this row at start. The (forthcoming) admin settings page mutates it without redeploys. Reseed via `pnpm db:seed:ai-settings` — idempotent UPSERT.

### 3. Pipeline orchestration — in-process fire-and-forget for first cycle

`src/jobs/generate-book.ts` exposes `kickoffGenerationIfNeeded(orderId)` — idempotent, called from the Paymob webhook + browser-return callback (both fire; second call is a no-op via the non-terminal-status check). Inside:

1. Insert `generations` row (`status='queued'`).
2. Update → `generating_story` → `generateStory()` (Vercel AI SDK `generateObject` + Zod schema) → store `storyJson` + tokens + cost → insert one `book_pages` row per page.
3. Update → `generating_illustrations` → `generateAllIllustrations()` (cover + body pages, concurrency 3) → upload each PNG to Cloudinary → write URLs back.
4. Update → `awaiting_review`. Update parent `orders.status='review'`. Emit SSE `generation_status` event.

Errors at any step → `status='failed'`, `error_log` populated (truncated to 8K), SSE emit. Single-attempt; admin retries via UI.

**ADR-010 deferred:** durable retries + dashboards via Trigger.dev are deliberately not in v1. The in-process job covers low-volume first cycle. When per-day generations cross ~50, switch.

### 4. Story content schema (matches few-shot examples)

The story Zod schema enforces:

- `title`, `dedication`, `coverDescription` (English illustration prompt — separate from page 1), `parentDiscussionQuestion` (Arabic Egyptian-dialect, asked after reading)
- `pages: [{ number, act ("setup"|"challenge"|"resolution"), emotionalBeat (English label), moralMoment (boolean), text (Arabic — mixed register), illustrationPrompt (English) }]`

Runtime invariants enforced in `story-generator.ts` after `generateObject`:
- Page count exactly matches `ai_settings.illustrationCount`
- Exactly ONE page with `moralMoment: true`
- Page numbers 1..N consecutive

### 5. PDF assembly — Puppeteer + HTML+Cairo

`src/lib/pdf/render-book.ts` launches headless Chromium, loads an HTML template (Tailwind-equivalent inline styles, Google Fonts Cairo for Arabic), `page.pdf({format: 'A5', printBackground: true})`. Output uploaded to Cloudinary as `raw` resource. `generations.pdf_url` populated; status flips to `delivered`.

**Why Puppeteer over alternatives:**
- `pdf-lib` alone — doesn't do Arabic letter shaping (would render disconnected letters)
- Client-side jspdf — no canonical artifact; renders differ per device
- Puppeteer — Chromium's font shaping is industry standard; PDF identical for everyone; reusable later for WhatsApp delivery (server-side artifact required)

**Tradeoff accepted:** Chromium adds ~150 MB to the Railway container. Mitigated via `pnpm.onlyBuiltDependencies: ["puppeteer"]` so postinstall runs on Railway. If Railway memory becomes tight, swap to `@sparticuz/chromium` (~50 MB serverless build).

## Consequences

**Wins:**
- Provider-agnostic story generation: dev cheap, prod premium, both run the same orchestration
- Admin can flip models without redeploys
- Cost is observable per-generation in the admin queue
- PDF is a real artifact, durable + sharable
- Schema invariants catch model failures at the boundary (gpt-4o-mini's first attempt at 16 pages produced 8; runtime check caught it; prompt iteration fixed it)

**Costs:**
- More moving parts: 4 AI keys (OpenAI + Anthropic + Google + fal.ai placeholder) on Railway
- Cost table needs manual updates as providers change pricing (~quarterly)
- Single-instance SSE bus — works for 1 backend instance; needs Redis pub/sub upgrade when scaling

## Migration path → Sprint 3

- Add validators framework (cultural / age-appropriate / religious-neutrality / theme-alignment) running after story generation; persist to `book_pages.validation_flags`
- Migrate orchestration to Trigger.dev v3 (per ADR-010) when concurrency or durability matters
- Add fal.ai illustration fallback (admin UI flip)
- Fix watercolor style adherence (current Gemini output is realistic-painted, not watercolor — needs stronger style anchor + negative prompt)
- Fix story content drift on gpt-4o-mini (declares moral verbatim; resolution pages are filler) — either upgrade to Claude Haiku 4.5 dev model or strengthen prompt with anti-pattern examples

## Files

- `src/lib/ai/schemas/story.ts`
- `src/lib/ai/router.ts`
- `src/lib/ai/story-generator.ts`
- `src/lib/ai/illustration-generator.ts`
- `src/lib/ai/prompts/story-system-prompt.ts`
- `src/lib/ai/prompts/build-story-user-prompt.ts`
- `src/lib/ai/prompts/story-examples/{01-friendship-3-5,02-school-5-7,03-eid-6-8}.ts`
- `src/jobs/generate-book.ts`
- `src/lib/pdf/render-book.ts`
- `src/db/schema.ts` — `ai_settings`, `generations`, `book_pages` tables
- `src/scripts/seed-ai-settings.ts`
- `src/scripts/test-generate-{story,illustration}.ts`
