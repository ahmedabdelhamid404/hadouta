# ADR-021: Admin app architecture — separate repo, email/password auth, role gate

**Date:** 2026-05-03 (session 9, Sprint 2 first cycle)
**Status:** Accepted
**Supersedes / extends:** ADR-013 (active learning + manual approval gate), ADR-018 (phone-first OTP for customers)

## Context

Sprint 2 ships the manual review queue per ADR-013. The reviewer (Ahmed for first cycle, future hires later) needs an interface to:
- See all generations awaiting review, sorted by recency
- Open one, read 16 pages of Arabic story + 17 watercolor illustrations
- Approve (triggers PDF assembly + delivery) or Reject (with category + reason)
- Get notified the moment a new generation lands

The customer-facing app (`hadouta-web`) already exists with full Hadouta brand chrome (Tajawal/El Messiri/Aref Ruqaa fonts, watercolor palette, cream background, RTL Arabic). Two routing options for the admin surface:

**Option A — admin pages under `/admin/*` on `hadouta-web`:** Single deploy, single repo, shared auth, fastest to ship.

**Option B — separate `hadouta-admin` Next.js app on its own Vercel deploy:** Independent surface, independent deploy cadence, independent auth model, no risk of admin code leaking into customer bundle, neutral chrome.

## Decision

**Option B — separate repo `hadouta-admin` deployed to Vercel.**

- **GitHub:** github.com/ahmedabdelhamid404/hadouta-admin (private)
- **Vercel:** hadouta-admin.vercel.app
- **Stack:** Next.js 16 + Tailwind 4 + plain shadcn-style components (skipped shadcn CLI — interactive prompts blocked scripted setup; will add when CLI supports `--yes` for component-library selection)
- **Theme:** default neutral palette (Hadouta brand chrome explicitly NOT applied — admin tool is operational, not customer-facing)
- **Auth:** Better-Auth **email/password** (separate from customer phone-OTP; same backend, both providers enabled simultaneously)
- **Bootstrap:** super-admin seeded via `pnpm db:seed:admin` (defaults to `ahmed41997@gmail.com` / `A7med@hadouta`); future admins added via `must_change_password` invite flow with default password `1234` and forced change on first login
- **Role gate:** all admin endpoints under `/api/admin/*` use `requireAdmin` middleware that validates `session.user.role === 'admin'`
- **Live notifications:** Server-Sent Events stream at `/api/admin/events` — when the generation pipeline transitions to `awaiting_review`, an in-process pub/sub bus emits, the SSE handler forwards, the admin UI toasts + refreshes the queue without polling

## Consequences

**Wins:**
- Customer bundle stays lean; no admin-only React code shipped to paying customers
- Admin can be redeployed without touching customer site (and vice versa)
- Different auth UX is appropriate: customers want zero-friction phone OTP, admins want stable email/password
- Permanent separation matches the eventual operational model (admins are a small known team; customers are anonymous-by-default)

**Costs:**
- Three repos to maintain (umbrella, hadouta-backend, hadouta-web, hadouta-admin = four total)
- Cross-origin admin → backend cookies are non-trivial — see "Open issue" below
- Two auth flows on backend (phone-OTP plugin + email/password) — both work simultaneously but the config surface is wider
- Admin app's `/api/*` calls require either a Next.js Route Handler proxy or direct cross-origin calls (proxy chosen for first cycle; cross-origin slated for Sprint 3)

**Single role for now:** all invited admins get `role='admin'` (full review queue + approve/reject powers). When the reviewer team grows beyond Ahmed, splitting into `reviewer` / `admin` roles becomes worth the schema migration; not before.

## Open issue

`Better-Auth` rejects sign-in via the Vercel Route Handler proxy with `INVALID_ORIGIN` because Node's undici fetch auto-appends `Sec-Fetch-Mode: cors`, and Better-Auth's `validateFormCsrf` middleware treats Sec-Fetch-* + cookie-presence as mandating strict origin validation. Worked around for first cycle by setting `advanced.disableCSRFCheck: true` on the backend. Documented in `docs/session-notes/2026-05-03-sprint-2-cycle-day-1.md` under "Open issue".

**Sprint 3 follow-up:** re-enable CSRF check by switching admin to direct cross-origin calls to Railway with Better-Auth `cookies.session.attributes.sameSite: 'none'`. Drop the proxy Route Handler.

## Files

- `hadouta-admin/` — entire repo
- `hadouta-backend/src/middleware/require-admin.ts`
- `hadouta-backend/src/routes/admin-generations.ts`
- `hadouta-backend/src/routes/admin-events.ts`
- `hadouta-backend/src/lib/admin-events.ts`
- `hadouta-backend/src/scripts/seed-admin.ts`
- `hadouta-backend/src/db/migrations/0005_admin_must_change_password.sql`
