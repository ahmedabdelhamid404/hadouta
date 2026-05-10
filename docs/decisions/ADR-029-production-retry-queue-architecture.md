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

**Layer 1 — Per-call retry-with-backoff** (in `illustration-generator.ts`):
```
retry on: 503, 429, 500, network timeout
bail on:  400, 401, 403 (permanent errors)
backoff:  10s, 30s, 60s, 120s, then 5min repeating
max:      effectively unlimited within a single illustration call
```

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
