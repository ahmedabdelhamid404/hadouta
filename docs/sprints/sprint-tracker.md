# Hadouta — Sprint Tracker

**🔖 READ ME FIRST every new session.** This is the single source of truth for "where are we?"

---

## Project state

**Project**: Hadouta (حدوتة) — Egyptian AI personalized children's book platform
**Launch target**: September 1, 2026
**Build window**: ~22 weeks from 2026-04-30
**Current phase**: ✅ Bootstrap · ✅ Sprint 1 wizard live · ✅ Sprint 2 SHIPPED · ✅ Phase 1 character-fidelity verdict (Nano Banana 2 locked, ADR-026) · ✅ **Sprint 3 #1+#2 + audit COMMITTED (local, not pushed): commits `919b846` + `5ef4690` + `d5de204`** · ✅ **Iter 7 face-fidelity marathon: full 16-page Hana book ON ADMIN with watercolor + multi-turn + role-assigned references on Google direct API (2026-05-08 → 2026-05-10)** · 🟢 **Sprint 3 production migration is the new top priority — iter 7 architecture must land in production code**

### GitHub repos (all live as of session 9)
- 📚 **Umbrella + docs** (public): https://github.com/ahmedabdelhamid404/hadouta
- ⚙️ **Backend** (public): https://github.com/ahmedabdelhamid404/hadouta-backend
- 🎨 **Customer frontend** (public): https://github.com/ahmedabdelhamid404/hadouta-web
- 👮 **Admin app** (private, NEW session 9): https://github.com/ahmedabdelhamid404/hadouta-admin

### Live URLs
- Customer: https://hadouta-web.vercel.app
- Admin: https://hadouta-admin.vercel.app
- Backend: https://hadouta-backend-production.up.railway.app

---

## Current sprint

**Sprint**: 3 — Validators framework + story-quality tuning + Trigger.dev migration
**Sprint window**: Weeks 5–8 (starts 2026-05-06 next session)
**Status**: 🟢 Ready to begin (Sprint 2 shipped + polished, ADRs 023/024/025 locked)
**Plan**: `docs/sprints/sprint-03-ai-pipeline.md`

## Previous sprint — Sprint 2 (CLOSED)

**Window**: Weeks 3–4 (2026-05-02 session 9 → 2026-05-05 illustration pipeline polish)
**Status**: ✅ SHIPPED to production (verified end-to-end with real customer photos)
**Original plan**: `docs/design/specs/2026-05-02-sprint-2-implementation-plan.md`
**Final architecture (post-pivot)**: `docs/decisions/ADR-024-bible-driven-illustration-pipeline.md`

### Sprint 2 goal (revised — wider than the doc-tree skeleton)

End-to-end AI generation cycle from paid order to customer-downloadable PDF: Paymob webhook auto-triggers generation → story (gpt-4o-mini, Egyptian-tuned prompt + diacritization) → 17 illustrations (Gemini 2.5 Flash Image) → status `awaiting_review` → admin reviews via separate hadouta-admin app → approves → Puppeteer assembles A5 RTL Arabic PDF → Cloudinary `raw` URL → customer downloads from `/account/orders/[id]`.

(Note: original sprint-tree had Sprint 2 = "validation infrastructure" and Sprint 3 = "AI pipeline." In practice we compressed AI pipeline + admin review queue + customer status page into Sprint 2. Sprint plan files are guidance, not contracts.)

### Sprint 2 acceptance criteria

