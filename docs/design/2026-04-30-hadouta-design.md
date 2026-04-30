# Hadouta (حدوتة) — Design Document

**Status**: Approved (2026-04-30)
**Owner**: Ahmed Abdelhameed
**Last updated**: 2026-04-30
**Document type**: Design spec / project north star

---

## Executive Summary

**Hadouta** is a web platform that generates personalized AI-illustrated Arabic children's books as occasion gifts for Egyptian families. A mom (or relative) uploads photos of her child plus up to two supporting characters, picks a theme, customizes details (skin tone, hijab, clothing, child's interests), and within minutes receives a 16-page digital book in MSA narration with Egyptian Arabic dialogue — featuring her child as the hero. Hardcover print upgrade ships separately in v1.5.

The platform's competitive moat is **Egyptian cultural specificity**, not technical novelty. Western competitors (Wonderbly, magicalchildrensbook.com, Magic Story) cannot replicate Egyptian themes, settings, dialect, family structures, and Islamic moral frameworks without years of cultural understanding. Saudi competitor Qessati exists but doesn't ship to Egypt and uses Saudi cultural framing. Hadouta v1 launches at the start of the September 2026 school year with a single killer theme — *First Day of School* — anchoring the most emotionally resonant moment in every Egyptian parent's calendar.

---

## 1. Problem & Goals

### 1.1 Problem statement

Egyptian parents face three simultaneous gaps:

1. **Quality kids' content for the Arabic-speaking market is dated.** Traditional Arabic kids' books (Nahdet Misr, Dar El Maaref, Diwan) follow 1990s-era illustration styles and offer zero personalization.
2. **Western personalized-book platforms are culturally tone-deaf.** Wonderbly, magicalchildrensbook.com, and others ship globally but in English with Western themes (Christmas, camping, fairies). Arabic translations are afterthoughts of poor quality.
3. **Egyptian gift-giving culture craves personalization but has no native option.** Egyptian families spend significantly on family-occasion gifts (birthdays, Eid, milestones). They want products that feel made-for-them culturally, not translated.

AI image-generation maturity in 2026 (Nano Banana 2/Pro, Vercel AI SDK, Trigger.dev) makes a solo-dev-buildable platform technically feasible for the first time.

### 1.2 Goals (v1, September 2026 launch)

- Launch by **September 1, 2026** aligned to school-year start
- **100+ paid orders** in launch month
- **70%+ conversion** from preview to checkout
- **<10% refund/regeneration rate** (industry baseline)
- **90%+ AI generation approval rate** (manual review gate during early operation)
- Net profit of **50,000 EGP/month by month 6** (post-launch ramp)

### 1.3 Non-goals (explicitly NOT in v1)

- Subscription tier — one-off purchases only
- Free-form custom story — deferred to v2 premium
- Multiple themes simultaneously — only First Day of School
- Multiple languages — Arabic only (diaspora English in v2)
- Mobile native app — responsive web + PWA only
- Print fulfillment — deferred to v1.5
- B2B / wholesale / school partnerships — out of scope until v3
- Refund-on-request for digital — replacement-only policy
- Live chat support — async (WhatsApp + email) only

### 1.4 Success metrics

| Metric | Month 1 | Month 3 | Month 6 |
|---|---|---|---|
| Total orders/month | 100 | 300 | 500 |
| Refund/regen rate | <12% | <8% | <5% |
| Validator approval rate | 85% | 92% | 95% |
| Manual review time per book | 5 min | 3 min | <1 min (auto) |
| Net profit/month (EGP) | break-even | 30K | 50K+ |
| Waitlist size at launch | 1,000+ | — | — |

---

## 2. Target Users

### 2.1 Primary persona — *"Manar"*

- **Age**: 30, mom of 4-year-old daughter Yara
- **Location**: Cairo middle class (Maadi, Nasr City, Sheraton)
- **Occupation**: works full-time, university-educated
- **Behavior**: active in Facebook mom groups; buys gifts for occasions, not impulse routine purchases; researches before buying
- **Trust signals she needs**: verified Egyptian brand, real customer reviews, clear refund policy, photo-deletion promise
- **Why she'd buy**: Yara starts school in September; Manar wants a memorable gift that captures the milestone

### 2.2 Secondary persona — *"Teta Suzanne"*

