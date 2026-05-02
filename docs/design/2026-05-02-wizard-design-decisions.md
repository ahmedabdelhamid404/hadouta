# Wizard design decisions — 2026-05-02

**Source**: Phase 3 brainstorming session (Sprint 1, session 6 work)
**Triggered by**: walkthrough of Replit AI-prototype "حكاية AI" + Hadouta's master-design-spec §7.1 + ADR-005 + brand brief v1.1
**Status**: locked in conversation; **needs formal capture as ADR-005 amendment + master-design-spec §7.1 update + Drizzle schema migration**

---

## Decision 1 — Photo-OR-description fork (extends ADR-005)

**Locked: Option 2 — Photo + parallel description, single price tier.**

Step 3 of the wizard offers two parallel paths:

| Path | Inputs | When customer picks |
|---|---|---|
| **Photo upload** | 1-3 images (JPG/PNG/WEBP, ≤5MB each); AI face-matches to watercolor portrait per ADR-005 | Default-recommended; highest-fidelity output |
| **Manual description** | (a) skin-tone color swatch picker — 6 swatches; (b) hair description free-text; (c) clothing-style picker — buttons: عصري / تقليدي مصري / زي مدرسي / مخصص (drop "Gulf traditional"); (d) optional eye color | Privacy-conscious parents; parents without good photos available |

**Single price tier** — both paths produce a 250 EGP digital book (per ADR-014 A/B test). Pricing-tier separation is a v1.5 question informed by real funnel data, not pre-launch speculation.

**Path commitment**: parent picks at the start of step 3; can switch via a "switch to description" / "switch to photo" toggle within step 3 if they change their mind.

**Brand-brief alignment**: H3 (diaspora as secondary segment) + cultural-authenticity foundation argue for inclusive ordering UX. Photo-only would lose Egyptian families with photo-privacy concerns (often Coptic, often conservative middle-class, often parents of daughters).

---

## Decision 2 — Story input combinatorial (extends ADR-005, schema impact)

**Locked: Option C — Theme + Moral Value + Custom Scene + Optional Occasion.**

Wizard step 4 ("الحدوتة" / story) collects 4 inputs:

| Axis | Required? | Schema field | UI control |
|---|---|---|---|
| **Theme** | Required | `orders.theme_id` (FK to `themes` table) | Button grid, age-band-filtered (per Decision 3) |
| **Moral value** | Required | `orders.moral_value_id` (FK to **new** `moral_values` table) | Button grid, single-select |
| **Custom scene** | Optional | `orders.custom_scene_text` (text, nullable) | Free-text textarea, placeholder shows examples |
| **Special occasion** | Optional | `orders.special_occasion_text` (text, nullable) | Free-text input, hint placeholder |

**Initial moral_values catalog** (8 values, brand brief + ADR-002 culturally-Egyptian):

1. الشجاعة (Courage)
2. الأمانة (Honesty)
3. الكرم (Generosity)
4. **احترام الكبار** (Respect for Elders) ← Egyptian-cultural anchor
5. المثابرة (Perseverance)
6. اللطف (Kindness)
7. التعاون (Cooperation)
8. الصبر (Patience)

**Why required+optional split**: required theme + required moral_value gives the AI prompt template consistent structured input (every story always teaches a value). Optional custom_scene + occasion give parents room to inject personal moments without breaking the pipeline if they skip.

**Brand-brief alignment**: explicit moral values reinforce cultural authenticity foundation; custom-scene operationalizes parent agency in the Storyteller voice ("the Storyteller invites; transactional commands push"). Special occasion lets parents tie books to real moments (first day of school, Eid, birthday, Sham El-Nessim).

---

## Decision 3 — Age-band tagging on themes (extends ADR-005, schema impact)

**Locked: Option B with overlapping bands + age-band picker + exact age spinner.**

### Bands (within Hadouta's 3-8 target age, per brand brief H2)

3 overlapping bands:
- `3-5` (early — simpler vocabulary, shorter sentences, fewer plot turns)
- `5-7` (mid — middle vocabulary tier)
- `6-8` (late — longer sentences, plot complexity, abstract values)

**Overlapping intentional**: a 5-year-old sees themes from both `3-5` and `5-7`; a 6-year-old sees themes from both `5-7` and `6-8`. Reflects developmental-psychology reality that age boundaries aren't crisp.

### Schema

`themes.suitable_age_bands text[]` — stores tags like `['3-5', '5-7']` or `['6-8']`. Theme is shown if **any** of its tagged bands matches the picked band.

### Wizard age capture

Two age inputs:
- **Step 1 — age band picker** (3 buttons, single-select). Used to filter themes (via Decision 3) + select narrative-complexity tier for AI prompt template.
- **Step 1 or step 2 — exact age spinner** (3-8). Used in story copy ("Layla turns 5 today…") + finer-grained AI tuning.

### Architectural-from-day-one note

Tagging now (~30-line Drizzle migration) is cheap. Tagging later (when production has 30+ themes referenced by orders) requires backfill + foreign-key migration on populated DB. Same architectural-from-day-one principle as ADR-019 (multi-style support).

The narrative-complexity tier is a downstream benefit: ADR-006 doesn't currently spec it, but having age-band as structured input makes that future enhancement trivial.

---

## What still needs to happen

1. **ADR-005 amendment** capturing Decisions 1-3 (single doc, ~1 page added). Could also be a fresh ADR-020 if scope grows; ADR-005 amendment is the minimal-viable path.
2. **Master-design-spec §7.1 update** to reflect new wizard structure (5 design steps + checkout + confirmation, see "Recommended wizard structure" below).
3. **Drizzle schema migration** (next clean `drizzle-kit generate`):
   - Add `moral_values` table (id, name_ar, name_en, description, suitable_age_bands text[], active boolean)
   - Add to `orders`: `moral_value_id` FK, `custom_scene_text` text, `special_occasion_text` text, `appearance_input_type` enum ('photo', 'description'), `description_skin_tone` text, `description_hair` text, `description_clothing_style` text, `description_eye_color` text (nullable for photo path)
   - Add to `themes`: `suitable_age_bands` text[]
4. **Theme catalog seed data**: extend the brand brief's theme list with age-band tags (e.g., "First day of school" → `['5-7', '6-8']`, "Fear of the dark" → `['3-5']`, etc.)

---

## Recommended wizard structure (post-decisions)

5 design steps + 2 transactional steps:

1. **أخبرنا عن طفلك (Tell us about your child)** — buyer name + child name + age band picker + exact age spinner + gender (boy/girl) + optional enrichment (hobbies, favorite food, favorite color, special characteristics)
2. **صورة طفلك (Your child's image)** — photo upload OR description fork (Decision 1)
3. **العائلة في الحدوتة (Family in the story)** — supporting characters (optional, max 2 per master-design-spec §7.1 step 5; each: name + role + photo OR description)
4. **حدوتة طفلك (Your child's story)** — theme (age-band-filtered per Decision 3) + moral value + custom scene (optional) + special occasion (optional) — Decision 2
5. **مراجعة وإهداء (Review + dedication)** — read-only summary + optional dedication textarea + final CTA "ابدأ حدوتة طفلك"
6. **Checkout** — phone-OTP per ADR-018 + Paymob payment + price tier (250/300 EGP A/B per ADR-014)
7. **Confirmation** — Storyteller-voice "حكايتك بدأت" per brand brief voice example sheet

This will be wireframed step-by-step in the visual companion next.
