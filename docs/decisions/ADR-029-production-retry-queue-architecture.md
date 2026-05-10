# ADR-029 — Production retry-queue architecture for AI illustration generation

**Date:** 2026-05-10
**Status:** Locked (per founder decision during 2026-05-10 session)
**Companion to:** ADR-010 (Workflow: Trigger.dev v3 with waitpoints) — this ADR is the implementation spec for the retry-resilience layer that ADR-010 promised.

## Context

The 2026-05-10 face-fidelity marathon session (`docs/session-notes/2026-05-10-face-fidelity-marathon.md`) tested the full 16-page Hana book pipeline against Google's `gemini-3.1-flash-image-preview` (Nano Banana 2) directly. The test surfaced production-grade reliability issues that the existing in-process fire-and-forget orchestration (per ADR-022) cannot handle:

1. **Google preview API returns 503 "high demand" frequently on Tier 1**. Multiple times per hour during global peak load. Failed calls don't bill, but customer waits silently while retries fire.

2. **Multi-turn refinement (turn 1 + turn 2 self-critique) is the killer feature** that justifies Google direct over fal.ai middleware. fal.ai's hosted endpoint is single-shot only.

3. **Cloudinary upload occasionally times out** with 499 client-timeout. Independent failure domain from the Google API.

4. **Long generations (16+ pages × multi-turn = 30+ minute jobs) cannot be synchronous.** Customer can't wait at the keyboard. Generation must run in background and notify on completion.

5. **Network partitions, Node restarts, OS sleep events** — any of these mid-generation must not lose state. Customer paid; their book must complete.

Synchronous fail-and-die is unacceptable when calling Google direct in production.

## Decision

Implement a **persistent queue-based retry architecture** for all AI illustration generation jobs. Customer-facing UX never observes Google API flakiness; the system absorbs it transparently.

### Architecture

```
Customer paid → Order row inserted (status: pending)
  ↓
Generation row inserted (status: queued)
  ↓
Worker picks up → status: generating_illustrations
  ↓                                 ↓
✓ all illustrations succeed     ✗ Google 503/429/500 OR Cloudinary timeout
  ↓                                 ↓
status: awaiting_review        status: failed_retry_pending
                               next_retry_at: NOW() + 5 min
                               retry_count: incremented
                               last_error: error message snapshot
                                   ↓
                       Cron worker every 5 min picks up
                       failed_retry_pending WHERE next_retry_at < NOW()
                       AND retry_count < MAX_RETRIES (default 20)
                                   ↓
                       Re-attempt → if success: awaiting_review
                                  → if fail: bump retry_count, update next_retry_at,
                                              save error, status stays failed_retry_pending
                                   ↓
                       After MAX_RETRIES → status: failed_human_review
                       (admin sees in dashboard, manually intervenes)
```

### Key invariants

1. **Same model on every retry.** Per founder direction during this session: NO model fallback. Brand consistency requires every customer's book to render on the same model. If `gemini-3.1-flash-image-preview` is down, every customer waits — none get their book on a different model.

2. **Retry costs are zero on transient failures.** Google + fal.ai don't bill 503/429/500/timeout. The only cost is on successful generations. Worst case: 20 free retries + 1 successful = same cost as one clean run.

3. **Resumability per illustration**. A 17-page generation that fails on page 11 does NOT redo pages 1-10. The queue runner re-queries `bookPages` for the generation, sees pages 1-10 already saved, and only re-attempts pages 11-17. Per-page persistence is mandatory.

4. **Bounded retry budget.** MAX_RETRIES = 20 (≈10 hours of attempts with exponential backoff). After that, escalate to human review — protects against permanent failure modes (corrupted reference photo, malformed prompt, etc.) burning indefinite retries.

5. **Customer comms via WhatsApp** (per ADR-018):
   - Order paid → "Your book for [child] is being prepared. Typically 5-10 min."
   - Queue >15 min → "We're seeing high AI illustration demand. Your book is queued — expected within 1 hour."
   - Queue >2 hours → "Your book is taking longer than usual. We'll notify within 24 hours OR refund automatically."
   - Success → "Your book is ready! [PDF link]"

### Implementation layers