- **Age**: 60, grandmother
- **Location**: Heliopolis or Maadi, often Egyptian living abroad (Gulf, US, UK)
- **Behavior**: highest spender per transaction; willing to pay premium for "thoughtful gift"
- **Why she'd buy**: birthday/milestone gift for grandchild she can't always see in person; sends with personalized dedication

### 2.3 Tertiary persona — *"Khalto Heba"*

- **Age**: 35, aunt to her sister's children
- **Behavior**: gift-giver across extended family; high social media presence
- **Why she'd buy**: Eid gift for nieces/nephews; shares photo of unboxing on Instagram

---

## 3. Architecture Overview

### 3.1 High-level pipeline

```
Customer journey:
  Land → Browse sample → Customize (name/photos/details) → Pay → Wait → Receive
                                                                          ↓
                                                          Background pipeline:
                                                          ┌─ Story generation (Claude Sonnet 4.6)
                                                          ├─ Universal validators (5 parallel, Haiku 4.5)
                                                          ├─ Theme-specific validator (Haiku 4.5)
                                                          ├─ Image generation (Nano Banana 2, fan-out)
                                                          ├─ PDF assembly (Puppeteer)
                                                          ├─ Manual approval gate (Trigger.dev waitpoint)
                                                          └─ Delivery (WhatsApp + email)
```

### 3.2 Component diagram

| Component | Technology | Hosting |
|---|---|---|
| **Customer-facing web** | Next.js 16 + React 19 + shadcn/ui + Tailwind 4 + next-intl | Vercel (Hobby → Pro) — see ADR-017 |
| **Admin web** | Same Next.js app, `/admin/*` routes guarded by Better-Auth role | Same |
| **API backend** | Hono on Node.js 22 | Railway |
| **Workflow engine** | Trigger.dev v3 (cloud) | Trigger.dev managed |
| **Database** | Neon Postgres + pgvector | Neon serverless |
| **Auth** | Better-Auth (in backend) | Backend |
| **Object storage** | Cloudflare R2 | Cloudflare |
| **AI: text** | Anthropic SDK via Vercel AI SDK (Claude Sonnet 4.6 + Haiku 4.5) | Anthropic |
| **AI: images** | fal.ai SDK (Nano Banana 2 digital, Nano Banana Pro 4K print v1.5, GPT Image 2 cover fallback) | fal.ai |
| **PDF generation** | Puppeteer (HTML → PDF) | Backend |
| **Email** | Resend | Resend |
| **WhatsApp** | Twilio Business API | Twilio |
| **Payments** | Paymob (Egypt-native) | Paymob |
| **AI observability** | Helicone | Helicone |
| **Product analytics** | PostHog | PostHog Cloud |
| **Errors** | Sentry | Sentry |

### 3.3 Repository structure

Two repos, type-synced via OpenAPI:

- **`hadouta-backend`** — Node + Hono API + Trigger.dev jobs + Drizzle DB layer + Better-Auth + content templates
- **`hadouta-web`** — Next.js 16 customer + admin app, consumes backend OpenAPI for types

Type sync workflow: backend exposes OpenAPI via `@hono/zod-openapi`; frontend runs `pnpm sync-types` to regenerate `lib/api/api-types.ts` from the backend OpenAPI endpoint.

---

## 4. Key Decisions Log

