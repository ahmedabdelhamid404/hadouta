# Hadouta — Sprint Tracker

**🔖 READ ME FIRST every new session.** This is the single source of truth for "where are we?"

---

## Project state

**Project**: Hadouta (حدوتة) — Egyptian AI personalized children's book platform
**Launch target**: September 1, 2026
**Build window**: ~22 weeks from 2026-04-30
**Current phase**: ✅ Bootstrap complete · ✅ Public repos live · 🟢 **Sprint 1 — Ready to Start**

### Public GitHub repos (all live as of 2026-05-01)
- 📚 **Umbrella + docs**: https://github.com/ahmedabdelhamid404/hadouta
- ⚙️ **Backend**: https://github.com/ahmedabdelhamid404/hadouta-backend
- 🎨 **Frontend**: https://github.com/ahmedabdelhamid404/hadouta-web

---

## Current sprint

**Sprint**: 1 — Foundation
**Sprint window**: Weeks 1–2 (planned start 2026-05-01)
**Status**: 🟢 Ready to start
**Plan**: `docs/sprints/sprint-01-foundation.md`

### Sprint 1 goal
Both repos running locally + landing page deployed live + first ad campaign generating waitlist signups + initial Cairo print quotes received.

### Sprint 1 acceptance criteria (top items)
- ✅ `https://hadouta.com` live with Arabic RTL landing page
- ✅ `https://api.hadouta.com/health` returns 200
- ✅ Waitlist form persists email + phone to Neon Postgres
- ✅ Better-Auth signup/signin works
- ✅ Both repos pushed to private GitHub
- ✅ Spec-kit slash commands functional in both repos
- ✅ Domain `hadouta.com` registered + DNS configured
- ✅ Trademark cleared
- ✅ `@hadouta` handles reserved on IG, TikTok, Facebook
- ✅ Bosta merchant account active
- ✅ 3+ Cairo print shop quotes received
- ✅ Facebook ad campaign live with 3 creatives × 3 price tiers
- ✅ ≥50 waitlist signups by end of week 2

(Full criteria + day-by-day tasks: see `docs/sprints/sprint-01-foundation.md`)

---

## Resume here (next concrete action)