**Layer 1 — Per-call retry with category-aware policy** (in `illustration-generator.ts`):
> ⚠️ The original "retry on 503/429/500, bail on 400/401/403" rule is INSUFFICIENT — it conflates throttling-429 with billing-429 with quota-429 and silently retries forever on permanent billing failures. Superseded by the **comprehensive error taxonomy** in the addendum at the bottom of this ADR. Use the taxonomy table as the canonical retry decision tree.

Summary of the policy classes:
- `forever-1min`: 503 capacity (Tier-1 throttling) — only category that retries indefinitely
- `honor-retryDelay`: 429 transient throttle — backoff per Google's `retryDelay` field
- `3x-backoff`: Cloudinary 5xx, Gemini 500/502, network blips — 3 attempts then alert
- `1x-then-alert`: Gemini STOP-no-image (model returned text only) — one reroll
- `no-retry`: billing depleted, spending cap, auth, content blocks — surface immediately to admin
- `retry-after-midnight-PT`: daily quota exhausted — schedule resume at PT midnight

**Layer 2 — Multi-turn refinement** (in `illustration-generator.ts`):
- Turn 1: customer photo + style reference + prompt → generate
- Turn 2: same conversation history (preserving `thought_signature` from turn 1's response) + critique prompt → refined output
- If turn 2 fails (e.g. context too long), fall back to turn 1's output (already a complete image)

**Layer 3 — Per-illustration persistence** (in `generate-book.ts`):
- After each successful illustration → insert `bookPages` row immediately
- Cover URL → update `generations.coverUrl` immediately
- Never hold completed illustrations in memory waiting for batch persist

**Layer 4 — Background retry worker** (new: `src/jobs/retry-failed-generations.ts`):
- Cron schedule: every 5 minutes
- Query: `failed_retry_pending` generations where `next_retry_at <= NOW()` and `retry_count < MAX_RETRIES`
- Limit: 5 generations per cron run (concurrency control)
- For each → re-trigger from where it stopped (per-illustration resume)

**Layer 5 — Trigger.dev migration (per ADR-010)**:
- Replace `setInterval`-style cron with Trigger.dev v3 durable jobs
- Survives Node restarts, observable in dashboard, automatic dead-letter handling
- Keep the layer 1-4 logic as-is — Trigger.dev wraps it with durability

### Schema changes required

```sql
-- Add new generation_status enum values
ALTER TYPE generation_status ADD VALUE 'failed_retry_pending';
ALTER TYPE generation_status ADD VALUE 'failed_human_review';

-- Add tracking columns
ALTER TABLE generations
  ADD COLUMN next_retry_at timestamptz,
  ADD COLUMN last_error text;
-- retry_count column already exists per current schema
```

### Direct Google API call shape (replaces fal.ai for production)

Endpoint: `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-image-preview:generateContent`

Request:
```json
{
  "contents": [
    { "role": "user", "parts": [
        { "inline_data": { "mime_type": "image/jpeg", "data": "<base64 customer_photo>" } },
        { "inline_data": { "mime_type": "image/jpeg", "data": "<base64 style_reference>" } },
        { "text": "<role-assigned narrative prompt per iter 7>" }
    ]}
  ],
  "generationConfig": {
    "responseModalities": ["IMAGE"],
    "temperature": 0.4,
    "imageConfig": { "aspectRatio": "3:4" }
  }
}
```

Multi-turn turn 2 includes turn 1's full response parts (preserving `thought_signature`):
```json
{
  "contents": [
    { "role": "user", "parts": [...turn 1 user content...] },
    { "role": "model", "parts": [...turn 1 raw response parts (with thought_signature)...] },
    { "role": "user", "parts": [{ "text": "<critique prompt>" }] }
  ],
  ...same generationConfig...
}
```

Use Node's built-in `https.request` with explicit 20-min socket timeout. Do NOT use `fetch()` with default undici (5-min headers timeout fires unpredictably).

## Consequences

### Positive
- **Customer experience uncoupled from Google API uptime**. Customer paid → eventually gets book regardless of throttling.
- **Cost-efficient**. Failed retries are free. Only successful illustrations bill.
- **Brand consistency**. Single model, no fallback. All customers' books render with the same aesthetic baseline.
- **Observable**. Failed-retry-pending and failed-human-review generations show up in admin dashboard with retry count + last error + next retry time.
- **Recoverable**. Network partitions, Node restarts, OS sleep all survivable via DB-persisted state + resumable workers.

### Negative
- **Customer wait time variance**. Best case 5-10 min, worst case 24 hours. WhatsApp comms must manage expectations.
- **Operational complexity**. Schema migration + cron worker + Trigger.dev dependency + admin dashboard panel for stuck generations. Sprint 3-4 work.
- **Potential for refund/regenerate edge cases**. Customer pays, system fails to deliver after MAX_RETRIES → automatic refund OR free regeneration credit policy (Sprint 5+).

### Neutral
- **No vendor lock-in**. Same model, same API key, same provider — just resilient against transient failures.
- **Tier 1 → Tier 2 migration is orthogonal**. The retry-queue handles whatever Google throws at us; Tier 2 just makes 503s rarer.

## Implementation tasks (Sprint 3 followup)

| Task | File(s) | Effort |
|---|---|---|
| Schema migration: enum + 2 columns | `db/migrations/000X_retry_queue.sql` | 30 min |
| Layer 1: retry-with-backoff in illustration-generator | `lib/ai/illustration-generator.ts` | 1 hour |
| Layer 2: multi-turn refinement | `lib/ai/illustration-generator.ts` | 2 hours |
| Layer 3: per-illustration persistence | `jobs/generate-book.ts` (already partial) | 30 min |
| Layer 4: background retry worker | `jobs/retry-failed-generations.ts` (new) | 2 hours |
| Layer 5: Trigger.dev migration | follow ADR-010 plan | Sprint 3+ |
| Admin dashboard: stuck-generations panel | `hadouta-admin/app/orders/...` | 2 hours |
| WhatsApp templates: paid / queued / completed / delayed / refunded | per ADR-018 | Sprint 4 |
| Customer-facing copy: expectation management | landing page, wizard | Sprint 3 |

Reference implementation: `hadouta-backend/src/scripts/_iter7_full_book.ts` — has every layer-1 and layer-2 element working end-to-end on a real generation. Layer 3 mostly there. Layer 4-5 are the production gap.

## Addendum (2026-05-10 evening) — Comprehensive error taxonomy

**Trigger for this addendum:** during iter 8 validation later the same day, the script silent-retried indefinitely on a 429 response with body `"Your prepayment credits are depleted"`. Founder noticed and topped up credits within ~3 minutes; without that intervention, the script would have retried forever. Root cause: the original Layer 1 rule treats ALL 429s as transient throttling, but Google uses 429 for at least four semantically distinct conditions, only ONE of which is retriable.

AI Engineer dispatch + parallel doc/web research produced the canonical taxonomy below. Reference implementation in `hadouta-backend/src/scripts/_iter8_full_book.ts` (`categorizeError()` + `callGoogleApi()` retry executor + parse-time `finishReason`/`blockReason` extraction). Production migration ports these into `src/lib/ai/illustration-generator.ts`.

### Critical gotchas (top of mind for reviewers)

1. **The 429 four-way ambiguity.** Status code alone is useless — match the message body. Order: billing patterns FIRST, daily quota SECOND, tier-misconfigured THIRD, throttle as fallthrough.
2. **Content blocks return HTTP 200, not 4xx.** `finishReason: IMAGE_SAFETY` and `promptFeedback.blockReason: SAFETY` come back inside a 200 OK body. Without parse-time extraction, content blocks become silent retry-forever-on-empty-response failures.
3. **Layer-2 safety blocks are non-configurable.** `safetySettings: BLOCK_NONE` only relaxes Layer 1 (HARASSMENT/HATE/SEXUAL/DANGEROUS). Layer 2 (IMAGE_SAFETY, PROHIBITED_CONTENT, RECITATION, CSAM, copyright, celebrity-likeness) cannot be disabled — for a kids-book platform with parent photo references, this WILL fire occasionally.
4. **`finishReason: STOP` with no inline image** ≠ safety block. Model returned text instead of image. One reroll usually fixes; not a hard failure.
5. **Cloudinary 420 is also for paid add-ons.** Background-removal/auto-tagging credit exhaustion returns 420 with `add-on usage` in message. Distinct from request-rate 420.

### Gemini direct API (`gemini-3.1-flash-image-preview`) error catalog

| HTTP | error.status / pattern | Category Label | Retry Policy | Severity | Admin Action |
|---|---|---|---|---|---|
| 400 | INVALID_ARGUMENT | Gemini Bad Request | no-retry | error | Fix request payload |
| 400 | `User location not supported` / `billing not enabled` / FAILED_PRECONDITION | Gemini Billing Region Block | no-retry | critical | Enable billing on GCP project |
| 401 | UNAUTHENTICATED / `API key not valid` / `API_KEY_INVALID` | Gemini Auth - Invalid Key | no-retry | critical | Rotate `GOOGLE_AI_API_KEY` |
| 403 | PERMISSION_DENIED | Gemini Auth - Permission Denied | no-retry | critical | Enable Generative Language API |
| 404 | `not found` + `model` / deprecated | Gemini Model Deprecated | no-retry | critical | Update model name in env |
| 408 / 504 | DEADLINE_EXCEEDED / `timeout` | Gemini Timeout | 3x-backoff | warn | Reduce prompt size |
| **429** | **`prepayment credits.*depleted` / `No available credits`** | **Gemini Billing - Credits Depleted** | **no-retry** | **critical** | **Top up Google AI prepay balance** |
| 429 | `monthly spending cap` / `billing account.*exceeded` | Gemini Billing - Spending Cap | no-retry | critical | Raise cap or wait for next cycle |
| 429 | `per day` / `RPD` / `requests per day` | Gemini Quota - Daily Exhausted | retry-after-midnight-PT | error | Wait 00:00 PT reset |
| 429 | `free_tier` + quota=0 (Tier-1 paid acct stuck) | Gemini Tier Misconfigured | no-retry | error | Verify Tier 1 took effect; contact GCP |
| 429 | (default fallthrough) | Gemini Rate Limit - Throttle | honor-retryDelay | warn | Backoff per `retryDelay` field |
| 500 | INTERNAL | Gemini Internal Error | 3x-backoff | warn | Transient Google-side |
| 502 | Bad Gateway | Gemini Gateway Error | 3x-backoff | warn | Transient |
| 503 | UNAVAILABLE / `model is overloaded` | Gemini Capacity (Tier 1) | forever-1min | warn | Known Tier-1 capacity pressure |
| **200** | `finishReason: IMAGE_SAFETY` (no inlineData) | **Gemini Content Blocked - Output Safety** | **no-retry** | **error** | Review prompt; flag for human review |
| 200 | `finishReason: PROHIBITED_CONTENT` / `IMAGE_PROHIBITED_CONTENT` | Gemini Content Blocked - Layer 2 | no-retry | error | Layer-2 (CSAM/copyright/celebrity) — rephrase |
| 200 | `promptFeedback.blockReason: SAFETY` (no candidates) | Gemini Prompt Blocked - Input | no-retry | error | Input prompt failed safety pre-check |
| 200 | `finishReason: STOP` + no inlineData | Gemini No Image Generated | 1x-then-alert | warn | Model returned text; reroll once |
| 200 | `finishReason: RECITATION` | Gemini Recitation Block | no-retry | warn | Output matched copyrighted training data |

### Cloudinary upload API error catalog

| HTTP | Message pattern | Category Label | Retry Policy | Severity | Admin Action |
|---|---|---|---|---|---|
| 400 | `Empty file` / `Invalid image file` | Cloudinary Bad Input | no-retry | error | Buffer corrupted upstream |
| 400 / 413 | `File size too large.*Maximum is N` | Cloudinary File Too Large | no-retry | error | Compress; check tier max (free=10MB) |
| 401 | `Invalid api_key` / `Invalid API key` | Cloudinary Auth - Invalid Key | no-retry | critical | Rotate `CLOUDINARY_API_KEY` |
| 401 | `Invalid Signature` / `String to sign` | Cloudinary Auth - Bad Signature | no-retry | critical | Check `CLOUDINARY_API_SECRET` |
| 401 | `cloud_name.*disabled` / `Customer is disabled` | Cloudinary Account Suspended | no-retry | critical | Contact Cloudinary support |
| 403 | `Customer is disabled` / `not allowed` | Cloudinary Plan Restricted | no-retry | critical | Upgrade plan |
| 420 | `Rate limit` / `concurrent requests` / `add-on usage.*exceeded` | Cloudinary Rate Limit / Quota | 3x-backoff | error | Reduce concurrency; check credit usage |
| 499 | (client closed) | Cloudinary Client Timeout | 3x-backoff | warn | Network blip |
| 500+ | Internal | Cloudinary Internal Error | 3x-backoff | warn | Transient Cloudinary-side |

### Network / DB fallthrough

| Pattern | Category Label | Retry Policy | Severity | Admin Action |
|---|---|---|---|---|
| `ECONN` / `ENOTFOUND` / `ETIMEDOUT` / `socket hang up` | Network Error | 3x-backoff | warn | Transient network blip |
| `postgres` / `drizzle` / `relation` / `column` / `constraint` | Database Error | no-retry | critical | Check schema/connection |
| (anything else unmatched) | Unknown Error | no-retry | error | Review logs; investigate |

### Retry policy decoder

| Policy | Behavior |
|---|---|
| `forever-1min` | Sleep 60s, retry. Indefinite. ONLY for confirmed-transient capacity 503s. |
| `honor-retryDelay` | Parse `retryDelay` from Google's RetryInfo (format: `"60s"`); if absent, exponential backoff capped at 60s. |
| `3x-backoff` | 3 attempts with 5s/10s/15s delays. Then surface to admin. |
| `1x-then-alert` | 1 retry after 2s. Then surface. |
| `retry-after-midnight-PT` | Don't retry in current run. Surface to admin; production queue worker schedules resume at next 00:00 PT. |
| `no-retry` | Surface immediately. Permanent until admin acts. |

### Phase B production migration mapping

The end-of-run summary structure in iter 8 (`printFailureSummary`) is the **direct UI mockup** for the Phase B admin alert dashboard. Each `PageFailure` row maps 1:1 to an admin alert card with:
- **Severity badge** (warn / error / critical) — color-coded
- **Category label** — bold heading
- **Page reference** (Cover / Page N) — context
- **Error message** — debugging detail
- **Admin action** — actionable instruction
- **Retry button** — re-trigger Gemini call (for `no-retry` permanent categories, this only fires after founder fixes the underlying issue)

Migration is a UI translation, not a logic redesign.

### Sources

- [Gemini API Troubleshooting](https://ai.google.dev/gemini-api/docs/troubleshooting) — official
- [Gemini API Rate Limits](https://ai.google.dev/gemini-api/docs/rate-limits) — official
- [Gemini API Billing](https://ai.google.dev/gemini-api/docs/billing) — official
- [Gemini Safety Settings](https://ai.google.dev/gemini-api/docs/safety-settings) — official
- [Vertex AI Image Responsible AI](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/multimodal/gemini-image-responsible-ai) — Layer 2 details
- [Cloudinary Diagnosing Error Codes](https://cloudinary.com/documentation/diagnosing_error_codes_tutorial) — official
- [Cloudinary Upload API Reference](https://cloudinary.com/documentation/image_upload_api_reference) — official
- [Cloudinary Invalid Signature](https://support.cloudinary.com/hc/en-us/articles/10679615558802) — support note
- [Forum: Tier-1 billing stuck on free quotas](https://discuss.ai.google.dev/t/tier-1-billing-enabled-but-stuck-on-free-quotas/122337)
- [Forum: Prepayment credits depleted error](https://discuss.ai.google.dev/t/billing-mismatch-gemini-api-429-on-tier-1-prepay-while-cloud-billing-has-funds-but-ai-studio-shows-0-00/140828)
- [Nano Banana 2 IMAGE_SAFETY Fix](https://www.aifreeapi.com/en/posts/gemini-image-silent-failure-image-safety-fix)

## Cross-references

- **ADR-006** — AI: Claude Sonnet 4.6 + Haiku 4.5 + Nano Banana 2/Pro + GPT Image 2 fallback (model layer)
- **ADR-010** — Workflow: Trigger.dev v3 with waitpoints (durable orchestration commitment; this ADR is the implementation)
- **ADR-018** — Auth: phone-first WhatsApp OTP (customer-facing comms layer)
- **ADR-022** — Sprint 2 AI pipeline architecture (the in-process orchestration that this ADR supersedes for resilience)
- **ADR-024** — Bible-driven illustration pipeline (data + prompt layer; orthogonal to retry layer)
- **ADR-026** — Phase 1 character-fidelity verdict (model selection)
- **ADR-028** — Watercolor revert (brand register; orthogonal to retry layer)
- **`docs/session-notes/2026-05-10-face-fidelity-marathon.md`** — empirical evidence + iteration journey
- **`hadouta-backend/src/scripts/_iter7_full_book.ts`** — reference implementation for layers 1-3