- ✅ AI generation pipeline runs against real paid orders end-to-end (story + illustrations + DB persistence)
- ✅ Paymob webhook auto-triggers generation; idempotent on retry
- ✅ Schema migrations 0004 (ai_pipeline) + 0005 (must_change_password) applied to Neon
- ✅ `ai_settings` singleton row — admin-tunable cost knobs (model, page count, retries)
- ✅ Multi-provider AI router (gpt-/claude-/gemini- prefix routing via Vercel AI SDK)
- ✅ Story Zod schema with runtime invariants (page count, exactly 1 moralMoment, sequential numbers)
- ✅ Egyptian-tuned story system prompt + 3 reviewed few-shot examples + diacritization policy
- ✅ Hadouta-admin Next.js app deployed to Vercel (separate repo per ADR-021)
- ✅ Admin endpoints: list / detail / approve / reject (gated by role='admin')
- ✅ Live SSE notifications when new generations enter `awaiting_review`
- ✅ Super-admin seeded (`ahmed41997@gmail.com` / `A7med@hadouta`) with role + must_change_password fields
- ✅ Puppeteer + Cairo Arabic font PDF assembly, uploaded to Cloudinary as raw
- ✅ Customer `/account` (phone-keyed orders list) + `/account/orders/[id]` (status + PDF download with auto-poll)
- ✅ Wizard step 7 → links to `/account/orders/[id]`
- ✅ Admin sign-in via deployed app — UNBLOCKED (Railway deploy was stale; `railway up` resolved it on 2026-05-04)
- ✅ End-to-end live cycle verified (paid order → AI generation → admin approve → customer downloads PDF)
- ✅ **PDF redesign shipped** (2026-05-03) — see ADR-023 + spec
- ✅ **Illustration pipeline rebuild shipped** (2026-05-04 → 2026-05-05) — Bible-driven, Nano Banana Pro Edit, multi-photo, gpt-4o, identity-preservation prompts. See ADR-024 + ADR-025.
- ⏸️ Validators framework v1 (cultural / age / religious-neutrality / theme-alignment) — Sprint 3
- ⏸️ Trigger.dev v3 migration (durable retries) — Sprint 3 per ADR-010
- ⏸️ WhatsApp delivery — Sprint 4 (Meta template approval lead time)

(Full plan: `docs/design/specs/2026-05-02-sprint-2-implementation-plan.md`)

---

## Resume here (next concrete action)

> **🟢 Iter 7 face-fidelity marathon CLOSED 2026-05-10. Sprint 3 production migration is the next concrete work.**
>
> **READ FIRST next session — in this exact order:**
> 1. `docs/session-notes/2026-05-10-face-fidelity-marathon.md` — full session log: 16-page book journey, LoRA misconception cleanup, watercolor revert, Google direct + multi-turn + thought_signature fix, retry-queue architecture, all generation IDs + admin URLs.
> 2. `docs/decisions/ADR-028-watercolor-revert-from-pixar-3d.md` — reverts ADR-027's Pixar-3D pivot back to watercolor. Architectural reason: Pixar models bias toward youthful-cute on adult characters; watercolor's softer edges absorb face-geometry imperfections. Brand register restored to ADR-005.
> 3. `docs/decisions/ADR-029-production-retry-queue-architecture.md` — production resilience layer: queue-based retry with `failed_retry_pending` + `failed_human_review` statuses, multi-turn refinement with thought_signature pass-through, Trigger.dev migration path.
> 4. `hadouta-backend/src/scripts/_iter7_full_book.ts` — the reference implementation. Every layer-1 and layer-2 fix from ADR-029 is in this script.
> 5. The reference output: https://hadouta-admin.vercel.app/orders/22563851-2047-4f9e-ac47-ad27e036d4ea — full 16-page Hana book in admin queue.
>
> **What's working right now (verified 2026-05-10):**
> - Iter 7 generation `22563851-2047-4f9e-ac47-ad27e036d4ea` — full 16-page Hana book on Google direct API with multi-turn refinement, role-assigned references, 3:4 aspect ratio, watercolor style, scale-fix on cover, unlimited retry on Google 503/500.
> - Customer wizard end-to-end (Sprint 1 + Sprint 2 functionality unchanged).
> - Admin app live with all iter 7 generations visible.
>
> **What's committed in `hadouta-backend` `main` (LOCAL, NOT pushed):**
> - `919b846` — Sprint 3 #1+#2: Pixar-3D Bible-gen + buildIllustrationPrompt rewrite + schema additions + tests + cleanup
> - `5ef4690` — Sprint 3 audit quick wins: glossary triggers + vision rewrite + sandwich anchors
> - `d5de204` — Sprint 3 audit followups: age-matched few-shot shuffle + 4th example
>
> ⚠️ **The Pixar-3D defaults shipped in `919b846` need to be reverted to watercolor before pushing to origin** (per ADR-028).
>
> **What's NOT in production but proven in iter 7 (Sprint 3 production migration tasks):**
> 1. **Watercolor revert in `bible-system-prompt.ts`** — undo Pixar-3D defaults from commit `919b846`, replace with watercolor (Tomie dePaola + Helen Oxenbury references, wet-on-wet keyword, cold-press paper, anti-Disney negatives). See ADR-028.
> 2. **Iter 7 prompt structure into `buildIllustrationPrompt`** — narrative paragraph (no bullets), role-assigned input images (Image 1 = identity only, Image 2 = style only), per-beat positive face/expression prose (no NOT-negatives), face-visibility floor, 3:4 aspect ratio, scale-fix language. Reference: `_iter7_full_book.ts` `buildPrompt()`.
> 3. **Switch `illustration-generator.ts` from fal.ai to Google direct API** (`gemini-3.1-flash-image-preview`, REST via `https.request`, 20-min socket timeout). Only Google direct supports multi-turn.
> 4. **Multi-turn refinement (turn 1 + turn 2 self-critique)** with `thought_signature` pass-through (raw model parts replay). Per-call cost goes from ~$0.04 → ~$0.08 (2 successful calls per illustration).
> 5. **Retry-with-backoff per Google call**: 503/429/500 → exponential backoff then unlimited 5-min retry. Bail on 400/401/403. See ADR-029 layer 1.
> 6. **Queue-based retry orchestration**: schema migration adds `failed_retry_pending` + `failed_human_review` + `next_retry_at` + `last_error`. Background worker every 5 min picks up stuck generations. See ADR-029 layers 3-4.
> 7. **Cloudinary upload retry** (3 attempts with backoff) — `_iter7_full_book.ts` had 2 transient timeouts.
> 8. **Tier 2 spending plan**: API key currently on Google AI Studio Tier 1. $250+ over 3 days bumps to Tier 2 (substantially fewer 503s + opt-out of training data use).
> 9. **3:4 aspect ratio lock** via `generationConfig.imageConfig.aspectRatio: "3:4"` — fits A5 PDF without cropping.
> 10. **Trigger.dev v3 migration** per ADR-010 — wraps the retry-queue in durable jobs. Sprint 3+.
>
> **Cleanup tasks (Sprint 3 closing):**
> - Delete experimental scripts in `hadouta-backend/src/scripts/_*` after migrating their lessons. KEEP: `_iter7_full_book.ts` (reference until production migration done), `_neon-probe.ts`, `_probe-google-api.ts`, `_iter7_get_urls.ts`. DELETE: all the `_iter1` through `_iter6` + recovery scripts + Qwen trials.
> - Remove `appendPixarStyleAnchor()` from `build-illustration-prompt.ts`.
> - Remove `flux-kontext-pixar` provider path + `callFluxKontextPixar` + `PIXAR_STYLE_LORA_URL` env var.
> - Update `docs/brand/brand-brief.md` from Pixar-3D back to watercolor.
> - Update landing page, wizard copy, order-confirmation email, WhatsApp template per ADR-028.
>
> **Sprint 3 deferred items (NOT face-fidelity related):**
> - Validators framework v1 (cultural / age / religious-neutrality)
> - Story-quality tuning
> - PostHog funnel events + Sentry instrumentation
> - HMAC magic-link tokens for `/api/public/order-status/:orderId`

