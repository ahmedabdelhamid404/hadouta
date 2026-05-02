# ADR-019: Multi-style illustration system — watercolor-only MVP with multi-style-ready architectural foundation

**Status**: Accepted
**Date**: 2026-05-01
**Decision-makers**: Ahmed, Claude
**Supersedes**: nothing
**Builds on**: ADR-005 (L3 photo + watercolor, NOT Pixar 3D), ADR-006 (AI stack), ADR-009 (Neon + R2 storage), ADR-012 (validator layered architecture), ADR-013 (active learning loop)
**Cross-references**: `docs/design/brand-brief.md` v1.1 (Illustration Style section)

## Context

The brand brief discovery (session 4 follow-up, 2026-05-01) and Brand Guardian audit pass both surfaced a tension between **strategic positioning** and **architectural readiness** for illustration style:

- **Brand decision (in brand brief v1.1):** Hadouta MVP IS the watercolor brand. Future style tiers (Pixar 3D, soft anime, kawaii) will be **distinct brand surfaces** — sub-brands or distinct landing experiences — not chrome variants on the same site.
- **Architectural decision (this ADR):** the codebase, data model, AI pipeline, and validator framework MUST architecturally support multi-style from day 1, even though MVP only ships single-style. Adding a style at v2 must be a feature flag flip, not a refactor.

The brand brief established the strategic principle. This ADR formalizes the architectural implications across the schema, AI pipeline, frontend, validator framework, image storage, and operational systems — so that the implicit "we'll figure it out later" assumption doesn't accumulate technical debt that becomes expensive when v2 multi-style actually launches.

The key constraint: **make additions cheap, don't pre-build the additions**. The architectural foundation lives in code structure and data model; concrete style implementations (kawaii prompt templates, anime validators, Pixar pricing tier) are deferred until those styles are on the roadmap.

## Decision

Adopt a **single-style-MVP, multi-style-ready foundation** architecture across seven concerns:

### 1. Database schema — `style` as a first-class field

Add `style` as a typed field to three tables (in their initial schema or as a Sprint-1 migration):

