# PDF redesign — design spec

**Date**: 2026-05-03
**Status**: Approved (brainstorming complete) — ready for implementation plan
**Sprint context**: Sprint 3 polish (Sprint 2 shipped functional PDF; this is the visual upgrade)
**Depends on**: ADR-019 (multi-style architecture, watercolor MVP), ADR-022 (Sprint 2 AI pipeline architecture), brand brief (cream/terracotta/ochre/teal palette + Aref Ruqaa / El Messiri / Cairo typography)
**Related ADR (to be written)**: ADR-023 — moral as first-class story output (drives schema change)

---

## 1. Context

The Sprint 2 PDF (see `hadouta-backend/src/lib/pdf/render-book.ts`) is functional but generic. It reads as a printable webpage rather than a printed children's book artifact. Specific issues identified during review:

- No paper texture — flat web cream
- No frame, watercolor wash, or visual structure beyond bare layout
- Page-numbering, image-placement, and text-placement are mechanical rather than intentional
- Parent-discussion-question rendered inside the book contradicts the locked story principle ("story ends with morals, not questions")
- Cover and body pages share no consistent design language
- No use of the brand's three-font hierarchy (Aref Ruqaa / El Messiri / Cairo) — currently uses Cairo + Lalezar only

This spec defines a coherent page system: cover and end-page as bookends in poster register, 16 body pages between them in framed-island register, all sharing the same paper, palette, ornament family, and typographic hierarchy.

## 2. Scope

**In scope:**
- Visual redesign of the three page types (cover, body ×16, end-page)
- Paper texture, palette tokens, ornament family, watercolor washes
- Three-font typographic hierarchy applied across all pages
- Story schema change: new `moralStatement` field on story output
- AI prompt update to generate `moralStatement`
- Removal of `parentDiscussionQuestion` from the PDF (field stays in `storyJson`)

**Out of scope (deferred):**
- Image-aspect handling for non-square Gemini outputs (follow-up brainstorm; current spec assumes square illustrations as Gemini produces them today)
- Moral-moment label (`★ لحظة الحكاية`) keep/drop on body pages — small open question, decide during implementation
- Parent-discussion-question new home — companion card, account-page section, or post-delivery email (separate decision, not blocking this spec)
- Validators framework rules for `moralStatement` quality — Sprint 3 validators work
- Egyptian motif library upgrade — when commissioned motifs land, `✦` ornaments get replaced; the layout doesn't change
- Admin review UX changes (story-as-divs review + PDF preview before approval) — separate brainstorm + spec

## 3. Design decisions (high-level)

| Decision | Outcome | Rationale |
|---|---|---|
| Cover register | Poster (3-edge bleed, 75% image, caption block bottom) | Painting is what the parent paid for — let it dominate. |
| Body register | Framed island (illustration card, ornamental divider, centered text, inner border + corner flourishes) | Forgives variability in Gemini output (consistent chrome regardless of illustration quality). |
| End-page register | Mirrors cover (3-edge bleed, 70% image, caption block bottom) | Front + back act as visual bookends. |
| End-page illustration | Last body page's illustration (page 16 of 16) reused | No new illustration needed; resolution scene is the right closing image. |
| Story closing | Moral statement on end-page (above "النهاية") — NOT a parent question | Story-design principle: stories end with morals, not questions. Parent question lives elsewhere. |
| "النهاية" font | Aref Ruqaa | The brand brief's "max one Ruqaa per page" rule — `النهاية` is the textbook use case. |
| Cover/body title font | El Messiri | Egyptian-designed editorial face; clean for headers without being calligraphic. |
| Body text font | Cairo | Brand body face, optimized for Arabic readability. |
| Brand mark placement | "حدوتة" wordmark, bottom-center, every page | Quiet but consistent presence. |
| Page numbers | Eastern Arabic numerals (٠١٢٣...) | Matches the body's Arabic register. |

## 4. Visual system

### 4.1 Palette

