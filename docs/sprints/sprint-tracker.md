# Hadouta — Sprint Tracker

**🔖 READ ME FIRST every new session.** This is the single source of truth for "where are we?"

---

## Project state

**Project**: Hadouta (حدوتة) — Egyptian AI personalized children's book platform
**Launch target**: September 1, 2026
**Build window**: ~22 weeks from 2026-04-30
**Current phase**: ✅ Bootstrap complete · ✅ Public repos live · ✅ **Sprint 1 Track A ~99.99% — wizard works end-to-end on production** · ⏸️ Track B (your launch prereqs) pending · ⏸️ Sprint 2 not started

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

> **🟢 Phase 3 (screen design) DONE** (session 6). 13 surface-design picks made via brainstorming + visual companion wireframes. All locked in `docs/design/specs/2026-05-02-phase-3-design-spec.md`. Brand brief amended with AI-honesty quiet middle path.
>
> **🟢 Phase 5 Part 1 (backend) SHIPPED + PUSHED** (sessions 6+7). Migration `0003_phase_5_wizard_schema.sql` applied to Neon dev. 3 new tables (`moral_values` + 8 seeded values, `supporting_characters`, `photos`). Extended `themes` + `orders` (~17 columns). API routes: `/api/orders/draft`, `/api/orders/:id` PATCH+GET, `/api/catalog/themes?ageBand=`, `/api/catalog/moral-values`. `hadouta-backend@0bfccec` on `feat/phase-5-implementation`, **PUSHED**.
>
> **🟢 Phase 5 Part 2 (landing page) SHIPPED + PUSHED** (sessions 6+7). 9 section components in `src/components/landing/`. AI-honesty middle path applied. CTAs route to `/wizard`. `hadouta-web@e75a8cf` on `feat/phase-5-implementation`, **PUSHED**.
>
> **🟢 Phase 5 Part 3 (wizard frontend) SHIPPED + PUSHED** (session 7). All 7 wizard steps live: child info form (react-hook-form + Zod), photo OR description fork (with skin-tone color picker), supporting characters (invitation + skip), story details (age-band-filtered theme grid + moral grid + custom scene + occasion), review with per-section edit-jumps + dedication, phone OTP wired to ADR-018 Better-Auth endpoints + Paymob redirect (graceful degradation if Task 1.10 not configured), Storyteller-voice confirmation. Zustand store persists across refreshes. ~1959 lines / 20 files. `hadouta-web@9183250` on `feat/phase-5-implementation`, **PUSHED**.
>
> **⏸️ Phase 5 Tasks 1.9 + 1.10 (CREDENTIAL-GATED)** — both have working code patterns in implementation plan; activate when creds available:
>   - **Task 1.9 — Photo upload (Cloudflare R2)**: Ahmed creates R2 bucket `hadouta-photos` + access keys. Then implement `src/lib/r2.ts` + `src/routes/photos.ts` per plan §1.9. Frontend already calls `uploadPhoto()` — will work once backend exists.
>   - **Task 1.10 — Paymob payment intent**: Ahmed completes Paymob merchant onboarding + grabs API key + integration IDs (card / Vodafone Cash / InstaPay) + iframe ID + HMAC secret. Then implement `src/lib/paymob.ts` + `src/routes/payments.ts` per plan §1.10. Frontend step 6 already calls `createPaymentIntent()` — will redirect to Paymob iframe once backend exists; otherwise step 6 shows informative error.
>
> ---
>
> **Step 1 — Verify Vercel preview deploy of all 3 branches** (5 min):
>   - Open Vercel dashboard → preview URL for `feat/phase-5-implementation` branch
>   - Verify landing page renders all 9 sections correctly (Arabic RTL, brand chrome)
>   - Verify `/wizard/1` loads (you'll see the form; submit will hit backend at `NEXT_PUBLIC_API_URL`)
>   - Verify `/wizard` redirects to `/wizard/1`
>
> **Step 2 — End-to-end smoke test** (~30 min, deferred from session 7):
>   - Manually walk through wizard 1→2→3→4→5 → confirm data persists to backend draft order via PATCH
>   - Step 6: real OTP flow with Twilio sandbox (or your real number) → confirms ADR-018 backend wiring works end-to-end
>   - Step 6 pay button: will show "Paymob deferred" error until Task 1.10 ships
>   - Step 7: confirms Storyteller voice landed correctly
>   - Database check via `pnpm db:studio` — verify orders + supporting_characters rows
>
> **Step 3 — Track B credentials acquisition** (Ahmed-owned, gates real launch):
>   - **Cloudflare R2** — create bucket `hadouta-photos`, generate access keys, set in Railway prod env. Unblocks Phase 5 Task 1.9.
>   - **Paymob merchant onboarding** — submit business docs (commercial register, tax card, bank account). 3-7 day approval. Once approved: API key + integration IDs (card/VC/InstaPay) + iframe ID + HMAC secret. Set in Railway prod env. Unblocks Phase 5 Task 1.10.
>   - **Meta Business Verification + Twilio WhatsApp sender** — long pole (3-7 day FB review). Start ASAP — needed for production WhatsApp OTP.
>   - **Domain `hadouta.com` registration** + DNS to Vercel (apex) + Railway (`api.hadouta.com`).
>   - **Trademark search** + `@hadouta` social handle reservation (IG, TikTok, Facebook, YouTube, X).
>   - **Egyptian decorative-motif library commission** (~10K EGP, 2-4 weeks lead time).
>   - **Egyptian writers + illustrators commissions** per ADR-002 — theme template seed content + watercolor reference style.
>   - **Team photos** for landing trust band (writers, illustrators, reviewers).
>   - Bosta merchant signup + Cairo print-shop outreach (v1.5 print upgrade).
>   - Ad creatives (FB+IG) + Real Resend API key for OTP tier-3 email fallback.
>
> **Step 3 — Track B (Ahmed-owned, gates real launch)**:
>   - Domain `hadouta.com` registration + DNS to Vercel (apex) + Railway (`api.hadouta.com`)
>   - Cloudflare R2 bucket `hadouta-photos` + access keys (unblocks Phase 5 Task 1.9)
>   - Paymob merchant onboarding + API keys + integration IDs (unblocks Phase 5 Task 1.10)
>   - Meta Business Verification + Twilio WhatsApp sender (long pole — 3-7 days FB review; needed for production WhatsApp OTP delivery)
>   - Trademark search + `@hadouta` social handle reservation
>   - Egyptian decorative-motif library commission (~10K EGP, 2-4 weeks lead time)
>   - Egyptian writers + illustrators commissions per ADR-002 (theme template seeding + watercolor reference style)
>   - Team photos for landing trust band (writers, illustrators, reviewers)
>   - Bosta merchant signup + Cairo print-shop outreach (v1.5 print upgrade)
>   - Ad creatives (FB+IG) + Real Resend API key
>
> **Step 4 — Phase 5 Part 4: production wiring** (after Part 3 completes):
>   - End-to-end smoke test (manual flow from landing → wizard → checkout → confirmation)
>   - Production env vars on Vercel + Railway (R2, Paymob, FRONTEND_URL pointing at hadouta.com once registered)
>   - WhatsApp template submission to Meta (auth template auto-approves; utility/marketing 24-48h review)
>   - Custom domain wire-up
>
> **Step 5 — Sprint 2 followups recorded** (don't lose track):
>   - Rate-limit hardening + Redis-backed secondary-storage on auth endpoints
>   - Session `ip_address` / `user_agent` PII retention ADR
>   - OpenAPI re-exposure of new wizard routes (currently plain Hono — frontend uses direct fetch)
>   - Test-data cleanup helper (leaks `test-*@example.com`, `e2e-test-2026-05-01@hadouta.local` into dev Neon)
>   - Drizzle migration validation pre-flight skill ("validate-drizzle-migration") — 0002 + 0003 both hand-written; recurring pain
>   - Real watercolor hero illustration (currently gradient placeholder)
>   - Theme card SVG icon library (currently emoji placeholders)
>   - Real waitlist-form.tsx removal (kept unused after landing rewrite)
>   - Vercel Node version pinning
>   - Latin companion font revisit (Fraunces vs Spectral)
>
> ---
>
> **Token-rotation status (closed — all leaked tokens revoked)**: 3 tokens rotated across sessions 4 + 5. Pattern documented in `docs/operations/observability-runbook.md`.

---

## Sprint 1 — In Progress (Sessions 2-7, 2026-05-01 to 2026-05-02)

Track A foundation work ~99.9% complete. **Hadouta is LIVE on the internet, observability is wired, design tokens shipped, ADR-018 backend implemented, Phase 3 designs locked, Phase 5 Parts 1+2+3 ALL SHIPPED + PUSHED (backend wizard schema/APIs + landing page + full 7-step wizard frontend).** Only credentials-gated tasks remain (R2 + Paymob), plus end-to-end smoke testing.
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
- ✅ **Phase 2 design tokens shipped** (session 5) — `globals.css` carries the full Hadouta palette (cream/terracotta/ochre/teal/brown/blush) as 3-tier tokens (raw `--hadouta-*` → semantic shadcn → Tailwind utilities). Typography stack live: Tajawal (body), El Messiri (headers, Egyptian-designed), Aref Ruqaa (decorative, max-1-per-page rule), Fraunces (Latin companion). Radius scale (4/8/16/24px) + storyteller-paced motion timing (200/400/600ms) per brand brief. WCAG AA verified. Dark mode kept as a stub.
- ✅ **Phase 3 screen design DONE via wireframing** (session 6) — wireframed landing + 7 wizard steps in visual companion (skipped Figma due to OAuth bugs; brand brief was so locked that Figma intermediate added no value). 13 surface-design picks made. Output: `docs/design/specs/2026-05-02-phase-3-design-spec.md` (~742 lines). 3 upstream structural decisions (photo-OR-description / theme combinatorial / age-band tagging) extend ADR-005 — captured in `docs/design/2026-05-02-wizard-design-decisions.md`. **Brand brief amended with AI-honesty production rule** (quiet middle path: lead with Egyptian human review + 2-3 day care, never claim hand-painted, don't lead with "AI generated").
- ✅ **Phase 5 Part 1 backend (wizard schema + APIs) on branch** (session 6) — migration `0003_phase_5_wizard_schema.sql` (hand-written, drizzle-kit interactive prompt issue same as 0002), 3 new tables (`moral_values`, `supporting_characters`, `photos`), extended `themes` + `orders` (~17 columns), 8 themes + 8 moral values seeded, new routes: orders CRUD + catalog. `hadouta-backend@0bfccec` on `feat/phase-5-implementation`, NOT YET PUSHED.
- ✅ **Phase 5 Part 2 landing page on branch** (session 6) — full Phase 3 design composed in `app/page.tsx`: 9 section components (hero option A + section rhythm option C). All copy applies AI-honesty middle path. CTAs route to `/wizard`. `hadouta-web@e75a8cf` on `feat/phase-5-implementation`, NOT YET PUSHED.
- ✅ **Phase 5 Part 3 wizard frontend SHIPPED + PUSHED** (session 7) — all 7 wizard steps live: child info form (react-hook-form + Zod), photo OR description fork (visual skin-tone picker + clothing buttons), supporting characters (invitation + skip + max 2), story details (age-band-filtered theme grid + moral grid + custom scene + occasion), review with per-section edit-jumps + dedication card, phone OTP (wired to ADR-018 Better-Auth endpoints from session 5) + Paymob redirect (graceful degradation if Task 1.10 not configured), Storyteller-voice confirmation with PostHog `order_confirmed` event. Zustand store with localStorage persist. ~1959 lines / 20 files. `hadouta-web@9183250` on `feat/phase-5-implementation`.
- ⏸️ **Phase 5 Task 1.9 photo upload (Cloudflare R2)** — code patterns in plan; needs R2 bucket + access keys (Track B).
- ⏸️ **Phase 5 Task 1.10 Paymob payment intent** — code patterns in plan; needs Paymob merchant onboarding + API keys + integration IDs (Track B).
- ⏸️ **Phase 5 Part 4 production wiring** — e2e smoke (next session), env vars (Track B credentials), WhatsApp template submission (Track B Meta verification dependency), custom domain (Track B `hadouta.com` registration dependency).
- ⏸️ Track B (Ahmed-owned) — domain, trademark, handles, services, ad campaign, Meta Business Verification + Twilio WhatsApp setup, R2 bucket, Paymob onboarding, Egyptian decorative-motif library commission, team photos, Egyptian writer+illustrator commissions.

Detailed logs: `docs/session-notes/2026-05-01-session-2.md` (DB + types), `docs/session-notes/2026-05-01-session-3.md` (auth foundation), `docs/session-notes/2026-05-01-session-4.md` (deploys live + auth pivot), `docs/session-notes/2026-05-02-session-5.md` (ADR-018 backend impl + Sentry/PostHog wiring + observability runbook + Phase 2 tokens), `docs/session-notes/2026-05-02-session-6.md` (Phase 3 designs + Phase 5 Parts 1+2 + brand brief AI-honesty amendment), `docs/session-notes/2026-05-02-session-7.md` (Phase 5 Part 3 wizard frontend complete).

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
| **1** | Weeks 1–2 | Foundation: skeletons + landing live + ad campaign | 🟢 ~99.99% (Track A engineering DONE — wizard works end-to-end on production with Cloudinary photo upload + Paymob payment + dev OTP bypass. Track B prereqs and credential upgrades remain.) |
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

**Last updated**: 2026-05-02 (session 8) by Claude. **Sprint 1 Track A ~99.99% — wizard works end-to-end on production.** Ahmed verified manually: landing → wizard step 1-5 → Cloudinary photo upload → step 6 dev-OTP bypass → Paymob test card → return → step 7 confirmation. Both Paymob callbacks fire (webhook server-to-server + browser redirect). Cloudinary photo storage live (free tier, no card needed). Dev-mode OTP bypass with hardcoded `123456` until Twilio creds land (one env var flip away). All Phase 5 implementation tasks complete that don't require external credentials. **Three "what's next" options**: (A) Track B credential acquisition for real launch (Twilio signup + Meta verification + domain + decorative-motif library + writer/illustrator commissions), (B) Sprint 2 AI pipeline kickoff (story generation + illustration + admin review queue), (C) Sprint 1 hardening (Paymob HMAC reject-on-mismatch, rate limiting, PII retention ADR, real hero illustration). See `docs/session-notes/2026-05-02-session-8.md` for the comprehensive direction analysis.