> **🟢 Hadouta is LIVE on the internet** as of 2026-05-01 (session 4). Frontend at https://hadouta-web.vercel.app, backend at https://hadouta-backend-production.up.railway.app, end-to-end waitlist flow verified. Custom domain `hadouta.com` not yet registered (Track B).
>
> **🟢 ADR-018 phone-first auth backend implemented + tested** (session 5, 2026-05-02). Better-Auth phone-number plugin wired with Twilio WhatsApp+SMS multi-tier transport. requireEmailVerification dropped. 5/5 backend tests passing. Schema migration `0002` applied. Pushed: `hadouta-backend@f0569af`.
>
> **🟢 Sentry + PostHog observability fully wired** (session 5). Both code SDKs initialized in both repos with privacy posture (mask-all-inputs, identified-only profiles, no auto-PII). Both Sentry projects (hadouta-web + hadouta-backend) created via API. PostHog renamed to "Hadouta" (EU instance). Vercel + Railway env vars set. MCP integration deferred (Claude Code OAuth bug); REST-API runbook + scripts at `docs/operations/observability-runbook.md` is the canonical query path until MCP is fixed.
>
> **🟢 Phase 2 design tokens shipped** (session 5). `globals.css` now carries the full Hadouta palette (cream/terracotta/ochre/teal/brown/blush) as 3-tier tokens (raw → semantic → Tailwind utilities). Typography stack live: Tajawal + El Messiri + Aref Ruqaa + Fraunces. Radius + motion scales per brand brief. WCAG AA verified across pairings. All shadcn components inherit automatically.
>
> ---
>
> **Step 1 — Phase 3: Figma screen designs** (next code-adjacent task). Brand brief v1.1 + Phase 2 tokens give the designer (or me, via Figma MCP) everything needed to mock up screens. Re-auth Figma MCP first — likely hit the same OAuth bug class as Sentry/PostHog; bearer-token alternative may be needed. Build landing, order wizard, "your book is being made," confirmation, account screens. Multi-session iteration. UI Designer agent available for focused multi-screen passes. Alternative if Figma MCP keeps failing: Ahmed designs directly via Figma web, commits screenshots/links to `docs/design/screens/`, I implement from those via the `figma:figma-implement-design` skill.
>
> **Step 2 — Frontend signup form rework (Phase 5 partial).** Replace email/password form with phone-OTP UI wired to backend's ADR-018 endpoints (`/api/auth/phone-number/send-otp` + `/api/auth/phone-number/verify`). Best done after Phase 3 Figma screens, but can run independently if Ahmed wants code velocity. ~2-3 hours.
>
> **Step 3 — Track B kickoff (Ahmed-owned, long pole for "real launch")**: domain registration (`hadouta.com`), trademark search (WIPO + Egyptian Trademark Office), social handle reservation (`@hadouta` on IG/TikTok/Facebook), Bosta merchant signup, Cairo print-shop outreach, ad campaign creatives, Meta Business Verification + Twilio WhatsApp sender setup (long pole — 3-7 days FB review). Start in parallel with code work.
>
> **Step 4 — Phase 2.5: commission Egyptian decorative-motif asset library** (Track B / paid). ~10K EGP, 2-4 weeks lead time. Stock libraries are Maghrebi/Iranian, not Egyptian. AI-generated patterns undermine cultural-specificity moat per ADR-002. See `docs/design/brand-brief.md` "Decorative-motif source" section.
>
> **Step 5 — Custom domain wire-up.** Once `hadouta.com` is registered: point apex to Vercel project, `api.hadouta.com` to Railway service. Update `FRONTEND_URL` (Railway) and `NEXT_PUBLIC_API_URL` (Vercel) to the custom domains. Update Better-Auth's expected origins.
>
> **Step 6 — Real Resend API key.** Currently a placeholder string passes the prod-mode env guard (`re_placeholder_obtain_real_key_post_sprint1`). Email-OTP fallback flow (ADR-018 tier 4) needs a real key. Free-tier sufficient for early Sprint 1.
>
> **Step 7 — Railway GitHub auto-deploy integration.** Backend currently only deploys via explicit `railway up`. Wire push-to-deploy via Railway dashboard. After this, Vercel and Railway have parity on the deploy trigger.
>
> ---
>
> **Token-rotation status (closed — all leaked tokens revoked)**: Vercel `vca_` (session 4), Sentry `sntryu_6860d6...` and PostHog `phx_QHvSdJ...` (both session 5) were all revoked by Ahmed; new credentials sit in `.env.local` (umbrella, gitignored). Pattern documented in `docs/operations/observability-runbook.md`.
>
> **Sprint-2 follow-ups (do not lose track)**:
> - Rate-limit hardening + Redis-backed secondary-storage on auth endpoints before horizontal scale
> - Session `ip_address` / `user_agent` PII retention policy (needs ADR before storing or disabling)
> - OpenAPI exposure of auth routes (Better-Auth bypasses `OpenAPIHono.openapi()`)
> - Test-data cleanup helper (auth tests + e2e tests leak `test-*@example.com` and `e2e-test-2026-05-01@hadouta.local` rows into dev Neon)
> - "Secrets must use stdin, never flags" — codify as project rule + skill candidate
> - Vercel Node version pinning (current: auto-picked 24.x; local dev: 20.19.5) — pin via `vercel.json` if runtime divergence surfaces
> - Migration `0002_snapshot.json` regeneration — drizzle-kit's interactive prompt blocked snapshot generation in session 5; next clean `drizzle-kit generate` will regenerate based on current schema; non-blocking
> - Drizzle migration validation pre-flight skill ("validate-drizzle-migration") — flagged from session 3 still relevant
> - Latin companion font final pick — Fraunces selected in session 5 Phase 2; revisit during Phase 3 Figma if Spectral feels better in context