### Sprint 2 followups (now scoped into Sprint 3)

- Reactivate Better-Auth CSRF + origin check; switch admin to direct cross-origin calls with `cookies.session.attributes.sameSite: 'none'`
- HMAC magic-link tokens for `/api/public/order-status/:orderId`
- `must_change_password` invite endpoint + force-change UX
- Admin settings page that reads/writes `ai_settings` row (currently DB-edited only)
- Validators framework v1 (cultural / age / religious-neutrality / theme-alignment)
- Trigger.dev v3 migration when concurrency demands durability (per ADR-010)
- Story prompt evaluation suite (a few hand-graded golden examples, regression-tested per prompt change)
- Backend Sentry instrumentation around generation pipeline stages
- PostHog events for funnel: `generation_started`, `generation_failed`, `generation_awaiting_review`, `generation_approved`, `generation_rejected`, `generation_delivered`
- Next.js 16 `middleware` → `proxy` rename (deprecation warning in build)
- Single-instance SSE pub/sub → Redis pub/sub when scaling beyond 1 backend instance
- Parent-question relocation (out-of-book to companion card / email / account-page) per ADR-023

### Deferred AI-quality investments (Sprint 4+)

- **Per-customer character LoRA training** — gold-standard identity preservation. 15–90 min training per customer breaks the real-time wizard. Sprint 5+ premium tier with async fulfillment. (ADR-024 deferred §)
- **Watercolor style LoRA** — train on commissioned Egyptian illustrations. Replaces style-prompt-engineering with model-baked style. Sprint 4+. (ADR-024 deferred §)
- **Egyptian-Arabic-voice text LoRA** via OpenAI fine-tuning. Shrinks story-system-prompt.ts from 600 → ~50 lines. Sprint 5+. (ADR-024 deferred §)

### Shipped post-Sprint-2 (the bridge into Sprint 3)