| # | Decision | Rationale |
|---|---|---|
| 1 | Real business intent (not learning project) | Determines validation-while-building, not after |
| 2 | Egyptian moms + gifting relatives, kids 3–5yr | Highest-emotion age band; gift-driven Egyptian spending behavior |
| 3 | Occasion gift positioning (not bedtime utility) | Egyptian gifts command 3–5x utility pricing |
| 4 | First Day of School theme for MVP | Universal Egyptian milestone; Sept timing gives 5-month build window |
| 5 | Digital-first MVP, print upgrade in v1.5 | Print logistics in Egypt are slow for solo dev; digital ships first; print as premium tier |
| 6 | L3 photo upload + watercolor style | Photo upload = emotional differentiator; watercolor matches Arabic typography + is achievable with Nano Banana 2 |
| 7 | Egyptian-specific themes/settings/characters | This IS the moat — Western players can't replicate culturally |
| 8 | Full AI generation + multi-layer validator + temporary manual gate + active learning | Matches automation vision while managing day-1 quality risk |
| 9 | 2-layer validator: Universal (theme-agnostic) + Theme-specific | Layered design lets future themes inherit ethics validators without rewrite |
| 10 | One theme MVP (FDS), theme-agnostic architecture from day 1 | Sharper marketing; better validator training; no painful refactor on theme #2 |
| 11 | Interest-tag customization in v1; free-form custom in v2 premium | Interest tag adds personalization without breaking validator |
| 12 | Validation parallel with build (Lean Startup) | Validates demand and pricing in real time; build is informed by data |
| 13 | 16 pages, kid + up to 2 supporting characters | Bedtime sweet spot for 3–5yr; 2-character limit keeps face consistency reliable |
| 14 | AI stack: Claude Sonnet 4.6 (story) + Haiku 4.5 (validators) + Nano Banana 2 (digital images) + Nano Banana Pro (4K print v1.5) + GPT Image 2 (text-heavy cover fallback) | Sonnet wins Arabic narrative; Haiku is cheap for validator passes; Nano Banana 2 wins face/multi-character consistency |
| 15 | Tentative pricing: A/B test 250 vs 300 EGP digital, +300 EGP print upgrade in v1.5 | Tier 1 (150 EGP) doesn't cover print costs; final price decided by Facebook ad A/B |
| 16 | Distribution: Facebook+Instagram paid + nano/micro influencers (phased) + organic mom group posts | Multi-channel triangulation; Egyptian mom groups are unique organic asset |
| 17 | Tech stack: Node + Hono + Vercel AI SDK + Trigger.dev + Neon + Better-Auth + Cloudflare R2 + Next.js 16 + shadcn/ui | TypeScript-everywhere; AI SDK is React-first; Trigger.dev waitpoints save weeks; Neon avoids Supabase scaling concerns |
| 18 | Brand name: Hadouta (حدوتة) | Cultural Egyptian word for bedtime story; max emotional resonance; counter-positions vs Saudi Qessati |
| 19 | Two repos (`hadouta-backend`, `hadouta-web`) with OpenAPI for type sync | Cleaner separation; independent deploy cycles |
| 20 | Free dev tier across all services; paid only at production launch | Zero fixed cost during development; scales gracefully |
| 21 | Refund policy: 1 free regen within 7 days; no cash refund for digital; replacement-only for damaged print | Industry standard; trust-builder for new Egyptian brand |
| 22 | Photo handling: max 3 photos per character; encrypted at rest in R2; auto-delete 30 days post-order | Egyptian privacy expectations + legal cover |
| 23 | Admin v1 scope: orders + review queue + approve/reject/regen + metrics | Defers theme/prompt editor to v1.5 (manage via git in MVP) |

---

## 5. Data Model

Schema sketch (Drizzle ORM, Postgres on Neon, with pgvector extension):

```
users
  id, email, password_hash, name, phone, role (customer | admin)
  email_verified_at, created_at, updated_at

orders
  id, user_id (FK), theme_id (FK)
  status (pending | paid | generating | awaiting_review | approved | delivered | refunded | failed)
  price_egp, payment_provider (paymob), payment_id, paid_at
  created_at, delivered_at

themes
  id, slug (unique), title_ar, title_en, description
  age_range_min, age_range_max
  status (draft | active | archived), launched_at

characters
  id, order_id (FK), role (main | mom | dad | sibling | grandparent | friend)
  name, gender, age
  photo_keys (JSONB array — R2 object keys)
  avatar_attributes (JSONB — skin_tone, hair, hijab, clothing, etc.)

generations
  id, order_id (FK), trigger_run_id (Trigger.dev correlation)
  status (queued | story_done | validating | image_gen | assembling | awaiting_review | delivered | failed)
  story_data (JSONB — full story object with pages array)
  pdf_key (R2 object key for digital PDF)
  story_model_version, image_model_version
  started_at, completed_at, delivered_at

validator_runs
  id, generation_id (FK), validator_layer (universal | theme_specific)
  validator_type (religious_safety | cultural_safety | age_appropriate | moral | language | educational | visual | format | theme_adherence)
  input_text, output_json, score (0-1), passed (bool)
  created_at

rejections                    -- active learning corpus
  id, generation_id (FK), reviewer_id (FK to users)
  rejection_categories (JSONB array of category enums)
  feedback_note (text)
  regenerated (bool), created_at

story_embeddings              -- pgvector for similarity search
  id, generation_id (FK), embedding (vector(1536))
  category (approved | rejected_<category>)
  created_at

regeneration_requests         -- customer-facing regen flow
  id, order_id (FK), customer_note, requested_at
  approved_by_admin_id, regen_completed_at, status

audit_log                     -- generic audit trail
  id, actor_id, action, resource_type, resource_id, metadata (JSONB), created_at
```

