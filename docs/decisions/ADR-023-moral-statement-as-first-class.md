# ADR-023: Moral statement as first-class story output (drives PDF redesign)

**Date:** 2026-05-03 (post-Sprint 2 polish session)
**Status:** Accepted
**Extends:** ADR-022 (Sprint 2 AI pipeline architecture), ADR-020 (AI-only generation, human review only)
**Related spec:** `docs/design/specs/2026-05-03-pdf-redesign-spec.md`
**Related plan:** `docs/design/specs/2026-05-03-pdf-redesign-implementation-plan.md`

## Context

Sprint 2 shipped a working AI generation cycle, but the PDF was the last piece to ship and got the least attention. The end-page rendered the AI-generated `parentDiscussionQuestion` field as the closing content — a question for the parent to ask the child. In a brainstorm session reviewing the first end-to-end output, Ahmed pushed back on this with a foundational story-design point we had discussed but not yet enforced:

> The story ends with **morals**, not with questions. The parent-discussion-question is a separate artifact — useful for parent-child conversation, but it does not belong **inside** the book.

This corresponds to a deeper principle in the brand brief and the locked story-craft rules in the system prompt:
- The moral is **shown** through the protagonist's choice on the moralMoment page (`storyOutputSchema.pages[].moralMoment === true`)
- The body of the story ends with the resolution (typically the last 25% of pages)
- A children's book closes on a **statement**, not a Socratic prompt

The Sprint 2 implementation had no place to render a closing moral statement, because no such field existed on the story output. The narrative-embedded moral on the moralMoment page reads as part of the story, not as a takeaway. So the AI-generated artifact contained a *question* but no distilled *takeaway*.

## Decision

### 1. New top-level `moralStatement` field on `storyOutputSchema`

Single distilled sentence stating the moral as a takeaway, in Storyteller voice. Constraints:
- 20–220 characters
- Required field (`z.string().min(20).max(220)`)
- Must NOT be phrased as a question
- Must NOT duplicate the moralMoment page text verbatim
- Must name the moral concept explicitly (e.g. "التعاون"، "الصدق"، "الشجاعة")

The page text shows the moral *embedded in narrative* ("هنا فكرت..."). The moralStatement states the lesson *as a takeaway* ("وعرفت هنا إن…", "وفي الآخر…").

### 2. AI prompt updates

The story system prompt (`src/lib/ai/prompts/story-system-prompt.ts`) gains a new "Story craft principles" bullet (#9) instructing the AI to produce moralStatement, with explicit voice requirements + good/bad examples + new anti-pattern bullets. All three few-shot examples in `src/lib/ai/prompts/story-examples/` are updated with hand-written moralStatement lines for their respective morals (kindness, courage, generosity-with-dignity).

### 3. PDF rendering — moralStatement on end-page, parentDiscussionQuestion no longer rendered

The PDF redesign (per spec) renders `moralStatement` on the end-page above "النهاية" (in Aref Ruqaa). The end-page no longer includes the parent-discussion-question or any "سؤال للحدوتة" header.

The `parentDiscussionQuestion` field stays on `storyOutputSchema` and in `generations.story_json`. It is not rendered in the book. **Where it goes instead** is a separate decision deferred to a future ADR — candidates include a small companion PDF, a section on the customer's `/account/orders/[id]` page, or the email Hadouta sends when the book is ready. None of those block this decision.

### 4. Backward compatibility

PDFs assembled from generations that predate this ADR (no `moralStatement` in `story_json`) fall back to the closing line `"حدوتة من القلب لقلبك"` so the end-page still renders. This fallback lives in `assembleBookPdf()` in `src/lib/pdf/render-book.ts`, not in the schema (the schema requires the field for new generations).

Existing delivered books are not retroactively reassembled. Customers keep the PDF they were delivered.

## Consequences

**Positive:**
- The book ends with the lesson it was built around. Stories close on statements, not questions.
- A new piece of structured data (`moralStatement`) is available to validators, the admin queue (could show "moral" snippet at-a-glance), and downstream artifacts (companion card, email).
- The system prompt's "Story craft principles" section becomes more explicit about what the moral surfaces look like at three layers: (a) embedded in moralMoment page, (b) reinforced in resolution, (c) distilled on end-page. Layered storytelling.
- AI prompt now explicitly forbids two failure modes that previously slipped through: question-shaped morals, and morals duplicating page text.

**Negative / cost:**
- Slightly larger system prompt (~25 added lines) → small token-cost increase per generation (~$0.0001 at gpt-4o-mini rates, negligible).
- One more thing the AI can fail at — though Zod validation catches missing/short/long values, semantic quality (Storyteller voice, names the moral, not a question) requires either prompt rigor or a future validator.

**Deferred:**
- Validators framework rule for `moralStatement` quality (Sprint 3) — checks Storyteller voice + names the moral + ≤220 chars. Schema enforces length only.
- Where parentDiscussionQuestion lives outside the book — future decision.
- Egyptian motif library (commissioned, ~10K EGP, 2-4 weeks lead) — when it lands, the ✦ ornaments around the page-number row, divider, and corner flourishes get replaced with real motifs without restructuring the layout.

## Implementation

Tracked in `docs/design/specs/2026-05-03-pdf-redesign-implementation-plan.md` (10 tasks). Schema + prompt + few-shot example changes shipped in commits `8effd4a`, `184ecb4`, `616f75c`. PDF rewrite shipped in commits `f87dfde` (scaffold) → `2fb31ff` (cover) → `f8f2322` (body) → `d1bc29a` (end-page) → `3614c92` (Cloudinary downsize for free-tier limit). Verified end-to-end against the existing dev generation `f7d4e9eb-360d-4000-8b13-00fb279512a1` (backfilled `moralStatement`, reassembled, visually inspected).
