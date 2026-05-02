# Session 10 resume checklist — start here

**Read this FIRST before doing anything else.** Companion to `2026-05-03-sprint-2-cycle-day-1.md` (the long-form session note).

## TL;DR — where Sprint 2 stopped

✅ Built end-to-end:
- AI generation pipeline (story + 17 illustrations + ai_settings cost knobs)
- Paymob webhook auto-triggers generation
- hadouta-admin separate Next.js app, deployed to Vercel
- Admin endpoints + role gate + live SSE notifications
- Puppeteer Arabic-shaping PDF assembly + Cloudinary upload
- Customer `/account` + `/account/orders/[id]` with PDF download
- Wizard step 7 → links to account

❌ Blocked: **admin sign-in via deployed app returns 403 INVALID_ORIGIN**.
Mitigation pushed (`advanced.disableCSRFCheck: true` on Better-Auth backend); needs verification.

## Step 1 — Verify the auth mitigation landed

```bash
# Wait until Better-Auth's rate-limit window resets (~10 min after session 9 end)
# then test:
curl -s -m 15 -X POST https://hadouta-backend-production.up.railway.app/api/auth/sign-in/email \
  -H "Origin: https://hadouta-admin.vercel.app" \
  -H "Sec-Fetch-Mode: cors" \
  -H "Content-Type: application/json" \
  -d '{"email":"ahmed41997@gmail.com","password":"WRONG"}' \
  -w "\nHTTP: %{http_code}\n"
```

**Expected if mitigation worked:** HTTP 401 + `INVALID_EMAIL_OR_PASSWORD` (origin gate cleared, just bad password).
**Expected if NOT worked:** HTTP 403 + `INVALID_ORIGIN`.

If 401: skip to Step 3.
If 403: do Step 2 (Plan B).

## Step 2 — Plan B if mitigation didn't take

Switch admin app from Vercel-proxy pattern to direct cross-origin calls. Files to change:

1. **`hadouta-admin/src/lib/api.ts`** — change all calls from relative `/api/*` to full `${process.env.NEXT_PUBLIC_API_URL}/api/*`. Keep `credentials: 'include'`.
2. **`hadouta-admin/src/middleware.ts`** — drop the cookie-presence check (cookies live on Railway domain, not vercel.app); replace with a server-side `auth.api.getSession({ headers })` call OR remove middleware and rely on per-page client-side auth.
3. **`hadouta-admin/next.config.ts`** — already empty after Sprint 2; no change.
4. **`hadouta-admin/src/app/api/[...path]/route.ts`** — DELETE this proxy handler.
5. **`hadouta-backend/src/auth/index.ts`** — add `advanced.cookies.session.attributes.sameSite: 'none'` so cookies flow cross-origin. Re-enable CSRF check (`advanced.disableCSRFCheck` removed).
6. **`hadouta-backend/src/server.ts`** — confirm CORS allows credentials from `https://hadouta-admin.vercel.app` (already done in session 9).

Then push both repos. Test login again.

## Step 3 — Run the end-to-end cycle live

Once admin sign-in works:

1. **Place an order:** `https://hadouta-web.vercel.app` → wizard 1-7. Use Paymob test card (any of: `5123 4567 8901 2346`, exp `12/25`, CVV `100`).
2. **Wait ~3-5 min** while pipeline runs. Verify on Railway logs:
   - `[payments] generation kickoff: orderId=... reason=started`
   - `[jobs/generate-book] story done: 16 pages, ~26000ms`
   - `[jobs/generate-book] illustrations done: 17 images, ~150000ms`
   - `[jobs/generate-book] generation=... → awaiting_review`
