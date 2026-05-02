# Hadouta Phase 3 design spec — landing + order wizard

**Date**: 2026-05-02
**Phase**: Phase 3 (screen design) of brand-brief sequence (Phase 1 brief → Phase 2 tokens → Phase 3 designs → Phase 4 review → Phase 5 implementation)
**Sprint**: Sprint 1 — Foundation (Track A)
**Status**: ✅ design decisions locked across landing + wizard; ready for Phase 5 implementation planning
**Scope authority**: this spec is the source of truth for all wireframe-level design decisions on landing + order wizard. Visual polish (real watercolor illustrations, real motifs, real team photos) and Phase 5 sub-section visuals are flagged inline as deferred — to be resolved during code build.

---

## Related documents

| Doc | Relationship |
|---|---|
| `docs/design/brand-brief.md` (v1.1+) | Brand foundation — palette, typography, voice, anti-mood. Every wireframe decision in this spec inherits from the brief. |
| `docs/design/2026-05-02-wizard-design-decisions.md` | The 3 upstream structural decisions (photo-OR-description / theme combinatorial / age-band tagging) that this spec operationalizes. |
| `docs/design/competitive-research/2026-05-02-hekaya-ai/findings.md` | Walkthrough of an AI-prototype on a similar problem. Surfaced the 3 upstream decisions above. (Note: not a competitor — a friend's Replit AI-prototype.) |
| `docs/design/2026-04-30-hadouta-design.md` | Master design spec §7.1 customer ordering flow — wizard structure originally specified here; this spec extends/refines it. |
| ADR-005, ADR-013, ADR-018, ADR-014, ADR-002 | Locked architectural decisions referenced throughout this spec. |
| `hadouta-web/src/app/globals.css` | Phase 2 design tokens — every visual decision below renders against this token set. |
| `.superpowers/brainstorm/<session>/content/*.html` | The actual wireframe HTML files (gitignored, scratch artifacts). Listed in "Visual artifacts" section at the end. |

---

## Executive summary — what was locked

This session locked **8 distinct design surfaces** through brainstorming + visual companion wireframing:

1. **Landing page hero** — Option A (illustration-right RTL eye-start, headline + CTA on left)
2. **Landing page section rhythm** — Option C (Story-first: Hero → Storyteller setup → Sample preview → How-it-works → Theme gallery → Trust band w/ team photos → Pricing → FAQ → Footer)
3. **Wizard structural fork — photo OR description** (Decision 1 from upstream): parallel paths, single price tier, switch-mid-step allowed
4. **Wizard story input combinatorial** (Decision 2 from upstream): Theme + Moral Value (both required) + Custom Scene + Special Occasion (both optional)
5. **Wizard age-band tagging on themes** (Decision 3 from upstream): overlapping bands `3-5` / `5-7` / `6-8`; band picker in step 1 + exact-age spinner; theme catalog filtered by band
6. **Wizard structure** — Option A (5 design steps + checkout + confirmation = 7 stops total)
7. **Wizard step 1-7 layouts** — all Option A across the board (Ahmed picked the recommended path consistently)
8. **AI-honesty / quiet-middle-path copy** — applied across all customer-facing surfaces; brand brief amended to capture this principle

---

## Brand foundation reference (no changes; recap for context)

### Palette (from `globals.css`)
- `--hadouta-cream` `#FBF5E8` — warm cream base, yellow undertone (NEVER cool/blue)
- `--hadouta-terracotta` `#C56B47` — primary CTA + warm accent
- `--hadouta-ochre` `#D4A24C` — secondary warm + checkout band
- `--hadouta-teal` `#2A6F75` — cool accent (5-10% visual weight max) + confirmation/secondary
- `--hadouta-brown` `#3D2817` — primary text + gravitas
- `--hadouta-blush` `#E8B7A0` — soft kid-magic accent
- WCAG AA verified: brown-on-cream 12.6:1 (AAA), cream-on-terracotta 5.0:1 (AA Large), brown-on-blush 9.5:1 (AAA)

### Typography (from `globals.css`)
- Tajawal — body & UI (`--font-sans`)
- El Messiri — section/page headers (`--font-heading`); Egyptian-designed letterforms
- Aref Ruqaa — decorative/kid-magic moments + logotype only (`--font-display`); **rule: max one per page**
- Fraunces — Latin companion when needed (`--font-latin`)

### Spacing scale (from `globals.css`)
- `--radius-tight` 4px — chips, badges
- `--radius-lg` 8px — buttons, inputs, base
- `--radius-xl` 16px — cards, larger surfaces
- `--radius-2xl` 24px — modals, sheets, hero panels
- `--motion-quick` 200ms — button hover, micro-interactions
- `--motion-paced` 400ms — modal/drawer/section reveal
- `--motion-page` 600ms — page-turn-feel state transitions

### Brand-honesty rule (NEW — from brand brief amendment 2026-05-02)
**Customer-facing copy** must NOT claim hand-painted/manually-written, must NOT lead with "AI generated" either; **lead with**: Egyptian human review, Egyptian writers/illustrators behind the templates, 2-3 day care + craft window. Test: would an Egyptian parent who reads this and later learns AI is involved feel deceived? If yes → revise.

---

## Upstream structural decisions (already documented in `docs/design/2026-05-02-wizard-design-decisions.md`)

This spec assumes those 3 decisions are locked. Brief recap:

### Decision 1 — Photo-OR-description fork (extends ADR-005)
- Parallel paths in step 3 of the wizard
- Photo path: 1-3 images, AI face-matching, watercolor portrait
- Description path: skin-tone color swatches (6) + hair free-text + clothing buttons (Modern / Egyptian Traditional / School Uniform / Custom — Gulf-Traditional dropped) + optional eye color
- Single price tier (no description-cheaper play in MVP); revisit in v1.5+ from funnel data
- Switch-path mid-step allowed via in-step toggle

### Decision 2 — Theme × Moral Value × Custom Scene × Optional Occasion
- Theme: required, FK to `themes` table, button grid (age-band-filtered)
- Moral value: required, FK to **new** `moral_values` table, single-select button grid
- Custom scene: optional, free-text textarea
- Special occasion: optional, free-text input

Initial moral_values catalog: الشجاعة / الأمانة / الكرم / **احترام الكبار** / المثابرة / اللطف / التعاون / الصبر (8 values; احترام الكبار kept as Egyptian-cultural anchor).

### Decision 3 — Age-band tagging
- 3 overlapping bands: `3-5` / `5-7` / `6-8` (brand brief H2 caps target at 3-8)
- `themes.suitable_age_bands` text[] — themes can match 1-3 bands
- Wizard step 1: age-band picker (3 buttons) + exact age spinner (3-8)
- Theme step 4 filters: a theme shows if any of its tagged bands matches the picked band
- Architectural-from-day-one: AI prompt template can use band as narrative-complexity tier later (no schema retrofit needed)

---

## Landing page design

### Hero (locked: Option A — illustration-right, text-left)

**Structure:**
```
[Cream section, full width]
┌─────────────────────────────────────────────────┐
│ [Logo: حدوتة] Aref Ruqaa, top-right           │  ← nav strip, slim
│ [Nav links: شوف نموذج · ابدأ] top-left        │
├─────────────────────────────────────────────────┤
│  ┌──────────────────┐  حدوتة لطفلك،           │
│  │                  │  من قلب مصر               │  ← El Messiri H1
│  │  Hero            │                            │
│  │  Watercolor      │  كتاب مخصص بعناية لطفلك،│  ← Tajawal sub
│  │  illustration    │  جاهز في ٢-٣ أيام         │
│  │  (60% width)     │                            │
│  │                  │  [ابدأ حدوتة طفلك]        │  ← Terracotta CTA
│  └──────────────────┘                            │
│                                                   │
└─────────────────────────────────────────────────┘
```

**Copy** (revised to AI-honesty middle path):
- H1: **"حدوتة لطفلك، من قلب مصر"** (locked from brand brief voice example sheet)
- Sub: **"كتاب مخصص بعناية لطفلك، جاهز في ٢-٣ أيام"** (revised from the dropped "كتاب مرسوم باليد")
- Primary CTA: **"ابدأ حدوتة طفلك"** (locked)

**Why hero option A:** RTL-natural eye-flow (Arabic readers' eye lands on right-side illustration first, then drops to text), illustration is the trust signal (sets watercolor expectation immediately), closest to brand-brief reference site (~75% match), avoids "fancy not warm" risk of full-bleed cinematic option.

**Hero illustration brief** (for Phase 5 production):
- Egyptian teta + child kitchen scene, watercolor style
- Soft brush wash on body shapes, dot-eyes (NOT Disney-Junior big-eyes)
- Egyptian skin tones, pan-Egyptian costume (galabeya + tarha generic enough for Cairo Muslim / Coptic / coastal)
- Generic Cairo skyline silhouette in window — NO pyramids, NO sphinx; one tiny dome OK (deliberately religion-ambiguous)
- Embroidered cloth with tatreez-edge, mint sprig in teal
- 4% paper-grain noise overlay on cream base
- 8% Coptic-Islamic-folk shared-rosette motif corner (top-left)
- Hand-drawn underline (wobbly brush stroke) under "مصر" in headline

### Section rhythm (locked: Option C — Story-first)

**Sequence (top to bottom):**

| # | Section | Band color | Required content |
|---|---|---|---|
| 1 | Hero (above) | cream | locked above |
| 2 | Storyteller setup | cream-tinted | "كل حدوتة بتبدأ بطفل…" — short paragraph in voice register, sets emotional frame before any product details |
| 3 | Sample preview | terracotta-tinted band | 2-3 sample book pages (real or placeholder), placeholder name "أحمد" |
| 4 | How it works | cream | 4-step explainer per ADR-013 + master design spec §7.1: صورة → موضوع → AI ترسم → مراجعة بشرية مصرية → كتاب طفلك. **Honest framing** — "AI ترسم" is fine here (in context of the production-step explainer; not as the brand headline) |
| 5 | Theme gallery | ochre-tinted band | 6-8 sample themes from catalog (religion-neutral: Eid + Christmas + Easter + Sham El-Nessim + first-day-school + birthday + friendship + adventure) |
| 6 | **Trust band** | teal-tinted band | **Three-part claim** (revised honest copy):<br/>1. "كتّاب ورسامين مصريين بيصمموا قوالب حكاياتنا"<br/>2. "كل حدوتة بنراجعها بدقة قبل ما توصلك"<br/>3. "حدوتتك جاهزة في ٢-٣ أيام — مش دقائق"<br/>Visual: photos of Egyptian team members where available (Track B — Ahmed sources) |
| 7 | Pricing | cream | Single price tier 250 EGP (per ADR-014 A/B test default); pricing-band as warm visual block |
| 8 | FAQ | cream | 4-6 standard questions (deferred to Phase 5 — derive from common support questions) |
| 9 | Footer | cream-tinted | Standard pattern; deferred to Phase 5 |

**Why section rhythm option C (Story-first with team-photo trust band):**
- Most Storyteller-voice expression — uses voice as the through-line
- Trust band gets photos of real Egyptian team members → lands as proof, not claim
- Cultural-specificity moat (ADR-002 + ADR-013) gets visible operational backing
- The Storyteller setup paragraph between hero and preview frames emotional tone before product details

**Execution risk flagged:** Story-first requires (a) a strong Storyteller paragraph between hero and preview, (b) actual photos of the Egyptian team (writers, illustrators, reviewers) for trust band, (c) the team-photos workstream is Track B (Ahmed-driven) — until photos exist, trust band uses watercolor placeholder + team names.

### Deferred landing page sub-section visuals (Phase 5)

Per the brainstorming session's path-B choice (move to wizard early), these landing sub-sections were not wireframed but their structural slots are locked:

| Sub-section | What's locked | What's deferred |
|---|---|---|
| Storyteller setup (#2) | Section position + voice direction | Exact paragraph copy (Phase 6 brand statements) + visual treatment |
| Sample preview (#3) | Position + role | Mini book viewer vs. static page-spread image vs. video — Phase 5 |
| How it works (#4) | 4-step list per ADR-013 | Visual treatment (numbered cards vs. horizontal timeline vs. hand-drawn arrows) — Phase 5 |
| Theme gallery (#5) | Position + 6-8 themes | Card visual treatment + grid vs. carousel — Phase 5 |
| Trust band (#6) | Position + 3-part claim copy | Team-photo collage vs. founder quote+photo — depends on Track B photo sourcing |
| Pricing (#7) | Single 250 EGP card | Card visual treatment — Phase 5 |
| FAQ (#8) | Standard pattern (accordion) | Question list — derive from support data |
| Footer (#9) | Standard pattern | Phase 5 |

---

## Order wizard design

### Wizard structure (locked: Option A — 5 design steps + checkout + confirmation)

```
[Stepper at top of every step]
١ طفلك  →  ٢ الصورة  →  ٣ العائلة  →  ٤ الحدوتة  →  ٥ مراجعة  →  ٦ الدفع  →  ٧ تم
(design steps in terracotta when active, teal-checkmarked when done; checkout in ochre; confirmation in teal)
```

**Why option A (5 design + 2 transactional):**
- Each step has a single emotional theme — Storyteller-voice friendly
- Supporting-characters as separate step makes "skip" obvious (most parents won't add)
- 7 stops total reads as manageable
- Maps cleanly to master-design-spec §7.1 customer ordering flow

### Step 1 — أخبرنا عن طفلك (locked: Option A — conversational, all enrichment visible)

**Layout:**
```
[Stepper showing step 1 active]
[Step title El Messiri H2: أخبرنا عن بطل الحدوتة]
[Step intro with Storyteller mark: "كل حدوتة بتبدأ بطفل. عرّفنا عن طفلك ونحن نبني له قصته."]

[Field: اسم الطفل *] [Tajawal text input]

[2-col row]
  [Field: الفئة العمرية *] [3-button: ٣-٥ / ٥-٧ / ٦-٨]
  [Field: العمر *] [number spinner 3-8]

[Field: الجنس *] [2-button grid: 👧 بنت / 👦 ولد]

[Field: هوايات طفلك (optional)] [text input with Egyptian placeholder]

[2-col row]
  [Field: أكلة مفضلة (optional)] [text input — placeholder: "الكنافة..."]
  [Field: لون مفضل (optional)] [text input — placeholder: "الأزرق..."]

[Field: حاجة مميزة عن طفلك (optional)] [textarea]

[Delivery info strip — separate visual zone, teal-tinted]
[Field: اسمك (ولي الأمر) *] [text input]

[Nav row: ← الرئيسية  /  التالي →]
```

**Required fields (4):** اسم الطفل + الفئة العمرية + العمر + الجنس + اسمك (parent)
**Optional fields (4):** الهوايات + الأكل + اللون + الحاجة المميزة

**Why option A:**
- Storyteller-voice consistent — child is the subject of the conversation
- All fields visible upfront — no hidden affordances, predictable UX
- Parent name in delivery strip at bottom — emotionally secondary (it's for WhatsApp delivery, not story content)
- Optional enrichment visible by default — parents who fill these get richer AI output; hiding them risks blander output

**Implementation notes:**
- Age band picked here filters theme catalog in step 4 (`suitable_age_bands` column on themes)
- Exact age used in story copy ("Layla turns 5 today…") and AI narrative-complexity tier
- All optional enrichment fields populate `child_profile` JSON or similar on `orders` table — used as AI prompt input
- Buyer name → `orders.buyer_name` for WhatsApp greeting + dedication ("a gift from {{buyer_name}}")

### Step 2 — صورة طفلك (locked: Option A path picker + both paths approved)

**Path picker (initial state):**
```
[Stepper: step 1 ✓, step 2 active]
[Step title: صورة طفلك في الكتاب]
[Step intro: "إزاي عاوز ليلى تظهر في الرسومات؟ في طريقتين، اختار اللي يريحك:"]

[Two side-by-side cards — equal weight]
┌─────────────────┐  ┌─────────────────┐
│ [الأكثر شيوعاً] │  │                 │
│ [📷 illust]     │  │ [✎ illust]      │
│ ارفع صور طفلك  │  │ اوصف طفلك      │
│ ١-٣ صور...     │  │ بدلاً من ذلك   │
└─────────────────┘  └─────────────────┘

[Nav: ← السابق / التالي →]
```

**Why option A path picker:**
- Both paths presented as peers — operationalizes brand stance "we serve privacy-conscious families equally"
- "الأكثر شيوعاً" tag on photo card guides majority without making description feel lesser
- Clicking a card commits to that path and expands inline (no separate sub-step)

**Photo path expanded** (after parent clicks photo card):
```
[Step title with path tag: 📷 طريقة الصور  صورة طفلك]
[Switch bar (teal, dashed): "اخترت طريقة الصور. ↻ تحويل لطريقة الوصف"]

[3-cell thumbnail strip — uploaded photos with ✕ delete button per cell, empty slots show +]
[Drag-drop zone: "ضيف صورة تانية" + "أو افتح الكاميرا 📸"]
[Tip box (ochre-tinted, right border): "للحصول على أفضل نتيجة: صور بضوء نهار، الوجه واضح، خلفية مش مزدحمة. ٢-٣ صور أفضل من واحدة."]

[Nav: ← السابق / التالي →]
```

**Description path expanded** (after parent clicks description card):
```
[Step title with path tag: ✎ طريقة الوصف  اوصف طفلك]
[Switch bar (teal, dashed): "اخترت طريقة الوصف. ↻ تحويل لرفع صور"]

[Field: لون البشرة *] [6-swatch row: dark to light brown circles]
[Field: وصف الشعر *] [text input with Egyptian placeholder: "شعر طويل أسود، شعر قصير بني مجعد..."]
[Field: طريقة اللباس *]
  [4-button grid: عصري / تقليدي مصري / زي مدرسي / مخصص]
[Field: لون العيون (optional)] [text input — placeholder: "بني، أخضر، أزرق..."]

[Nav: ← السابق / التالي →]
```

**Implementation notes:**
- Schema: `orders.appearance_input_type` enum ('photo' | 'description')
- Photo path: writes to `photos` table (FK to orders), AI face-matching pipeline downstream
- Description path: `orders.description_skin_tone` (text — color hex from swatch) + `description_hair` (text) + `description_clothing_style` (enum: modern / egyptian_traditional / school_uniform / custom) + `description_eye_color` (text, nullable)
- Switch-path link: client-side state preserved in wizard store; switching does NOT clear filled fields (parent can switch back without losing data)
- Photo upload: 5MB limit per file, JPG/PNG/WEBP accepted, HEIC iPhone format supported via client-side conversion (Phase 5 implementation detail)
- Face-detection failure UX: surface "we couldn't detect a face — try a different photo or switch to description" toast — Phase 5 detail

**Sub-decisions deferred to Phase 5:**
- Hair: structured picker (length + color + texture) vs. free-text — current spec is free-text; revisit if AI prompt output quality suffers
- Clothing "Custom" sub-picker — does it expand to a free-text input, or open a modal? Phase 5
- Photo upload progressive enhancement (mobile camera direct, multi-file drag, EXIF rotation handling) — Phase 5

### Step 3 — العائلة في الحدوتة (locked: Option A — invitation card + explicit skip)

**Layout:**
```
[Stepper: steps 1-2 ✓, step 3 active]
[Step title: حد تاني في الحدوتة؟]
[Step intro: "حدوتة ليلى هتكون عنها أساساً. لو حابة تضيفي أخت، صديق، تيتا، أو حد من العيلة في القصة — تقدر دلوقتي. اختياري."]

[Invitation card — white surface, illustrated icon]
  [Watercolor-feel illustration of family group]
  [أضف شخصية للحدوتة]
  [Subcopy: "أخ، أخت، صديق، تيتا، جدو، أو شخصية مهمة لطفلك. حتى ٢ شخصيات."]
  [+ أضف شخصية — soft outlined button, terracotta border]

[Nav row]: 
  [تخطي هذه الخطوة — teal underlined link, peer to Next]   [التالي → — terracotta CTA]
```

**On "+ أضف شخصية" click — inline form expands:**
```
[Character mini-form card — cream-tinted bg]
  [Header: "شخصية ١" tag + remove link]
  [Input: اسم الشخصية (placeholder: "نور")]
  [Role buttons (3-col grid, single-select): أخ/أخت / صديق / تيتا/جدو / أب/أم / حيوان أليف / آخر]
  [Photo OR description sub-fork: 2-button row 📷 ارفع صورة / ✎ اوصف]

[+ شخصية تانية (optional)] — appears after first character is filled
```

**Why option A:**
- Best balance of warm invitation + obvious skip
- Soft outlined add button avoids "you must do this" pressure of solid CTA
- Skip is explicit (peer to Next in nav row) — no FOMO
- Empty state is illustrated, warm — not "you forgot something" energy

**Implementation notes:**
- Schema: `supporting_characters` table (id, order_id FK, name, role enum, photo_id nullable FK, description JSON nullable, position [1 or 2])
- Roles enum: `sibling` / `friend` / `grandparent` / `parent` / `pet` / `other`
- Per-character photo OR description: same fork logic as step 2 main child, scoped to the character
- Max 2 enforced client-side and server-side
- "Skip this step" sets `orders.has_supporting_characters = false` and proceeds; no characters created
- Step is fully optional in `orders` schema (no FK constraint forcing creation)

### Step 4 — حدوتة طفلك (locked: Option A — all-visible vertical with illustrated theme cards)

**Layout:**
```
[Stepper: steps 1-3 ✓, step 4 active]
[Step title: حدوتة ليلى عن إيه؟]
[Step intro: "اختار موضوع القصة + قيمة تربوية تحب طفلك يتعلمها. تقدر تضيف لمسة شخصية أكتر بعدها."]

[Field label: موضوع الحدوتة * (with filter tag: "مفلتر للعمر ٥-٧")]
[Theme grid — 2-col, 8 illustrated cards:]
  ┌─────────────┐ ┌─────────────┐
  │ 🏫 illust   │ │ 🤝 illust   │
  │ أول يوم     │ │ الصداقة     │
  │ مدرسة      │ │             │
  │ [tag: ٥-٧] │ │ [tag: ٣-٥] │
  └─────────────┘ └─────────────┘
  ... (8 themes total: school / friendship / Eid / Ramadan / Christmas / Sham El-Nessim / birthday / adventure)

[Field label: قيمة تربوية تحب طفلك يتعلمها *]
[Moral grid — 4-col, 8 text-only buttons:]
  الشجاعة  الأمانة  الكرم  احترام الكبار
  المثابرة  اللطف  التعاون  الصبر

[Field label: مشهد خاص تحب يكون في الحدوتة (optional)]
[Textarea — placeholder: "مثلاً: مشهد ليلى بتساعد أخوها الصغير يربط الحذاء، أو لما ركبت العجلة لأول مرة..."]

[Field label: مناسبة خاصة (optional)]
[Text input — placeholder: "عيد ميلاد ليلى، نجاحها بالمدرسة، أول يوم في حضانة..."]

[Nav: ← السابق / التالي →]
```

**Theme catalog (initial seed — religion-neutral pan-Egyptian):**

| Theme | Arabic | Suitable age bands |
|---|---|---|
| First day at school | أول يوم في المدرسة | `5-7`, `6-8` |
| Friendship | الصداقة | `3-5`, `5-7` |
| Eid | العيد | `3-5`, `5-7`, `6-8` |
| Ramadan | رمضان | `5-7`, `6-8` |
| Christmas | الكريسماس | `3-5`, `5-7`, `6-8` |
| Sham El-Nessim | شم النسيم | `5-7`, `6-8` |
| Birthday | عيد ميلاد | `3-5`, `5-7`, `6-8` |
| Big adventure | مغامرة كبيرة | `5-7`, `6-8` |

(Theme catalog can grow over time; the brand brief notes 30-theme catalog is plausible by month 3-6.)

**Moral values catalog (locked from Decision 2):**
الشجاعة / الأمانة / الكرم / احترام الكبار / المثابرة / اللطف / التعاون / الصبر

**Why option A:**
- Theme cards as illustrated 2-col grid does justice to the highest-emotional-payload moment in the wizard
- Age-filter tag visible — makes the work transparent (parents see why some themes appear and others don't)
- Consistent with step 1 Option A (all-visible pattern)
- No hidden affordances at the conversion-critical step

**Implementation notes:**
- Schema (per Decision 2): `orders.theme_id` FK + `orders.moral_value_id` FK + `orders.custom_scene_text` text + `orders.special_occasion_text` text
- Theme illustrations in cards: simple watercolor-feel SVG icons inline (not full illustrations); align with the theme (school = backpack, Eid = crescent, Sham El-Nessim = colored egg, etc.)
- Theme card tap target: full card clickable, terracotta border + cream-tinted bg on selection
- Custom scene textarea: ~150 character limit (signal: "a sentence or two, not an essay")
- Moral value: required single-select; if both theme and moral picked, "Next" enables

### Step 5 — مراجعة + إهداء (locked: Option A — rich cards + per-section edit + reassurance CTA)

**Layout:**
```
[Stepper: steps 1-4 ✓, step 5 active]
[Step title: حكاية ليلى جاهزة تبدأ]
[Step intro (revised honest copy): "راجع التفاصيل قبل ما نبدأ. تقدر تعدل أي قسم بضغطة واحدة."]
  (Note: "نبدأ" / "we begin" is neutral — refers to the Hadouta team starting work, not a literal storyteller writing)

[Summary card — الطفل]
  [👧 الطفل] [تعديل link → step 1]
  [Rows: الاسم / العمر / الجنس / الهوايات / حاجة مميزة]

[Summary card — الصورة]
  [📷 الصورة] [تعديل link → step 2]
  [Row: الطريقة (صور / وصف يدوي)]

[Summary card — العائلة]
  [👨‍👩‍👧 العائلة] [تعديل link → step 3]
  [Empty state: "مفيش شخصيات إضافية — الحدوتة عن ليلى" if skipped]

[Summary card — الحدوتة]
  [📖 الحدوتة] [تعديل link → step 4]
  [Rows: الموضوع / القيمة / مشهد خاص / المناسبة]

[Dedication card — warm-tinted card]
  [✉ إهداء (optional)]
  [Subcopy: "جملة قصيرة هتظهر في أول صفحة من الكتاب — لمسة عائلية. اختياري."]
  [Textarea — placeholder example with proper voice]

[CTA block — bottom strip, teal-tinted bg]
  [Reassurance copy (revised honest version): "فريقنا المصري بيراجع كل كتاب قبل التسليم — حدوتتك جاهزة في ٢-٣ أيام"]
  [Pay button — terracotta, El Messiri 700:
    "ابدأ حدوتة ليلى — ٢٥٠ ج.م"
    [secondary line: "الخطوة التالية: تأكيد رقم الموبايل + الدفع"]]
```

**Per-section edit semantics:**
- Click "تعديل" link → jumps to that step with all OTHER answers preserved (no progress loss)
- After edit, parent returns to step 5 via "Continue" button on the edited step
- Wizard store holds full state; navigation is non-destructive

**Why option A:**
- Confidence-building at conversion-critical moment — parent verifies each section independently
- Per-section edit preserves momentum (no "back, back, back, back, edit, forward, forward, forward, forward")
- Reassurance copy + price + next-step preview closes the conversion
- Storyteller-voice register maintained without false production claims

**Implementation notes:**
- Wizard state: persists in client store + autosaves to `orders` table draft (status='draft') from step 1 onwards
- Edit jumps preserve full state — implementation pattern: routing with state hydration, not URL params alone
- Dedication: `orders.dedication_text` (text, nullable, ~120 character limit suggested)
- Reassurance copy is the locked production-honesty version

### Step 6 — الدفع + التحقق (locked: single design — phone OTP + Paymob redirect)

**Layout:**
```
[Stepper: steps 1-5 ✓, step 6 active]
[Step title: تأكيد + الدفع]
[Step intro: "محتاجين رقم موبايل لما الكتاب يجهز نبعتلك إشعار على واتساب. مش هتسجل أو تحفظ كلمة سر."]

[OTP section — white card]
  [H4: رقم موبايلك]
  [Subcopy: "مصري — هنبعت رمز التأكيد على واتساب أول"]
  [Phone input row: [🇪🇬 +20 prefix locked] [phone field, LTR-direction local format]]
  [Once submitted → verified state shows:]
    [✓ تم التأكيد tag]
    [6-digit OTP code cells, LTR-direction]
    [Meta row: "إعادة الإرسال متاحة في 0:42" / "تغيير الرقم" link]
    [Fallback row: "ما وصلش الواتساب؟ جرب SMS أو إيميل بدلاً من ذلك"]

[Payment summary card — ochre-tinted bg]
  [Row: حدوتة ليلى — أول يوم مدرسة (الشجاعة) | ٢٥٠ ج.م]
  [Total row: المجموع | ٢٥٠ ج.م]
  [Payment methods note: "الدفع آمن عبر Paymob | كارت فيزا/ماستركارد · فودافون كاش · إنستاباي"]

[Pay button — terracotta, full-width:
  "ابدأ حدوتة ليلى — ادفع ٢٥٠ ج.م"
  [secondary line: "هتتحول للدفع الآمن عبر Paymob"]]

[Nav: ← مراجعة]
```

**ADR-018 fallback chain implemented:**
- Tier 1: WhatsApp OTP (default, ~95% success expected)
- Tier 2: SMS fallback ("جرب SMS" link surfaces after WhatsApp tier-1 timeout or manual click)
- Tier 3: Email fallback ("إيميل بدلاً من ذلك" link — collects email if needed; rare, requires email field input then sends OTP)
- Tier 4: Google OAuth (fallback if email tier fails — implemented but not surfaced in step 6 UI; reserved for support escalation)

**OTP UX details:**
- 6-digit code, auto-advance between cells, paste-from-WhatsApp-keyboard support
- Resend timer: 60s (industry standard); "إعادة الإرسال" link active after timer
- "تغيير الرقم" link allows phone re-entry without losing wizard progress
- Phone validation: client-side regex `^01[0125]\d{8}$` for Egyptian mobile; server validates again

**Payment UX:**
- Pay button → POST to backend → backend creates Paymob payment intent → redirect URL returned → client redirects to Paymob hosted UI
- Paymob handles all card / Vodafone Cash / InstaPay flows on their domain
- Success/failure return URL: `/order/{order_id}/confirmation` (success) or `/order/{order_id}/payment-failed` (failure with retry option)
- Order status transitions: `draft` → `pending_payment` (on OTP verify) → `paid` (on Paymob success) → `in_production` (on AI pipeline kickoff via Trigger.dev per ADR-010)

**Implementation notes:**
- OTP placement BEFORE payment (per ADR-018 invisible-accounts semantics: account exists once phone is verified, payment ties to that account)
- Single screen — no sub-step for OTP-then-payment because Paymob is a redirect; the OTP verify + pay-button-click are sequential interactions on one screen
- Order ID format: `HAD-YYYY-NNNN` (proposed; ops can revise)

### Step 7 — حكاية بدأت (locked: single design — Storyteller-voice confirmation)

**Layout:**
```
[Stepper: all 6 ✓, step 7 active (teal-tinted)]

[Hero block — warm gradient bg]
  [Watercolor-feel illustration placeholder: small Storyteller-at-desk character (Phase 5 produces real illustration)]
  [H2 Aref Ruqaa: حكاية ليلى بدأت]
  [El Messiri: — شكراً يا أحمد]
  [Storyteller-line (revised honest copy):
   "بدأنا في إعداد حدوتة ليلى. خلال ٢-٣ أيام، فريقنا المصري بيراجعها وبيبعتلك رسالة على واتساب لما تكون جاهزة."]

[Order metadata card — white]
  [Row: رقم الطلب | #HAD-2026-0042]
  [Row: الموضوع | أول يوم مدرسة · الشجاعة]
  [Row: طول الكتاب | ١٦ صفحة · رسومات مائية]
  [Row: جاهز خلال | ٢-٣ أيام]
  [Row: الإشعار على | +20 100 1234567 · واتساب]

[Reassurance card — teal-tinted bg]
  [Honest revised copy:
   "كل حدوتة بنراجعها بعناية. لو الإصدار الأول مش بمستوى طفلك، بنحضّرها تاني — وقت إضافي حوالي ٢٤ ساعة، شامل في السعر."]

[Actions]
  [Track order button — terracotta-bordered, white bg: "تتبع حالة الطلب"]
  [Secondary link: "العودة للصفحة الرئيسية"]
```

**Why this design:**
- Aref Ruqaa headline is the emotional Storyteller-voice moment; per brand brief "max one Aref Ruqaa per page" rule, this is THE one
- "بدأنا في إعداد" copy (revised) is neutral about WHO/WHAT does the work — doesn't claim human writer, doesn't volunteer AI
- "فريقنا المصري بيراجعها" emphasizes the human review gate (true and brand-positive)
- Order metadata card builds trust through specificity (order ID, exact ETA, notification channel)
- Reassurance card reuses the ADR-013 "regen if not good enough" promise

**Implementation notes:**
- WhatsApp template "order confirmation (utility category)" fires on transition to step 7 (per brand brief WhatsApp spec)
- Page emits PostHog `order_confirmed` event for funnel tracking (per Sentry+PostHog wiring from session 5)
- Track-order link → `/account/orders/<id>` page (deferred to Sprint 4; placeholder for now)
- ETA copy: "٢-٣ أيام" assumed; pull from real Trigger.dev workflow timing once implemented (ADR-010)
- Hero illustration: placeholder gradient now → real watercolor "Storyteller at desk" character in Phase 5

---

## Database schema migration plan

The locked design implies these schema changes. To be applied as a Drizzle migration alongside or after Phase 5 wizard implementation:

### New tables

**`moral_values`**
```sql
id           uuid PK
name_ar      text NOT NULL
name_en      text NOT NULL
description  text NULL                            -- short pedagogical description
suitable_age_bands  text[] NOT NULL DEFAULT '{}'   -- e.g. {'3-5','5-7','6-8'}
active       boolean NOT NULL DEFAULT true
sort_order   int NOT NULL DEFAULT 0
created_at, updated_at
```

Initial seed: 8 values per Decision 2.

**`supporting_characters`**
```sql
id              uuid PK
order_id        uuid FK orders ON DELETE CASCADE
name            text NOT NULL
role            text NOT NULL CHECK (role IN ('sibling','friend','grandparent','parent','pet','other'))
appearance_input_type  text NOT NULL CHECK (appearance_input_type IN ('photo','description'))
photo_id        uuid FK photos NULL
description_skin_tone, description_hair, description_clothing_style, description_eye_color  text NULL
position        smallint NOT NULL CHECK (position IN (1,2))
created_at
```

### Modified `themes` table

```sql
ALTER TABLE themes ADD COLUMN suitable_age_bands text[] NOT NULL DEFAULT '{}';
ALTER TABLE themes ADD COLUMN description_ar text NULL;
ALTER TABLE themes ADD COLUMN description_en text NULL;
```

### Modified `orders` table

```sql
ALTER TABLE orders
  ADD COLUMN buyer_name text NOT NULL,
  ADD COLUMN child_name text NOT NULL,
  ADD COLUMN child_age_band text NOT NULL CHECK (child_age_band IN ('3-5','5-7','6-8')),
  ADD COLUMN child_age_exact smallint NOT NULL CHECK (child_age_exact BETWEEN 3 AND 8),
  ADD COLUMN child_gender text NOT NULL CHECK (child_gender IN ('boy','girl')),
  ADD COLUMN child_hobbies text NULL,
  ADD COLUMN child_favorite_food text NULL,
  ADD COLUMN child_favorite_color text NULL,
  ADD COLUMN child_special_traits text NULL,
  ADD COLUMN appearance_input_type text NOT NULL CHECK (appearance_input_type IN ('photo','description')),
  ADD COLUMN description_skin_tone text NULL,
  ADD COLUMN description_hair text NULL,
  ADD COLUMN description_clothing_style text NULL CHECK (description_clothing_style IS NULL OR description_clothing_style IN ('modern','egyptian_traditional','school_uniform','custom')),
  ADD COLUMN description_eye_color text NULL,
  ADD COLUMN has_supporting_characters boolean NOT NULL DEFAULT false,
  ADD COLUMN theme_id uuid FK themes,
  ADD COLUMN moral_value_id uuid FK moral_values,
  ADD COLUMN custom_scene_text text NULL,
  ADD COLUMN special_occasion_text text NULL,
  ADD COLUMN dedication_text text NULL;
```

(Note: `style` already exists per ADR-019 schema migration `0002` from session 5.)

### Indexes

```sql
CREATE INDEX idx_orders_theme_id ON orders(theme_id);
CREATE INDEX idx_orders_moral_value_id ON orders(moral_value_id);
CREATE INDEX idx_themes_age_bands ON themes USING gin(suitable_age_bands);
CREATE INDEX idx_supporting_characters_order_id ON supporting_characters(order_id);
```

---

## ADR amendments needed

### ADR-005 amendment (extend, don't replace)

The current ADR-005 says "L3 photo upload + watercolor style." Amendment adds:

> **2026-05-02 amendment**: Photo upload is the recommended path; a parallel manual-description path is also offered for parents who decline photo upload. Description schema: skin-tone color picker (6 swatches) + hair free-text + clothing style buttons (Modern / Egyptian Traditional / School Uniform / Custom — Gulf Traditional dropped per ADR-002 Egyptian-only stance) + optional eye color. Both paths produce the same watercolor output style. Single price tier in MVP. Pricing-tier separation (description-cheaper) is a v1.5+ question informed by funnel data.

> **Story input combinatorial**: Each order has theme + moral value (both required) + optional custom scene text + optional special occasion. Adds `moral_values` catalog table; adds `theme_id`, `moral_value_id`, `custom_scene_text`, `special_occasion_text` columns to `orders`.

> **Age-band tagging**: Themes are tagged with `suitable_age_bands text[]` (overlapping bands `3-5` / `5-7` / `6-8` within Hadouta's 3-8 target age per brand brief H2). Wizard step 1 asks for both age band (theme filter) and exact age (story copy + AI narrative-complexity tier). Theme is shown if any of its tagged bands matches the picked band.

### Brand brief v1.2 (already amended in this session, 2026-05-02)

New section "How to talk about production publicly — the quiet middle path" added after "Cultural-authenticity foundation." Core rule: lead with Egyptian human review + writers/illustrators behind templates + 2-3 day care window; never claim hand-painted; don't lead with "AI generated." Applies to all customer-facing surfaces.

### No new ADR needed

Decisions in this spec are refinements of ADR-005 + ADR-013 + ADR-018 + ADR-014 + ADR-002 — all locked already. ADR-005 amendment captures the additions; no fresh ADR justified.

---

## Open follow-ups for Phase 5 implementation

### Wireframe-level deferred items (low-leverage, derive from tokens + standard patterns)

| Surface | Deferred decision |
|---|---|
| Landing storyteller-setup paragraph | Final copy — Phase 6 brand statements |
| Landing sample preview UX | Mini book viewer vs. static spread vs. video |
| Landing how-it-works visual | Card stack vs. horizontal timeline |
| Landing theme gallery | Grid vs. carousel vs. featured + more |
| Landing trust band team-photos | Photo collage vs. founder quote + photo (depends on Track B photo sourcing) |
| Landing pricing card | Visual treatment per token system |
| Landing FAQ | Accordion with 4-6 questions (derive from support data) |
| Landing footer | Standard pattern |
| Wizard step 2 photo path: face-detection failure UX | Toast vs. modal vs. inline error |
| Wizard step 2 description path: hair input | Free-text vs. structured (length + color + texture) |
| Wizard step 2 description path: clothing "Custom" | Sub-input expansion or modal |
| Wizard step 4 theme card illustrations | Inline SVG or generated assets |
| Wizard step 6 OTP fallback to email | Email field collection UX (rare path) |
| Wizard step 7 hero illustration | Real watercolor "Storyteller at desk" character |

### Production prerequisites (Track B / Ahmed-driven)

| Item | Blocking |
|---|---|
| Egyptian decorative-motif library commission (~10K EGP, 2-4 weeks) | Phase 2.5 — landing trust band, hero corner motifs, accent-band corner motifs |
| Egyptian writers + illustrators commissions (per ADR-002) | Theme template seed content + watercolor reference style |
| Team photos (writers, illustrators, reviewers) | Landing trust band visual treatment (option C) |
| Meta Business Verification + Twilio WhatsApp sender (3-7 day FB review) | Wizard step 6 OTP delivery (production); blocks real launch |
| Domain `hadouta.com` registration | Custom domain wire-up; brand presence |
| Real Resend API key | Wizard step 6 OTP tier-3 email fallback |

### Sprint-2+ followups (not Sprint 1 critical-path)

| Item | Source |
|---|---|
| Wizard state persistence + edit-jump state preservation | Step 5 implementation; needs careful client store design |
| Active learning loop on theme+value combinations | ADR-013, after first ~200 orders |
| AI prompt templates per moral value × theme combination | ADR-006 + Sprint 3 |
| Validator framework: cultural authenticity + age-appropriateness | ADR-012, ADR-013 — Sprint 3 |
| Test-data cleanup helper (auth tests + e2e tests leak rows) | session 5 followup |
| Rate-limit hardening + Redis-backed secondary-storage | session 5 followup |

---

## Visual companion artifacts (gitignored — `.superpowers/brainstorm/<session>/content/`)

Wireframe HTML files produced this session, in design-flow order:

1. `landing-hero.html` — initial 3 hero structure options (lo-fi)
2. `landing-section-rhythm.html` — initial 3 section-rhythm options (lo-fi)
3. `landing-hero-hifi.html` — hi-fi version of hero option A (UI Designer agent)
4. `landing-section-rhythm-hifi.html` — hi-fi version of 3 section-rhythm options (UI Designer agent)
5. `wizard-structure.html` — 3 wizard step-sequence options
6. `wizard-step1-layout.html` — 3 step-1 layout options
7. `wizard-step2-pathpicker.html` — 3 step-2 path-picker options
8. `wizard-step2-paths-expanded.html` — both paths expanded
9. `wizard-step3-supporting.html` — 3 step-3 supporting-characters options
10. `wizard-step4-story.html` — 3 step-4 story-details options
11. `wizard-step5-review.html` — 3 step-5 review-and-dedication options
12. `wizard-step6-7-checkout-confirmation.html` — single design each for steps 6 and 7

Each wireframe is mid-fi: real Hadouta brand chrome (palette + fonts), real Egyptian Arabic copy, watercolor-feel SVG placeholders, hand-drawn-feel dividers. Visual companion server runs at `http://localhost:<port>` (gets a new port on each restart).

---

## Self-review checklist (run at end of writing this spec)

- [ ] **Placeholder scan**: any "TBD", "TODO", incomplete sections? — No vague placeholders found; sections marked "deferred to Phase 5" are scoped explicitly.
- [ ] **Internal consistency**: do sections contradict each other? — Photo-OR-description is consistent across upstream Decision 1, step 2 layout, and schema migration. Theme age-band tagging is consistent across upstream Decision 3, step 1 + step 4 layouts, theme catalog seed, and schema. Honest-copy revisions are consistent across landing trust band, step 5 reassurance, and step 7 confirmation.
- [ ] **Scope check**: focused enough for a single Phase 5 implementation plan? — Yes; this spec covers landing + wizard. Phase 5 split into landing build + wizard build is natural.
- [ ] **Ambiguity check**: any requirement open to two interpretations? — Wizard state preservation across edit-jumps is flagged as Phase 5 implementation detail (could be done multiple ways: client store hydration, URL params, server-persisted draft); chosen path called out as "client store + autosave to draft order."
- [ ] **AI-honesty rule applied throughout**: ✓ all customer-facing copy revised; brand brief amended; memory updated.
- [ ] **Deferred items called out, not hidden**: ✓ explicit "Open follow-ups for Phase 5" section.
- [ ] **References work**: ✓ ADR numbers, file paths, brand brief sections all real and in-tree.

---

**End of design spec. Ready for user review.**
