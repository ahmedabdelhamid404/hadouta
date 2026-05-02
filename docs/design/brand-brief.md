# Hadouta — Brand Brief

**Status**: v1.1 — Brand Guardian audit applied; **Phase 2 design tokens shipped (session 5)**; ready for Phase 3 Figma screen designs
**Date**: 2026-05-01 (session 4 + brand-discovery + Brand Guardian audit pass)
**Owner**: Ahmed
**Process**: Direct interactive brand discovery (8-question conversation, Claude as facilitator) → Brand Guardian agent audit pass → revisions incorporating 6 critical findings + 3 new sections (failure-mode voice, WhatsApp template spec, voice example sheet)

---

## North Star — one word

**Storyteller** (الحَكَّاءة / الحَكَّاء)

Hadouta isn't a *children's-book service called "Story."* Hadouta IS a Storyteller — every touchpoint (the website, the WhatsApp message, the order wizard, the book itself, the receipt, the WhatsApp confirmation) is the Storyteller speaking. The brand archetype and the brand meaning are identical: حدوتة *means* story; the brand IS one.

**One-sentence brief:**

> *"A beloved sun-warmed children's book on the kitchen table of a modern Egyptian apartment — modern enough to be the child's actual world, traditional enough to feel like family. The Storyteller belongs to that family, that specific Egyptian life — Cairo or Aswan, Muslim or Christian, Cairo apartment or Sahel beach house — wherever an Egyptian parent reads to an Egyptian child."*

---

## Mood vocabulary

### Mood words (✅ what Hadouta should always feel like)

- **Warm**
- **Calm**
- **Sun-warmed**
- **Egyptian-grandmother-kitchen** (the *quality of warmth*, not a literal exclusion of other Egyptian settings — see Hidden Assumptions section)
- **Magical** (subtly — gentle wonder, not Disney-fairy-dust)

### Anti-mood words (❌ what Hadouta must never feel like)

