# ADR-027: Watercolor → Pixar-3D brand pivot

> ⚠️ **SUPERSEDED on 2026-05-10 by ADR-028** (`ADR-028-watercolor-revert-from-pixar-3d.md`). The Pixar-3D brand pivot decided here was reversed after iter 7 face-fidelity testing showed Pixar models bias toward youthful-cute on adult characters and amplify face-geometry rigidity that Nano Banana 2 already struggles with. ADR-005's watercolor register is restored. ADR-026's illustration model lock (Nano Banana 2 + multi-image identity) stands.

**Date:** 2026-05-06
**Status:** ⚠️ SUPERSEDED (was Accepted)
**Supersedes:** ADR-005's "Watercolor/storybook style" decision (the L3 photo-upload decision in ADR-005 stands)
**Superseded by:** ADR-028 (2026-05-10)
**Companion:** ADR-026 (Phase 1 character-fidelity verdict)
**Type:** Brand decision

---

## Context

ADR-005 (2026-04-30) locked Hadouta's visual style as "watercolor/storybook" with explicit rationale: "Watercolor culturally aligns with traditional Arabic kids' books (nostalgia for parents)" and "Watercolor pairs better with Arabic typography than Western Pixar 3D." That decision was made before the team had empirical data on how watercolor as a register interacts with face-fidelity preservation in stylized illustration.

Phase 1 character-fidelity verification (May 2026) produced two findings that contradicted the ADR-005 rationale:

1. **Watercolor washes structurally destroy face fidelity.** Heavy painterly textures wash out the fine features (eye shape, skin tone, hairline detail) that drive the founder's "wtf that's him" recognition test. Industry convergence — Magic Story, Little Hero, Lullaby.ink, TinyTeller — uses Pixar-3D / 3D-stylized registers because face geometry maps directly onto rendered 3D faces. Watercolor was an aesthetic preference that fought the gem-of-the-product.

2. **Pixar-3D pairs cleanly with Arabic typography in our pipeline.** ADR-005's concern was hypothetical (no empirical test). In Phase 1 iteration 6, Nano Banana 2 rendered Pixar-3D Egyptian children alongside Arabic alphabet posters (الألف الباء التاء) on classroom walls and Egyptian cultural anchors (date palms, warm-stone arches) without typographic clash. The PDF assembly layer (Puppeteer rendering Arabic titles in Aref Ruqaa / El Messiri / Cairo fonts per ADR-023) is independent of the illustration register and works equally well over Pixar-3D body images.

3. **The cultural-nostalgia argument was speculative.** The actual cultural specificity of Hadouta lives in *content* (Egyptian-Arabic story voice, kahk/fanous/makarona-bashamel cultural anchors, Egyptian settings, Egyptian human reviewer), not in the *illustration register*. ADR-024's Bible-driven cultural-glossary captures the moat at the content layer. The aesthetic register is now an open variable.

## Decision

**Hadouta's locked illustration register is Pixar-3D animated.**

Specifically: stylized 3D rendering in the visual register of Disney Encanto / Coco / Inside Out / Turning Red — soft volumetric lighting, expressive 3D-rendered facial features, smooth subsurface scattering on warm skin, warm cinematic color grading, painterly textures on clothing.

The watercolor/storybook anchor from ADR-005 is dropped.

## Implications for code, brand, and copy

### Code (committed during Phase 1)

- `src/lib/ai/prompts/build-illustration-prompt.ts` — `appendPixarStyleAnchor()` exists as a transitional safety-net overlay; once Sprint 3 rewrites the Bible-gen prompt to produce Pixar-friendly `styleBible` defaults, this overlay can be retired.
- The default `styleBible.medium` Bible-gen produces (`"soft watercolor on cream paper"`) is wrong and will be rewritten in Sprint 3.
- The default `styleBible.negativeStyle` Bible-gen produces (`"NOT 3D-rendered"`) is wrong and will be rewritten in Sprint 3.

### Brand brief (`docs/brand/brand-brief.md` — Sprint 3 edit needed)

The brand-brief watercolor language must be replaced. Specifically:

- "Visual style: watercolor with visible brush strokes and gentle wet-edge bleeds" → "Visual style: Pixar-3D animated, in the visual register of Disney Encanto / Coco / Inside Out, with Egyptian cultural specificity in costuming + setting + props"
- "Palette: warm cream backgrounds, terracotta accents, soft sage greens, golden afternoon light" — the palette stays similar in spirit but is now applied in a 3D-rendered register
- The "AI is the brush, not the artist" tagline stays — it's about how the AI is positioned, not about the medium

The Egyptian-cultural-direction + human-review language stays unchanged. The cultural moat per ADR-002 is content-side, not register-side.

### Customer-facing copy (Sprint 3 edit needed)

- Landing page hero language: replace any "hand-painted watercolor" / "watercolor storybook" framing with "Pixar-quality 3D illustration" / "stylized animated illustration"
- Wizard step copy: any references to watercolor in style-explanation copy are replaced
- Order-confirmation email: same
- WhatsApp delivery template: same
- The AI-honesty framing per `feedback_ai_honesty.md` is preserved (we never claim hand-painted; we now claim "AI-generated stylized illustration with Egyptian cultural direction")

### Sprint 4+ scope unchanged

- ADR-005's L3 photo upload tier — still valid, still in scope
- ADR-005's privacy framing (auto-delete after 30 days, parental consent) — unchanged
- ADR-005's mandatory 1-free-regen-in-7-days policy — unchanged

## What this does NOT mean

- **Egyptian cultural specificity is unchanged.** Pixar-style + Egyptian content = Encanto's relationship between Latin American specificity and Pixar's 3D register. Nothing about Pixar-3D forces Westernization of content.
- **The "premium children's book" positioning is unchanged.** If anything Pixar-3D is more premium-coded than watercolor in the current children's-book market. Magic Story's success at higher price points than watercolor competitors is a market signal.
- **The Storyteller voice is unchanged.** Voice lives in copy + story, not in illustration register.
- **ADR-024's Bible pattern is unchanged.** The Bible still locks character/setting/style/cultural anchors; only the `styleBible.medium` value changes.
- **ADR-019's multi-style architecture is honored.** The `style` field on themes/orders/illustrations is the foundation that made this swap feasible without database migrations.

## Why this ADR is a separate decision from ADR-026

ADR-026 is an *architectural* decision (which model + which prompt strategy + which provider). ADR-027 is a *brand* decision (what does Hadouta look like). They could have been fused but separating them keeps reasoning clean: if a future Phase shows Pixar-3D doesn't fit the market (e.g., Egyptian parents prefer watercolor in usability testing), ADR-027 can be revisited independently of ADR-026's architectural verdict.

## References

- ADR-005 — L3 photo + watercolor (style portion superseded; L3 photo portion stands)
- ADR-019 — Multi-style illustration architecture (the foundation that made this swap painless)
- ADR-024 — Bible-driven illustration pipeline (Bible structure preserved)
- ADR-026 — Phase 1 character-fidelity verdict (architectural companion)
- `feedback_ai_honesty.md` — brand-honesty rules preserved
- Brand brief at `docs/brand/brand-brief.md` (Sprint 3 edit needed to land this ADR's customer-visible side)