| Token | Hex / RGBA | Used for |
|---|---|---|
| Cream base | `#fffbf3` | Page background base |
| Cream edge | `#fbf4e6` | Outer radial gradient stop |
| Terracotta | `#c66a3d` | Title color, ornament accents, ✦ glyph, page-number numerals |
| Warm tan | `#8b6a4a` | Dedications, moral statement secondary text |
| Body charcoal | `#2d2421` | Body text, moral statement primary text |
| Brand neutral | `rgba(181, 148, 120, 0.7)` | Brand wordmark "حدوتة" |
| Border accent | `rgba(198, 106, 61, 0.18)` | Inner border on body pages |
| Watercolor warm | `rgba(198, 106, 61, 0.18)` + `rgba(232, 201, 160, 0.55)` | Cover/end-page top-right wash |
| Watercolor cool | `rgba(86, 124, 122, 0.10)` + `rgba(232, 201, 160, 0.30)` | Cover/end-page bottom-left wash |

All values match `hadouta-web/src/app/globals.css` design tokens; backend PDF CSS reads them as hard-coded values for portability.

### 4.2 Typography

**Three-font hierarchy** mapped to three semantic roles:

| Font | Role | Used for | Size range | Weight |
|---|---|---|---|---|
| Aref Ruqaa | Decorative, calligraphic — **max one word per page** | "النهاية" stamp on end-page | 36px (end-page) | 700 |
| El Messiri | Editorial headers | Cover title, body-page page-number labels, body-page divider, moral-moment label, end-page ornament label | 10–30px | 600–700 |
| Cairo | Body text | Story text, dedications, moral statement, brand wordmark, closing taglines | 9–17px | 400–600 |

Font loading: single Google Fonts URL with all three families, `display=swap`. Puppeteer `waitUntil: networkidle0` ensures fonts load before render.

### 4.3 Paper texture

All pages share the same paper background (CSS):

```css
background:
  /* paper grain, ~1.5% opacity */
  repeating-linear-gradient(92deg, rgba(139,106,74,0.012) 0, rgba(139,106,74,0.012) 1px, transparent 1px, transparent 3px),
  repeating-linear-gradient(2deg,  rgba(139,106,74,0.018) 0, rgba(139,106,74,0.018) 1px, transparent 1px, transparent 4px),
  /* warm cream radial */
  radial-gradient(ellipse at 50% 50%, #fffbf3 0%, #fbf4e6 90%);
```

Two cross-hatched stripes at ~1.5% opacity simulate paper grain. Almost imperceptible but stops the page reading as flat web cream.

### 4.4 Watercolor washes

Used in caption zones of **cover and end-page only** (body pages have no washes — their visual structure is the inner border + ornaments).

Washes are stacked radial gradients with a 2px blur, layered as `::before` and `::after` pseudo-elements on the caption zone. Two compositions:

- **Lower-left wash** (cool): teal `rgba(86,124,122,0.10)` + ochre `rgba(232,201,160,0.30)` at `60% 50%` and `50% 70%` respectively
- **Lower-right wash** (warm): terracotta `rgba(198,106,61,0.10)` + ochre `rgba(232,201,160,0.20)` at `30% 40%` and `50% 70%` respectively

Both extend ~50–55% wide × 85–95% tall, anchored just outside the caption-zone edge (negative `top: -4px`, negative side offsets) so they bleed naturally.

### 4.5 Ornament family

Single ornamental glyph: **✦** (U+2726). Used everywhere ornament is needed — corners, dividers, page numbers, decorative crowns.

When the commissioned Egyptian motif library lands (per brand brief Track B), this glyph gets replaced by per-context motifs (corner motifs distinct from divider motifs distinct from page-number motifs). The current ✦ family is forward-compatible — replacing it doesn't restructure layouts.

### 4.6 Page dimensions

| Property | Value |
|---|---|
| Format | A5 |
| Width | 148 mm |
| Height | 210 mm |
| Aspect ratio | 1 : 1.4189 |
| Print margin | `0` (full bleed; padding is handled inside the `.page` element) |
| Mockup scale during design | 480 px × 678 px (≈85% of print size) |

Puppeteer call: `page.pdf({ format: "A5", printBackground: true, margin: { top:0, right:0, bottom:0, left:0 } })`.

## 5. Page specifications

### 5.1 Cover