- ✅ **PDF redesign** (2026-05-03) — cover/body/end-page system, three-font hierarchy (Aref Ruqaa / El Messiri / Cairo), paper texture, watercolor washes, ornament ✦ family. Story schema + prompt updated to produce `moralStatement`; rendered on the end-page above "النهاية" in Aref Ruqaa. `parentDiscussionQuestion` retained on schema but no longer rendered. PDF size 5.5 MB (Cloudinary URL transforms `c_limit,w_750,f_jpg,q_70`). See ADR-023.
- ✅ **Illustration pipeline rebuild** (2026-05-04 evening → 2026-05-05) — original Sprint 2 pipeline had four orthogonal failures: style drift, character drift, setting drift, cultural literalness. Plus customer photos were dead-letter. Brainstormed → spec'd Flux+PuLID → built 14 of 16 tasks → Phase H verification (8 real-API iterations, ~$3.10 spend) revealed PuLID has portrait-only ceiling that can't render character-in-scene. Pivoted to Nano Banana Pro Edit. Architecture locked: Bible (locked character/setting/style/cultural anchors) + multi-photo identity references + identity-preservation prompt language + cover-as-cover-only (NOT body reference). gpt-4o adopted as production model (gpt-4o-mini permanently rejected per feedback memory). See ADR-024 (architecture) + ADR-025 (Phase H pivot lessons).
- ✅ **Phase 1 character-fidelity verdict** (2026-05-06) — 6-iteration verification sprint to answer the founder's "wtf it's him" face-fidelity goal. Tried Flux Kontext Pro + Civitai Pixar LoRA across iterations 2–4 (got to ~98% wtf face but supporting-character age + narrative-action + accessory-state issues persisted). Iteration 5 (gpt-image-2) blocked at OpenAI org-verification gate. **Iteration 6 (`fal-ai/nano-banana-2/edit` with iter-4 Pixar prompts) won decisively** — adult-character differentiation, active narrative moments, dramatic atmospherics, cross-page consistency, bilingual text-in-image capability, all at half the per-page cost. Total Phase 1 spend ~$2.50. Production endpoint upgraded (commit `278f0a3`). Brand pivoted from watercolor to Pixar-3D. Architecture locked: Nano Banana 2 + multi-image identity reference (1–3 customer photos) + Pixar-3D prompt overlay (no LoRA needed). See ADR-026 (verdict) + ADR-027 (brand pivot) + session note `2026-05-06-phase-1-character-fidelity-verdict.md`.

### Sprint 2 followups (recorded so we don't lose track)

- Reactivate Better-Auth CSRF + origin check; switch admin to direct cross-origin calls with `cookies.session.attributes.sameSite: 'none'`
- HMAC magic-link tokens for `/api/public/order-status/:orderId` (currently unprotected — phone-only identity is a Sprint 2 first-cycle shortcut)
- `must_change_password` invite endpoint + force-change UX (super-admin works for first cycle; multi-admin needs the invite path)
- Admin settings page that reads/writes `ai_settings` row (currently DB-edited only)
- Validators framework v1 (cultural / age / religious-neutrality / theme-alignment)
- Story-quality fixes: stronger anti-declared-moral prompt, watercolor style adherence (Gemini ignores it), pacing fix on resolution-act filler
- Trigger.dev v3 migration when concurrency demands durability (per ADR-010)
- Story prompt evaluation suite (a few hand-graded golden examples, regression-tested per prompt change)
- Backend Sentry instrumentation around generation pipeline stages
- PostHog events for funnel: `generation_started`, `generation_failed`, `generation_awaiting_review`, `generation_approved`, `generation_rejected`, `generation_delivered`
- Next.js 16 `middleware` → `proxy` rename (deprecation warning in build)
- Single-instance SSE pub/sub → Redis pub/sub when scaling beyond 1 backend instance
- WhatsApp delivery template (Meta approval 24-48h) — bring online for v2 cycle

### Sprint 1 followups (still open)