The `story_embeddings` table powers the active-learning loop: when a new generation completes, we embed the story and pgvector-similarity-search against past rejections. If it's similar to a known-rejected pattern, the validator weights that pattern more heavily before passing to manual review.

---

## 6. AI Pipeline Architecture

### 6.1 Generation state machine

```
[order.paid event]
    ↓
generateStory() — Vercel AI SDK + Claude Sonnet 4.6 + Zod schema
    ↓ (validated structured output)
runUniversalValidators() — 5 parallel Haiku 4.5 calls
    ↓ all pass
runThemeValidator() — Haiku 4.5
    ↓ pass
generateImages() — fan-out to fal.ai Nano Banana 2 (17 parallel calls: 16 pages + 1 cover)
    ↓ all complete (with retry on individual failures)
assemblePdf() — Puppeteer renders Angular template → PDF
    ↓
waitForApproval() — Trigger.dev waitpoint, sends notification to admin
    ↓ admin clicks ✅
deliverBook() — WhatsApp + email with web reader link + PDF download
```

### 6.2 Universal validator design

Each universal validator is a separate Haiku 4.5 call with a focused system prompt + few-shot examples. They run in parallel for speed. All must pass.

| Validator | Catches |
|---|---|
| `religious_safety` | Christian symbols misplaced, alcohol, pork, music if traditionally avoided, gendered prohibitions |
| `cultural_safety` | Egyptian-specific norms (respect for elders, hospitality), gender role appropriateness |
| `age_appropriate` | Violence, scary themes, inappropriate adult content for 3–5yr |
| `moral_correctness` | Lying praised, cheating glorified, bullying without consequence |
| `language_safety` | Slurs, profanity, derogatory terms, inappropriate dialect mixing |
| `educational_soundness` | Factual errors about Islam, Egypt, geography |

### 6.3 Theme-specific validator design

For First Day of School:

- Story MUST mention school setting at least once
- Story MUST include teacher character or arriving-at-school scene
- Story SHOULD include a moment of mild anxiety + reassurance (developmentally appropriate)
- Story SHOULD include pride/accomplishment moment
- Word count: 240–400 words total (~30 per page)

### 6.4 Retry logic

If any validator fails:
1. Capture the validator's structured feedback (category + reason)
2. Send back to story generator with feedback prepended to prompt: `"The previous attempt failed validator X with: [reason]. Regenerate avoiding that issue."`
3. Limit retries: 3 attempts total. If still failing → flag for manual story rewrite (admin task)

### 6.5 Manual approval gate (Trigger.dev waitpoint)

```typescript
// In generateBook job
await assemblePdf();
const approval = await wait.forRequest({
  resourceId: orderId,
  expirationTime: '7d',  // auto-fail if admin doesn't review in 7 days
});

if (approval.action === 'approved') {
  await deliverBook();
} else if (approval.action === 'reject') {
  // Capture rejection categories + feedback
  await storeRejection(approval.feedback);
  await regenerateBook(approval.feedback);
}
```

When admin clicks approve/reject in admin UI, frontend sends a request to backend that resolves the waitpoint. Workflow auto-resumes from the exact step.

### 6.6 Active learning loop

- Every rejection captures: structured category + free-text note
- Helicone observability auto-tags requests with rejection metadata
- Helicone Request Datasets feature builds training corpus automatically
- pgvector embeddings store rejected vs approved patterns
- Weekly script: regenerate validator system prompts with new few-shot examples drawn from recent rejections
- New validator versions must pass the **regression test suite** (100+ hand-crafted ethics test cases) before deploying

Once approval rate hits 95%+ over a 30-day window, switch from "manual gate every book" to "manual gate only on borderline scores," then to "full auto with periodic spot-check."

---

## 7. User Flows

### 7.1 Customer ordering flow