```
┌──────────────────────────────┐
│                              │ ← top edge bleed
│  ┌────────────────────────┐  │
│  │                        │  │
│  │    ILLUSTRATION        │  │ ← 75% of page height
│  │    (3-edge bleed)      │  │
│  │                        │  │
│  └────────────────────────┘  │ ← 32px watercolor fade to cream
│  ────── ✦ ──────             │ ← ornament row
│                              │
│   هُنَا وَعيد ميلادها              │ ← title, El Messiri 28px terracotta
│                              │
│  لـ هُنَا، الحدوتة دي ليكي…       │ ← dedication, Cairo italic 12px
│                              │
│           حدوتة              │ ← brand wordmark
└──────────────────────────────┘
```

**Specifications:**
- Page padding: handled internally; no outer padding
- Illustration: position absolute, top:0, left:0, right:0, height:75%, `object-fit: cover`
- Illustration vignette: radial gradient transparent 65% → `rgba(0,0,0,0.12)` 100%
- Watercolor fade at illustration bottom: 32px tall, `linear-gradient(180deg, transparent 0%, rgba(255,251,243,0.50) 60%, rgba(255,251,243,0.88) 92%, #fffbf3 100%)`
- Caption zone: position absolute, top:75%, bottom:0, padding `0 36px 38px`, `display: flex; flex-direction: column; justify-content: flex-end; align-items: center; text-align: center`
- Two watercolor washes (cool lower-left, warm lower-right) per §4.4
- Ornament row: 32px lines + 12px ✦ centered, 10px gap, color `rgba(198,106,61,0.55)`, ✦ in `#c66a3d`
- Title: El Messiri 700, 28px, color `#c66a3d`, line-height 1.2, letter-spacing 0.01em
- Dedication: Cairo italic 12px, color `#8b6a4a`, line-height 1.6, max-width 320px, margin-top 10px
- Brand wordmark: position absolute, bottom 12px, 9px Cairo 600, color `rgba(181,148,120,0.7)`, letter-spacing 0.35em, centered

**Illustration prompt requirement for cover generation:**
- Subject must be in upper two-thirds of the frame
- Bottom of illustration should be neutral painting (no critical elements like faces, key props) since the bottom 32px will fade

### 5.2 Body page (×16)

```
┌──────────────────────────────┐
│ ✦                          ✦ │ ← inner border + corner flourishes
│   ┌──────────────────────┐   │
│   │                      │   │
│   │   ILLUSTRATION CARD  │   │ ← aspect 4:3.4
│   │                      │   │
│   └──────────────────────┘   │
│                              │
│         ───── ✦ ─────        │ ← ornamental divider
│                              │
│      ★ لحظة الحكاية          │ ← moral-moment label (only on moralMoment pages — open Q)
│                              │
│   هُنَا فكرت: «كل عيد ميلاد…»     │ ← body text, Cairo 17px, centered
│                              │
│       ✦ صفحة ١٤ ✦            │ ← page number, El Messiri terracotta
│ ✦                          ✦ │
└──────────────────────────────┘
                حدوتة            ← brand tick (outside inner border)
```

**Specifications:**
- Page padding: `32px 32px 28px`
- Inner border: `position: absolute; inset: 18px; border: 0.5px solid rgba(198,106,61,0.18); border-radius: 1px; pointer-events: none`
- Corner flourishes: 4× ✦ at the inner border corners, color `rgba(198,106,61,0.4)`, 12px font-size
  - top-left (outer): top:12px, right:12px
  - top-right (outer): top:12px, left:12px
  - bottom-left (outer, above brand-tick): bottom:60px, right:12px
  - bottom-right (outer, above brand-tick): bottom:60px, left:12px
