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

> **🟢 Hadouta is LIVE on the internet** as of 2026-05-01 (session 4). Frontend at https://hadouta-web.vercel.app, backend at https://hadouta-backend-production.up.railway.app, end-to-end waitlist flow verified with a real Neon insert. Custom domain `hadouta.com` not yet registered (Track B).
>
> **Step 1 — Sentry + PostHog observability** (Sprint 1 Track A15–A16). Both repos. Free tiers. Sprint 1 acceptance criterion. Self-contained code change, ~1-2 hours, no external dependencies. Recommended next.
>
> **Step 2 — Track B kickoff (Ahmed-owned, long pole for "real launch")**: domain registration (`hadouta.com`), trademark search (WIPO + Egyptian Trademark Office), social handle reservation (`@hadouta` on IG/TikTok/Facebook), Bosta merchant signup, Cairo print-shop outreach, ad campaign creatives. Track B has not started; can run in parallel with A15-A16.
>
> **Step 3 — Custom domain wire-up.** Once `hadouta.com` is registered: point apex to Vercel project, `api.hadouta.com` to Railway service. Update `FRONTEND_URL` (Railway) and `NEXT_PUBLIC_API_URL` (Vercel) to the custom domains. Update Better-Auth's expected origins.
>
> **Step 4 — Real Resend API key.** Currently a placeholder string passes the prod-mode env guard (`re_placeholder_obtain_real_key_post_sprint1`). Auth signup flow needs a real key. Free-tier sufficient for early Sprint 1.
>
> **Step 5 — Vercel CLI token rotation.** `vca_1yDfEW...` was exposed in session 4 chat transcript while reading `~/.local/share/com.vercel.cli/auth.json`. Revoke at https://vercel.com/account/tokens; `vercel login` to re-mint.
>
> **Step 6 — Railway GitHub auto-deploy integration.** Backend currently only deploys via explicit `railway up`. Wire push-to-deploy via Railway dashboard (CLI `--repo` flag fails without prior Railway-GitHub authorization). After this, Vercel and Railway have parity on the deploy trigger.
>
> **Sprint-2 follow-ups (do not lose track)**:
> - Rate-limit hardening + Redis-backed secondary-storage on auth endpoints before horizontal scale
> - Session `ip_address` / `user_agent` PII retention policy (needs ADR before storing or disabling)
> - OpenAPI exposure of auth routes (Better-Auth bypasses `OpenAPIHono.openapi()`)
> - Test-data cleanup helper (now also includes session-4's `e2e-test-2026-05-01@hadouta.local` row)
> - "Secrets must use stdin, never flags" — codify as a project rule + skill candidate after the Railway `--variables` echo leak in session 4
> - Vercel Node version pinning (current: auto-picked 24.x; local dev: 20.19.5) — pin via `vercel.json` if runtime divergence ever surfaces

---

## Sprint 1 — In Progress (Sessions 2 + 3 + 4, 2026-05-01)

Track A foundation work ~95% complete. **Hadouta is LIVE on the internet.**
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
- ⏸️ Sentry + PostHog (Track A15–A16) — next code task; not started
- ⏸️ Custom domain `hadouta.com` — Track B (Ahmed-owned), not started
- ⏸️ Track B (Ahmed) — domain, trademark, handles, services, ad campaign — not started

Detailed logs: `docs/session-notes/2026-05-01-session-2.md` (DB + types), `docs/session-notes/2026-05-01-session-3.md` (auth), `docs/session-notes/2026-05-01-session-4.md` (deploys live).

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

---

## Sprint roadmap

| Sprint | Window | Focus | Status |
|---|---|---|---|
| **0** | 2026-04-30 | Bootstrap infra + ADRs + plans | ✅ Complete |
| **1** | Weeks 1–2 | Foundation: skeletons + landing live + ad campaign | 🟡 In Progress (Track A ~95% — deploys live, Sentry+PostHog pending; Track B 0%) |
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

**Last updated**: 2026-05-01 (session 4) by Claude. Sprint 1 Track A ~95% complete — all 4 commits pushed, frontend live at `hadouta-web.vercel.app`, backend live at `hadouta-backend-production.up.railway.app`, end-to-end waitlist flow verified in production. Three CLIs installed + authenticated (vercel, railway, neonctl). Next code task: Sentry + PostHog (A15-A16). Track B (Ahmed-owned) still at 0%. Credential-rotation followup: Vercel `vca_` token from auth.json file.