1. **Land** on hadouta.com from Facebook ad / mom group / influencer
2. **Browse** auto-generated demo book preview (placeholder name "أحمد")
3. **CTA**: *"اعملي حدوتة طفلك دلوقتي"*
4. **Customize step 1** — main character: name, gender, age, upload 1–3 photos, optional interest tag
5. **Customize step 2** — supporting characters (optional, max 2): name, role, upload 1–2 photos OR pick avatar attributes
6. **Customize step 3** — preview cover (auto-generated based on params), choose price tier (250 or 300 EGP)
7. **Checkout** via Paymob — card / Vodafone Cash / InstaPay
8. **Confirmation**: *"كتابك جاهز خلال ٢٤ ساعة. هنبعتلك على واتساب الرقم: [phone]"*
9. **Background**: pipeline runs, manual approval gate, delivery
10. **Delivery notification** — WhatsApp + email with web reader link + PDF download
11. **View** book in branded web reader (mobile-friendly, RTL Arabic typography)
12. **Optional v1.5**: upgrade to print (+300 EGP)

### 7.2 Admin review flow

1. Backend completes generation, hits Trigger.dev waitpoint
2. Webhook sends notification (push / email) to admin
3. Admin opens `/admin/review-queue`
4. AG Grid table shows pending orders with: customer, theme, generated_at, generation duration
5. Click into order → split-pane view: full story (left) + page-by-page illustrations (right)
6. Read story (~2 min), scan illustrations (~30s each)
7. Click **Approve** → pipeline auto-resumes, delivery triggers
8. OR click **Reject** → modal with structured categories (Religious / Cultural / Age / Pacing / Language / Format / Visual / Other) + free-text note → workflow regenerates
9. Stats dashboard tracks: approval rate by category, common rejection reasons, manual review time per book

### 7.3 Customer regeneration flow

1. Customer receives book, doesn't love it (face match weak, story off-tone, etc.)
2. Within 7 days, clicks "اطلب تعديل" link in delivery email
3. Form: choose reason category + free-text feedback
4. Submission creates `regeneration_requests` row, notifies admin
5. Admin reviews: if valid concern → trigger regen with feedback embedded; if invalid → reply with explanation
6. Regenerated book delivered with note: *"تم تعديل الحدوتة حسب ملاحظاتك"*

---

## 8. Admin Panel Scope (v1)

### 8.1 Must-have features

- **Orders list** — paginated, filterable by status/date, AG Grid
- **Review queue** — books awaiting your approval, sorted by generation time
- **Order detail view** — story preview, image gallery, character details
- **Approve / Reject / Regenerate** action buttons with structured feedback capture
- **Customer support panel** — order lookup by email/phone, regeneration request handling, manual refund (rare)
- **Metrics dashboard** — orders today/week/month, approval rate, regen rate, MTD revenue, validator failure breakdown

### 8.2 Deferred to v1.5+

- Theme management UI (v1: edit `/content/themes/*` files via git, redeploy)
- Validator rule editor (v1: edit JSON in `/content/universal-validators/*` via git)
- Prompt template editor (v1: edit Markdown via git)
- Active learning analytics dashboard (v1: read raw data from Helicone)
- Customer profile / lifetime value tracker
- Marketing dashboard (UTM source attribution)

---

## 9. Tech Stack (locked)

See section 3.2 for full table. Highlights:

- **Two repos**: `hadouta-backend` (Node + Hono) and `hadouta-web` (Next.js 16)
- **Type sync**: OpenAPI generated by `@hono/zod-openapi` → consumed by `openapi-typescript` in frontend
- **AI orchestration**: Vercel AI SDK with `generateObject()` + Zod schemas for type-safe LLM outputs
- **Workflow**: Trigger.dev v3 with waitpoints for the manual approval gate
- **DB**: Neon Postgres + pgvector (scale-to-zero in dev, predictable scaling in prod)
- **Auth**: Better-Auth (free, runs in Hono, stores users in Neon)
- **Storage**: Cloudflare R2 (zero egress, generous free tier)
- **Free dev tier**: every service has free tier sufficient for full development cycle. Only AI usage charges during dev (~$15 free trial credits cover ~30 books)
- **Production fixed cost**: ~$50–80/month at MVP scale + per-book AI usage (~50 EGP)

---

## 10. Cultural & Content Strategy

### 10.1 Theme catalog roadmap

| Theme | Version | Egyptian context |
|---|---|---|
| First Day of School (المدرسة الأولى) | v1 | Universal Sept milestone |
| Eid Al-Adha gift | v1.5 | June 2027 launch |
| New Sibling Welcome (المولود الجديد) | v1.5 | Year-round high demand |
| Birthday (عيد الميلاد) | v1.5 | Year-round |
| Mawlid stories | v2 | Religious-cultural |
| Ramadan adventures | v2 | Annual February-March |
| Quran completion (ختم القرآن) | v2 | Religious milestone |
| Free-form custom (premium) | v2 | Tail-of-demand cases |