- Illustration card: width 100%, aspect-ratio `4 / 3.4`, border-radius 4px, `object-fit: cover`, inset shadow `inset 0 0 18px rgba(80,60,40,0.10)`, drop shadow `0 2px 6px rgba(80,60,40,0.08), 0 6px 18px rgba(80,60,40,0.10)`
- Ornamental divider: 60% width centered, ✦ ornament with fading lines either side, margin `22px auto 18px`
- Moral-moment label (conditional on `moralMoment: true` on the page): "★ لحظة الحكاية" centered, El Messiri 600, 10px, color `#c66a3d`, letter-spacing 0.18em, uppercase, margin-bottom 12px
- Text block: flex 1 with `align-items: center, justify-content: center`, padding `0 8px`
- Text: Cairo 500, 17px, line-height 2.0, color `#2d2421`, text-align center, RTL
- Page number: symmetric `✦ صفحة ١٤ ✦` flex centered with 10px gaps, El Messiri 600, ✦ at `rgba(198,106,61,0.45)` 10px, "صفحة" 13px, num 15px, color `#c66a3d`
- Brand tick: position absolute, bottom 8px, "حدوتة" 9px Cairo 600, color `rgba(181,148,120,0.55)`, letter-spacing 0.25em, centered

### 5.3 End page

```
┌──────────────────────────────┐
│                              │ ← top edge bleed
│  ┌────────────────────────┐  │
│  │                        │  │
│  │  ILLUSTRATION          │  │ ← 70% of page height; reuses page-16 illustration
│  │  (3-edge bleed)        │  │
│  │                        │  │
│  └────────────────────────┘  │ ← 32px watercolor fade
│                              │
│         ────                 │ ← hairline rule above moral
│   وفي الآخر، عرفت هُنَا إن            │
│   التعاون هو السر…                │ ← moral statement, Cairo 14.5px
│                              │
│           النهاية              │ ← Aref Ruqaa 36px terracotta
│                              │
│           حدوتة              │ ← brand wordmark
└──────────────────────────────┘
```

**Specifications:**
- Illustration: same as cover but height 70% (not 75%); image source = page 16 illustration URL
- Watercolor fade + vignette: same as cover
- Caption zone: position absolute, top:70%, bottom:0, padding `18px 32px 36px`, `flex-direction: column; justify-content: flex-end; align-items: center`
- Two watercolor washes per §4.4 (same as cover)
- **Moral statement** (Cairo 500, 14.5px, line-height 1.85, color `#2d2421`, max-width 360px, centered, margin-bottom 18px)
  - Hairline rule above: 36px wide, 1px high, color `rgba(198,106,61,0.4)`, margin `0 auto 12px`
- "النهاية" stamp: Aref Ruqaa 700, 36px, color `#c66a3d`, line-height 1.0, padding `4px 0 2px` (Ruqaa renders better with breathing)
- Brand wordmark: same as cover

## 6. Pipeline changes (story schema + prompts)

### 6.1 New schema field

Add `moralStatement` to the story Zod schema (`hadouta-backend/src/lib/ai/schemas/story.ts`):

```ts
moralStatement: z
  .string()
  .min(20, "moralStatement must be ≥20 chars")
  .max(220, "moralStatement must be ≤220 chars")
  .describe("Single distilled sentence stating the moral as a takeaway, in Storyteller voice. Names the moral concept explicitly. Used on the end-page above 'النهاية'."),
```

This is a top-level field on the story output (sibling of `title`, `dedication`, `pages[]`, `parentDiscussionQuestion`). Not nested inside any page.

### 6.2 System prompt update

The story system prompt (currently in `hadouta-backend/src/lib/ai/prompts/story-examples/` and the system-prompt module) must instruct the AI to produce `moralStatement` separately from the moralMoment page text. Voice guidance:

- Storyteller voice ("وعرفت X إن…", "وفي الآخر…")
- Names the moral concept explicitly ("التعاون"، "الصدق"، etc.)
- ≤220 characters (single line, two lines max when wrapped)
- Not a question
- Not a marketing tagline ("حدوتة من القلب لقلبك")
- Not the moralMoment page text verbatim — distilled summary, written as a takeaway

Update each few-shot example to include a `moralStatement` field. The validators framework (Sprint 3) will enforce the rules above.

### 6.3 Removal of `parentDiscussionQuestion` from PDF

The field is **kept** on the story schema and in the database — only the PDF rendering removes it.

**Where it lives instead:** TBD, deferred to a separate decision. Candidates:
- Companion card delivered as a second small PDF
- A section on the customer's `/account/orders/[id]` page
- An email Hadouta sends when the book is ready ("بعد ما تخلصوا قراية، اتكلموا في…")