> **Original Sprint 1 next steps below — most still applicable.**

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
| ADR-020 | AI-only generation, Egyptian human review only — no Egyptian writers/illustrators commissioned for MVP. Cultural-specificity moat lives in (1) Egyptian-tuned system prompts + reviewed few-shot examples, (2) validators framework, (3) manual review gate (added 2026-05-02; supersedes ADR-002 production-model section) |
| ADR-021 | Admin app architecture: separate `hadouta-admin` Next.js repo deployed to Vercel; email/password auth; default neutral chrome; super-admin seeded; Server-Sent Events for live notifications (added 2026-05-03) |
| ADR-022 | Sprint 2 AI pipeline architecture: multi-provider router (gpt-/claude-/gemini- prefix routing via Vercel AI SDK), `ai_settings` singleton row for admin-tunable cost knobs, in-process fire-and-forget orchestration (Trigger.dev migration deferred), Puppeteer for Arabic-shaping-aware PDF assembly (added 2026-05-03; extends ADR-006 + ADR-010 + ADR-020) |
| ADR-023 | moralStatement as first-class story output: new top-level Zod field on storyOutputSchema, generated by AI per updated system prompt, rendered on PDF end-page above "النهاية"; parentDiscussionQuestion stays on schema but is no longer rendered inside the book — relocation to a separate artifact deferred (added 2026-05-03; extends ADR-022 + ADR-020) |
| ADR-024 | Bible-driven illustration pipeline with Nano Banana Pro Edit: 5-step pipeline (Story → Bible → per-page prompts → 17 illustrations via fal-ai/nano-banana-pro/edit → PDF); multi-photo identity references on every illustration call; structured Bible (characterBible + settingBible + styleBible + culturalNotes) generated by gpt-4o; cultural-glossary.ts with Egyptian terms + negative examples is the moat; per-book cost ~$0.74; body pages do NOT receive cover as image reference (Phase H proved cover-as-ref produces duplicate scenes) (added 2026-05-05; extends ADR-006 + ADR-019 + ADR-022; supersedes Sprint 2 Gemini-direct illustration provider) |
| ADR-025 | Phase H pivot — Flux+PuLID rejected: spec called for Flux 1.1 Pro + PuLID per industry-survey research; 8 real-API iterations during Phase H verification proved PuLID has a portrait-only ceiling unaffected by id_weight or start_step tuning (parameter ceiling vs capability ceiling distinction); pivoted to Nano Banana Pro Edit which natively supports multi-image conditioning. Lessons-learned ADR. Real-API verification PRECEDES architecture lock-in for any future model-selection spec (added 2026-05-05; drives ADR-024) |
| ADR-026 | Phase 1 character-fidelity verdict — Nano Banana 2 (Gemini 3.1 Flash Image, fal-ai/nano-banana-2/edit, $0.08/edit) + multi-image identity reference (1–3 customer photos) + Pixar-3D prompt overlay (no LoRA needed) is the locked illustration architecture. 6-iteration verification sprint produced ~$2.50 spend; iter 6 dramatically beat iter-4's Flux Kontext + Pixar LoRA on adult-character age differentiation, narrative-action depiction, accessory-state stability, and per-page cost. Production endpoint upgraded (commit 278f0a3). Production prompt-builder gaps (Bible-gen styleBible + supportingCharacters; buildIllustrationPrompt structure) recorded as Sprint 3 top-priority work (added 2026-05-06; extends ADR-024) |
| ADR-027 | Watercolor → Pixar-3D brand pivot: ADR-005's watercolor anchor is dropped (the L3 photo-upload portion stands). Pixar-3D animated register (Disney Encanto / Coco / Inside Out) is the locked illustration style. Egyptian cultural specificity moves to content layer (story voice, kahk/fanous/makarona-bashamel cultural anchors, settings) — register is now an open product variable. Brand brief + customer copy edits required as Sprint 3 followup (added 2026-05-06; supersedes ADR-005 style portion; companion to ADR-026) — **SUPERSEDED by ADR-028 on 2026-05-10** |
| ADR-028 | Watercolor revert from Pixar-3D: reverts ADR-027 brand portion. Pixar models bias toward youthful-cute regardless of explicit age cues; watercolor's softer edges absorb face-geometry imperfections that Pixar exposes. Tomie dePaola's Strega Nona + Helen Oxenbury's We're Going on a Bear Hunt as named-work style anchors. ADR-005's watercolor register restored. ADR-026's illustration architecture (Nano Banana 2 + multi-image identity) stands (added 2026-05-10) |
| ADR-029 | Production retry-queue architecture: persistent queue-based retry for AI illustration generation. New generation statuses `failed_retry_pending` + `failed_human_review`. New columns `next_retry_at` + `last_error`. Per-call retry-with-backoff (10s/30s/60s/120s/then 5-min unlimited) on 503/429/500. Multi-turn refinement (turn 1 + turn 2 self-critique) with thought_signature pass-through. Cloudinary upload retry (3-attempt). Background cron worker every 5 min picks up stuck generations. Trigger.dev v3 migration per ADR-010. Reference implementation: `hadouta-backend/src/scripts/_iter7_full_book.ts` (added 2026-05-10; companion to ADR-022) |
| ADR-030 | Production illustration architecture (post-validation): locks the ACTUAL shipped state across `src/lib/ai/*`. Google direct API + multi-turn + Image 1..N customer photos (identity) + FINAL image static Beatrix Potter PD watercolor (style; non-recursive) + mandatory photo upload + 4-layer text-only wardrobe enforcement + skip-and-continue orchestration + 18+ category error taxonomy + V7 retry queue (schema 0008 + cron worker + resume logic). Pixar-3D legacy DELETED. Iter scripts no longer load-bearing — production is the source of truth (added 2026-05-10 evening; supersedes the implementation gap in ADRs 022/024/026/028/029) |

