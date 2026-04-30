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

> **First**: configure git user.email + user.name in both sub-repos to a personal account (not Intcore work email). Ahmed will provide the email + GitHub username. Then create three PUBLIC GitHub repos (`hadouta`, `hadouta-backend`, `hadouta-web`) and push initial commits.
>
> **Then verify backend dev server boots cleanly:**
> ```bash
> cd /home/ahmed/Desktop/hadouta/hadouta-backend
> cp .env.example .env
> # Add a temporary placeholder DATABASE_URL (real Neon URL comes after Ahmed creates Neon project)
> pnpm install
> pnpm dev
> # In another terminal:
> curl http://localhost:3001/health
> # Expected: {"status":"ok","service":"hadouta-backend",...}
> ```
>
> **Then verify frontend boots and connects:**
> ```bash
> cd /home/ahmed/Desktop/hadouta/hadouta-web
> cp .env.example .env.local
> pnpm dev
> # Open http://localhost:3000
> # Verify Arabic landing page renders RTL with Tajawal font
> # Submit waitlist form; check backend console for received signup
> ```
>
> **Once both work locally, the next major task is Track A4 (Drizzle migration to Neon) which requires Ahmed creating a Neon project (Track B2).** These two tasks are concurrent — Ahmed creates Neon, Claude wires migration code while waiting.

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
| **1** | Weeks 1–2 | Foundation: skeletons + landing live + ad campaign | 🟢 Ready to start |
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

**Last updated**: 2026-05-01 by Claude (manager). Bootstrap complete; ADR-017 added (Vercel + public repos); awaiting Ahmed's personal git email + GitHub remote setup.
