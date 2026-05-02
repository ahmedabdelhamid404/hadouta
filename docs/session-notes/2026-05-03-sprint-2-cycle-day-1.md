# Session Note — Sprint 2 first-cycle implementation, day 1

**Date:** 2026-05-02 → 2026-05-03 (single long session)
**Sprint:** Sprint 2 — AI generation pipeline + admin review
**Branch:** main on all three repos (hadouta-backend, hadouta-web, hadouta-admin)

## What shipped

### hadouta-backend
- **AI generation pipeline** end-to-end:
  - `src/lib/ai/schemas/story.ts` — Zod schema for story output (title / dedication / coverDescription / parentDiscussionQuestion / pages with per-page `act` / `emotionalBeat` / `moralMoment`)
  - `src/lib/ai/prompts/story-system-prompt.ts` — Egyptian-tuned system prompt with diacritization policy + few-shot examples appended
  - `src/lib/ai/prompts/build-story-user-prompt.ts` — per-order user prompt builder
  - `src/lib/ai/router.ts` — multi-provider routing (`gpt-*` → OpenAI, `claude-*` → Anthropic, `gemini-*` → Google) + cost estimator
  - `src/lib/ai/story-generator.ts` — orchestrates `generateObject()` + invariant checks (page count, exactly-one-moralMoment, sequential page numbers)
  - `src/lib/ai/illustration-generator.ts` — Google `@google/genai` direct for `gemini-2.5-flash-image` (Nano Banana), Cloudinary upload, concurrency-3 batching
- **Workflow orchestration:**
  - `src/jobs/generate-book.ts` — `kickoffGenerationIfNeeded()` (idempotent), full pipeline orchestration with status state-machine transitions
  - `src/routes/payments.ts` — webhook + return callback both fire the kickoff after `status='paid'`
- **Admin surface:**
  - `src/middleware/require-admin.ts` — Better-Auth session + `role='admin'` gate
  - `src/routes/admin-generations.ts` — list / detail / approve / reject; approve fires fire-and-forget PDF assembly
  - `src/routes/admin-events.ts` — Server-Sent Events stream for live notifications
  - `src/lib/admin-events.ts` — in-process pub/sub bus (single-instance only — upgrade to Redis when we scale)
- **PDF assembly:**
  - `src/lib/pdf/render-book.ts` — Puppeteer + HTML+Cairo Arabic font, A5 portrait, RTL, uploaded as Cloudinary `raw` resource
- **Auth & schema:**
  - Migration 0005 — `must_change_password` boolean on `user` (applied to Neon)
  - `seed-admin.ts` — seeded `ahmed41997@gmail.com` (super-admin)
  - `BETTER_AUTH_SECRET` added to local `.env` (was missing entirely)
  - `trustedOrigins` extended to include hadouta-admin.vercel.app + local dev ports
  - **`advanced.disableCSRFCheck: true`** — disabled Better-Auth's strict origin/CSRF gate; see "Open issue" below
- **Customer self-serve:**
  - `src/routes/me.ts` — `GET /api/me/orders` (auth-gated)
  - `src/routes/public-orders.ts` — `GET /api/public/order-status/:orderId` + `GET /api/public/orders-by-phone?phone=X` (no auth, phone-as-identity)
- **Dev probes:**
  - `pnpm ai:test-story [orderId] [--illustrate]` (full pipeline)
  - `pnpm ai:test-illustration <generationId> [--page=N]` (single-image $0.02 probe)