### 10.2 Settings library (visual scenes for image prompts)

- Cairo balcony overlooking the city (Maadi, Heliopolis, Zamalek styles)
- Alexandria corniche / Mediterranean sunset
- Nile felucca rides
- Pyramids day trip
- Quran school (كُتّاب) traditional setting
- Modern private school classroom
- Public school classroom (for accessibility to wider audience)
- Mosque (general, age-appropriate)
- Family iftar table during Ramadan
- Eid celebration (sweets, new clothes, family gathering)
- Traditional balad neighborhood (Nasr City, Mansoura, Tanta-style)
- Modern compound / new Cairo style

### 10.3 Character options

- **Skin tones**: fair Egyptian → Mediterranean olive → Upper Egyptian → Nubian
- **Hair**: short / long / curly / straight / wavy; **hijab option** for moms and older girls (multiple styles: simple wrap, modern fashion, traditional)
- **Clothing**: modern Western, traditional galabeya/jellabiya, school uniform, Eid clothes
- **Facial features**: beard option for fathers, mustache option, glasses optional

### 10.4 Story moral frameworks (v1 for FDS theme)

- **Family bonds (الصلة)**: kid feels secure because of family support
- **Respect for elders (احترام الكبار)**: kid greets teacher/headmaster appropriately
- **Bravery without recklessness**: kid is anxious but pushes through with reassurance
- **Honesty (الصدق)**: kid admits when nervous instead of pretending
- **Gratitude (الشكر)**: kid thanks mom and teacher

### 10.5 Language strategy

| Element | Language | Example |
|---|---|---|
| Narration | 100% MSA (الفصحى) | *"استيقظ أحمد في الصباح الباكر، قلبه يخفق بقوة"* |
| Mom/family dialogue | Egyptian Arabic | *"ماما هتجبلك السندوتشات بكره، متخفش يا حبيبي"* |
| Teacher dialogue | MSA | *"أهلاً بك يا أحمد، تفضّل بالجلوس"* |
| Kid's spoken thoughts | Egyptian Arabic (lean) | *"هو ليه قلبي بيدق كده؟"* |

---

## 11. Validator Architecture (detailed)

### 11.1 Layered design

```
                 ┌─ Universal validators (5 parallel) ─────────────┐
[Story output] ──┤  - religious_safety                             │── all pass? ──┐
                 │  - cultural_safety                               │               │
                 │  - age_appropriate                               │               ↓
                 │  - moral_correctness                             │       [theme-specific
                 │  - language_safety                               │        validator]
                 │  - educational_soundness                         │               │
                 │  - visual_safety                                 │               ↓
                 └──────────────────────────────────────────────────┘     [pass → image gen]
                                                                          [fail → regen]
```

### 11.2 Regression test suite

- 100+ hand-crafted test cases stored in `/tests/validator-regression-suite/`
- Each test case: `input.json` (a story) + `expected.json` (which validators should pass/fail)
- Run on every validator prompt change in CI
- Test cases grow organically: every real rejection becomes a new test case

### 11.3 Active learning data pipeline

- Helicone tags every LLM call with custom metadata (order_id, validator_type, decision)
- Helicone Request Datasets aggregates rejections by category
- Embeddings stored in pgvector for similarity search
- Weekly job updates validator few-shot examples from recent rejections
- New validator versions tested against regression suite before deployment

---

## 12. Roadmap

### v1 — September 1, 2026

- Brand: Hadouta (حدوتة)
- One theme: First Day of School
- L3 photo upload + watercolor style (Nano Banana 2)
- 16 pages, kid + up to 2 supporting characters, optional interest tag
- Digital book delivery only (PDF + responsive web reader)
- Manual approval gate (admin reviews every book pre-delivery)
- Single language: Arabic (MSA + Egyptian dialect)
- Admin panel: orders + review queue + metrics
- Pricing: A/B tested, locked at 250 or 300 EGP per ad campaign data

### v1.5 — Q4 2026 / Q1 2027

