# Replit AI-prototype flow walkthrough — UX patterns to consider

> **Important context (added after initial writeup)**: this is **not a competitor**. It's a quick AI-prototype Ahmed's friend built on Replit from a short prompt. Read the writeup below as **"useful UX patterns surfaced by an AI prototype on a similar problem"** — *not* competitive-research / threat-assessment. The "patterns to AVOID" section reflects engineering quality of an AI quick-prototype, not adversarial framing.

**Date**: 2026-05-02
**Walkthrough by**: Claude (Opus 4.7) via Playwright
**Source URL**: https://hekaya-ai--maslouh0303.replit.app/ (friend's Replit AI-prototype, "حكاية AI" / "Hekaya")
**Purpose**: Surface useful UX patterns for Hadouta order wizard design (Phase 3, Sprint 1)
**Time invested**: ~15 min — full customer flow + admin panel

---

## Executive summary

**Hekaya AI is a Replit-hosted demo of an Arabic personalized children's-book MVP.** Same generic-Arabic-noun naming problem as Hadouta (حكاية means "story"). Currently **non-functional** — customer flow ends in a leaked OpenAI 401 error, all 3 historical orders failed. Public admin panel has zero authentication. Demo-grade execution, not a market-deployed competitor.

**Threat level for Hadouta**: **LOW today, MEDIUM strategic reference.** Hekaya is not in market — but the wizard structure they shipped is a useful starting point because they've already made many of the same UX decisions Hadouta needs to make. Treat as "what the same product would look like if built by a less-rigorous team," and steal what's good while improving what's bad.

**Three patterns worth copying** (with adaptation):

1. **Photo upload OR manual description** — they offer both; description-path lowers conversion friction
2. **Theme × Moral-value × Custom-scene combinatorial structure** — smart product design that yields more personalized output
3. **Age-band tagging on themes** — multi-select age tags per theme; UI filters themes appropriate to entered child age

**Three patterns NOT to copy** — these are signals of immature execution:

1. **Leaking raw provider errors** to the customer (with API key prefix)
2. **No authentication on admin panel** (publicly accessible at /admin/orders)
3. **No payment, no signup, no auth** — they have no business model wired in; this is pure tech-demo, not product

**Three openings for Hadouta's positioning** vs. Hekaya:

1. **Religion-neutral positioning** — Hekaya only offers Muslim holidays (Eid, Ramadan). No Christmas, Easter, Sham El-Nessim, Coptic feasts. Hadouta's pan-Egyptian brand brief is genuinely differentiated.
2. **Egyptian-specific cultural rooting** — Hekaya's "clothing style" includes "Gulf traditional" and "Egyptian traditional" as peer options, signaling pan-Arab generic positioning. Hadouta's Egyptian-only stance per ADR-002 is sharper.
3. **Family-warmth supporting characters vs. animal-sidekicks** — Hekaya's "fictional characters" are lion/rabbit/parrot/turtle (Western-Disney-coded). Hadouta's supporting characters are real siblings/friends/family — operationalizes the Storyteller / teta-warmth archetype.

---

## Customer flow — all 5 steps documented

Screenshots in `screenshots/` directory.

### Landing page (`/`)
- Brand: حكاية AI
- Hero: "اجعل طفلك بطل قصته الخاصة"
- Sub: "حكاية تصنع كتاباً مخصصاً لطفلك — قصة مكتوبة بالعربي بالكامل، رسوم احترافية، وطفلك هو البطل. في دقائق."
- Primary CTA: "ابدأ إنشاء كتابك — مجاناً"
- Sub-CTA: "لا يحتاج تسجيل · جاهز في 5 دقائق"
- Three sample-book cards (animal-companion themed: lion-courage, butterfly-friendship, star-perseverance)
- "كيف يعمل؟" section: 3 steps (tell us about your child → AI creates → print & gift)
- "لماذا حكاية؟": 6 features (photo in book, Arabic+English, watercolor/semi-real/photoreal styles, educational values, ready in minutes, child-safe)
- **No pricing visible** — pure free-conversion play
- Bottom CTA banner: "قصة يطلب طفلك سماعها مرة بعد مرة"
- Footer: minimal