- **`themes.supported_styles`** — `text[]` array of style codes a theme supports. At MVP, all themes have `['watercolor']`. Future themes may support multiple (`['watercolor', 'kawaii']`) or be single-style-specific.
- **`orders.style`** — `text` (or eventually a Postgres enum), the single style the customer chose for this order. At MVP, always `'watercolor'`. Default at order creation; never null.
- **`illustrations.style`** — `text`, the style this rendered illustration was generated in. (Table doesn't exist yet — defined in Sprint 3 when the AI pipeline lands; should include `style` from inception.)

Style codes (initial canonical set, expandable):
- `'watercolor'` — MVP default and only-active value
- `'pixar_3d'` — reserved for v2+ Pixar tier
- `'soft_anime'` — reserved for v2+ Studio Ghibli-vibe tier
- `'kawaii'` — reserved for v2+ chibi/manga tier

Use **`text` with a CHECK constraint** initially (cheap, easy to add codes later); migrate to a Postgres enum when the codes stabilize (likely after 2-3 styles ship and the set is unlikely to change quickly).

### 2. AI prompt pipeline — parameterized by style

Per ADR-006, the AI stack is Claude Sonnet 4.6 + Haiku 4.5 + Nano Banana 2/Pro + GPT Image 2 fallback. The illustration-generation layer must:

- Accept `style` as an input parameter to every illustration-generation function/template
- Maintain a **per-style prompt template registry** — at MVP, only the watercolor template exists; the registry is structured to add more
- Allow **per-style model selection** — different styles may use different generators (Pixar 3D may need a different model than watercolor)
- Allow **per-style negative-prompt sets** — what's "anti-on-brand" differs per style (e.g., for watercolor: "no Pixar-3D rendering, no flat-vector, no photoreal"; for kawaii: different anti-list)

**Concrete code shape (Sprint 3 implementation reference):**
```typescript
type IllustrationStyle = 'watercolor' | 'pixar_3d' | 'soft_anime' | 'kawaii';

interface StylePromptTemplate {
  style: IllustrationStyle;
  basePrompt: string;
  negativePrompt: string;
  preferredModel: 'nano-banana-2' | 'gpt-image-2' | 'pixar-future';
  fallbackModel?: string;
}

const PROMPT_REGISTRY: Record<IllustrationStyle, StylePromptTemplate | null> = {
  watercolor: { /* MVP-active */ },
  pixar_3d: null,        // v2 reserved
  soft_anime: null,      // v2 reserved
  kawaii: null,          // v2 reserved
};
```

### 3. Validator framework — style-aware

Per ADR-012's universal-vs-theme-specific validator architecture, validators become **three-axis**:

- **Universal validators** — apply across all themes AND all styles (e.g., "no harmful content," "Egyptian-cultural-fit," "child-safety")
- **Theme-specific validators** — apply across all styles for a given theme (e.g., "Ramadan theme requires fanous-shaped element," regardless of whether it's watercolor or kawaii)
- **Style-specific validators** — apply across all themes for a given style (e.g., "watercolor must have soft outlines," "kawaii must have proportions in chibi range")

Validators register their applicable axis at definition time. The orchestrator dispatches validators based on the order's (theme, style) combination.

ADR-012 should be updated with a brief addendum noting this third axis when implementation lands; this ADR captures the architectural decision now.

### 4. Active learning loop — style-aware

Per ADR-013's manual-approval gate (first ~200 books), the loop becomes per-style:

- **Each style has its own approval/rejection dataset.** Watercolor's first-200 don't inform kawaii's; kawaii needs its own first-200 manual-approval gate when launched.
- **Embeddings stored in pgvector are style-tagged.** Vector similarity searches filter by style — a watercolor approval dataset doesn't pollute a kawaii approval dataset.
- **Rejection categories may differ per style.** ADR-013's category list is a baseline; future styles may add style-specific rejection reasons.

Practical implication: launching a new style requires re-engaging the manual-approval gate for that style's first ~100-200 books, similar to watercolor's launch.

### 5. Image storage (Cloudflare R2 per ADR-009) — style-namespaced paths

R2 object keys include style as a first-class component:

```
hadouta-illustrations/<style>/<order_id>/<illustration_id>.png
hadouta-illustrations/watercolor/abc-123/page-04.png
hadouta-illustrations/kawaii/def-456/page-04.png  (future)
```

Benefits:
- Per-style migration / pruning / cost analysis becomes trivial (filter by R2 prefix)
- Per-style CDN cache policies become possible (e.g., kawaii images may benefit from longer TTL than watercolor for some reason)
- Per-style access controls if ever needed (e.g., a "watercolor preview tier" with looser access)

### 6. Frontend — order wizard with hidden style step

The order wizard's internal state includes `selectedStyle: IllustrationStyle`, defaulted to `'watercolor'` at MVP.

**At MVP**: the user-facing "choose your style" wizard step is **skipped automatically** (the style is pre-selected and the step is conditionally rendered). The state field exists; the UI just doesn't render the step.

**At v2**: the step is unhidden. Same wizard structure; one feature-flag flip. No structural rewrite.

**Concrete code shape:**
```typescript
const wizardSteps = [
  PhoneNumberStep,
  ChildInfoStep,
  PhotoUploadStep,
  // StylePickerStep — hidden at MVP via feature flag MULTI_STYLE_ENABLED
  ThemeSelectionStep,
  PaymentStep,
];

const visibleSteps = wizardSteps.filter(step =>
  step !== StylePickerStep || featureFlags.MULTI_STYLE_ENABLED
);
```

### 7. Brand surface architecture — distinct surfaces, not chrome variants

When v2 multi-style launches, future styles get **distinct brand surfaces**, NOT chrome variants on the same site. Architectural support today:

- **Next.js route-based theming**: Next.js's nested-layout-per-route architecture allows future routes (e.g., `/pixar/*`, `/kawaii/*`) to have their own `layout.tsx` with distinct chrome — without affecting the watercolor default at `/`. No code structure needed today; the framework supports it natively.
- **Sub-brand domain option**: alternative is dedicated subdomains (`pixar.hadouta.com`, `kawaii.hadouta.com`) — DNS + Vercel project per subdomain. Heavier; defer the choice between route-based and subdomain-based to v2-launch decision.
- **Marketing-creative implications**: ad campaigns for each style point at the appropriate surface. ADR-016's distribution strategy will need per-style segmentation when v2 launches.

**Decision deferred**: route-based-theming vs subdomain-based — pick at v2 launch based on customer signal (do the audiences overlap or diverge? do we want shared cart / shared account across styles?).

## Rationale

### Why MVP is single-style despite multi-style being on the roadmap

- **Production complexity is real.** Each style needs its own prompt templates, validation rules, manual-approval gate (first ~200 books), and brand surface. Launching all four at MVP is not "just one extra column" — it's 4× the validator work, 4× the manual-approval bandwidth, and 4× the marketing-creative production.
- **Customer demand is unproven.** ADR-014's pricing A/B test is currently watercolor-only. Until we have data on watercolor MVP customer behavior, adding stylistic variants is solving for hypothetical preference rather than observed.
- **Brand authenticity (ADR-002) is easier to defend with one style.** The cultural-specificity moat compounds when we can point at a coherent body of work. Four styles diluted across the same period weakens the cultural-authenticity claim.

### Why the architecture must still be multi-style-ready

- **Schema migrations on populated production tables are expensive.** Adding `style` to `orders` after 5,000 orders means: data migration, application code update, prompt code update, R2 key migration, validator framework refactor. Cost: 1-2 weeks. Adding it now: 5 minutes.
- **Frontend wizard refactors are expensive AND customer-facing.** Restructuring an order flow that customers are actively using means: A/B testing the new flow vs old, support burden for customers caught mid-transition, possible conversion drops during the migration period. Adding a hidden step now: half a day.
- **AI prompt pipeline coupling is the highest-risk lock-in.** If prompts are written assuming "one style globally," the rewrite to parameterize-by-style touches every generation function. Cost grows with how much prompt logic accumulates. Doing it now: 1-2 hours of foundation; doing it at v2: depends on how much code accumulated against the single-style assumption.

### Why "distinct surfaces" rather than "chrome variants"

The brand brief made this call after Brand Guardian audit C5: pretending the chrome is style-agnostic is a lie that breaks at v2 launch. The current cream + paper-grain + Aref Ruqaa chrome is watercolor-coded; a kawaii customer would feel mismatch. Distinct surfaces (route-based or subdomain-based) preserve brand integrity per style. Architectural support is free under Next.js's layout system — the decision is "preserve the option," not "build the surfaces now."

## Consequences

### What changes immediately (Sprint 1 / Sprint 2 work)

- **Schema migration**: add `themes.supported_styles text[] DEFAULT ARRAY['watercolor']` and `orders.style text NOT NULL DEFAULT 'watercolor'` with CHECK constraint on the canonical set
- **Type definitions**: introduce `IllustrationStyle` type alias used across backend + frontend + AI pipeline
- **Drizzle schema update**: reflect the new columns; migration generated
- **Order creation flow**: include `style: 'watercolor'` in every order insert (defaulted server-side)

### What changes when AI pipeline lands (Sprint 3)

- **Prompt registry pattern**: implement `PROMPT_REGISTRY` as a typed map; only watercolor populated
- **Generation function signature**: `generateIllustration({theme, style, ...})` — style is required even though only watercolor exists
- **Validator dispatch**: validators register applicable styles; orchestrator filters by order's style
- **R2 path scheme**: object keys include style namespace from day 1

### What changes when frontend order wizard lands (Sprint 4)

- **Wizard state shape**: `selectedStyle: IllustrationStyle` field, defaulted
- **StylePickerStep component**: defined in code, conditionally rendered (`MULTI_STYLE_ENABLED` flag, false at MVP)
- **Order creation API call**: includes `style` field; backend defaults if missing for forward-compat

### What's deferred to v2

- Concrete prompt templates for non-watercolor styles
- StylePickerStep UX design (Figma)
- Per-style brand surface design (route-based or subdomain-based)
- Per-style pricing decisions (ADR-014 extends with style tier)
- Per-style marketing creative
- Per-style validator implementations (universal + theme + style three-axis dispatcher exists; concrete style-specific validators wait until needed)

### What's risk-balanced

- **Risk: over-architecting for hypothetical future.** Mitigation: the architectural cost is small (a few columns, a few type parameters, a hidden wizard step). We're not building anything that's not used; we're shaping data so future use is cheap. The premature-optimization concern is real but doesn't apply when the cost of the foundation is < 1% of the cost of the eventual addition.
- **Risk: customer confusion at v2 launch ("wait, I thought Hadouta was watercolor").** Mitigation: brand brief commits to "Hadouta IS the watercolor brand" at MVP. v2 styles get distinct surfaces with their own branding (sub-brand or route). The watercolor customer's relationship with Hadouta is not disrupted by v2 launch.
- **Risk: schema enum vs text-with-CHECK ambiguity.** Mitigation: start with text+CHECK (cheap to add codes); migrate to Postgres enum when the code set stabilizes. Drizzle supports both.

## Implementation plan

### Phase A — Sprint 1 / Sprint 2 schema foundation (~2 hours)

1. Drizzle schema update in `hadouta-backend/src/db/schema.ts`:
   ```typescript
   export const themes = pgTable("themes", {
     // ...existing fields...
     supportedStyles: text("supported_styles").array().notNull().default(sql`ARRAY['watercolor']`),
   });

   export const orders = pgTable("orders", {
     // ...existing fields...
     style: text("style").notNull().default('watercolor'),
   });
   ```
2. Add CHECK constraint in raw SQL (Drizzle migration custom step):
   ```sql
   ALTER TABLE orders ADD CONSTRAINT orders_style_check
     CHECK (style IN ('watercolor', 'pixar_3d', 'soft_anime', 'kawaii'));
   ```
3. Type definitions in `hadouta-backend/src/types/illustration.ts`:
   ```typescript
   export type IllustrationStyle = 'watercolor' | 'pixar_3d' | 'soft_anime' | 'kawaii';
   export const ACTIVE_STYLES: readonly IllustrationStyle[] = ['watercolor'] as const;
   export const RESERVED_STYLES: readonly IllustrationStyle[] = ['pixar_3d', 'soft_anime', 'kawaii'] as const;
   ```
4. Generate + apply migration; run typecheck + tests

### Phase B — Sprint 3 AI pipeline foundation (timing follows ADR-006 implementation)

1. `PROMPT_REGISTRY` pattern with watercolor-only populated
2. Generation function signature parameterized by style
3. Validator dispatch with three-axis (universal / theme / style) logic
4. R2 path scheme includes style namespace

### Phase C — Sprint 4 frontend order wizard (timing follows order-flow implementation)

1. `selectedStyle` field in wizard state
2. `StylePickerStep` component scaffolded but conditionally hidden
3. Feature flag `MULTI_STYLE_ENABLED=false` at MVP
4. Order API call includes style

### Phase D — v2 future style launch (no fixed date)

For each new style:
1. Add prompt template to `PROMPT_REGISTRY`
2. Implement style-specific validators
3. Set up first-200-books manual-approval gate per ADR-013
4. Design style-specific brand surface (route-based or subdomain-based)
5. Update ADR-014 with style-tier pricing if applicable
6. Production marketing creative for the new style
7. Flip `MULTI_STYLE_ENABLED` flag (or add per-style flag for staged rollout)

## References

### Internal

- **`docs/design/brand-brief.md` v1.1** — Illustration Style section, "Hadouta IS the watercolor brand" decision + architectural-from-day-one notes (this ADR formalizes those notes)
- **ADR-002** — Egyptian cultural specificity is the moat (motivates per-style cultural-authenticity gates)
- **ADR-005** — L3 photo upload + watercolor (NOT Pixar 3D) — MVP illustration choice; future Pixar tier reserved here without contradicting
- **ADR-006** — AI stack — multi-model selection per style is enabled by this ADR
- **ADR-009** — Database + R2 storage — R2 paths now include style namespace
- **ADR-012** — Validator layered architecture — extended with style-specific axis (third axis on top of universal + theme)
- **ADR-013** — Active learning loop — per-style approval gates and pgvector tagging
- **ADR-014** — Pricing A/B test — currently watercolor-only; future style tiers extend it
- **ADR-016** — Distribution channels — per-style marketing creative when v2 styles launch
- **ADR-018** — Phone-first WhatsApp OTP auth — orthogonal but referenced in brand brief; no direct dependency

### Sources of guidance

- Wonderbly's multi-tier model (illustrated standard tier + photo-collage premium tier) — proves multi-tier personalized-book products work commercially
- Postgres enum vs text-with-CHECK trade-off — standard schema-design literature; Drizzle supports both with later migration path

---

**This ADR formalizes the architectural-from-day-one decisions captured in brand-brief v1.1. Implementation lands incrementally across Sprints 1-4 (schema first, AI pipeline at Sprint 3, frontend at Sprint 4) with v2 actual multi-style launch on no fixed date — gated by customer-signal evidence and operational readiness.**