- **Print upgrade flow** with selected Cairo print partner (signed in week 1 validation)
- **4K image generation** via Nano Banana Pro for print quality
- **Refund/regenerate UX** improvements based on first 3 months of data
- **Validator transitions** to threshold-based auto-approval (manual gate only on borderline scores)
- **2–3 additional themes**: Eid Al-Adha, New Sibling, Birthday
- **Prompt template editor** in admin (eliminates git-edit dependency)
- **Validator rule editor** in admin

### v2 — Q2 2027

- **Free-form custom story** as premium tier (300 EGP digital / +400 EGP print)
- **More themes** (Mawlid, Ramadan, Quran completion)
- **Pixar-quality 3D animation** as luxury image style upgrade (DreamBooth-style fine-tuning)
- **Diaspora market** support: English version, USD pricing, international shipping
- **Multi-character beyond 2** (kid + 4 family members)
- **Possible**: subscription tier ("Family Library" — book per quarter)

---

## 13. Cost Model

### 13.1 Per-book unit economics (300 books/month volume)

| Component | Digital book | Print upgrade (additional) |
|---|---|---|
| AI LLM (Sonnet + Haiku validators) | ~3 EGP | (included) |
| AI images (Nano Banana 2 @ 1K, 17 imgs, 20% retry) | ~45 EGP | +106 EGP (4K via Nano Banana Pro) |
| Payment processing (Paymob 2.75% + 3 EGP) | ~9 EGP | +9 EGP |
| Allocated infrastructure | ~11 EGP | — |
| Print production (Cairo, 100/mo batch) | — | +80 EGP (estimated, validate week 1) |
| Shipping (Bosta intra-Egypt) | — | +60 EGP (estimated, validate week 1) |
| **Total cost** | **~70 EGP** | **+255 EGP additional** |

### 13.2 Margin at A/B-tested pricing

Assuming 30% of digital buyers upgrade to print at launch (post v1.5):

| Scenario | Digital margin | Print margin | Combined contribution per customer |
|---|---|---|---|
| 250 EGP digital / 550 EGP print | ~130 EGP (52%) | ~45 EGP (15%) | ~144 EGP |
| 300 EGP digital / 600 EGP print | ~230 EGP (77%) | ~45 EGP (15%) | ~244 EGP |

### 13.3 Monthly fixed cost

- **During development**: $0 (free tiers across all non-AI services; AI usage on $15 free trial credits)
- **At launch**: ~$50–80/month fixed
  - Trigger.dev: $10
  - Neon: $5–10
  - Railway: $10
  - Helicone: $0 (free 10K req/mo)
  - Resend, Twilio, etc.: $20–30 combined
  - Total: $45–60 + buffer

### 13.4 Break-even and growth targets

- Break-even at mid-tier 250 EGP digital: ~40 books/month
- 50K EGP/month net profit at 300 EGP digital: ~240 books/month
- Stretch target month 6: 500 books/month → ~115K EGP/month net

---

## 14. Risks & Open Questions

### 14.1 Known unknowns (must validate before/during launch)

- **Cairo print shop costs** — actual quotes from 3–5 shops needed week 1
- **Bosta merchant rates** — sign up + confirm in week 1
- **Final pricing** — A/B test result determines 250 vs 300 EGP
- **Egyptian children's writer + illustrator partners** — sourcing in week 3–4
- **Domain availability** — `hadouta.com` first, fall back to `.co` / `.gift` / `.me`
- **Trademark conflicts** — WIPO Global Brand Database search week 1

### 14.2 Risks and mitigations

| Risk | Severity | Mitigation |
|---|---|---|
| EGP/USD volatility | High | Keep 3-month runway in USDT/USD; review pricing quarterly; build 15% EGP-side buffer above raw USD cost |
| Validator quality requires real data | High | Manual approval gate during first 200 books; aggressive feedback capture |
| Hijab AI handling weak | Medium-High | Explicit reference images in prompt; test in week 1 of build |
| Photo upload trust in Egyptian market | Medium-High | Explicit deletion promise; parental consent at upload; "preview without photo" option for hesitant users |
| COD return rates 8–15% | Medium | Card/wallet only for digital; COD only for print (where cost is amortized in shipped book) |
| AI provider outages (Anthropic, fal.ai) | Medium | Documented fallback models in code; queue smoothing via Trigger.dev |
| AI cost spike during traffic peaks | Low-Medium | Prompt caching reduces 70-80% cost; weekly print batching reduces print cost |
| Vendor lock-in (Trigger.dev, Neon, Helicone) | Low-Medium | Document migration paths; avoid vendor-specific features beyond what's portable |
| Competitor enters Egypt (Qessati expansion) | Low | First-mover advantage + cultural moat is hard to replicate quickly |