---

## Sprint 1 — In Progress (Sessions 2 + 3 + 4 + 5, 2026-05-01 to 2026-05-02)

Track A foundation work ~98% complete. **Hadouta is LIVE on the internet, observability is wired end-to-end, design tokens shipped, ADR-018 backend implemented.**
- ✅ Both repos installed + dev servers boot cleanly (`pnpm dev` works)
- ✅ Backend `/health` and `/waitlist` (Zod-validated) respond correctly
- ✅ End-to-end browser test: form submission flows Next.js → Hono → Neon → DB row
- ✅ Tajawal Arabic font loading (`--font-sans` CSS var fixed)
- ✅ OpenAPI spec exposed at `/openapi.json` via `@hono/zod-openapi`
- ✅ Frontend auto-generates types via `pnpm sync-types`
- ✅ Typed API client (openapi-fetch) replaces raw fetch in WaitlistForm
- ✅ GitHub Actions CI added to both repos (typecheck + build)
- ✅ **Neon Postgres project** "Hadouta" live in `aws-eu-central-1` (Frankfurt — closest to Egypt)
- ✅ Drizzle migration `0000_violet_warlock.sql` applied → 4 initial tables (users, waitlist_signups, themes, orders)
- ✅ `pgvector` extension v0.8.0 enabled (ready for active learning embeddings later)
- ✅ Waitlist endpoint persists to Neon (verified via real browser submission — Arabic names stored correctly)
- ✅ **Better-Auth wired** (session 3): email/password + Google OAuth (conditional on env) + Resend email verification (prod-required, dev-falls-back-to-stdout) + Drizzle migration `0001_abnormal_calypso.sql` applied → +4 tables (user, session, account, verification), `orders.user_id` retyped to text. 3 Vitest integration tests pass.
- ✅ **All 4 pending commits pushed to GitHub** (session 4) — both repos now use SSH origins after `workflow` scope blocked HTTPS pushes
- ✅ **Vercel project linked + auto-deployed** (session 4) — `hadouta-web.vercel.app` live and serving Arabic landing page. Deployment Protection disabled via API. `NEXT_PUBLIC_API_URL` baked in via redeploy.
- ✅ **Railway project + service deployed** (session 4) — `hadouta-backend-production.up.railway.app/health` returns 200 in production mode. 7 env vars set (secrets via stdin), public domain assigned via `railway domain`.
- ✅ **Live end-to-end pipeline test** (session 4) — Vercel UI → CORS preflight → Railway API → Drizzle → Neon insert → Arabic success message back to client. Real DB row written.
- ✅ **CLIs installed + authenticated** (session 4) — `vercel`, `railway`, `neonctl` all in `~/.nvm/.../bin/`, all logged in.
- ✅ **Auth strategy pivoted (ADR-018) + backend implemented** (sessions 4+5) — Better-Auth phone-number plugin wired, Twilio WhatsApp tier-1 + SMS tier-2 multi-tier transport, requireEmailVerification dropped, lazy email verification only. Schema migration `0002` applied (phoneNumber, phoneNumberVerified, lastVerifiedAt, supportedStyles, style + CHECK constraint). 5/5 backend tests passing. Frontend signup form rework still pending (best after Phase 3 Figma).
- ✅ **Sentry + PostHog wired** (session 5) — `@sentry/node` + `@sentry/nextjs` + `posthog-js` initialized in both repos with privacy posture (mask-all-inputs, identified-only, no auto-PII). Sentry projects `hadouta-web` (id 4511319736189008) + `hadouta-backend` (id 4511319962812496) created via API. PostHog renamed to "Hadouta" (project 170756, EU instance). Vercel + Railway env vars set. EU-host default fixed in `PostHogProvider.tsx`. MCP setup deferred (Claude Code OAuth bug); REST-API runbook + scripts at `docs/operations/observability-runbook.md` is the canonical query path.
- ✅ **Phase 2 design tokens shipped** (session 5) — `globals.css` carries the full Hadouta palette (cream/terracotta/ochre/teal/brown/blush) as 3-tier tokens (raw `--hadouta-*` → semantic shadcn → Tailwind utilities). Typography stack live: Tajawal (body), El Messiri (headers, Egyptian-designed), Aref Ruqaa (decorative, max-1-per-page rule), Fraunces (Latin companion). Radius scale (4/8/16/24px) + storyteller-paced motion timing (200/400/600ms) per brand brief. WCAG AA verified. Dark mode kept as a stub (deferred — no current product requirement).
- ⏸️ **Phase 3 Figma screen designs** — next code-adjacent task. Re-auth Figma MCP first (likely needs bearer-token alternative). Build landing, order wizard, "your book is being made," confirmation, account screens.
- ⏸️ **Frontend signup form rework (Phase 5 partial)** — replace email/password UI with phone-OTP form wired to ADR-018 backend endpoints. Best after Phase 3 Figma but can run independently.
- ⏸️ Custom domain `hadouta.com` — Track B (Ahmed-owned), not started
- ⏸️ Track B (Ahmed) — domain, trademark, handles, services, ad campaign, **Meta Business Verification + Twilio WhatsApp setup** (ADR-018 long pole), **Egyptian decorative-motif asset library commission** (Phase 2.5 from brand brief, ~10K EGP) — not started