---

## Sprint roadmap

| Sprint | Window | Focus | Status |
|---|---|---|---|
| **0** | 2026-04-30 | Bootstrap infra + ADRs + plans | ✅ Complete |
| **1** | Weeks 1–2 | Foundation: skeletons + landing live + ad campaign | 🟢 ~99.99% (Track A engineering DONE — wizard works end-to-end on production with Cloudinary photo upload + Paymob payment + dev OTP bypass. Track B prereqs and credential upgrades remain.) |
| **2** | Weeks 3–4 | **AI generation pipeline + admin review queue + customer account/PDF download** (compressed: original Sprint 2 "validation infra" + Sprint 3 "AI pipeline" + parts of Sprint 4/5). Plus PDF redesign (ADR-023) + illustration pipeline rebuild (ADR-024 + ADR-025). | ✅ Shipped & verified |
| **3** | Weeks 5–8 | **Bible-gen prompt rewrite (Pixar-friendly + supporting-chars populated) + buildIllustrationPrompt rewrite (per-page pose/props/character-presence) + brand brief update per ADR-027** + validators framework v1 + Trigger.dev migration + Sentry/PostHog instrumentation + cleanup of Phase 1 alt code paths (flux-kontext-pixar provider + LoRA env + verify-fal-kontext-lora.ts) | 🟢 Ready to start (refreshed entry points 2026-05-06) |
| **4** | Weeks 9–12 | Customer ordering polish + WhatsApp delivery + email fallback + magic-link tokens | ⏸️ Skeletoned |
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

**Last updated**: 2026-05-10 (LATER, post-refactor) by Claude. **Production refactor SHIPPED — iter 7/8 wins ported into `src/lib/ai/*`, recursive AI references killed, V7 retry queue implemented, end-state validated against 10 customer use cases. ADR-030 documents the locked architecture. Production probe rendered cover + page 1 with iter-8-quality face fidelity. Architecture is shipping-ready pending 4 ops steps (apply migration 0008 to prod, set STATIC_WATERCOLOR_ANCHOR_URL on Railway, wire Railway cron, verify wizard photo-mandatory gate).**

### 2026-05-10 update — Production refactor closed (later same day)

After the iter 7 face-fidelity marathon, founder directive was clear: stop editing iter scripts, port everything into `src/lib/ai/*`. End-of-day session executed that, plus AI Engineer end-state validation across 10 customer use cases identified 3 production-blocker bugs (V3 turn-2 face-blend, UC10 single-page failure killing book, V7 retry queue not implemented despite ADR-029) and 5 quick wins. All fixed.

Architectural locks (ADR-030):
- API: Google direct (`gemini-3.1-flash-image-preview`), NOT fal.ai
- Image stack: customer photos as Image 1..N (identity), Beatrix Potter 1902 PD plate as FINAL image (style). Customer photos LEAD per iter 8's empirically-proven pattern.
- Multi-turn refinement on cover + every body page (5-axis turn-2 critique: face/wardrobe/scale/full-body/expression)
- Mandatory customer photo upload (wizard gate + backend defensive validation)
- Wardrobe consistency: text-only 4-layer enforcement (no Image 3 anchor — recursive AI removed)
- Skip-and-continue orchestration (single-page failure no longer kills whole book)
- Comprehensive error taxonomy with 18+ Gemini categories + per-category retry policy
- V7 retry queue: schema migration 0008 + `retry-failed-generations.ts` cron worker + resume logic in `runGenerationPipeline`
- Pixar-3D legacy code DELETED per ADR-028