### 14.3 Items not yet discussed (potential v1.5+ work)

- Legal entity setup in Egypt (sole proprietorship vs LLC)
- VAT registration (Egyptian VAT 14% threshold)
- Terms of Service + Privacy Policy specific text
- Customer support process and SLA
- Disaster recovery beyond Neon's PITR
- Native mobile app vs PWA decision
- Diaspora market expansion details

---

## 15. Validation Plan (parallel with build)

### Week 1–2: Foundation + initial market test

- Stand up minimal landing page (Next.js + Resend signup form) at hadouta.com
- Deploy free dev environment for backend
- Launch Facebook + Instagram ads: 3 creative variants × 3 price tiers (250 / 300 / 350 EGP)
- Begin organic posts in 5–10 Egyptian mom Facebook groups
- Get 3–5 real Cairo print shop quotes
- Sign up for Bosta merchant account; confirm shipping rates
- Domain + trademark + Instagram/TikTok handle locks

### Week 3–4: Optimize + influencer recruitment

- Optimize on best-performing ad creative + price
- Recruit 5–10 nano (<10K followers) and micro (10K–100K) Egyptian mom influencers; offer free sample book (mock-up) + 500 EGP per post for week 5–6 launch
- Continue mom group organic posts (expand to 15 groups)
- Run validator regression test suite as it's built

### Week 5–6: Scale ads + influencer launch

- Influencer posts go live with validated message + creative
- Decide final pricing tier based on conversion data
- Begin commissioning Egyptian children's writer for FDS templates

### Week 7–12: Core build + content production

- Backend AI pipeline complete (story → validators → image gen → assembly)
- Admin panel review queue MVP complete
- Frontend customer ordering flow complete (auth, customization, photo upload, checkout)
- Commission illustrator for 5–10 watercolor reference scenes (~5K EGP)
- Integrate Paymob + Twilio WhatsApp + Resend
- Validator test suite reaches 100+ cases

### Week 13–16: Closed beta

- Generate 100 test books in dev with synthetic personas
- Manually review every book to calibrate validators
- Closed beta with 20 free customers from waitlist
- Fix issues, refine UX
- Decide launch pricing definitively

### Week 17–20: Soft launch

- Paid launch to top 100 waitlist members (limited capacity)
- Manual approval gate active for every book
- Iterate on rejection categories, validator rules
- Customer support process trial-by-fire

### Week 22 (early September 2026): Public launch

- Full public launch with macro influencer push
- Hero ad creative live across Facebook + Instagram + TikTok
- WhatsApp Business API live for notifications
- Press/media outreach to Egyptian parenting blogs/sites

---

## Appendix A — Brand Identity Notes

- **Brand voice**: warm, intimate, motherly. Not commercial. Not techy. Hadouta is a memory-maker, not a software product.
- **Tagline candidates** (test in ads):
  - *"حدوتة طفلك… وهو البطل"* (Your child's bedtime story… and he's the hero)
  - *"كل طفل بطل قصته"* (Every child is the hero of his story)
  - *"الذكرى اللي مش بتتكرر"* (The memory that doesn't repeat itself)
- **Visual direction**: warm watercolor palette (sunset oranges, soft greens, dusty blues); hand-drawn calligraphic logo of حدوتة + Hadouta in Latin underneath
- **Sample-book-as-marketing**: pre-generate 3 demo books with stock-photo "kids" for ad creatives, web reader previews, influencer kits

---

## Appendix B — Open Items Tracker

| Item | Owner | Target week | Status |
|---|---|---|---|
| Domain registration (hadouta.com) | Ahmed | Week 1 | Pending |
| Trademark search (WIPO + Egypt) | Ahmed | Week 1 | Pending |
| Cairo print shop quotes (3–5) | Ahmed | Week 1 | Pending |
| Bosta merchant signup | Ahmed | Week 1 | Pending |
| Egyptian children's writer recruitment | Ahmed | Week 3 | Pending |
| Watercolor illustrator recruitment | Ahmed | Week 3 | Pending |
| Final pricing decision (post A/B test) | Ahmed | Week 4 | Pending |
| Legal entity setup | Ahmed | Week 8 | Pending |
| Terms of Service + Privacy Policy | Ahmed | Week 10 | Pending |

---

*End of design doc.*