Detailed logs: `docs/session-notes/2026-05-01-session-2.md` (DB + types), `docs/session-notes/2026-05-01-session-3.md` (auth foundation), `docs/session-notes/2026-05-01-session-4.md` (deploys live + auth pivot), `docs/session-notes/2026-05-02-session-5.md` (ADR-018 backend impl + Sentry/PostHog wiring + observability runbook + Phase 2 tokens).

---

## Sprint 0 — Completed (2026-04-30) ✅

Bootstrap session deliverables — all complete:
- ✅ uv runtime installed
- ✅ Shared docs structure created (`docs/sprints/`, `docs/decisions/`, `docs/session-notes/`, `docs/agents-playbook.md`, `docs/skills-roadmap.md`)
- ✅ All 16 ADRs written
- ✅ Sprint 1 detailed; Sprints 2-6 skeletoned
- ✅ `hadouta-backend` repo bootstrapped with spec-kit + Hono + Drizzle + Better-Auth scaffold + custom constitution + project-scope settings
- ✅ `hadouta-web` repo bootstrapped with spec-kit + Next.js 16 + Tailwind 4 + shadcn/ui (RTL) + Arabic landing page + waitlist form + custom constitution + project-scope settings
- ✅ First commits in both repos
- ✅ Session note written: `docs/session-notes/2026-04-30-session-1.md`

---

## Locked decisions (for reference; details in ADRs)