**Key decisions locked tonight (don't relitigate)**: see `docs/session-notes/2026-05-10-production-refactor.md` and `docs/decisions/ADR-030-production-illustration-architecture.md`.

**Resume protocol next session**:
1. Read `docs/session-notes/2026-05-10-production-refactor.md` first.
2. Read `docs/decisions/ADR-030-production-illustration-architecture.md` for the architecture lock-in.
3. Apply migration 0008 to Railway prod (use `_apply_0008.ts` workaround OR raw SQL — Drizzle journal stops at 0004).
4. Set `STATIC_WATERCOLOR_ANCHOR_URL` on Railway production env.
5. Wire Railway cron for `pnpm tsx src/scripts/run-retry-worker.ts` every 5 min.
6. Verify wizard mandates photo upload on `hadouta-web`.
7. Bump Google AI Studio API key to Tier-2 (>$250 cumulative spend) — Tier-1 was producing 5-17 min waits per illustration tonight.
8. Don't re-litigate locked decisions in ADR-030.

### 2026-05-10 update — Iter 7 face-fidelity marathon closed

3-day session (2026-05-08 → 2026-05-10) shipped a full 16-page Hana book at https://hadouta-admin.vercel.app/orders/22563851-2047-4f9e-ac47-ad27e036d4ea using a substantially different illustration architecture than what's in production code. Reference implementation in `hadouta-backend/src/scripts/_iter7_full_book.ts`.

**Key architectural shifts (NOT YET in production code; Sprint 3 production migration must port them):**

1. **Watercolor brand register restored** per ADR-028, superseding ADR-027's Pixar-3D pivot. Pixar models biased toward youthful-cute on adult characters; watercolor's softer edges forgive face-geometry imperfections.

2. **Role-assigned input images**: Image 1 = IDENTITY REFERENCE only (face/skin/hair, ignore expression/pose), Image 2 = STYLE REFERENCE only (watercolor medium, ignore character). Task framing = "render fresh, do NOT copy any input pose." Single narrative paragraph, no NOT-negatives. Per AI Engineer audit citing 4 independent 2026 sources.

3. **Multi-turn refinement** (turn 1 + turn 2 self-critique) — only available on Google direct API, NOT fal.ai. Requires `thought_signature` pass-through via raw model parts replay.

4. **Direct Google API** (`gemini-3.1-flash-image-preview`) replaces fal.ai for production. Tradeoff: Tier 1 throttling pain vs fal.ai middleware buffer. Founder direction: stay on Google for multi-turn capability.

5. **Production retry-queue architecture** spec'd in ADR-029. `failed_retry_pending` + `failed_human_review` statuses. Unlimited 5-min retry on Google 503/500. 3-attempt Cloudinary retry. Background cron worker. Trigger.dev migration.

6. **3:4 aspect ratio lock** via `generationConfig.imageConfig.aspectRatio` — fits A5 PDF without cropping.

7. **LoRA misconception cleared up** definitively — empirical proof that fal.ai's `nano-banana-2/edit` ignores `loras` field; community "Nano Banana + LoRA" patterns are Pattern A (Nano Banana as TEACHER for training data, not in inference loop). Three independent research dispatches converged.

**Cost data**: ~$8-12 estimated total session spend across all iterations + experiments. Per-book projections: single-pass on Flash ~$0.68, multi-turn on Flash ~$1.36, multi-turn on Pro ~$5.10.

**Resume here next session**: read `docs/session-notes/2026-05-10-face-fidelity-marathon.md` first, then ADR-028 + ADR-029, then `_iter7_full_book.ts`. Pick the highest-priority production migration task (item 1 — watercolor revert in `bible-system-prompt.ts` — is the obvious starter since it unblocks pushing the 3 committed Sprint 3 #1+#2 commits to origin).

### 2026-05-06 update — Phase 1 character-fidelity verdict closed

Phase 1 (separate from Sprint numbering) was a focused 1-day verification sprint to answer the founder's "wtf it's him" face-fidelity goal — the gem-of-the-product question Hadouta launches on. Six iterations against real APIs (~$2.50 total spend) on حنين's First Day at School order produced an unambiguous architectural verdict.

**Tested + rejected:** Flux 1 Kontext Pro + Civitai Pixar-3D LoRA + multi-image identity reference (the "Path D" architecture from the design spec). Got to ~98% wtf face on iteration 1 but plateaued on iterations 2–4: supporting characters (mother/teacher) kept rendering as teenage versions of Hanine despite explicit age cues + Pixar movie references; narrative-action moments (active ribbon-tying) refused to depict; accessory state drifted (ribbon vs headband across pages). Pixar-trained-flow models bias toward youthful-cute regardless of prompt strength.

**Tested + blocked:** OpenAI gpt-image-2 (April 2026 release with native reasoning). HTTP 403 — organization verification required. Founder verified but propagation didn't complete during session. Script committed (`run-phase-1-iteration-5-gpt-image-2.ts`) for retry but unlikely to displace verdict (cost 5–10× more).

**Tested + adopted:** Iteration 6 — `fal-ai/nano-banana-2/edit` (Gemini 3.1 Flash Image, Feb 2026 release, $0.08/edit, half the prior Nano Banana Pro cost) + same iter-4 Pixar prompts. Nano Banana 2's reasoning planner disambiguated subject-of-photo from other-characters-in-scene, rendering the mother as a clearly adult woman, the active ribbon-tying moment, the teacher as mature authority figure, two named distinct classmates — all the bugs that resisted Flux Kontext for 3 iterations. Bonus: legible English + Arabic typography baked into images (text-in-image is a Nano Banana 2 first-class capability; cover got "HANINE'S FIRST DAY" baked in, classroom got the Arabic alphabet poster on the wall).

**Production code shipped:** `fal-ai/nano-banana-pro/edit` → `fal-ai/nano-banana-2/edit` constant swap (commit `278f0a3`); `appendPixarStyleAnchor()` helper added to `build-illustration-prompt.ts` with NO-TEXT-IN-IMAGE clause (suppresses the cover-typography emergent behavior). Production endpoint upgraded; production prompt-builder still uses watercolor-era Bible defaults — Sprint 3 must rewrite Bible-gen + buildIllustrationPrompt to land iter-6 quality on real customer orders.

**Brand pivot:** ADR-005's watercolor anchor dropped per ADR-027. Pixar-3D animated register locked. Brand brief + customer copy updates queued for Sprint 3.

**Verdict generation in admin:** https://hadouta-admin.vercel.app/orders/fe8fe560-c009-4cd4-8533-83fca7b0a5e8

**Resume here next session:** Sprint 3 with REFRESHED entry points — Bible-gen prompt rewrite + buildIllustrationPrompt rewrite take top priority over original validators-first plan. See "Resume here" section above + ADR-026 + ADR-027 + session note `2026-05-06-phase-1-character-fidelity-verdict.md`.

### 2026-05-05 update — illustration pipeline rebuild closed

End-to-end customer test on 2026-05-04 surfaced four orthogonal failure modes in Sprint 2's illustration pipeline (style drift, character drift, setting drift, cultural literalness like "kahk → chocolate cookies") plus uploaded photos were dead-letter data. Brainstormed → spec'd → built 14 of 16 tasks across 8 phases (83/83 tests pass). **Phase H verification (8 real-API iterations, ~$3.10 spend across 2026-05-04 evening through 2026-05-05 morning) revealed the spec'd Flux+PuLID architecture has a portrait-only ceiling that fundamentally cannot render character-in-scene illustrations regardless of parameter tuning.** Pivoted to Nano Banana Pro Edit (`fal-ai/nano-banana-pro/edit`) — Gemini 2.5 Flash Image with native multi-image conditioning support. Final architecture (Iteration 8): multi-photo identity references on every call, gpt-4o for story + Bible + vision (gpt-4o-mini permanently rejected per feedback memory), strengthened Bible system prompt (explicit four-top-level-keys structure + hair-styling capture + outfit-continuity rules), identity-preservation prompt language on body pages. Iteration 8 generation `fad8f418-...` verified in admin queue.

**Resume here next session:** Sprint 3 — validators framework v1, story-quality tuning, Trigger.dev migration. See "Resume here" section above for priority order.

### 2026-05-03 update — Sprint 2 cycle

Session 9 built the entire AI generation + admin review + customer download cycle in one long session:
- AI pipeline (story + illustrations) with multi-provider routing, schema invariants, cost tracking
- `hadouta-admin` separate Next.js repo created + deployed to Vercel
- Customer `/account` + `/account/orders/[id]` pages on hadouta-web
- Schema migrations 0004 + 0005 applied to Neon
- Super-admin seeded
- Puppeteer-based Arabic-shaping-aware PDF assembly
- Better-Auth `INVALID_ORIGIN` blocker — resolved 2026-05-04 by `railway up` (deploy was stale, the fix was already in main)

ADR-021 (admin app architecture) + ADR-022 (Sprint 2 AI pipeline architecture) + ADR-023 (moralStatement) + ADR-024 (Bible-driven Nano Banana pipeline) + ADR-025 (Phase H pivot) all locked in `docs/decisions/`.
