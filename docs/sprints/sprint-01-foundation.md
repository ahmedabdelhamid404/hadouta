# Sprint 1 — Foundation

**Window**: Weeks 1–2 of build (after Sprint 0 bootstrap completes)
**Status**: ⏸️ Pending Sprint 0 completion
**Sprint goal**: Both repos running locally + landing page deployed live + first ad campaign generating waitlist signups + initial Cairo print quotes received.

---

## Sprint goal (one sentence)

Have a real Hadouta landing page on `https://hadouta.com` collecting waitlist emails, with the first Facebook ad campaign live and the foundation infrastructure ready for AI pipeline work in Sprint 3.

---

## Acceptance criteria (Sprint complete when all true)

- ✅ `https://hadouta.com` resolves to live landing page (Arabic, RTL) on Cloudflare Pages
- ✅ `https://api.hadouta.com/health` returns `200 OK` from Railway-hosted Hono backend
- ✅ Landing page form submission persists email + phone to Neon Postgres `waitlist_signups` table
- ✅ Better-Auth signup/signin flow works for admin user (Ahmed creates first admin account)
- ✅ Both repos pushed to private GitHub with proper README, .gitignore, contribution guide
- ✅ Spec-kit slash commands functional in both repos (`/speckit.specify`, `/speckit.plan`, `/speckit.tasks`)
- ✅ Domain `hadouta.com` registered + DNS pointing correctly
- ✅ Trademark search confirms Hadouta is clear in Egypt + WIPO
- ✅ Instagram, TikTok, Facebook handles `@hadouta` reserved
- ✅ Bosta merchant account active with confirmed shipping rates
- ✅ 3+ real Cairo print shop quotes received and documented in `docs/research/print-quotes.md`
- ✅ Facebook Business Manager + ad account configured
- ✅ 3 ad creatives live with 3 price tiers (250 / 300 / 350 EGP digital)
- ✅ Mom group organic posts started in 5+ groups
- ✅ ≥50 waitlist signups received (validates demand baseline)

---

## Two parallel tracks

### Track A — Code & Infrastructure (Claude executes, Ahmed reviews)

**Day 1–2: Repos already bootstrapped (Sprint 0); now flesh out skeletons**

- A1. Backend: implement `/health` route returning `{ status: 'ok', version, timestamp }`
- A2. Backend: implement `/waitlist` POST route — validates email + phone via Zod, inserts into Neon DB, returns 201 + thank-you message
- A3. Backend: implement Drizzle schema for `users`, `waitlist_signups`, `themes`, `orders` (initial sketch — full schema in Sprint 3)
- A4. Backend: run first migration; verify table structure in Neon dashboard
- A5. Backend: configure Better-Auth (email/password + Google OAuth + magic link via Resend); test signup/signin from curl

**Day 3–4: Frontend landing page**

- A6. Frontend: configure RTL Arabic via `next-intl` + `<html lang="ar" dir="rtl">` switching
- A7. Frontend: install + configure shadcn/ui (button, input, card, form components)
- A8. Frontend: design system tokens — Tailwind config with Hadouta colors (warm watercolor palette: terracotta `#C75D3F`, sage `#7A9576`, dusty blue `#5A7B95`, cream `#FAF6EE`)
- A9. Frontend: landing page (`app/page.tsx`):
  - Hero: Arabic headline + Hadouta logo + tagline "حدوتة طفلك… وهو البطل"
  - Sample book preview (placeholder for now — real demo books in Sprint 2)
  - Email + phone signup form → POST to backend `/waitlist`
  - "How it works" 3-step section
  - FAQ section (8 common questions)
  - Footer with Privacy + ToS placeholder links
- A10. Frontend: add `next-sitemap` + basic meta tags + OG image (placeholder)

**Day 5: Deploy + DNS**

- A11. After Ahmed registers domain (Track B), configure DNS:
  - `hadouta.com` → Cloudflare Pages (Next.js frontend)
  - `api.hadouta.com` → Railway (Hono backend)
  - `mail.hadouta.com` → Resend domain verification (DKIM, SPF)
- A12. Deploy backend to Railway free tier
- A13. Deploy frontend to Cloudflare Pages (free)
- A14. Smoke test end-to-end: form submission flows from production landing page → production backend → Neon DB

**Day 6–7: Observability + commit hygiene**

- A15. Configure Sentry for both frontend + backend (free tier)
- A16. Configure PostHog for product analytics + UTM source tracking
- A17. Create GitHub Actions: backend CI (typecheck + test), frontend CI (typecheck + build)
- A18. Document deploy process in `hadouta-backend/README.md` and `hadouta-web/README.md`
- A19. Set up `.env.example` files in both repos with all required vars

---

### Track B — Business / Validation (Ahmed executes, with Claude assistance)

**Day 1: Brand legal + handles**