3. **Sign in to admin:** `https://hadouta-admin.vercel.app/login` → `ahmed41997@gmail.com` / `A7med@hadouta`
4. **Verify SSE toast:** if you're already on `/orders` when generation finishes, expect a top-right toast "🔔 New review ready: [child name]". The queue auto-refreshes.
5. **Open the order detail.** Read 16 pages of Arabic story. Scan all 17 illustrations + per-page metadata badges (act, emotionalBeat, ⭐ moralMoment).
6. **Click ✓ Approve.** Status flips to `assembling_pdf`. PDF assembles in ~10-15 s. Status flips to `delivered` (SSE pushes the change). "Open PDF ↗" button appears.
7. **Customer download:** `https://hadouta-web.vercel.app/account/orders/[orderId]` → click "حمّل الكتاب (PDF)". Downloads from Cloudinary.

## Pre-cycle pre-flight checks

These could silently break the cycle if not verified:

### AI keys on Railway

Required: `OPENAI_API_KEY` (story) + `GOOGLE_AI_API_KEY` (illustrations). Optional: `ANTHROPIC_API_KEY` + `FAL_API_KEY`.

```bash
cd /home/ahmed/Desktop/hadouta
railway variables -s hadouta-backend 2>&1 | grep -E "OPENAI|GOOGLE_AI"
```

If empty, sync from local:
```bash
bash scripts/openai/sync-to-railway.sh
bash scripts/google-ai/sync-to-railway.sh
```

### Puppeteer Chromium on Railway

The package.json has `pnpm.onlyBuiltDependencies: ["puppeteer"]` which should make Railway run puppeteer's postinstall (downloads Chromium). If approving an order results in `status='failed'` with `errorLog: ".*chromium.*not.*found"`:
- Switch to `@sparticuz/chromium` (lighter, ~50 MB serverless build)
- Or set `PUPPETEER_EXECUTABLE_PATH` env var on Railway pointing at a system Chrome install

### `BETTER_AUTH_SECRET` on Railway