This decision doesn't block the PDF redesign — the field already exists in `storyJson` and renders nowhere by default once we remove its end-page block.

## 7. Implementation file map

| File | Change |
|---|---|
| `hadouta-backend/src/lib/pdf/render-book.ts` | Full rewrite of `buildHtml()` — three new templates (cover, body, end), new shared CSS for paper / washes / ornaments / typography. Update Google Fonts link to add `Aref+Ruqaa:wght@400;700` alongside El Messiri + Cairo |
| `hadouta-backend/src/lib/ai/schemas/story.ts` | Add `moralStatement` field (top-level, sibling of `title`) |
| `hadouta-backend/src/lib/ai/prompts/story-*` (system prompt + few-shot examples in `story-examples/`) | Add `moralStatement` to every few-shot example; update system prompt to require it with the voice guidance in §6.2 |
| `hadouta-backend/src/lib/ai/illustration-generator.ts` (or wherever cover-illustration prompt lives) | Add "subject in upper two-thirds of frame; bottom of illustration neutral painting (no critical elements)" to the cover prompt only — required because the bottom 32px fades into cream |
| Database | No migration — `moralStatement` lives inside the existing `generations.story_json` JSON column |
| `docs/decisions/ADR-023-*.md` | Write ADR for "moral as first-class story output" — references this spec |

## 8. Migration / rollout

- New design applies to **all new generations** from the day the rewritten `render-book.ts` ships
- **No backfill** for existing generations — they keep their old PDF (cheaper, simpler, and the old design isn't broken, just generic)
- Existing generations whose moralStatement field is missing (because they predate the schema update): end-page falls back to a default closing line ("حدوتة من القلب لقلبك") so the page still renders. This fallback is in code, not in the schema.

## 9. Open questions deferred (do not block this spec)

1. **Image-aspect handling** — Gemini outputs are typically square. The body page card is 4:3.4 (slightly portrait). When/if the illustration aspect doesn't match (square stretched into 4:3.4 via object-fit:cover), we may lose key compositional elements at the top/bottom edges. Follow-up brainstorm needed; possible solutions: dynamic card aspect per illustration, prompt change to require 4:3 composition, or accept current stretching as good-enough.
2. **Moral-moment label** ("★ لحظة الحكاية") **keep or drop on body pages?** — Now that the moral statement lives on the end-page, the body-page label is redundant per some readings. Decide during implementation. Defaulting to: keep.
3. **Where parent-discussion-question goes** — companion card / account page / email. Out of scope for this spec.
4. **Validators for moralStatement** — Sprint 3.
5. **Egyptian motif library upgrade** — `✦` glyphs replaced with commissioned motifs when they land. Layout doesn't change.

## 10. Success criteria

| Criterion | How to verify |
|---|---|
| Cover title is legible at thumbnail size in admin queue | Admin queue UI inspection |
| 16 body pages render with consistent chrome regardless of illustration aspect | Visual review of 3–5 generations across themes |
| End-page moral statement reads cleanly with Aref Ruqaa "النهاية" | Visual review |
| Arabic text shaping correct on all pages (RTL, ligatures, diacritics) | Native-speaker review of 1+ generation |
| Cream paper background prints correctly | Open generated PDF in Acrobat/Preview, confirm paper color renders, not white |
| File size under 5 MB for typical 18-page book | `du -h` on a generated PDF |
| Print fidelity: A5 dimensions exact (148×210mm) | Open PDF, check page properties → dimensions match |
| All three fonts load before render (no FOUT) | Inspect first generated PDF; ensure Aref Ruqaa visible on end-page |

## 11. Related decisions / specs

- ADR-019 — Multi-style architecture (watercolor MVP)
- ADR-022 — Sprint 2 AI pipeline architecture
- `docs/design/specs/2026-05-02-phase-3-design-spec.md` — earlier design phase
- Brand brief — palette, typography hierarchy, "max one Ruqaa per page" rule
- (To be written) ADR-023 — Moral as first-class story output

---

**Brainstorm session artifacts** for traceability: `.superpowers/brainstorm/223352-1777803759/content/01..14-*.html` (page-layout exploration through final recap).