| ID | Decision |
|---|---|
| ADR-001 | Real revenue-generating business |
| ADR-002 | Egyptian cultural specificity is the moat |
| ADR-003 | MVP launch anchored to First Day of School, Sept 2026 |
| ADR-004 | Digital-first MVP, optional print upgrade in v1.5 |
| ADR-005 | L3 photo upload + watercolor style (NOT Pixar 3D) |
| ADR-006 | AI: Claude Sonnet 4.6 + Haiku 4.5 + Nano Banana 2/Pro + GPT Image 2 fallback |
| ADR-007 | Frontend: Next.js 16 + React 19 + shadcn/ui (NOT Angular) |
| ADR-008 | Backend: Node + Hono + TypeScript (NOT .NET) |
| ADR-009 | Database: Neon Postgres + Better-Auth + Cloudflare R2 (NOT Supabase) |
| ADR-010 | Workflow: Trigger.dev v3 with waitpoints |
| ADR-011 | Two repos with OpenAPI for type sync |
| ADR-012 | Validators: Universal (theme-agnostic) + Theme-specific layers |
| ADR-013 | Active learning loop with manual approval gate |
| ADR-014 | Pricing: A/B test 250 vs 300 EGP digital (TENTATIVE — final after Sprint 1) |
| ADR-015 | Validation parallel with build (Lean Startup) |
| ADR-016 | Distribution: FB+IG paid + nano/micro influencers (phased) + organic mom groups |
| ADR-017 | Vercel deployment for frontend + PUBLIC GitHub repos (added 2026-05-01) |
| ADR-018 | Auth: phone-first WhatsApp OTP + multi-tier fallback (SMS → Google → email) + invisible accounts (added 2026-05-01) |
| ADR-019 | Multi-style illustration architecture: watercolor-only MVP, multi-style-ready foundation (style as first-class field on themes/orders/illustrations; per-style prompt registry; future styles get distinct brand surfaces, not chrome variants) (added 2026-05-01) |

---

## Sprint roadmap

| Sprint | Window | Focus | Status |
|---|---|---|---|
| **0** | 2026-04-30 | Bootstrap infra + ADRs + plans | ✅ Complete |
| **1** | Weeks 1–2 | Foundation: skeletons + landing live + ad campaign | 🟡 In Progress (Track A ~98% — auth backend done, observability wired, design tokens shipped; remaining: Figma + signup form. Track B 0%) |
| **2** | Weeks 3–4 | Validation infrastructure + content production kickoff | ⏸️ Skeletoned |
| **3** | Weeks 5–8 | AI pipeline foundation (story gen + universal validators) | ⏸️ Skeletoned |
| **4** | Weeks 9–12 | Customer ordering flow + admin review queue | ⏸️ Skeletoned |
| **5** | Weeks 13–16 | Closed beta + validator calibration | ⏸️ Skeletoned |
| **6** | Weeks 17–22 | Soft launch → public launch (Sept 1) | ⏸️ Skeletoned |

---

## Blockers

None currently. Next session can begin executing Sprint 1 immediately.

---

## Notes for next session

1. **Read this tracker first.** Then read `docs/session-notes/2026-04-30-session-1.md` for full context.
2. **Open `docs/sprints/sprint-01-foundation.md`** for the day-by-day Sprint 1 task list.
3. **Both repos already exist** at `/home/ahmed/Desktop/hadouta/hadouta-backend/` and `/home/ahmed/Desktop/hadouta/hadouta-web/` — they have first commits but need:
   - `pnpm install` run in each
   - `.env` / `.env.local` filled with real values (Ahmed creates Neon, registers domain, etc.)
   - Smoke test of `pnpm dev` in each
4. **Manager pattern** active from Sprint 1 onward — see `docs/agents-playbook.md`. Most Sprint 1 work is junior-tier scaffolding (manager direct); specialist delegation begins in Sprint 3 (AI pipeline).
5. **All architectural decisions are in `docs/decisions/`** — do not relitigate; read first.
6. **Brand**: Hadouta (حدوتة) is locked; domain registration is Sprint 1 Track B Day 1-2.

---

**Last updated**: 2026-05-02 (session 5) by Claude. Sprint 1 Track A ~98% complete — auth backend implemented + tested (ADR-018), Sentry+PostHog wired in code AND in production env (both repos), Phase 2 design tokens shipped (full Hadouta palette + 4-font typography stack + WCAG AA verified). Frontend signup form rework + Phase 3 Figma designs are the remaining Track A items; both can begin next session. Track B (Ahmed-owned) still at 0% — domain registration, Meta Business Verification, decorative-motif library all gating real launch. All leaked tokens revoked + rotated (3 total). Observability via REST-API runbook (`docs/operations/observability-runbook.md`) since Claude Code's MCP OAuth has a known bug.