Already set in Railway from before (otherwise backend wouldn't be running). Just don't overwrite by accident.

### Cloudinary

Already configured (free tier, no card). `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` set on Railway. No action.

### Paymob

Already configured (test mode). HMAC verification logs warning but doesn't reject in dev. No action for first cycle; harden in Sprint 3.

## State snapshots

### Existing orders + generations in dev DB (use for re-runs)

Last successful run from session 9:
- Order: `382a13c0-a16d-4513-8008-d93be83f3201` (child=نوح, age=3-5, theme=Eid, moral=Generosity)
- Generation: `213ad0d6-7e7a-4580-acb1-919518d445f0` (status=story_done, 16 pages, gpt-4o-mini, ~$0.0017)
- Cover image: https://res.cloudinary.com/dvewybhzv/image/upload/v1777756450/hadouta/orders/382a13c0-a16d-4513-8008-d93be83f3201/illustration_cover/ev6hzjmvqqeuoxphyx0h.png

To re-illustrate without rerunning story: `pnpm ai:test-illustration <generationId> [--page=N]` (single image, ~$0.02).

### Local env files

- `hadouta-backend/.env` has all the keys including `BETTER_AUTH_SECRET` (added session 9 — was missing)
- `hadouta-admin/.git/config` has `user.email = ahmedsoftwaredev3@gmail.com` (set session 9 — Vercel rejected commits authored as `ahmed.abdelhameed@intcore.com` due to seat-block)

## Known issues / debt (also captured in tracker + ADRs)

1. **`disableCSRFCheck: true`** on Better-Auth — temporary mitigation. Sprint 3 proper fix is documented above.
2. **Story content drift** on gpt-4o-mini — declares moral verbatim ("الكرم هو..."), pads resolution pages. Either upgrade dev model to Claude Haiku 4.5 OR strengthen anti-pattern examples in system prompt.
3. **Watercolor not honored** by Gemini 2.5 Flash Image — output is realistic-painted, not watercolor. Need stronger style anchor + negative prompts.
4. **`/api/public/order-status/:orderId` is unauthenticated** — anyone with an orderId can see the order. Sprint 3 must add HMAC magic-link tokens.
5. **Single-instance SSE pub/sub** in `lib/admin-events.ts` — works for 1 backend instance; needs Redis upgrade when scaling.
6. **Next.js 16 `middleware` deprecation** — should rename to `proxy.ts` (warning at build).
7. **WhatsApp delivery not built** — explicitly skipped Sprint 2 (Twilio + Meta template approval take 24-48h). For first cycle, customer downloads PDF from `/account` page directly.

## Documentation locations (everything you might need)

| What | Where |
|---|---|
| This checklist | `docs/session-notes/2026-05-03-RESUME-CHECKLIST.md` |
| Long-form session note | `docs/session-notes/2026-05-03-sprint-2-cycle-day-1.md` |
| Sprint tracker | `docs/sprints/sprint-tracker.md` |
| Sprint 2 implementation plan (original — now mostly complete) | `docs/design/specs/2026-05-02-sprint-2-implementation-plan.md` |
| Admin architecture decision | `docs/decisions/ADR-021-admin-app-architecture.md` |
| AI pipeline architecture decision | `docs/decisions/ADR-022-sprint-2-ai-pipeline-architecture.md` |
| AI-only generation strategic pivot | `docs/decisions/ADR-020-ai-only-generation-human-review-only.md` |
| Better-Auth phone-OTP for customers | `docs/decisions/ADR-018-phone-first-whatsapp-otp-auth.md` |
| Story system prompt + few-shot policy | `hadouta-backend/src/lib/ai/prompts/story-examples/README.md` |

## Repo / deploy URL cheat sheet

| Component | URL |
|---|---|
| Umbrella repo | github.com/ahmedabdelhamid404/hadouta (public) |
| Backend repo | github.com/ahmedabdelhamid404/hadouta-backend (public) |
| Customer web repo | github.com/ahmedabdelhamid404/hadouta-web (public) |
| **Admin repo (NEW session 9)** | github.com/ahmedabdelhamid404/hadouta-admin (private) |
| Customer site | https://hadouta-web.vercel.app |
| Admin site | https://hadouta-admin.vercel.app |
| Backend API | https://hadouta-backend-production.up.railway.app |

## Identity mapping (recurring gotcha — kept here so it stops surprising future-you)

| Service | Account |
|---|---|
| GitHub | `ahmedabdelhamid404` |
| Vercel | `ahmedmohamedabdelhamed` (team `ahmedmohamedabdelhameds-projects`) |
| Railway / Neon | `ahmedsoftwaredev3@gmail.com` |
| Better-Auth super-admin | `ahmed41997@gmail.com` / `A7med@hadouta` |
| Vercel commits gate | requires git author email = `ahmedsoftwaredev3@gmail.com` (set per-repo in `.git/config`) |

## Most recent commits at session-9 end

| Repo | Last commit | Purpose |
|---|---|---|
| umbrella | `417ecef` | docs(sprint): close out session 9 — Sprint 2 status + ADR-021/022 |
| hadouta-backend | `99712a5` | feat(public-orders): public order-status endpoints for /account page |
| hadouta-web | `f44f00f` | feat(account): customer order-status page with PDF download |
| hadouta-admin | `3a299ba` | fix(api): also force forwarded + x-forwarded-host headers (debug headers still present in [...path]/route.ts) |

## Cleanup before Sprint 3

The hadouta-admin proxy handler `src/app/api/[...path]/route.ts` has DEBUG response headers (`x-hadouta-proxy-origin`, `x-hadouta-proxy-target`) added during the INVALID_ORIGIN diagnosis. Remove them once the auth issue is resolved:

```ts
// remove these 3 lines from the response:
responseHeaders.set("x-hadouta-proxy-origin", headers.get("origin") ?? "");
responseHeaders.set("x-hadouta-proxy-target", target);
```

If pivoting to Plan B (direct cross-origin), the entire file gets deleted instead.