### Step 1 of 5 — معلومات الطلب (Order info) `/create`
**Asks the buyer about themselves and structural choices.**
- اسمك الكامل (Your full name) — required text
- عدد الصفحات (Page count) — 4 button options: 5 / 10 / 15 / 20 (default: 10)
- الفئة العمرية (Age group) — 4 buttons: 0-2 / 3-5 / 6-9 / 10+ (default: 3-5)
- لغة الكتاب (Book language) — Arabic / English (default: Arabic)
- أسلوب الرسوم (Illustration style) — 3 buttons: كرتون ألوان مائية / شبه واقعي / واقعي
- حجم الكتاب (Book size) — 4 buttons: A5 / A4 / Square / US Letter (default: A4)

**Note**: Hekaya lets users pick page count, illustration style, and book size — Hadouta's MVP locks all three (16 pages, watercolor, fixed size per ADR-005). Hekaya is more flexible-but-decision-heavy; Hadouta is locked-but-simpler. Both are defensible.

### Step 2 of 5 — معلومات الطفل (Child info)
**No photo upload here.** Character built from text fields only.
- اسم الطفل (Child name) — required text
- العمر (Age) — required number/spinner (separate from the age-band picked in step 1)
- الجنس (Gender) — 2 buttons: ولد / بنت (boy / girl). No third option.
- الهوايات (Hobbies) — free-text, placeholder: "الرسم، كرة القدم، القراءة"
- الطعام المفضل (Favorite food) — free-text, placeholder: "الشاورما، الكنافة"
- اللون المفضل (Favorite color) — free-text, placeholder: "الأزرق، البنفسجي"
- مميزات خاصة (Special characteristics) — textarea, "أي شيء مميز يعرف عنه الطفل..."

### Step 3 of 5 — مظهر الطفل (Child appearance) **← CRITICAL FINDING**
**Photo upload OR manual description — both supported.**

**Photo upload** (labeled "اختياري — موصى به" / Optional — recommended):
- Up to 3 images (JPG/PNG/WEBP), 5MB each
- Subtitle: "الذكاء الاصطناعي سيستخدم الصور لرسم وجه طفلك في كل صفحة"
- Drag-and-drop area + click-to-select