- B1. Domain check + register: `hadouta.com` (preferred), fallback `.co` / `.gift` / `.me`
- B2. Trademark search: WIPO Global Brand Database + Egyptian Trademark Office for "Hadouta" / "حدوتة"
- B3. Reserve handles: `@hadouta` on Instagram, TikTok, Facebook page

**Day 2–3: Service signups**

- B4. Open accounts:
  - Cloudflare (free) — for Pages + R2 + DNS
  - Neon (free tier) — Postgres database
  - Better-Auth — no signup needed (runs in our backend)
  - Trigger.dev (free Hobby tier)
  - Helicone (free tier)
  - Resend (free tier 3K/mo) — verify domain `mail.hadouta.com`
  - Twilio (free trial) — WhatsApp Business API access
  - PostHog (free tier)
  - Sentry (free tier)
  - Anthropic API ($5 free credits)
  - fal.ai ($10 free credits)
  - Paymob (account approval takes 3-5 days; start now)
- B5. Sign up for Bosta merchant account; confirm shipping rates per parcel weight + governorate
- B6. Email 5 Cairo print shops with sample 16-page hardcover spec; request quotes at 50 / 100 / 200 batch tiers
  - Salama Printing
  - ZX Printing
  - Cairo Press
  - Sparkle Egypt
  - Nina Prints

**Day 4–5: Ad creative production**

- B7. Generate 2-3 demo book mockups using Anthropic + fal.ai trial credits (Claude assists with prompts; output PDFs)
- B8. Write Arabic landing page copy (Claude drafts, Ahmed refines for Egyptian dialect feel — focus on HERO, value prop, FAQ)
- B9. Design 3 Facebook ad creatives:
  - Creative A: kid + finished book mockup (visual product focus)
  - Creative B: mom + child reading scene (emotional intimacy)
  - Creative C: surprise gift unboxing moment (gift-culture hook)
- B10. Write Arabic ad copy variants for each creative
- B11. Configure Facebook Business Manager + ad pixel installed on landing page

**Day 6–7: Campaign launch**

- B12. Launch Facebook + Instagram ads:
  - Total budget: 3K EGP over 14 days
  - 3 creatives × 3 price tiers (250 / 300 / 350 EGP) = 9 variants
  - Audience: Egyptian women, age 25–40, parents of children (3-5 interest signals), Cairo + Alex + major governorates
  - Optimize for: email signups (waitlist conversion)
- B13. Begin organic posts in 5 Egyptian Facebook mom groups (helpful content style — "preparing your child for first day of school" article + soft Hadouta mention with waitlist link)
- B14. Track all sources via UTM parameters; review daily in PostHog dashboard

---

## Deliverables (filed by end of sprint)

- **Code**: both repos with deployed landing page + backend
- **Docs**:
  - `docs/research/print-quotes.md` (Cairo print shop quotes summary)
  - `docs/research/bosta-rates.md` (shipping rates by governorate)
  - `docs/research/ad-campaign-week1-results.md` (Facebook ad data)
- **Brand**: domain owned, trademark cleared, social handles reserved
- **Validation**: ≥50 waitlist signups, conversion rate by price tier known
- **Foundation**: development environment fully set up, deploy pipeline working

---

## Risks for this sprint

1. **Domain `hadouta.com` already taken** — fallback to `.co` or `.gift`; document brand variant
2. **Facebook ad account approval delay** — start signup Day 1; if delayed, organic mom group posts cover Week 1 validation gap
3. **Print shops slow to respond** — email follow-up Day 4; if no quotes by end of Sprint 1, push to Sprint 2 (not blocking)
4. **Resend domain verification delays** — use a temporary domain for Better-Auth emails until propagation completes
5. **Cloudflare Pages + Next.js 15 edge runtime issues** — fallback to Vercel free tier hosting if `@cloudflare/next-on-pages` adapter has bugs

---

## Manager pattern in this sprint

Most code in this sprint is junior-tier scaffolding (handled by Claude directly). Mid-tier delegation begins in Sprint 3 when AI pipeline complexity appears.

| Task type | Who handles |
|---|---|
| Backend skeleton (health, waitlist routes) | Claude direct |
| Frontend skeleton (landing page, signup form) | Claude direct |
| RTL + i18n setup | Claude direct |
| Better-Auth integration | Senior Developer agent (one delegation) |
| Code review on full sprint output | Code Reviewer agent (mandatory) |

---

## Sprint retrospective template (fill at sprint end)

```markdown
## What went well
- ...

## What slowed us down
- ...

## Decisions changed during sprint
- (any locked ADRs that needed revision)

## Velocity check
- Tasks planned: X
- Tasks completed: Y
- Slip reasons: ...

## Carry-over to Sprint 2
- (anything not done that becomes Sprint 2 scope)

## Skill candidates noticed
- (patterns repeating that might warrant a skill — see skills-roadmap.md)
```