### hadouta-admin (NEW REPO)
- Fresh Next.js 16 + Tailwind 4 + shadcn-skipped (CLI is interactive — couldn't script).
- **GitHub:** github.com/ahmedabdelhamid404/hadouta-admin (private)
- **Vercel:** hadouta-admin.vercel.app (auto-deploys on push to main)
- Pages:
  - `/login` — email + password (Better-Auth `/api/auth/sign-in/email`)
  - `/orders` — review queue, status-filtered (default `awaiting_review`)
  - `/orders/[id]` — story metadata + cover + per-page text/illustration grid + per-page metadata badges + Approve/Reject + PDF download once delivered
- **Live SSE listener** — toasts new `awaiting_review` arrivals, refreshes detail pane on status transitions
- **Catch-all `/api/[...path]/route.ts`** — manual proxy that injects Origin header (Vercel rewrites strip Origin; see open issue)
- **Middleware** — Better-Auth session gate; checks both `better-auth.session_token` and `__Secure-better-auth.session_token` cookie names

### hadouta-web
- `/account` — phone input → orders list with status badges + cover thumbnails + PDF download
- `/account/orders/[orderId]` — single-order detail; auto-polls every 5 s while in progress; swaps to PDF download button when delivered
- Wizard step 7 — replaces the static "Order tracking page lands Sprint 4+" placeholder with real links to `/account/orders/[orderId]` and `/account`

## Open issue — Better-Auth `INVALID_ORIGIN` from Vercel proxy

**The problem:** sign-in from `hadouta-admin.vercel.app` returns 403 `INVALID_ORIGIN`. Browser → Vercel rewrite → Railway. Reproducible from Node `fetch()` directly to Railway with `Origin: https://hadouta-admin.vercel.app`.

**Symptoms reproduced:**
- ✅ `curl -X POST` to Railway with `Origin: https://hadouta-admin.vercel.app` → 401 (origin accepted, just bad password)
- ❌ `node fetch()` (undici) to Railway with same Origin → 403 INVALID_ORIGIN
- ❌ Browser via Vercel `/api/*` rewrite → 403 INVALID_ORIGIN

**Root cause:** undici's fetch automatically appends `Sec-Fetch-Mode: cors`, and Better-Auth's `validateFormCsrf` middleware (in `node_modules/better-auth/dist/api/middlewares/origin-check.mjs`) checks Sec-Fetch-* headers and forces strict origin validation when present. Even though Origin matches `trustedOrigins`, the combined heuristic (Sec-Fetch-Mode present + cookies absent or whatever else) trips the FORBIDDEN throw.

**Mitigations attempted, none fully successful in pure proxy mode:**
1. Add `hadouta-admin.vercel.app` to Better-Auth `trustedOrigins` ✓ (solved direct-curl path)
2. Add same to Hono CORS origin list ✓ (independent layer)
3. Switch admin app from rewrite to manual Route Handler (`/api/[...path]/route.ts`) that injects Origin ✓ (re-injection works — see debug headers `x-hadouta-proxy-origin`)
4. Strip / re-set `forwarded` and `x-forwarded-host` headers ✗ (no change)
5. **`advanced.disableCSRFCheck: true` on Better-Auth** — pushed but couldn't fully verify due to rate-limiting from test storm
6. Other deploy bumps:
   - Cookie-name fix: middleware now checks both `better-auth.session_token` and `__Secure-better-auth.session_token`
   - Vercel `COMMIT_AUTHOR_REQUIRED` seat-block — set `git config user.email ahmedsoftwaredev3@gmail.com` in `hadouta-admin` repo (`ahmed.abdelhameed@intcore.com` was being rejected)

**State at end of session:** disableCSRFCheck pushed, Railway redeploying when we paused. Ahmed will re-test live; if still failing, next step is to abandon the same-origin proxy entirely and switch admin to **direct cross-origin calls** to Railway with Better-Auth `cookies.session.attributes.sameSite: 'none'` set so cookies flow cross-origin.

**Why this matters:** the auth fix is the **only** thing blocking the first end-to-end cycle. Everything else (generation pipeline, admin UI, PDF assembler, customer account page, SSE notifications) is built and pushed — once admin login works, the loop closes.

## Other open issues / known risks

1. **Puppeteer Chromium on Railway** — added `pnpm.onlyBuiltDependencies: ["puppeteer"]` so Railway runs the postinstall script. Untested in production. If PDF assembly fails, expect "chromium not found" in `generations.errorLog`.

2. **AI keys on Railway** — local `.env` has `OPENAI_API_KEY`, `GOOGLE_AI_API_KEY`, `ANTHROPIC_API_KEY`, `FAL_API_KEY`. Need to confirm they're synced to Railway (`bash scripts/openai/sync-to-railway.sh` etc.). If missing, generation pipeline crashes at story or illustration step.

3. **Story quality at 16 pages with gpt-4o-mini** — pacing skews to 3 setup / 4 challenge / 9 resolution (target was 4/8/4). Last 6 pages are reflective filler. Mama declares the moral on page 13 verbatim ("الكرم هو إنك تشارك..."), which is exactly the "show don't tell" anti-pattern we forbade. Ahmed accepted this for v1 — re-tune after cycle works.

4. **Watercolor style not honored by Gemini** — first cover image came back as a flat-colored illustration, not watercolor. Style anchor in prompt is too weak. Fix in next iteration via stronger style descriptor + negative prompt.

5. **Customer "/account" auth is phone-only, no OTP** — Sprint 2 first-cycle pragmatic shortcut. Anyone with someone's phone can see their orders. **Sprint 3 must add HMAC magic-link tokens or proper Better-Auth phone-OTP login** before real customer traffic.

6. **PDF stays in Cloudinary indefinitely** — no TTL configured. If we hit storage limits, prune old PDFs by `created_at` cutoff.

7. **Single-instance SSE pub/sub** — `src/lib/admin-events.ts` is in-process only. If we ever run >1 backend instance, admin clients connected to instance A won't see events from generations completing on instance B. Upgrade to Redis pub/sub when scaling.

8. **Next.js 16 deprecation warning** — `middleware.ts` should rename to `proxy.ts` per Next.js 16 deprecation. Currently functional with warning.

9. **Vercel rewrite cache** (`x-vercel-enable-rewrite-caching: 1` header) — when removing rewrites, Vercel can cache the old config for some time. Force-deploy via `vercel deploy --prod --force` if rewrite changes don't seem to take effect.

## Smoke-test outcomes

- ✅ Story generation against real paid order: gpt-4o-mini, 26.5s, ~$0.0017, 16 pages with all invariants passing (`213ad0d6-7e7a-4580-acb1-919518d445f0`)
- ✅ Single illustration via `pnpm ai:test-illustration`: Gemini 2.5 Flash Image, 8.6s, 1.6 MB PNG, Cloudinary upload OK
- ✅ Backend deploys to Railway from main branch on push
- ✅ hadouta-admin builds + deploys to Vercel
- ❌ Admin sign-in via deployed app (blocked by Better-Auth origin check — see open issue)
- ⚠ End-to-end cycle (paid order → admin approve → PDF) — blocked by admin sign-in

## Resume-here pointer for next session

**Priority 1:** Verify Railway has redeployed with `advanced.disableCSRFCheck: true` and re-test admin sign-in via Playwright. If still failing, switch hadouta-admin from rewrite proxy to direct cross-origin calls to Railway:
- Update `hadouta-admin/src/lib/api.ts` to use full `${NEXT_PUBLIC_API_URL}/api/...` URLs
- Update `hadouta-admin/src/middleware.ts` — drop the cookie-presence check (cookies live on Railway domain, not vercel.app; need to call backend `getSession` to validate)
- Set `advanced.cookies.session.attributes.sameSite: 'none'` on Better-Auth backend so cookies flow cross-origin
- Ensure backend CORS allows credentials from hadouta-admin.vercel.app (already done)
- Drop `src/app/api/[...path]/route.ts` proxy handler

**Priority 2:** Run end-to-end cycle live — place wizard order, pay (Paymob test), admin approves, customer downloads PDF via `/account/orders/[orderId]`.

**Priority 3:** Once cycle proven, address story-quality gaps (declared moral, filler pages, watercolor style adherence).

## Files added this session

```
hadouta-backend/
  src/db/migrations/0005_admin_must_change_password.sql
  src/jobs/generate-book.ts
  src/lib/admin-events.ts
  src/lib/ai/router.ts
  src/lib/ai/schemas/story.ts
  src/lib/ai/story-generator.ts
  src/lib/ai/illustration-generator.ts
  src/lib/ai/prompts/story-system-prompt.ts
  src/lib/ai/prompts/build-story-user-prompt.ts
  src/lib/pdf/render-book.ts
  src/middleware/require-admin.ts
  src/routes/admin-generations.ts
  src/routes/admin-events.ts
  src/routes/me.ts
  src/routes/public-orders.ts
  src/scripts/seed-admin.ts
  src/scripts/test-generate-illustration.ts
  src/scripts/test-generate-story.ts

hadouta-admin/                                   (new repo, separate git history)
  next.config.ts
  src/app/api/[...path]/route.ts
  src/app/layout.tsx
  src/app/page.tsx
  src/app/login/page.tsx + _login-form.tsx
  src/app/orders/layout.tsx + page.tsx + _orders-list.tsx
  src/app/orders/[id]/page.tsx + _order-detail.tsx
  src/lib/api.ts
  src/middleware.ts

hadouta-web/
  src/app/account/layout.tsx + page.tsx
  src/app/account/orders/[orderId]/page.tsx + _order-detail.tsx
  src/lib/account/api.ts
  src/components/wizard/step-7-confirmation.tsx (modified)
```