**Separator: "أو صف مظهر الطفل يدوياً" (Or describe the child's appearance manually)**

**Manual-description fallback:**
- لون البشرة (Skin tone) — **6 visual color swatches** (dark to light brown). Visual picker, not free-text.
- وصف الشعر (Hair description) — free-text, placeholder: "شعر قصير بني، شعر مجعد أسود..."
- طريقة اللباس (Clothing style) — 5 buttons: عصري (Modern) / تقليدي مصري (Egyptian traditional) / تقليدي خليجي (Gulf traditional) / زي مدرسي (School uniform) / مخصص (Custom)

**Strategic implications for Hadouta**:
- The photo-OR-description fork is *the most important UX pattern in this whole flow.* Hadouta's ADR-005 currently presumes photo upload; consider whether to add a description-only fallback for parents who don't want to upload child photos (privacy concern, no good photo on hand, etc.).
- The visual skin-tone color swatches are a smart pattern — much faster than verbal description.
- The clothing-style picker including BOTH Egyptian-traditional and Gulf-traditional confirms regional positioning matters in this market. Hadouta could simplify to Egyptian-only options + "Modern" + "School uniform" + "Custom".

### Step 4 of 5 — تفاصيل القصة (Story details)
**Theme × moral-value × custom-scene combinatorial structure.**

**موضوع القصة (Story theme) — 7 themes**:
1. أول يوم في المدرسة (First day at school)
2. الصداقة (Friendship)
3. أخ أو أخت جديدة (New sibling)
4. العيد (Eid) ← Muslim
5. رمضان (Ramadan) ← Muslim
6. الخوف من الظلام (Fear of the dark)
7. يوم في المزرعة (Day on the farm)

(Admin panel reveals more — see Theme catalog section below — including "The Big Adventure" not shown in customer UI.)

**القيمة التربوية (Educational value/moral) — 8 values**:
1. الشجاعة (Courage)
2. الأمانة (Honesty)
3. الكرم (Generosity)
4. احترام الكبار (Respect for Elders) ← culturally-specific
5. المثابرة (Perseverance)
6. اللطف (Kindness)
7. التعاون (Cooperation)
8. الصبر (Patience)

**Free-text:**
- مناسبة خاصة (Special occasion) — text, placeholder: "عيد ميلاد، نجاح مدرسي، العيد..."
- مشهد خاص تريده في القصة (Special scene you want) — textarea, placeholder: "مثلاً: مشهد حيث يتغلب الطفل على خوفه من الماء..."

**Strategic implications for Hadouta**:
- The theme×value combinatorial pattern is genuinely smart — yields a more personalized story than just picking a theme. **Adopt this pattern.**
- The "احترام الكبار" (Respect for elders) value is culturally specific to MENA — keep in Hadouta.
- The "special scene" free-text gives parent agency to inject specific personal moment — consider for Hadouta wizard.
- The Muslim-only holiday lineup is a competitive opening: Hadouta's pan-Egyptian themes (Christmas, Easter, Sham El-Nessim, Coptic feasts in addition to Eid/Ramadan) are differentiated.

### Step 5 of 5 — مراجعة الطلب (Order review)
**Summary table + one extra optional field + final CTA.**
- Read-only table listing every collected value
- إهداء (Dedication) — optional textarea, "أكتب إهداءً يظهر في بداية الكتاب..."
- Info banner: "بعد الضغط على 'ابدأ الإنشاء' سيبدأ الذكاء الاصطناعي في إنشاء قصة مخصصة وصور احترافية. العملية تستغرق 2-5 دقائق."
- Final CTA: "ابدأ الإنشاء"

**No phone, email, login, or payment collected anywhere.** This is a pure free demo.

### Generating screen `/create/generating/{order_id}`
- **Failed in production with raw OpenAI 401 error displayed to user**:
  > Error: 401 Incorrect API key provided: sk-proj-************...SH8A. You can find your API key at https://platform.openai.com/account/api-keys.
- Two options shown: إعادة المحاولة (Retry) / إنشاء طلب جديد (New order)
- The order *is* persisted with status=Failed (visible in admin panel)

### What we never see (because the API key is dead)
- Generated book preview UI
- Page-by-page navigation
- PDF download flow
- Any post-purchase or post-generation UX

---

## Admin panel intel — `/admin/*`

**Critical security observation: the admin panel has zero authentication.** Anyone can navigate from the public landing → "لوحة التحكم" button → see all orders, edit themes, view API key UI, etc. Customer PII (names, child names) is publicly visible.

### Inferred data model from nav

| Admin section | URL | Likely table/concept |
|---|---|---|
| Orders | `/admin/orders` | `orders` |
| Analytics | `/admin/analytics` | aggregate views |
| API Keys | `/admin/api-keys` | provider credentials (UI-managed, not env-var) |
| AI Models | `/admin/settings` | model selection per task |
| Story Skill | `/admin/prompts` | prompt templates |
| Themes | `/admin/themes` | `themes` |
| Moral Values | `/admin/moral-values` | `moral_values` |
| Characters | `/admin/fictional-characters` | `fictional_characters` (pre-made AI companions) |

Hadouta's planned tables (from current Drizzle schema): users, sessions, accounts, verifications, waitlist_signups, themes, orders. Hekaya's nav suggests they also have moral_values + fictional_characters as catalog tables — **a pattern worth considering for Hadouta's content schema.**

### Orders observed (3 total, all Failed)
- #1 — نوح for نوح — 5/2/2026 3:36 PM — Failed
- #2 — محمد for مها — 5/2/2026 5:42 PM — Failed
- #3 — أحمد محمد for ليلى — 5/2/2026 6:51 PM — Failed (the order created during this research)

Empty product. The demo has zero working orders ever. Hadouta is not behind.

### Theme catalog (admin)
Each theme has Arabic + English name, description, **age-band multi-select tags**, active status.

| Theme (AR) | Theme (EN) | Age tags |
|---|---|---|
| أول يوم في المدرسة | First Day at School | 3-5, 6-9 |
| الصداقة | Friendship | 3-5, 6-9, 10+ |
| المغامرة الكبيرة | The Big Adventure | 6-9, 10+ |
| أخ أو أخت جديدة | New Baby Sibling | 3-5, 6-9 |
| العيد | Eid Celebration | 0-2, 3-5, 6-9 |
| رمضان | Ramadan | 3-5, 6-9, 10+ |
| الخوف من الظلام | Fear of the Dark | 3-5 |

(More themes likely below the fold; not all visible in the screenshot.)

**Smart pattern**: age-band tags filter which themes show up in the customer wizard based on the age-band selection in step 1. Adopt for Hadouta.

### Fictional Characters catalog
Pre-defined AI companion characters that get inserted into stories alongside the child:

| Character (AR) | Character (EN) | Description |
|---|---|---|
| الأسد الشجاع | The Brave Lion | "A majestic golden lion with a warm, friendly smile, wearing a small crown, child-friendly and approachable" |
| الأرنب الذكي | The Smart Rabbit | "A clever white rabbit with large bright eyes, wearing small round spectacles, always holding a book" |
| الببغاء الملون | The Colorful Parrot | "A vibrant parrot with red, blue, and green feathers, always cheerful and singing" |
| السلحفاة الحكيمة | The Wise Turtle | "An ancient wise turtle with a beautifully patterned shell, gentle smile, speaks slowly and thoughtfully" |

**Strategic implications**:
- This is a genuinely different product decision than Hadouta's. Hekaya inserts a *fictional animal companion* into every book. Hadouta plans to let customer add *real* supporting characters (sibling, friend, family).
- Hekaya's choice reads as Western-Disney-sidekick-coded.
- Hadouta's choice reads as Egyptian-family-warmth-coded — operationalizes the Storyteller / teta archetype better.
- **Don't copy this pattern.** Hadouta's decision is more aligned with brand brief.

---

## Strategic findings — implications for Hadouta wizard design

### Patterns to ADOPT (with adaptation)

1. **Photo upload OR manual description fallback (step 3)** ← biggest finding
   - Lower-friction path for privacy-concerned parents
   - Visual skin-tone color swatches (not free-text)
   - Hair: free-text
   - Clothing: button picker (simplify to Egyptian-only options + "Modern" + "School uniform" + "Custom")

2. **Theme × Moral-value × Custom-scene combinatorial structure (step 4)**
   - More personalized story output than theme-alone
   - Add "احترام الكبار" (Respect for elders) to Hadouta's value list
   - Custom-scene free-text gives parent agency

3. **Age-band tags on themes**
   - Themes are tagged with which age bands they're appropriate for
   - Wizard filters theme list based on age selection
   - Smart product design

4. **Order review summary table + optional dedication field (step 5)**
   - Standard pattern; works.
   - Dedication ("إهداء") is a great low-cost personalization

5. **Visual stepper at top of wizard with step names**
   - 5-step indicator: الطلب · الطفل · المظهر · القصة · المراجعة
   - Each step has an icon + label + checkmark when completed
   - Standard pattern; copy directly

### Patterns to AVOID

1. **Public admin panel (no auth)** — security failure. Hadouta uses Better-Auth from day 1 (per ADR-018).
2. **Leaking raw provider errors to customer** — Storyteller-voice violation (per Hadouta brand brief). Use the `step-out-of-story` rule for failures.
3. **API keys managed via admin UI** — Hadouta uses env vars + secrets-via-stdin (per memory).
4. **Pre-defined fictional animal-companion characters** — Western-Disney-coded; doesn't match Hadouta brand register.
5. **Letting users pick illustration style at order time** — Hadouta MVP is watercolor-only per ADR-005 (multi-style ready architecturally per ADR-019, but not exposed to customers in MVP).
6. **Free demo with no business model** — Hadouta is a real revenue-generating business per ADR-001.
7. **Pan-Arab positioning with Gulf-and-Egyptian as peer clothing options** — Hadouta is Egyptian-specific per ADR-002.
8. **Muslim-only holiday lineup** — Hadouta's pan-Egyptian religion-neutral chrome (per brand brief) includes Christmas, Easter, Sham El-Nessim, Coptic feasts.

### Hadouta wizard structure decisions informed by this research

Based on Hekaya's flow + Hadouta's master design spec §7.1 + ADR-005 + ADR-018 + brand brief:

**Recommended Hadouta wizard structure (5 steps + checkout + confirmation):**

1. **معلومات الكتاب (Book info)** — buyer name + age band only (lock page count, style, size to MVP defaults; expose later via ADR-019 multi-style)
2. **معلومات الطفل (Child info)** — name, age (number), gender, hobbies, fav food, fav color, special characteristics (mostly matches Hekaya step 2)
3. **مظهر الطفل (Child appearance)** — photo upload (1-3 photos per ADR-005) OR description fallback (skin-tone swatch picker, hair free-text, clothing buttons — Egyptian-only options)
4. **القصة + الموضوع (Story + theme)** — theme picker (age-band-filtered, includes Christmas/Easter/Sham El-Nessim per brand brief) × moral value × optional special-occasion text × optional special-scene text
5. **شخصيات الدعم (Supporting characters)** — Hadouta-specific: optional siblings/friends/family (max 2), each with name + role + photo OR description (per ADR-005 master design spec §7.1 step 5)
6. **مراجعة + إهداء (Review + dedication)** — read-only summary, optional dedication textarea, final CTA "ابدأ حدوتة طفلك"
7. **Checkout** — phone-first OTP (per ADR-018) + Paymob payment + price tier (250 vs 300 EGP per ADR-014 A/B test)
8. **Confirmation** — Storyteller-voice "حكايتك بدأت" (per brand brief voice example sheet)

That's 8 steps total but only 6 are "design" steps (1-6); checkout and confirmation are mostly transactional.

**Open questions for the next brainstorming round:**

- Do we keep 5 design steps + checkout, or fold steps 1+6 together to reduce friction?
- How does OTP fit in? At checkout, or before the wizard starts (eager auth)? ADR-018 implies invisible accounts at checkout — confirm.
- Photo-OR-description fork in step 3: is description-only the same price tier, or do we charge less since AI face-matching is the harder lift?
- Do we expose all 7+ themes at age-band-filtered list, or feature 3 hero themes + "more" link?
- Do we let parents skip step 5 (supporting characters) entirely or make it required?

---

## Useful artifacts

- `screenshots/01-landing.png` — full landing
- `screenshots/02-wizard-step1.png` — order info step
- `screenshots/03-wizard-step2-child.png` — child info step
- `screenshots/04-wizard-step3-appearance.png` — photo upload OR description fork ← critical
- `screenshots/05-wizard-step4-story.png` — theme + moral + custom-scene step
- `screenshots/06-wizard-step5-review.png` — order review + dedication
- `screenshots/07-generating.png` — leaked OpenAI 401 error
- `screenshots/08-dashboard.png` — admin orders panel (no auth)
- `screenshots/09-admin-themes.png` — theme catalog with age-band tags
- `screenshots/10-admin-characters.png` — fictional-companion catalog

---

**Bottom line for Phase 3 wizard design**: Hekaya gave us free product validation on most of the wizard's structural decisions. Their flow is more comprehensive than the master-design-spec §7.1 anticipated. Steal: photo-OR-description, theme×value combinatorial, age-band tags, dedication field, visual stepper. Improve: failure UX (use Storyteller's step-out-of-story rule), auth (real OTP gate), error sanitization, admin auth, Egyptian cultural specificity, religion-neutral theme lineup. Skip: animal-companion characters, pan-Arab positioning, pick-your-style-at-order-time.