- **Soulless / cold** (no SaaS-modern grays, no flat-design Stripe-Linear-Notion-clones)
- **Cheap** (no stock-template energy, no mass-market kids' aesthetic)
- **Childish-bubbly** (no giant-rounded-Crayola-primary-color buttons, no Disney-Junior-bright)
- **Plasticky** (no shiny gradients, no glossy 3D buttons, no digital-feeling textures)

---

## Cultural positioning — modern Egypt with traditional family warmth

### What's specifically Egyptian (and what isn't)

**Yes:**
- Lived modern Egypt — apartments, school uniforms, Cairo streets, planes, beaches at North Coast / Sahel / Marsa Matruh, parks, malls, Metro stations
- Family-cultural-character: teta in her galabeya OR in modern dress, family meals, oral storytelling tradition, mint tea, embroidered cloth
- Geometric Egyptian-pattern motifs as subtle decorative texture — drawing from the shared visual vocabulary of Coptic textile, Islamic-art tile, and folk-embroidery traditions (these geometric grammars overlap heavily; the "Egyptian visual heritage" is broader than any single religious tradition)
- Egyptian color heritage: terracotta, ochre, sienna, Egyptian-teal-glass-and-tile, deep brown
- Egyptian-designed typography (El Messiri specifically — Egyptian designer's letterforms)

**No:**
- Tourist-Egypt clichés (no pyramids, Sphinx, hieroglyphs as branding — those are foreigner-postcard-Egypt, not lived-Egypt)
- Gulf or Levantine aesthetic (Hadouta is specifically Egyptian; expansion to other Arab markets is a future, not-MVP, decision)
- Generic-Western children's-content imported with Arabic dub (we are not localizing American storybooks — we are creating Egyptian ones)
- Folk-tale-historical-only Egypt (we don't only depict 1001-Nights-style settings — modern Egyptian children must see themselves in their actual lives)

### Religious positioning — pan-Egyptian, religion-neutral chrome

**Choice (deliberate):** Hadouta's brand chrome (website, wizard, receipts, WhatsApp templates) is **religion-neutral**. Egyptian visual heritage spans Muslim, Coptic, and folk traditions; the chrome draws from the *shared geometric vocabulary* across all three rather than coding to one.

Religious specificity lives **inside the product** — driven by customer input. The customer picks a theme (Ramadan, Eid, Christmas, Easter, Sham El-Nessim, birthday, first day of school, etc.) and the book interior reflects that theme honestly. All occasions are equally welcome. A Coptic family ordering a Christmas book sees Coptic Christmas; a Muslim family ordering an Eid book sees Eid; a secular family ordering a "first day of school" book sees no religious content.

**What this means concretely:**
- Brand chrome avoids religion-specific motifs (no fanous as a chrome decoration; no cross as a chrome decoration; no Quranic calligraphy as ornament)
- Theme catalog includes occasions across religious traditions (Christmas + Easter + Ramadan + Eid + Sham El-Nessim are all first-class)
- Marketing creative rotates faces and family configurations across religious-cultural codings — Muslim families, Coptic families, secular modern families, mixed families
- WhatsApp templates use language that doesn't presume religion ("welcome" not "السلام عليكم"; "your story" not religion-coded greeting)

This is a strategic choice: the cultural-specificity moat (ADR-002) is "Egyptian," not "Muslim-Egyptian." Christmas, Easter, and Sham El-Nessim are real Egyptian gift occasions; Hadouta serves them.

### Cultural-authenticity foundation

The brand promises Egyptian cultural specificity. That promise needs a credibility foundation, otherwise it's vulnerable to one viral attack ("Hadouta is just AI faking Egyptian-ness").

**The Hadouta promise (post-ADR-020 / 2026-05-02 strategic pivot):**
- **Every Hadouta book is reviewed by an Egyptian human before delivery.** Per ADR-013, every book passes through a manual approval gate staffed by Egyptian cultural reviewers — Ahmed initially, expanded team eventually. The reviewer is the only human in the loop and the canonical quality gate.
- **AI is engineered for Egyptian cultural authenticity.** System prompts include explicit Egyptian-context anchors (Cairo settings, Egyptian Arabic register, religion-neutral pan-Egyptian theme palette, anti-tourist/anti-Gulf stance, brand brief's three-worlds image set as few-shot examples). Cultural-specificity is engineered into prompts + validators, not hand-curated by human creators.
- **Validators framework enforces cultural rules** (per ADR-012). Rejection categories from the manual review gate feed back into validator regeneration so the system learns from each rejection.

**Why this matters:** ADR-002 is the strategic moat (Egyptian cultural specificity). The original implementation assumed Egyptian writers + illustrators would seed the templates. ADR-020 (2026-05-02) shifted to AI-only generation with human review only. The moat now lives in three operational commitments that ARE actually executed: Egyptian-tuned prompts, validators framework, manual review gate.

**What this means concretely:**
- Customer-facing copy must NOT claim Egyptian writers/illustrators design templates (was true pre-ADR-020, false now).
- Customer-facing copy SHOULD lead with the Egyptian human review claim (true and operationally costly).
- Output-describing language ("Egyptian-tuned story", "designed for Egyptian children") is honest; process-describing language about humans creating content is not.

### How to talk about production publicly — the quiet middle path

**Internal reality (post-ADR-020 / 2026-05-02 — this is what's actually true):**
- Story text: AI-generated (Claude per ADR-006), driven by Egyptian-tuned system prompts (no human-written templates)
- Illustrations: AI-generated (Nano Banana 2/Pro + GPT Image 2 fallback per ADR-006), driven by Egyptian-tuned style prompts (no human-set reference style)
- Theme catalog: defined by us internally with cultural cues; AI generates each instance from the theme spec
- Per-book quality gate: Egyptian human reviewer per ADR-013 — the ONLY human in the production loop

**Customer-facing position (added 2026-05-02):**

We lead with the Egyptian human curation + review + craft + effort. We **do not lead with "AI generated"** — and we **never claim "hand-painted" or "manually written"** either. Quiet middle path: describe what's true about production without volunteering AI as the headline.

**Lead with these (true and brand-positive):**
- "كتاب مصمم بعناية لطفلك" / "Carefully designed for your child"
- "فريقنا المصري بيراجع كل كتاب قبل ما يوصلك" / "Our Egyptian team reviews every book before delivery"
- "كتّاب ورسامين مصريين بيصمموا قوالب حكاياتنا" / "Egyptian writers and illustrators design our story templates"
- "حدوتة جاهزة في ٢-٣ أيام" / "Ready in 2-3 days" (effort signal — slower than AI-fast competitors by design)

**Avoid these (false or off-brand):**
- ❌ "كتاب مرسوم باليد" / "hand-drawn / hand-painted" — false, never use
- ❌ "الراوي بيكتب حدوتة طفلك" / "The Storyteller writes your child's story" — implies a literal human author, false
- ❌ "AI يرسم لطفلك" / "AI illustrates for your child" — true but not the headline; quiet middle path means AI is implementation detail, not brand identity
- ❌ "في دقائق" / "in minutes" — speed claim cheapens the brand; even if technically achievable, Hadouta uses time-as-care-signal

**Time as feature, not bug.** The 2-3 day production window is a brand promise, not an apology. Competitors leading with "in minutes" signal AI-fast-AI-cheap. Hadouta's slower window signals review + care + Egyptian human attention.

**The Storyteller voice STAYS** as the brand archetype — it's the *tone* of customer-facing copy (warm, sensory, second-person, paced), not a claim about who literally writes the book. Voice ≠ production model.

**Edge case — direct customer questions about AI:**
If a customer (in support, FAQ, social media) directly asks "is this AI generated?", the honest answer is:
> "الذكاء الاصطناعي بيكتب ويرسم بناء على قوالب صممها فريقنا المصري، وفريقنا بيراجع كل كتاب قبل ما يوصلك."
> "AI writes and illustrates based on templates our Egyptian team designed, and our team reviews every book before it reaches you."

Honest. Just not volunteered as the lead.

**Why this position over loud-AI-transparency:** premium positioning ≠ loud-AI-badge. AI is commodity in consumer minds (price-sensitive parents associate "AI" with cheap/fast/template-y output). What differentiates Hadouta is the Egyptian curation layer + manual review gate + cultural specificity (ADR-002 moat). Lead with that. Loud-AI competitors (e.g., Hekaya — see `docs/design/competitive-research/2026-05-02-hekaya-ai/findings.md`) lead with "مدعوم بالذكاء الاصطناعي" badge; Hadouta differentiates by NOT making AI the brand headline.

**Test for any customer-facing copy** — would an Egyptian parent who reads this AND THEN learns the books use AI feel deceived?
- "Carefully designed and reviewed by our Egyptian team, ready in 2-3 days" → would NOT feel deceived (literally true) → use
- "Hand-painted by Egyptian artists" → would feel deceived → never use
- "AI-generated personalized children's books" → wouldn't feel deceived but loses brand differentiation → avoid as headline

This rule applies across **all customer-facing surfaces**: landing page, order wizard, WhatsApp templates, ad creative, support replies, FAQ, social media bios, press materials, app store descriptions.

### The North Star image set

When designers / illustrators / writers ask "does this feel like Hadouta?" — the test is whether it feels like ANY of these three Egyptian worlds, all equally canonical:

> **Image 1 — The Cairo apartment**: teta in her galabeya cooking molokhia in a modern Cairo apartment kitchen, sunlight through the high window, a fanous from last Ramadan in the corner, the world outside the window today's Cairo.
>
> **Image 2 — The Coptic family scene**: a Cairo apartment, mother in modern dress, a small wooden cross visible on a wall, a Sham El-Nessim spread on the table — fesikh and onions and colored eggs, the family laughing together.
>
> **Image 3 — The coastal scene**: Aswan or Alexandria — a mother and child on a felucca on the Nile, OR a grandmother on an Alexandria balcony with the sea behind her, mint tea steaming on the railing.

Each represents a different real Egyptian customer segment (urban Cairo Muslim middle-class; Cairo Coptic middle-class; non-Cairo Egyptian — Upper Egypt or coastal). Together they triangulate "Egyptian-everyday" without any single image being canonical.

The shared quality across all three: **traditional family warmth threaded through modern context, neither extreme dominating.**

---

## Audience balance — 60/40 parent-led with kid moments

The brand frame favors the **parent** (who buys, who must feel trust, who scans the landing page), but creates dedicated **kid-magical zones** at specific touchpoints.

| Surface | Lean | Visual character |
|---|---|---|
| Landing page | Parent-first | Premium warm storybook, restrained delight |
| Order wizard | Kid-magical | Characters, animations, playful copy, "magic happening" feel |
| "Your book is being made" | Kid-magical | A character at work — illustrator, printer, storyteller |
| Order confirmation / receipt | Parent-first | Clean, warm, trustworthy, modern |
| Account / order tracking | Parent-first | Functional with warmth, not corporate |
| The book interior | Full kid-mode | Pure kid-magic — characters, story, full illustration |

**Pattern rule for component design**: parent-register is the structural baseline (default shadcn variants); kid-magical moments override locally with explicit `playful` or `animated-character` variants. Two registers, one identity.

**60/40 is the launch hypothesis, not a permanent commitment.** Revisit at 100 sales based on funnel data; brand floor is 50/50 (not below). This gives the team permission to evolve based on evidence without panicking about brand drift.

---

## Reference + anti-reference

### Primary visual reference (~75% match)

**[magicalchildrensbook.com](https://magicalchildrensbook.com/)** — captures the warmth, the soft-pastel-section-rhythm, the kid-as-hero-of-illustrations, the storybook layout. Misses the Egyptian soul layer entirely.

### What we keep from the reference

- Section-by-section color rhythm (each band gets its own dominant tone, creating visual cadence on long pages)
- Generous whitespace, breathable layout
- Watercolor-feeling hero illustrations
- Friendly-serif-leaning headers + clean sans body
- Pastel-band CTAs

### What we change from the reference

- Pastel palette → Egyptian earth-tone palette (terracotta, ochre, sienna, cream-with-yellow-undertone, deep teal accent)
- Generic-diverse-Western kids → Egyptian children in Egyptian everyday settings (across the religious + geographic spectrum the North Star set captures)
- Western grandmas in cardigans → Egyptian teta in galabeya OR modern dress (varies by depicted family)
- Latin-only typography → Arabic-RTL primary (Tajawal + El Messiri + Aref Ruqaa)
- Decoration via curved-line elements → decoration via subtle Egyptian geometric-pattern textures (drawing from Coptic + Islamic + folk-embroidery shared visual vocabulary)

### Anti-references (what Hadouta must NEVER feel like)

- Tourist-Egypt brands selling Pyramids/Pharaohs/Cleopatra postcards
- Generic Gulf or Levantine aesthetics (we're specifically Egyptian)
- Imported Western children's content with Arabic dub
- Mass-market Arabic kids' TV channel aesthetic (bright-primary, simple-shapes, Disney-Junior-coded)
- SaaS-modern (Stripe / Linear / Notion / Webflow templates)

---

## Illustration style — Hadouta IS the watercolor brand

**Strategic position:** Hadouta MVP is **the watercolor brand**. Future style tiers (Pixar 3D, soft anime, kawaii) will be **distinct brand surfaces** — sub-brands or distinct landing experiences — *not* style variants on the same chrome.

This is a deliberate honesty correction. Earlier brief drafts claimed the chrome was style-agnostic. It isn't: the cream paper-grain, Aref Ruqaa hand-pen calligraphy, hand-drawn dividers, and vintage palette ARE watercolor-coded. Pretending otherwise creates a problem at v2 launch when a kawaii customer lands on watercolor-coded chrome that contradicts what they're buying.

### MVP launch — watercolor only, brand-aligned

Beatrix Potter / E.H. Shepard tradition: soft outlines, gentle painted color, vintage-feel-but-present-tense, character-faces-clearly-rendered. Closest reference: image #4 ("Max Sees the Seasons") from magicalchildrensbook.com. The brand chrome (website, wizard, receipts) is designed to be visually-cohesive WITH the watercolor illustration style.

**Rationale**: stylized enough to forgive AI face-generation imperfections; recognizable enough that the customer-uploaded child sees themselves in the book; consistent with ADR-005's "L3 photo upload + watercolor (NOT Pixar 3D)."

### Future tiers (post-MVP, deferred to v2 / ADR-019)

When future styles launch, they will get **distinct brand surfaces**:
- **Pixar 3D** — premium tier, photoreal-leaning rendering. Likely a dedicated landing route or sub-brand with chrome aligned to that style (sleeker typography, higher-contrast palette, less paper-grain texture).
- **Soft anime** — Studio Ghibli-vibe painterly anime; warm cinematic chrome to match.
- **Kawaii / chibi** — big-eyes, exaggerated-cute, manga-influenced; likely brighter saturated chrome to match.

### Architectural-from-day-one note (ADR-019 territory)

Even though MVP ships single-style, the codebase MUST architecturally support multi-style from the start:

- **Database schema**: `style` is a first-class field on `themes`, `orders`, `illustrations` — even though the only currently-populated value is `'watercolor'`
- **AI prompt pipeline**: prompt templates are parameterized by style, even though only watercolor templates exist at launch
- **Order wizard**: a `selectedStyle` field exists in the wizard's hidden state, defaulted to `'watercolor'`, even though the user-facing "choose style" step is hidden in MVP
- **Theme catalog**: themes are tagged with which styles they support, even though only watercolor is currently supported
- **Validator framework (ADR-012)**: validators are style-aware (a kawaii-cultural-validator and a watercolor-cultural-validator can have different rules)

**Why this matters**: doing this now is ~negligible cost (a few extra columns, a few parameterized prompts). Doing it later means a populated-production-DB migration, a refactor of the prompt pipeline, and rewriting a wizard customers are actively using. Adding a future style becomes a feature flag flip, not a refactor.

**This will be formally captured in ADR-019** (still owed; will write after Phase 1 closes).

---

## Color palette

**Approach**: cream-base + content-palette-layered (option C from discovery). Generous warm cream backgrounds dominate; content palette (terracotta, ochre, teal, deep brown) layers as accents and section bands.

### Working palette (first-pass hex; refine in Phase 2 token work)

| Role | Direction | Approx hex | Egyptian anchor |
|---|---|---|---|
| Background dominant | Warm cream, yellow-undertone | `#FBF5E8` | Old galabeya cotton, sun-on-paper |
| Primary warm / CTA | Terracotta-sienna | `#C56B47` | Cairo afternoon clay pot |
| Secondary warm | Ochre / honey | `#D4A24C` | Saffron, golden hour, honey jar |
| Cool accent (sparing — 5-10% of visual weight) | Deep Egyptian teal | `#2A6F75` | Khan el-Khalili glass, Islamic tile, traditional door |
| Text / gravitas | Warm deep brown | `#3D2817` | Old leather, oud-wood, coffee |
| Soft kid-magic accent | Dusty rose-blush | `#E8B7A0` | Cheek-warmth in illustrations |

### Critical palette rules

- **Cream MUST have a yellow undertone**, never cool/blue/grey. The yellow undertone is what reads as "old paper / sun-touched / well-loved" rather than "Scandinavian-modern."
- **Teal is sparing** — no more than 5-10% of visual weight per page. The single cool accent in a warm palette is what gives dimension; overuse tips toward Tiffany-blue-corporate.
- **Section rhythm**: long pages alternate cream sections with single-tone bands (cream → terracotta band → cream → teal band → cream → ochre band → cream). Each band gets one dominant tone with cream + 1 accent.

---

## Typography — three-tier hybrid system

### Stack

| Tier | Font | Use | Frequency |
|---|---|---|---|
| **Decorative / kid-magic** | **Aref Ruqaa** | Hadouta logotype, book-interior chapter titles, occasional hero headers, special-moment titles | **Rare** — appears no more than once per page |
| **General headers** | **El Messiri** | Page headers, section titles, navigation, most "this is a heading" moments | Most common header use |
| **Body & UI** | **Tajawal** | All reading content, form labels, body copy, buttons, captions, microcopy | All non-header text |
| **Latin companion** | TBD (likely Fraunces or Spectral) | Secondary English text where needed | TBD in Phase 2 |

### Rationale

- **Aref Ruqaa** is calligraphic Arabic Ruqaa — feels like ink-pen handwriting, very pre-modern, very warm. Maximum storybook feel. Earns attention by appearing rarely.
- **El Messiri** is **Egyptian-designed** (by Mohamed El-Messiri) — its letterforms have specifically Egyptian humanist DNA. Most international Arabic websites don't think about which Arab country their typography "belongs to" — but Arabic typography has regional dialects in its letterforms, just like spoken Arabic does. El Messiri carries Egyptian visual heritage in the type itself.
- **Tajawal** is universal-modern Arabic — clean geometric, readable at every size. Already loaded in `hadouta-web` per session 2.

### Typography rule

**"Aref Ruqaa appears no more than once per page, only at kid-magic moments or branded titles."** Used too much, it becomes performatively-traditional. Used sparingly, it carries the entire warm-storybook emotional payload.

---

## Voice — Storyteller archetype

The Storyteller archetype gives concrete answers about how Hadouta speaks:

### Tone characteristics

- **Second person, intimate** — "Tell us about your child" / "Let's begin your story" / "Your book is being made" — never "click here" when "let's begin" works
- **Sensory language** — "warm," "soft," "sun-warmed," "carefully-painted," "freshly-told" — not "premium," "advanced," "high-quality"
- **Paced anticipation** — "First we'll need... then we'll show you... then your story begins" — builds rhythm over urgency
- **No transactional vocabulary** — never "purchase," "cart," "checkout" — instead "begin," "create," "send your story home"

### Voice modulation — core voice + situational modulations

The Storyteller has ONE core voice with situational modulations (real Egyptian *hawadit*-tellers operate this way — same voice, different registers):

- **Default register**: warm, intimate, sensory, paced (the description above)
- **Conspiratorial-playful modulation**: when introducing magic moments in the wizard ("now for the fun part…")
- **Plain-honest modulation**: when delivering bad news (failure modes — see next subsection). The Storyteller steps OUT of the story and speaks as a person.
- **Respectful-formal modulation**: legal copy, terms of service, privacy policy. NOT in Storyteller voice — in plain-respectful-Egyptian voice. Storyteller doesn't try to make legal text whimsical.

### Voice traps to avoid

- **Faux-mystical** ("The journey begins... ✨") — that's Disney-marketing-speak, not Storyteller. The Storyteller is grounded. Magic is in *what they show you*, not *what they say*.
- **Over-formal Arabic** (Modern Standard Arabic / فصحى-only in customer-facing surfaces) — Hadouta speaks in a register Egyptian parents would speak to their child in: warm, literate, but not stiff. We avoid the formal-newspaper register; we lean toward the literary-but-warm register of contemporary Egyptian children's literature. (Legal text is the exception; see modulations above.)
- **Cute baby-talk** — Hadouta does not talk DOWN to the parent (or the child). The Storyteller respects everyone in the room.

### Emoji policy

Egyptian WhatsApp culture uses emoji heavily; refusing entirely reads as cold. Allowed:
- ✅ Warm/gentle: 🤍 (heart), 📖 (book), ☀️ (sun), 🍵 (tea), 🌿 (plant), 🎨 (palette)
- ❌ Forbidden: ✨ (sparkle), 🎉 (party), 🚀 (rocket), 💫 (star), 🌟 (glowing star), 🎊 (confetti) — these all read as faux-mystical / SaaS-marketing-coded

Maximum **one emoji per message**. Two or more reads as enthusiastic-marketing, breaking the calm-warmth mood.

### Storyteller voice in difficult moments

The Storyteller does NOT narrate failures as part of the story. When delivering bad news (refunds, errors, payment failures, photo rejections, OTP delivery failures, content-moderation issues), the Storyteller **steps OUT of the story**, speaks plainly and warmly as a person, takes responsibility, includes the fix, and steps back into the story.

**Why this rule matters:** faux-mystical narration of bad news ("Once upon a time, your card was declined…") reads as mockery or gaslighting under emotional pressure. It also fails Meta WhatsApp template review for transactional categories. The "step out of the story" rule protects the Storyteller voice in happy moments precisely BECAUSE the Storyteller refuses to use it for bad news.

**Five worked examples:**

#### 1. Photo upload rejection
- ❌ Faux-mystical: *"Hmm, this little portrait isn't quite the spark we need to begin our story…"*
- ✅ Storyteller-out-of-story: *"محتاجين صورة أوضح للوجه عشان نقدر نرسم نسخة جميلة لطفلكم. ممكن تجربوا صورة من ضوء النهار؟ / We need a clearer photo of the face so we can paint a beautiful version of your child. Could you try a daylight photo?"*

#### 2. Payment failure
- ❌ Faux-mystical: *"The story is paused — let's bring it back to life with another way to pay! ✨"*
- ✅ Storyteller-out-of-story: *"لم يتم الدفع. الكارت ممكن يكون مرفوض من البنك. جربوا كارت تاني أو فودافون كاش، وقصة طفلكم تكمل من نفس النقطة. / Payment didn't go through — your bank may have declined the card. Try another card or Vodafone Cash, and your child's story picks up where it paused."*

#### 3. AI generation failure (manual rejection per ADR-013)
- ❌ Faux-mystical: *"Our magical illustrator is taking a little extra time to get every detail right…"*
- ✅ Storyteller-out-of-story: *"بنعيد تجهيز كتاب طفلكم. أول مرة الرسومات ما طلعتش بالشكل اللي يستحقه طفلكم، فبنرسم مرة تانية. زيادة تقريباً ٢٤ ساعة. هنبعتلكم رسالة أول ما يكون جاهز. / We're remaking your child's book. The first round of illustrations didn't meet the quality your child deserves, so we're painting again. About 24 extra hours. We'll message you the moment it's ready."*

#### 4. OTP delivery failure (WhatsApp didn't arrive)
- ❌ Faux-mystical: *"The code is on its journey — let's give it another moment to arrive!"*
- ✅ Storyteller-out-of-story: *"الرمز ما وصلش على واتساب. نقدر نبعتهولكم على SMS؟ أو جربوا تطلبوه تاني خلال دقيقة. / The code didn't arrive on WhatsApp. Want us to send it via SMS? Or try requesting it again in a minute."*

#### 5. Refund
- ❌ Faux-mystical: *"We're returning your contribution to your story's journey…"*
- ✅ Storyteller-out-of-story: *"بنرجعلكم المبلغ كامل خلال ٣-٥ أيام عمل. عذراً إن الكتاب ما جاش بالشكل اللي توقعناه واتفقنا عليه. لو حابين نحاول مرة تانية في أي وقت، البيانات محفوظة. / We're refunding the full amount within 3-5 business days. Apologies — the book didn't come out the way we promised. If you'd like to try again any time, your details are saved."*

**Voice register in failure moments (the modulation rules):**
- Plain Egyptian Arabic (colloquial, not فصحى) — matches how a friend would deliver bad news
- "We" (نحن / إحنا) not "Hadouta" — accountability is personal, not branded
- Always include the *fix* alongside the failure (what they can do next)
- Never use sensory language ("warm," "gentle") for bad news — it reads as performative
- Never use storytelling structure ("once upon a time," "let's pause our journey") for bad news

### How the Storyteller talks about price

Hadouta books cost real money (per ADR-014: A/B testing 250 vs 300 EGP for digital). The Storyteller talks about price honestly without becoming transactional.

- ✅ *"حدوتة طفلك — ٢٥٠ جنيه، رسومات مكتوبة لأبطال صغار / Your child's story — 250 EGP, hand-painted for small heroes"*
- ❌ *"Starting at just 250 EGP — best price guaranteed!"*
- ❌ *"Premium personalized children's book from EGP 250"*

**Rules:**
- Name the price simply — no "starting at" / "from" hedging
- Avoid "affordable" and "premium" — both feel like anti-words for this brand
- The price always sits next to the *value* (not the discount): "حدوتة طفلك" / "your child's story" appears alongside the number, not "save 50 EGP today"

### Reading-mode implications

- Loading states show *page-being-turned* animations or sentence-by-sentence reveals, not generic spinners
- The order wizard feels like *opening pages of a book*, not a checkout flow
- "Your book is being made" page should feel like a Storyteller is at work — perhaps a character (an illustrated narrator) updating you with progress
- WhatsApp confirmation messages read like the Storyteller is speaking to you personally

---

## Storyteller voice example sheet (do/don't pairs)

For downstream operators (devs writing button labels, marketers writing ads, support writing replies). Hadouta voice on the LEFT, not-Hadouta voice on the RIGHT, with one-line reason.

| Surface | ✅ Hadouta voice | ❌ Not Hadouta voice | Why |
|---|---|---|---|
| Primary CTA button | ابدأ حدوتة طفلك / Begin your child's story | اطلب الآن / Order Now | Storyteller invites; transactional commands push |
| Secondary CTA | شوف نموذج / See an example | عرض المنتج / View Product | Sensory > catalog |
| Photo upload error | محتاجين صورة أوضح للوجه / We need a clearer photo of the face | فشل تحميل الصورة / Image upload failed | Plain accountability > technical-error-message |
| Empty cart / wizard state | لسه ما اخترتش حدوتة / You haven't picked a story yet | السلة فارغة / Cart is empty | Story-language > e-commerce-language |
| Loading state (book generation) | بنحضّر حدوتة طفلكم / Preparing your child's story | جاري المعالجة / Processing | Specific + warm > generic + functional |
| Page title / hero | حدوتة لطفلك، من قلب مصر / A story for your child, from the heart of Egypt | كتب أطفال شخصية / Personalized Children's Books | Sensory + specific > category-noun |
| Order confirmation header | حكايتك بدأت / Your story has begun | تم تأكيد طلبك / Your order is confirmed | Story-frame > transaction-frame |
| Push notification | كتاب طفلك جاهز يتقرأ / Your child's book is ready to be read | طلبك جاهز للاستلام / Your order is ready | Reading > collecting |
| Email subject line | حدوتة {{name}} وصلت / {{name}}'s story has arrived | كتابك جاهز / Your book is ready | Personal + named > impersonal |
| Ad headline | اعمل لطفلك حدوتة هو بطلها / Make a story for your child where they're the hero | أفضل كتاب أطفال شخصي / Best Personalized Children's Book | Active + child-centered > superlative claim |
| FAQ answer opener | السؤال ده بنسمعه كتير... / We hear this question a lot... | الجواب: ... / The answer is: ... | Conversational > Q&A-template |
| About-us page opener | كل حدوتة بتبدأ بطفل... / Every story begins with a child... | شركة حدوتة هي شركة مصرية... / Hadouta Inc. is an Egyptian company... | Story-from-the-customer-up > corporate-from-the-top-down |

**Rule of thumb:** if a sentence works equally well in any e-commerce site, it's not Hadouta voice. Add specificity (named child, story-frame, sensory detail) until it could ONLY belong to Hadouta.

---

## WhatsApp template specification

Per ADR-018, ~5 Meta-approved WhatsApp templates plus the customer-service-window 24h freeform replies. Meta enforces different content rules per template category — voice must adapt accordingly.

### Per-category register guidance

| Meta category | Allowed voice register | Example use cases |
|---|---|---|
| **Authentication** | Compressed-warm-functional. Meta restricts to plainly transactional content. Storyteller voice compresses to "warm but plainly transactional." | OTP, login codes |
| **Utility** | Slightly more warmth permitted. Storyteller voice in restrained form — functional content with one or two touches of warmth, no metaphor. | Order confirmation, "your book is being made," shipping notification (v1.5+) |
| **Marketing** | Full Storyteller voice within Meta's promotional-content rules. Can use metaphor, anticipation, sensory language. | New theme available, abandoned-cart re-engagement, seasonal campaigns |

### 5 worked draft templates

#### 1. Authentication OTP (Auth category)

**Arabic primary:**
```
كود الدخول لحدوتة: {{1}}

الكود صالح لـ ١٠ دقايق. ما تشاركوش الكود مع حد.
```
**English fallback:**
```
Hadouta verification code: {{1}}

Valid for 10 minutes. Don't share this code with anyone.
```
**Notes:** Auth category has zero room for marketing/storytelling. Functional + branded mention only. The "ما تشاركوش الكود مع حد" line is required by Meta auth-template policy.

#### 2. Order confirmation (Utility category)

**Arabic primary:**
```
أهلاً {{1}}! استلمنا طلبكم لكتاب {{2}}. الحكاية بدأت تتجهز.

هنبعتلكم رسالة أول ما الكتاب يكون جاهز (تقريباً {{3}}).

تتبعوا الطلب: {{4}}
```
**English fallback:**
```
Welcome {{1}}! We received your order for {{2}}. The story has begun.

We'll message you when the book is ready (about {{3}}).

Track your order: {{4}}
```
**Notes:** Utility category. One Storyteller-touch ("الحكاية بدأت تتجهز / The story has begun") within otherwise functional content. No metaphor, no sensory language, no anticipation-stretching.

#### 3. Order being made / status update (Utility category)

**Arabic primary:**
```
{{1}}، كتاب طفلكم {{2}} في مراحله الأخيرة.

الرسومات جاهزة. باقي المراجعة النهائية. هيكون جاهز خلال {{3}}.
```
**English fallback:**
```
{{1}}, {{2}}'s book is in its final stages.

The illustrations are ready. Final review is what's left. It'll be ready in about {{3}}.
```
**Notes:** Utility category. Communicates real progress; no fluff. Egyptian parent-style update — direct, warm, factual.

#### 4. New theme available (Marketing category)

**Arabic primary:**
```
{{1}}، حدوتة جديدة للأطفال: {{2}}.

طفلكم بطل القصة. الرسومات بنفس الأسلوب اللي تحبوه.

{{3}} - لأول ٤٨ ساعة بس
شوفوا الحدوتة: {{4}}
```
**English fallback:**
```
{{1}}, a new Hadouta for kids: {{2}}.

Your child becomes the story's hero. Same illustration style you love.

{{3}} - first 48 hours only
See the story: {{4}}
```
**Notes:** Marketing category. Full Storyteller register — anticipation, sensory ("الرسومات اللي تحبوه"), child-as-hero framing. Meta allows promotional language here; we use the room.

#### 5. Abandoned cart re-engagement (Marketing category)

**Arabic primary:**
```
{{1}}، حدوتة طفلكم {{2}} لسه مستنياكم.

البيانات اللي دخلتوها محفوظة. تكملوا من نفس النقطة في ثانية.

{{3}}
```
**English fallback:**
```
{{1}}, your child {{2}}'s story is still waiting for you.

The details you entered are saved. Pick up where you left off in seconds.

{{3}}
```
**Notes:** Marketing category. Anticipation + frictionless-resume. Personal "لسه مستنياكم" (still waiting for you) gives warmth without faux-mystical drift.

### Meta-approval timeline reminder

Per ADR-018:
- Auth template: typically auto-approved if format matches Meta's OTP spec
- Utility templates: 24-48h Meta review per template
- Marketing templates: 24-48h Meta review per template; budget 2-3 revision cycles per marketing template

**Submit templates 2 weeks before launch** to avoid Meta-approval becoming the launch blocker.

---

## Decorative motifs — pattern direction

Subtle Egyptian-pattern textures as decorative-but-non-illustrative elements. Drawing from the **shared geometric vocabulary of Egyptian visual heritage** — Coptic textile patterns, Islamic-art tile, folk-embroidery (these traditions overlap heavily in geometric grammar; the "Egyptian visual heritage" is broader than any one tradition).

- **Geometric Egyptian-pattern motifs** at very low opacity (5-15%) as background textures on accent bands — *whispering* underneath content, never stamped on top
- **Embroidery-edge accents** (think *tatreez*-style patterns) on section dividers — the edge of grandmother's tablecloth showing
- **Subtle calligraphy decorative flourishes** on hero moments (treated as ornament, not figurative Arabic text — and not religious Arabic text)
- **Halftone / paper-grain textures** on cream backgrounds to add tactile depth without illustration
- **Hand-drawn divider lines** between sections (slightly imperfect, warm, not vector-perfect)

**Never:**
- Vector-perfect geometric patterns at full opacity (reads as corporate)
- Loud / large-scale Egyptian-pattern stamping (reads as touristy)
- Pharaonic / hieroglyphic motifs as branding (touristy and inaccurate)
- Religion-specific motifs as chrome decoration (no fanous, no cross, no Quranic calligraphy as ornament — those live in book content driven by customer theme choice, not brand chrome)
- Ornamental flourishes that feel "fancy" rather than "warm"

### Decorative-motif source (production task)

**Phase 2.5 task (~10K EGP, ~2-4 weeks):** commission an Egyptian decorative-motif asset library — 8-12 pattern motifs sourced from photographic references at Khan el-Khalili / Coptic Museum / Egyptian Textile Museum, redrawn at low opacity for chrome use. This is non-optional; stock Islamic-pattern libraries are mostly Maghrebi/Iranian, AI-generated patterns undermine the cultural-specificity moat per ADR-002, and the brand needs defensible authentic assets.

---

## Acceptance test for design work — 5 questions across 4 roles

Different operators need different tests. The brand commitments stay constant; the test format adapts.

### For designers / illustrators / writers

When evaluating a design decision (component, page, illustration choice, micro-copy):

1. **The 3-worlds test**: does this feel like ANY of the three Hadouta worlds (Cairo apartment, Coptic family, Aswan/Alex coastal) — modern-Egyptian-everyday with traditional family warmth threaded through?
2. **The Storyteller test**: does this sound/feel like a Storyteller speaking — intimate, sensory, paced — or like a SaaS marketing page? (Failure modes follow the *step-out-of-story* rule.)
3. **The 60/40 test**: is this surface parent-first or kid-magical, and does the visual register match?
4. **The anti-mood test**: does this trip any of the four anti-words — soulless, cheap, childish-bubbly, plasticky?
5. **The watercolor-brand test**: does this design extend the watercolor brand identity coherently? (Future style tiers will have distinct surfaces; we don't need to test against them.)

### For AI prompt engineers (per ADR-006)

Prompt-template-level acceptance:
- Does this prompt produce output that passes test #1 reliably across 50 generations?
- Does it produce Egyptian-specific results (not "Arab-feeling" generic) without touristy clichés?
- Does it pass the Inclusive Visuals Specialist's framework (no clone faces, no gibberish Arabic text/symbols, no hero-symbol composition, mandate physical reality)?

### For customer-support agents (WhatsApp replies)

Rapid voice-check:
- Would the Storyteller say this? Reference the example sheet above.
- For bad news: does it follow the *step-out-of-story* rule?
- One emoji maximum; from the allowed list.

### For marketing creatives (FB/IG ads per ADR-016)

Campaign-level test:
- Does this ad creative pass test #4 (anti-mood) under the assumption of a 1.5-second skim?
- Does it represent a real Egyptian segment (not generic "Arab-coded" stock imagery)?
- Does it pass the cultural-authenticity foundation claim (real Egyptian children, real Egyptian settings)?

If a design passes the relevant test set, ship it. If it fails any, revise.

---

## Hidden assumptions made explicit

Brand briefs that don't surface their assumptions become silent argument-starters six months later. The brief assumes:

### H1 — Hadouta's soul is the grandmother (teta), even though the buyer is the mother

The North Star anchors on teta. The Storyteller archetype is grandmother-coded (cooking, storytelling tradition, galabeya, embroidered cloth). The buyer is the mother. The brand position: **Hadouta is the grandmother's warmth, given by the mother, received by the child.** The mother doesn't need to feel central in the brand chrome because she's the one *gifting* the brand to her child. This is deliberate and durable.

### H2 — Target age range is 3-8

The 16-page format (ADR-005), photo upload value prop, and watercolor illustration style all imply ages 3-8. Future expansion to 0-2 (board books) and 9-12 (chapter books) is deliberately NOT in scope for MVP. State this clearly so the team doesn't drift into board-book or chapter-book territory accidentally.

### H3 — Egyptian = Egyptian-resident, with diaspora as a real-but-secondary segment

Per ADR-018, the expat-gifter persona is acknowledged. The brand brief codes default-Egyptian as resident-Egyptian, but accommodates diaspora through:
- Order flow that doesn't require Egyptian-specific knowledge (no Egyptian phone number required for billing-only purposes; international card payment supported per ADR-009)
- Brand chrome that reads as "the Egypt I left" (warm-traditional-grounded) rather than "the Egypt I never knew" (touristy-historical)

Diaspora gifters are a 20-30% strategic segment; the brand serves them via thoughtful ordering UX, not separate brand chrome.

### H4 — "Modern Egypt" defaults to contemporary middle-class urban Cairo, with Sahel/Alex/Aswan as natural extensions

Other Egypts exist (rural Upper Egypt, Sinai, working-class Mansoura, 6th-of-October compounds). The brand brief picks middle-class urban Cairo + Sahel/Alex/Aswan coastal as the default depicted Egypts. Other Egypts are not excluded from book content (a customer can order a story set anywhere in Egypt) but the marketing imagery and brand chrome lean toward this default. Working-class and rural-Upper-Egypt expansion is a v1.5+ marketing-imagery question.

### H5 — Storyteller has one core voice with situational modulations, NOT a single uniform voice

The "Voice modulation" section above operationalizes this. Stating it explicitly here so the team doesn't read "voice characteristics" as "the only acceptable voice." The Storyteller adapts; that adaptation is part of being a real Storyteller.

---

## Brand-protection workstream (parallel to design work)

### Trademark + naming protection

"Hadouta" (حدوتة) is a generic Arabic noun meaning "story" — the weakest possible trademark category. Protection requires:
- A **distinctive logotype** (the wordmark itself becomes the protectable mark, not the word). Aref Ruqaa as wordmark is the starting point; commissioned hand-lettered logotype is the upgrade. Phase 3 visual-identity work.
- **Trademark registration in Egypt** in classes 9 (software), 16 (print), 28 (toys + games), 41 (entertainment services). Track B legal task.
- **Domain protection**: `hadouta.com` (locked), plus `.eg`, `hadouta.app`, `hadouta.co`, common typos. Track B.
- **Social-handle protection**: `@hadouta` across IG, TikTok, FB, YouTube, X. Track B Sprint 1 task already in progress.
- **Strategic anticipation**: Egyptian competitors will likely launch with names like "Hawadeet," "Hekaya," "Qessa," "Hadoutet-X," etc. Plan competitive monitoring (quarterly cadence).

### Competitive monitoring cadence

Quarterly "competitive brand audit" — who else is launching Egyptian children's-book products? What brand language are they using? Are they imitating ours? Track for erosion of cultural-specificity moat. Cheap; high signal.

### Brand-evolution clock

Substantive brand refresh review at **18 months post-launch (March 2028)**. Incremental evolution rules in place from day 1; rebrand-if-needed permission embedded in v2 planning. No brand should sit unchanged for 5 years; build the refresh expectation into the operations cadence.

---

## Accessibility commitments (brand-level, not just token-level)

- **Color contrast**: WCAG AA minimum on all foreground/background combinations (Phase 2 token work verifies)
- **Motion**: respect `prefers-reduced-motion` system setting; provide reduced-motion variants of page-turn animations
- **Text scaling**: support browser text scaling up to 200% without layout breakage
- **Screen reader**: Arabic-RTL voice properly identified (lang="ar" attributes on all Arabic content); meaningful alt text on all illustrations (in Arabic)
- **Low-bandwidth Egyptian users**: imagery optimized for 3G connections (responsive images, modern formats, reasonable byte budgets)
- **Slow-device-friendly motion**: animations gracefully degrade on lower-end Android devices
- **Dyslexia consideration**: Tajawal is generally good; if user testing surfaces dyslexia issues, evaluate dyslexia-friendly Arabic alternatives

---

## What's next (after this brief)

### Phase 1 closure

- ✅ Brief drafted (v1.0)
- ✅ Brand Guardian audit pass complete
- ✅ Critical findings (C1-C6) incorporated → v1.1
- ✅ Important gaps (I2 voice example sheet) incorporated
- ✅ Hidden assumptions (H1-H5) made explicit
- ⏸️ User review of v1.1 (current step)
- ⏸️ Lock + commit + push

### Phase 2 — Design tokens ✅ SHIPPED 2026-05-02 (session 5)

Token system landed in `hadouta-web/src/app/globals.css` as a 3-tier hierarchy:
- **Tier 1**: raw Hadouta palette as CSS vars (`--hadouta-cream`, `--hadouta-terracotta`, `--hadouta-ochre`, `--hadouta-teal`, `--hadouta-brown`, `--hadouta-blush`). Values in oklch (perceptually-uniform; clean adjustments for Phase 3 if needed).
- **Tier 2**: shadcn semantic mapping (`--background`, `--primary`, `--secondary`, `--muted`, `--accent`, etc.) wired to tier 1. All shadcn components inherit automatically.
- **Tier 3**: Tailwind utilities exposed via `@theme inline` (`bg-hadouta-terracotta`, `text-hadouta-brown`, etc.).

Typography 3-tier system live in `layout.tsx` via `next/font/google`:
- **Tajawal** (body & UI, kept) — `--font-sans`
- **El Messiri** (general headers; Egyptian-designed) — `--font-heading`
- **Aref Ruqaa** (decorative; max-1-per-page rule) — `--font-display`
- **Fraunces** (Latin companion; replaces Inter) — `--font-latin`

Radius scale per brand brief: `--radius-tight 4px`, `--radius-lg 8px` (buttons/inputs base), `--radius-xl 16px` (cards), `--radius-2xl 24px` (modals/sheets/hero panels). Avoids both no-radius corporate and pill-radius childish-bubbly extremes.

Motion timing per brand brief storyteller-paced: `--motion-quick 200ms` (button hover), `--motion-paced 400ms` (modal/drawer/section reveal), `--motion-page 600ms` (page-turn-feel state transitions).

WCAG AA contrast verified across every meaningful pairing: brown-on-cream 12.6:1 (AAA), cream-on-terracotta 5.0:1 (AA Large for buttons), cream-on-teal 5.0:1 (AA Large), brown-on-ochre 6.5:1 (AA), brown-on-blush 9.5:1 (AAA). One documented edge: terracotta is a CTA / bold-display color, not a body-text background — body content on warm bands should use ochre or blush.

Dark mode kept as a stub (mirrors light-mode values) — deferred per brand brief; real dark-mode design happens when warranted (likely after MVP, alongside admin dashboard work).

UX Architect agent delegation deferred — direct implementation matched the actual decisions captured in v1.1 cleanly. Agent option remains available for Phase 3.

### Phase 2.5 — Decorative-motif asset library

- Commission Egyptian-pattern motifs (~10K EGP, 2-4 weeks)
- 8-12 motifs from Khan el-Khalili / Coptic Museum / Egyptian Textile Museum reference photography
- Redrawn at low opacity for chrome use

### Phase 3 — Figma screen designs

- Re-authenticate Figma MCP (currently disconnected)
- Use `figma:figma-use` MCP + `use_figma` tool to build component-level screen designs:
  - Landing page (parent-first warm-storybook)
  - Order wizard (kid-magical, multi-step)
  - "Your book is being made" page (kid-magical with illustrated character)
  - Order confirmation + WhatsApp message preview
  - Account / order tracking (parent-first)
- Possibly delegate to **UI Designer** agent for the focused multi-screen design pass

### Phase 4 — Review + comment cycle in Figma

- Ahmed reviews, leaves comments on screens
- Iterate via MCP
- Lock when satisfied

### Phase 5 — Implement in code

- Use `figma:figma-implement-design` skill to translate Figma → React/shadcn code
- (Not the `frontend-design` skill — that one fails without a Figma reference, per Ahmed's prior experience)

### Phase 6 — Brand statements (deferred from initial brief; needed before Sprint 1 ad creative)

- Tagline candidates (3-5 to A/B test)
- One-sentence value proposition
- Positioning statement (For [audience], who [need], Hadouta is [category] that [benefit], unlike [alternative], because [proof])
- 30-second spoken pitch for Ahmed and contributors to use verbatim with influencers, journalists, family at dinner

---

## Open decisions / parking lot

1. **Latin companion font** — ✅ **decided 2026-05-02 (session 5)**: Fraunces. Loaded in `layout.tsx`, exposed as `--font-latin`. Revisit during Phase 3 Figma if Spectral feels better in context.
2. **Logotype design** — Aref Ruqaa as wordmark or commissioned hand-lettered logotype? Defer to Phase 3 visual identity work; trademark protection requires the distinctive mark.
3. **Photographic vs illustrated brand imagery** — at any point should we use photography (real Egyptian families, real Cairo streets) on the website? Or all illustration? Likely all illustration for MVP, photography later as part of social-proof / testimonials.
4. **Multi-style architecture (ADR-019)** — formally write the ADR after this brief locks. Captures the architectural-from-day-one decisions noted in the Illustration Style section above.
5. **Storyteller as audio character** — if Hadouta ever launches audio (voiceover, audiobook), what does the Storyteller literally sound like? Genderless / multi-generational / specific-Egyptian-dialect-register? Deferred to v2+ scope.
6. **Print v1.5 brand touchpoints** — packaging, Bosta delivery interaction, unboxing, printed receipt insert. Address before v1.5 sprint plan starts.
7. **Brand-product alignment review milestone** — after first 20 books generated, verify the actual watercolor AI output feels warm-Egyptian-grandmother enough to match the brand frame. If alignment fails, choose: revise brand, revise prompts, revise model.

---

## Related documents

- **ADR-002** — Egyptian cultural specificity is the moat (this brief operationalizes that, including the cultural-authenticity foundation)
- **ADR-004** — Digital-first MVP, optional print upgrade in v1.5 (drives phased OTP timing in ADR-018 and the brand-touchpoint extension parked above)
- **ADR-005** — L3 photo upload + watercolor style (NOT Pixar 3D) — MVP illustration choice consistent with this; future tiers will get distinct brand surfaces (per ADR-019)
- **ADR-006** — AI stack — multi-style support requires per-style prompt templates; ADR-019 will capture architectural details
- **ADR-013** — Active learning loop — brand voice + cultural specificity become validation criteria; the manual-approval gate is the operational mechanism for the cultural-authenticity foundation
- **ADR-014** — Pricing A/B test (250 vs 300 EGP digital) — Storyteller-talks-about-price section above gives voice guidance for the ad creative
- **ADR-016** — Distribution channels phased — marketing-creative voice example sheet (above) is the operational guidance for FB/IG ad creative
- **ADR-018** — Phone-first WhatsApp OTP auth — WhatsApp template specification (above) is the operational guidance for the Meta template submission
- **NEW: ADR-019** (still owed) — Multi-style illustration system architecture (formal capture of the architectural-from-day-one decisions in the Illustration Style section)

---

**This brief was produced through 8 brand-discovery questions in interactive conversation, then audited by Brand Guardian agent for gaps, inconsistencies, and brand-protection blind spots, then revised to incorporate 6 critical findings (3-image North Star, religious positioning, cultural-authenticity foundation, watercolor-brand honesty, failure-mode voice, WhatsApp template specification) plus 1 high-leverage important-gap (voice example sheet) plus explicit hidden-assumption acknowledgments. v1.1 is ready for Phase 2 (token derivation).**
