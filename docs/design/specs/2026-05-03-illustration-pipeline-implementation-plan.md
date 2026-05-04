# Illustration Pipeline Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Sprint 2's text-only Gemini illustration pipeline with a Bible-driven Flux+PuLID pipeline that fixes the four observed failure modes (style drift, character drift, setting drift, cultural literalness).

**Architecture:** Two-stage AI pipeline — gpt-4o-mini generates the story (existing) AND a structured Bible (new) describing locked character/setting/style/cultural anchors. Each per-page illustration prompt is built deterministically from `Bible + scene addendum` and sent to Flux 1.1 Pro via Fal.ai. When customer uploads a photo, gpt-4o-vision describes their child into the Bible AND PuLID injects the actual face during generation. Body pages use the generated cover as visual reference (Edit-based pipeline pattern). New `bible_json` column on `generations` table stores the Bible separately so admin can re-roll illustrations without regenerating story or Bible.

**Tech Stack:** TypeScript 5 strict, Zod 3.x, Vercel AI SDK + GPT-4o-mini, `@fal-ai/client` (Flux 1.1 Pro + PuLID), Drizzle ORM + PostgreSQL (Neon), vitest. Frontend: Next.js 16 + shadcn/ui (RTL Arabic).

**Spec:** `docs/design/specs/2026-05-03-illustration-pipeline-redesign-spec.md`

---

## Phase map

| Phase | Tasks | What ships |
|---|---|---|
| **A. Schema foundations** | 1–4 | Bible schema, persona library, cultural glossary, story scene-rename. Unit-tested. |
| **B. Database migration** | 5 | `bible_json` column. Schema typed end-to-end. |
| **C. Bible generator** | 6–7 | `bible-generator.ts` produces validated Bibles (no-photo + with-photo paths). |
| **D. Illustration prompt + Fal.ai** | 8–10 | `build-illustration-prompt.ts`, Fal.ai client wrapper, PuLID integration. |
| **E. Pipeline orchestration** | 11 | Existing `generate-book.ts` orchestrator wires Bible step + threads everything through. |
| **F. Admin reroll** | 12–13 | `POST /admin/generations/:id/reroll` endpoint + admin UI buttons. |
| **G. Wizard persona picker** | 14 | Frontend swap from free-form to persona grid (with "describe my own" escape). |
| **H. Verification + docs** | 15–16 | E2E real-generation verification + ADR-024 + sprint tracker update. |

You can stop after **Phase E** and have working software that fixes the consistency problem; F and G are UX polish on top.

---

## Pre-flight

```bash
cd /home/ahmed/Desktop/hadouta/hadouta-backend
git status
# Expect: clean tree on main

# Optional: feature branch
# git checkout -b feat/illustration-pipeline-redesign

pnpm test
# Expect: 42/42 tests pass (baseline from PDF redesign work)

# Verify @fal-ai/client is in deps (it is per package.json, but unused)
grep '"@fal-ai/client"' package.json
# Expect: "@fal-ai/client": "^1.10.0"

# Confirm we have a FAL_KEY env var locally
grep "^FAL_KEY=" .env || echo "MISSING: FAL_KEY needs to be set in .env (Ahmed sets up)"
```

If `FAL_KEY` is missing, get it from fal.ai dashboard before starting Phase C+. It's also needed on Railway prod for deploy (set via `railway variables --stdin` per `feedback_secrets_via_stdin` memory — never echo on CLI).

---

## File structure (full map)

| File | Phase | Action | Responsibility |
|---|---|---|---|
| `src/lib/ai/schemas/bible.ts` | A | NEW | Zod schema for Bible structure |
| `tests/unit/bible-schema.test.ts` | A | NEW | Schema validation tests |
| `src/lib/ai/personas.ts` | A | NEW | 6 starter persona definitions |
| `tests/unit/personas.test.ts` | A | NEW | Persona library validates against expected shape |
| `src/lib/ai/cultural-glossary.ts` | A | NEW | 15 Egyptian-term entries with negatives + triggers |
| `tests/unit/cultural-glossary.test.ts` | A | NEW | Glossary entries valid + no duplicate keys |
| `src/lib/ai/schemas/story.ts` | A | MODIFY | Rename `illustrationPrompt` → `scene`; shrink min length; update description |
| `src/lib/ai/prompts/story-system-prompt.ts` | A | MODIFY | Update CORE_INSTRUCTIONS to instruct scene-only output |
| `src/lib/ai/prompts/story-examples/01-friendship-3-5.ts` | A | MODIFY | Each page: `illustrationPrompt` → `scene` (rewrite to scene-only) |
| `src/lib/ai/prompts/story-examples/02-school-5-7.ts` | A | MODIFY | Same |
| `src/lib/ai/prompts/story-examples/03-eid-6-8.ts` | A | MODIFY | Same |
| `src/db/schema.ts` | B | MODIFY | Add `bibleJson` + `bibleRegeneratedAt` to generations table |
| `src/db/migrations/0006_add_bible_json.sql` | B | NEW | Migration adding the column + index |
| `src/lib/ai/prompts/bible-system-prompt.ts` | C | NEW | System prompt for Bible generator |
| `src/lib/ai/bible-generator.ts` | C | NEW | gpt-4o-mini call producing validated Bible |
| `tests/unit/bible-generator.test.ts` | C | NEW | Mocked-AI tests for Bible generation paths |
| `src/lib/ai/prompts/build-illustration-prompt.ts` | D | NEW | Assembles `Bible + scene` per page |
| `tests/unit/build-illustration-prompt.test.ts` | D | NEW | Verify prompts assemble correctly |
| `src/lib/ai/illustration-generator.ts` | D | REWRITE | Drop Gemini, integrate Fal.ai (Flux + optional PuLID) |
| `src/lib/ai/router.ts` | D | MODIFY | Add `flux-*` model prefix routing for cost tracking |
| `tests/unit/illustration-generator.test.ts` | D | NEW | Mocked-Fal.ai tests for cover + body + photo flows |
| `src/jobs/generate-book.ts` | E | MODIFY | Insert Bible generation step; thread Bible + photoUrl into illustration generator |
| `src/routes/admin-generations.ts` | F | MODIFY | Add `POST /:id/reroll` endpoint with `{ scope: "illustrations" \| "bible" \| "story" }` |
| `tests/integration/admin-reroll.test.ts` | F | NEW | Integration test for reroll endpoint scope semantics |
| `hadouta-admin/src/app/orders/[id]/_order-detail.tsx` | F | MODIFY | Reject modal gains scope checkbox/radio |
| `hadouta-web/src/app/wizard/[step]/page.tsx` | G | MODIFY (likely; verify exact path) | Wizard step 2: replace free-form with persona picker grid |
| `hadouta-web/src/components/wizard/persona-picker.tsx` | G | NEW | New component for persona grid |
| `docs/decisions/ADR-024-bible-driven-illustration-pipeline.md` | H | NEW | ADR capturing the architectural shift |
| `docs/sprints/sprint-tracker.md` (umbrella) | H | MODIFY | Sprint 3 entry recording the work |

---

# PHASE A — Schema foundations

Goal: lock the data shapes everything else flows from. After this phase, the schemas exist and validate, but no generators or pipelines use them yet. Pure setup.

## Task 1: Add Bible Zod schema

**Files:**
- Create: `src/lib/ai/schemas/bible.ts`
- Create: `tests/unit/bible-schema.test.ts`

- [ ] **Step 1: Write the failing test**

Create `tests/unit/bible-schema.test.ts`:

```ts
import { describe, expect, it } from "vitest";
import { bibleSchema } from "../../src/lib/ai/schemas/bible.js";

const VALID_BIBLE = {
  characterBible: {
    mainChild: {
      name: "هُنَا",
      age: 4,
      gender: "girl" as const,
      appearance: {
        hair: "dark curly hair shoulder-length pulled into two pigtails with red ribbons",
        skin: "warm medium-olive skin with subtle warm undertones",
        eyes: "almond-shaped large brown eyes with thick lashes",
        distinguishing: "small dimple on left cheek, slight gap between front teeth",
      },
      outfit: {
        default: "yellow cotton sundress with white daisy print, white short-sleeved cardigan, brown leather sandals",
        variations: [],
      },
      personalityVisual: "energetic posture, often mid-motion, expressive eyebrows",
    },
    supportingCharacters: [],
  },
  settingBible: {
    primaryLocation: "Hena's family apartment in Maadi, Cairo",
    primaryLocationDetails:
      "terracotta tile floors, cream-colored walls with framed family photos, teal velvet sofa, ceiling fan, small balcony with potted basil visible through french doors",
    secondaryLocations: [],
  },
  styleBible: {
    medium: "soft watercolor on cream paper, visible brush strokes, gentle wet-edge bleeds, no hard digital lines",
    palette: "warm cream backgrounds, terracotta accents, soft sage greens, golden afternoon light",
    light: "golden afternoon light through soft window curtains",
    negativeStyle: "NOT photorealistic, NOT 3D-rendered, NOT Disney-cartoon, NOT anime, NOT vector-flat, NOT sharp digital lines",
    compositionAnchors: "subject in upper two-thirds of frame, neutral lower third, no embedded text or signage in scene",
  },
  culturalNotes: ["Story takes place during Eid el-Fitr — kahk biscuits on table, NOT chocolate chip cookies"],
};

describe("bibleSchema", () => {
  it("accepts a fully populated valid bible", () => {
    const parsed = bibleSchema.parse(VALID_BIBLE);
    expect(parsed.characterBible.mainChild.name).toBe("هُنَا");
  });

  it("rejects when mainChild.appearance.hair is too short", () => {
    const result = bibleSchema.safeParse({
      ...VALID_BIBLE,
      characterBible: {
        ...VALID_BIBLE.characterBible,
        mainChild: {
          ...VALID_BIBLE.characterBible.mainChild,
          appearance: {
            ...VALID_BIBLE.characterBible.mainChild.appearance,
            hair: "short",
          },
        },
      },
    });
    expect(result.success).toBe(false);
  });

  it("rejects invalid gender enum", () => {
    const result = bibleSchema.safeParse({
      ...VALID_BIBLE,
      characterBible: {
        ...VALID_BIBLE.characterBible,
        mainChild: {
          ...VALID_BIBLE.characterBible.mainChild,
          gender: "other",
        },
      },
    });
    expect(result.success).toBe(false);
  });

  it("rejects when settingBible.primaryLocationDetails is too short", () => {
    const result = bibleSchema.safeParse({
      ...VALID_BIBLE,
      settingBible: {
        ...VALID_BIBLE.settingBible,
        primaryLocationDetails: "short",
      },
    });
    expect(result.success).toBe(false);
  });

  it("accepts empty supportingCharacters and secondaryLocations (MVP)", () => {
    const parsed = bibleSchema.parse(VALID_BIBLE);
    expect(parsed.characterBible.supportingCharacters).toEqual([]);
    expect(parsed.settingBible.secondaryLocations).toEqual([]);
  });

  it("accepts outfit variations array", () => {
    const withVariation = {
      ...VALID_BIBLE,
      characterBible: {
        ...VALID_BIBLE.characterBible,
        mainChild: {
          ...VALID_BIBLE.characterBible.mainChild,
          outfit: {
            default: VALID_BIBLE.characterBible.mainChild.outfit.default,
            variations: [
              { pageNumbers: [13, 14], description: "wearing a red Eid dress with gold embroidery" },
            ],
          },
        },
      },
    };
    const parsed = bibleSchema.parse(withVariation);
    expect(parsed.characterBible.mainChild.outfit.variations).toHaveLength(1);
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
pnpm test tests/unit/bible-schema.test.ts
```

Expected: all tests fail because `src/lib/ai/schemas/bible.ts` does not exist yet.

- [ ] **Step 3: Create the Bible schema**

Create `src/lib/ai/schemas/bible.ts`:

```ts
// Bible schema — locked character/setting/style/cultural anchors that all
// 17 illustration prompts inherit from. Generated once per story by
// gpt-4o-mini (with optional vision call when customer photo is uploaded).
//
// Per docs/design/specs/2026-05-03-illustration-pipeline-redesign-spec.md §5.1.

import { z } from "zod";

const childAppearanceSchema = z.object({
  hair: z
    .string()
    .min(20, "hair must be ≥20 chars — needs detail to anchor identity across pages")
    .describe(
      "Detailed locked description: type, length, color, style. e.g. 'dark curly hair pulled into two pigtails with red ribbons, shoulder length'",
    ),
  skin: z.string().min(10),
  eyes: z.string().min(10),
  distinguishing: z
    .string()
    .describe(
      "Distinguishing features that anchor identity across pages — gap teeth, dimple, freckles, glasses, etc. Empty string OK.",
    ),
});

const outfitVariationSchema = z.object({
  pageNumbers: z.array(z.number().int().min(1)),
  description: z.string().min(10),
});

const supportingCharacterSchema = z.object({
  name: z.string().min(1),
  relationship: z.string().min(1),
  appearance: z.string().min(20),
});

const secondaryLocationSchema = z.object({
  name: z.string().min(1),
  description: z.string().min(20),
});

export const bibleSchema = z.object({
  characterBible: z.object({
    mainChild: z.object({
      name: z.string().min(1),
      age: z.number().int().min(2).max(10),
      gender: z.enum(["boy", "girl"]),
      appearance: childAppearanceSchema,
      outfit: z.object({
        default: z
          .string()
          .min(20)
          .describe(
            "Default outfit on all pages unless story changes it. Specific colors + items.",
          ),
        variations: z
          .array(outfitVariationSchema)
          .describe("Story-driven outfit changes. Most stories have 0–2."),
      }),
      personalityVisual: z
        .string()
        .min(10)
        .describe(
          "Body language, posture cues. e.g. 'energetic posture, often mid-motion, expressive eyebrows'",
        ),
    }),
    supportingCharacters: z
      .array(supportingCharacterSchema)
      .describe("MVP: empty array. Future: regional prompting per character."),
  }),
  settingBible: z.object({
    primaryLocation: z
      .string()
      .min(20)
      .describe("Where the story is mostly set. e.g. 'Hena's family apartment in Maadi, Cairo'"),
    primaryLocationDetails: z
      .string()
      .min(50)
      .describe(
        "Locked visual details that recur across pages — wall colors, furniture, recurring decor. The longer and more specific, the more consistent the illustrations.",
      ),
    secondaryLocations: z.array(secondaryLocationSchema),
  }),
  styleBible: z.object({
    medium: z.string().min(20),
    palette: z.string().min(20),
    light: z.string().min(10),
    negativeStyle: z
      .string()
      .min(20)
      .describe(
        "What this is NOT. Powerful constraints — Flux honors negative prompts. e.g. 'NOT photorealistic, NOT 3D, NOT Disney-cartoon, NOT anime, NOT vector-flat'",
      ),
    compositionAnchors: z
      .string()
      .min(20)
      .describe(
        "Composition rules that apply per page. 'subject in upper two-thirds; neutral lower third; no embedded text or signage in scene'",
      ),
  }),
  culturalNotes: z
    .array(z.string().min(10))
    .describe(
      "Story-specific cultural callouts the AI should remember. e.g. ['Story takes place during Eid el-Fitr — kahk biscuits on table, NOT chocolate chip cookies']. References the static cultural glossary.",
    ),
});

export type Bible = z.infer<typeof bibleSchema>;
export type BibleMainChild = z.infer<typeof bibleSchema.shape.characterBible>["mainChild"];
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
pnpm test tests/unit/bible-schema.test.ts
```

Expected: 6 tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/lib/ai/schemas/bible.ts tests/unit/bible-schema.test.ts
git commit -m "$(cat <<'EOF'
feat(schema): add Bible Zod schema for illustration pipeline

Per docs/design/specs/2026-05-03-illustration-pipeline-redesign-spec.md
§5.1 — locked character/setting/style/cultural anchors that all 17
illustration prompts inherit from. Generated once per story by
gpt-4o-mini (with optional vision call when photo uploaded).

MVP: empty supportingCharacters and secondaryLocations arrays. Future
phases add region-aware multi-character handling.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

## Task 2: Add persona library

**Files:**
- Create: `src/lib/ai/personas.ts`
- Create: `tests/unit/personas.test.ts`

- [ ] **Step 1: Write the failing test**

Create `tests/unit/personas.test.ts`:

```ts
import { describe, expect, it } from "vitest";
import { PERSONAS, getPersonaById, type Persona } from "../../src/lib/ai/personas.js";

describe("PERSONAS library", () => {
  it("contains exactly 6 starter personas", () => {
    expect(PERSONAS).toHaveLength(6);
  });

  it("every persona has unique id", () => {
    const ids = PERSONAS.map((p) => p.id);
    expect(new Set(ids).size).toBe(ids.length);
  });

  it("every persona has Arabic label", () => {
    for (const p of PERSONAS) {
      expect(p.label).toMatch(/[؀-ۿ]/);
    }
  });

  it("every persona has detailed appearance fields", () => {
    for (const p of PERSONAS) {
      expect(p.appearance.hair.length).toBeGreaterThanOrEqual(20);
      expect(p.appearance.skin.length).toBeGreaterThanOrEqual(10);
      expect(p.appearance.eyes.length).toBeGreaterThanOrEqual(10);
    }
  });

  it("every persona has default outfit", () => {
    for (const p of PERSONAS) {
      expect(p.outfit.length).toBeGreaterThanOrEqual(20);
    }
  });

  it("ageBand is one of '3-5' | '5-7' | '6-8'", () => {
    const validBands: Persona["ageBand"][] = ["3-5", "5-7", "6-8"];
    for (const p of PERSONAS) {
      expect(validBands).toContain(p.ageBand);
    }
  });

  it("getPersonaById returns the correct persona", () => {
    const persona = getPersonaById("curly-girl-young");
    expect(persona).toBeDefined();
    expect(persona!.label).toContain("مجعد");
  });

  it("getPersonaById returns undefined for unknown id", () => {
    expect(getPersonaById("does-not-exist")).toBeUndefined();
  });

  it("personas cover both genders", () => {
    const genders = new Set(PERSONAS.map((p) => p.gender));
    expect(genders.has("boy")).toBe(true);
    expect(genders.has("girl")).toBe(true);
  });

  it("personas cover all three age bands", () => {
    const bands = new Set(PERSONAS.map((p) => p.ageBand));
    expect(bands.size).toBe(3);
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
pnpm test tests/unit/personas.test.ts
```

Expected: tests fail because the file doesn't exist.

- [ ] **Step 3: Create the persona library**

Create `src/lib/ai/personas.ts`:

```ts
// Persona library — 6 starter personas for the no-photo wizard flow.
// User picks a persona that roughly matches their child; the persona
// description seeds the Bible's mainChild appearance block (gpt-4o then
// refines based on actual age + name).
//
// Per docs/design/specs/2026-05-03-illustration-pipeline-redesign-spec.md §5.2.

export interface Persona {
  id: string;
  label: string;
  /** "girl" | "boy" — appears in Bible.characterBible.mainChild.gender */
  gender: "boy" | "girl";
  ageBand: "3-5" | "5-7" | "6-8";
  appearance: {
    hair: string;
    skin: string;
    eyes: string;
    distinguishing: string;
  };
  outfit: string;
}

export const PERSONAS: readonly Persona[] = [
  {
    id: "curly-girl-young",
    label: "بنت بشعر مجعد، 3-5 سنوات",
    gender: "girl",
    ageBand: "3-5",
    appearance: {
      hair: "dark curly hair shoulder-length pulled into two pigtails with colorful ribbons",
      skin: "warm medium-olive skin",
      eyes: "large round dark-brown eyes with thick lashes",
      distinguishing: "small dimple on left cheek, slight gap between front teeth",
    },
    outfit:
      "yellow cotton sundress with small white daisy print, white short-sleeved cardigan, brown leather sandals",
  },
  {
    id: "straight-girl-young",
    label: "بنت بشعر طويل ناعم، 3-5 سنوات",
    gender: "girl",
    ageBand: "3-5",
    appearance: {
      hair: "long straight dark-brown hair past the shoulders, simple front fringe",
      skin: "warm fair-olive skin",
      eyes: "almond-shaped honey-brown eyes",
      distinguishing: "rosy cheeks, freckles across the bridge of the nose",
    },
    outfit:
      "soft pink cotton dress with elastic waist, white tights, white canvas sneakers with pink laces",
  },
  {
    id: "hijab-girl-older",
    label: "بنت محجبة، 6-8 سنوات",
    gender: "girl",
    ageBand: "6-8",
    appearance: {
      hair: "wearing a soft cream-colored hijab covering hair completely, small modest visible front",
      skin: "warm medium-olive skin",
      eyes: "large dark-brown eyes with confident expression",
      distinguishing: "wears small silver heart-shaped earrings",
    },
    outfit:
      "long-sleeved sage-green tunic dress over loose cream pants, white sneakers, cream hijab",
  },
  {
    id: "glasses-boy-mid",
    label: "ولد بنظارة، 5-7 سنوات",
    gender: "boy",
    ageBand: "5-7",
    appearance: {
      hair: "short dark wavy hair, side-parted, slightly tousled",
      skin: "warm medium-olive skin",
      eyes: "round dark-brown eyes behind thin round metal-framed glasses",
      distinguishing: "small mole on right cheekbone, gap between front teeth",
    },
    outfit:
      "white short-sleeved t-shirt with simple navy stripe across the chest, dark blue cotton shorts, white sneakers",
  },
  {
    id: "short-hair-boy-young",
    label: "ولد بشعر قصير، 3-5 سنوات",
    gender: "boy",
    ageBand: "3-5",
    appearance: {
      hair: "very short dark-brown hair, slight tuft at front",
      skin: "warm medium-olive skin",
      eyes: "wide-set large dark-brown eyes with curious expression",
      distinguishing: "small dimple on left cheek when smiling",
    },
    outfit:
      "red short-sleeved t-shirt with white star on the chest, beige cotton shorts, white canvas sneakers",
  },
  {
    id: "curly-boy-older",
    label: "ولد بشعر مجعد، 6-8 سنوات",
    gender: "boy",
    ageBand: "6-8",
    appearance: {
      hair: "thick dark-brown curly hair, slightly grown out and tousled",
      skin: "warm tan-olive skin",
      eyes: "large dark-brown eyes with mischievous expression",
      distinguishing: "small scar above right eyebrow from a childhood fall, dimple on right cheek",
    },
    outfit:
      "olive-green button-down short-sleeved shirt over a white t-shirt, dark cotton shorts, brown sandals",
  },
];

export function getPersonaById(id: string): Persona | undefined {
  return PERSONAS.find((p) => p.id === id);
}
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
pnpm test tests/unit/personas.test.ts
```

Expected: 10 tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/lib/ai/personas.ts tests/unit/personas.test.ts
git commit -m "$(cat <<'EOF'
feat(ai): add 6 starter personas for no-photo wizard flow

Persona library is the seed for Bible.characterBible.mainChild when
customer doesn't upload a photo. Covers 6 common Egyptian child types
across 3 age bands and both genders.

Per docs/design/specs/2026-05-03-illustration-pipeline-redesign-spec.md
§5.2.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

## Task 3: Add Egyptian cultural glossary

**Files:**
- Create: `src/lib/ai/cultural-glossary.ts`
- Create: `tests/unit/cultural-glossary.test.ts`

- [ ] **Step 1: Write the failing test**

Create `tests/unit/cultural-glossary.test.ts`:

```ts
import { describe, expect, it } from "vitest";
import {
  CULTURAL_GLOSSARY,
  findRelevantGlossaryEntries,
} from "../../src/lib/ai/cultural-glossary.js";

describe("CULTURAL_GLOSSARY", () => {
  it("contains at least 15 entries", () => {
    expect(CULTURAL_GLOSSARY.length).toBeGreaterThanOrEqual(15);
  });

  it("every entry has Arabic, latin, description, notExamples, triggerKeywords", () => {
    for (const entry of CULTURAL_GLOSSARY) {
      expect(entry.ar).toMatch(/[؀-ۿ]/);
      expect(entry.latin.length).toBeGreaterThanOrEqual(2);
      expect(entry.description.length).toBeGreaterThanOrEqual(40);
      expect(entry.notExamples.length).toBeGreaterThanOrEqual(1);
      expect(entry.triggerKeywords.length).toBeGreaterThanOrEqual(1);
    }
  });

  it("no duplicate latin keys", () => {
    const latinKeys = CULTURAL_GLOSSARY.map((e) => e.latin);
    expect(new Set(latinKeys).size).toBe(latinKeys.length);
  });

  it("includes makarona bashamel with anti-spaghetti negative", () => {
    const entry = CULTURAL_GLOSSARY.find((e) => e.latin === "makarona bashamel");
    expect(entry).toBeDefined();
    expect(entry!.notExamples.some((n) => n.toLowerCase().includes("spaghetti"))).toBe(true);
  });

  it("includes kahk with anti-cookie negative", () => {
    const entry = CULTURAL_GLOSSARY.find((e) => e.latin === "kahk");
    expect(entry).toBeDefined();
    expect(entry!.notExamples.some((n) => n.toLowerCase().includes("cookie"))).toBe(true);
  });

  it("findRelevantGlossaryEntries matches by trigger keyword (case-insensitive)", () => {
    const matches = findRelevantGlossaryEntries(["birthday cake at home", "EID celebration"]);
    const eidMatch = matches.find((e) => e.triggerKeywords.includes("eid"));
    expect(eidMatch).toBeDefined();
  });

  it("findRelevantGlossaryEntries deduplicates", () => {
    const matches = findRelevantGlossaryEntries(["eid eid eid"]);
    const eidEntries = matches.filter((e) => e.triggerKeywords.includes("eid"));
    expect(eidEntries.length).toBeLessThanOrEqual(2); // dedup means each entry returned once even if its trigger appears multiple times in inputs
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
pnpm test tests/unit/cultural-glossary.test.ts
```

Expected: tests fail because file doesn't exist.

- [ ] **Step 3: Create the cultural glossary**

Create `src/lib/ai/cultural-glossary.ts`:

```ts
// Static curated Egyptian cultural glossary. Each entry has:
//   - ar: Arabic term
//   - latin: Latin transliteration (lookup key)
//   - description: full English description for the illustration prompt
//   - notExamples: explicit negative examples (what it is NOT) — Flux honors negatives strongly
//   - triggerKeywords: keywords that trigger inclusion when found in story/wizard inputs
//
// The Bible generator scans storyJson + wizard inputs for trigger keywords
// and includes matching entries in bibleJson.culturalNotes so per-page
// illustration prompts reference them concretely.
//
// Per docs/design/specs/2026-05-03-illustration-pipeline-redesign-spec.md §5.3.

export interface GlossaryEntry {
  ar: string;
  latin: string;
  description: string;
  notExamples: string[];
  triggerKeywords: string[];
}

export const CULTURAL_GLOSSARY: readonly GlossaryEntry[] = [
  {
    ar: "كحك",
    latin: "kahk",
    description:
      "Round Egyptian Eid biscuits dusted with powdered sugar; pale yellow color; sometimes filled with dates or nuts; served on round metal trays at family gatherings during Eid el-Fitr",
    notExamples: ["NOT chocolate chip cookies", "NOT macarons", "NOT Western shortbread"],
    triggerKeywords: ["eid", "kahk", "biscuit", "celebration food"],
  },
  {
    ar: "مكرونة بشاميل",
    latin: "makarona bashamel",
    description:
      "Egyptian baked layered pasta with white béchamel sauce; looks like lasagna's Egyptian cousin; served from a square casserole dish; pale beige top with golden-brown crust; hot family dinner staple",
    notExamples: [
      "NOT spaghetti with meatballs",
      "NOT carbonara",
      "NOT plain pasta",
      "NOT Italian-style red-sauce lasagna",
    ],
    triggerKeywords: ["pasta", "makarona", "family dinner", "casserole"],
  },
  {
    ar: "كشري",
    latin: "koshari",
    description:
      "Egyptian street food: stacked layers of rice + brown lentils + small pasta + chickpeas, topped with crispy fried onions and red tomato-vinegar sauce, served in a takeaway bowl or street-stall plate",
    notExamples: ["NOT plain rice", "NOT biryani", "NOT Indian dal"],
    triggerKeywords: ["street food", "koshari", "lunch"],
  },
  {
    ar: "فطير",
    latin: "fateer",
    description:
      "Egyptian layered flaky pastry; can be sweet (with honey, powdered sugar) or savory (with cheese, ground meat); served sliced into wedges from a round pan; thin gold-brown layered look",
    notExamples: ["NOT pizza", "NOT croissant", "NOT pancake"],
    triggerKeywords: ["fateer", "pastry", "bakery"],
  },
  {
    ar: "ملوخية",
    latin: "molokhia",
    description:
      "Egyptian green soup made from finely chopped jute leaves cooked in chicken or rabbit broth; deep emerald green; served in a deep bowl with rice and torn flat bread on the side",
    notExamples: ["NOT spinach soup", "NOT pesto sauce"],
    triggerKeywords: ["molokhia", "soup", "green dish"],
  },
  {
    ar: "فول",
    latin: "ful",
    description:
      "Egyptian fava beans dish; mashed brown beans with olive oil, lemon, and cumin; served in a small ceramic bowl with flat bread; typical breakfast staple",
    notExamples: ["NOT hummus", "NOT refried beans", "NOT bean salad"],
    triggerKeywords: ["breakfast", "ful", "fava beans"],
  },
  {
    ar: "عيش بلدي",
    latin: "aish baladi",
    description:
      "Egyptian flat round bread with hollow pocket; warm beige color with dusting of flour; sold from street stalls in stacks; ~15cm diameter",
    notExamples: ["NOT pita exactly (Egyptian version is darker, denser)", "NOT naan", "NOT tortilla"],
    triggerKeywords: ["bread", "aish", "baladi"],
  },
  {
    ar: "شاي",
    latin: "shay",
    description:
      "Egyptian tea brewed dark and strong in a small clear glass (NOT a teacup with handle); often served on a small tray; sometimes with fresh mint sprigs",
    notExamples: ["NOT English teacup with handle", "NOT bubble tea", "NOT iced tea"],
    triggerKeywords: ["tea", "shay", "drink", "morning"],
  },
  {
    ar: "جلابية",
    latin: "galabeya",
    description:
      "Egyptian long traditional gown reaching the ankles; loose-fitting; typically worn by adult men or older women; cotton or linen; muted colors (cream, navy, brown, gray)",
    notExamples: ["NOT Saudi thobe (different cut)", "NOT abaya"],
    triggerKeywords: ["traditional clothing", "galabeya", "grandfather", "village"],
  },
  {
    ar: "جامع",
    latin: "gama'",
    description:
      "Local Egyptian neighborhood mosque; sand-colored stone; one or two slender minarets; modest size; warm colored at sunset; often visible at end of a Cairo street",
    notExamples: ["NOT massive Saudi-style mosque", "NOT Iranian-style mosque with blue tiles"],
    triggerKeywords: ["mosque", "gama", "prayer", "neighborhood"],
  },
  {
    ar: "شارع القاهرة",
    latin: "shari' cairo",
    description:
      "Cairo street: narrow, lined with 4–6 story apartment buildings with balconies, satellite dishes, hanging laundry, occasional palm tree, taxi or microbus parked at the curb",
    notExamples: [
      "NOT suburban American street with houses + lawns",
      "NOT Gulf-style boulevards with skyscrapers",
    ],
    triggerKeywords: ["street", "neighborhood", "outside", "balcony", "apartment"],
  },
  {
    ar: "شقة قاهرية",
    latin: "shaqqa cairo",
    description:
      "Typical Cairo apartment interior: terracotta tile floors, cream walls, ceiling fan, framed family photos, balcony doors with thin curtains, simple sofa with patterned throw pillows",
    notExamples: ["NOT American suburban house", "NOT Gulf-style luxury villa"],
    triggerKeywords: ["home", "apartment", "living room", "indoor"],
  },
  {
    ar: "فانوس رمضان",
    latin: "fanous ramadan",
    description:
      "Ramadan lantern: small handheld colorful lantern made of tin and stained glass; warm interior candle glow; geometric patterns; held by children walking around at dusk",
    notExamples: ["NOT Halloween jack-o-lantern", "NOT Western Christmas lantern"],
    triggerKeywords: ["ramadan", "fanous", "lantern", "ramadan night"],
  },
  {
    ar: "سكر ملون",
    latin: "sukkar malawan",
    description:
      "Egyptian rock-candy: hard colored sugar pieces (red, yellow, green) sold in small paper cones at sweet shops; traditional during Mawlid",
    notExamples: ["NOT generic Western candy", "NOT lollipops"],
    triggerKeywords: ["mawlid", "candy", "sweet shop", "festival"],
  },
  {
    ar: "حفلة عيد ميلاد",
    latin: "birthday party cairo",
    description:
      "Egyptian children's birthday party: family living room, balloons taped to wall, large round homemade cake (often cream-frosted with fruit on top), kids in colorful clothes; relatives bring small wrapped gifts",
    notExamples: [
      "NOT American kids' birthday party with rented venue",
      "NOT pinata setup",
      "NOT bouncy castle at the park",
    ],
    triggerKeywords: ["birthday", "party", "celebration", "cake"],
  },
];

/**
 * Finds glossary entries whose triggerKeywords appear (substring, case-insensitive)
 * in any of the input strings. Deduplicates the result.
 */
export function findRelevantGlossaryEntries(inputs: string[]): GlossaryEntry[] {
  const haystack = inputs.join(" ").toLowerCase();
  const matches = new Map<string, GlossaryEntry>();
  for (const entry of CULTURAL_GLOSSARY) {
    for (const keyword of entry.triggerKeywords) {
      if (haystack.includes(keyword.toLowerCase())) {
        matches.set(entry.latin, entry);
        break;
      }
    }
  }
  return Array.from(matches.values());
}
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
pnpm test tests/unit/cultural-glossary.test.ts
```

Expected: 7 tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/lib/ai/cultural-glossary.ts tests/unit/cultural-glossary.test.ts
git commit -m "$(cat <<'EOF'
feat(ai): add static Egyptian cultural glossary (15 entries)

Each entry has Arabic + latin + description + explicit negative examples
+ trigger keywords. The Bible generator uses findRelevantGlossaryEntries()
to populate culturalNotes based on story content, ensuring illustration
prompts ground Egyptian terms in concrete visual descriptions (kahk = NOT
chocolate chip cookies; makarona bashamel = NOT spaghetti meatballs).

This file is the cultural-specificity moat (per ADR-002) made concrete.
A US team can build the same Bible+Flux+PuLID stack — but they don't
have this curated glossary.

Per docs/design/specs/2026-05-03-illustration-pipeline-redesign-spec.md
§5.3.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

## Task 4: Rename `illustrationPrompt` → `scene` on story schema + few-shot examples + system prompt

**This is a bundled task** — story schema, system prompt, and 3 examples all change in lockstep to keep the type system consistent. Single commit.

**Files:**
- Modify: `src/lib/ai/schemas/story.ts`
- Modify: `src/lib/ai/prompts/story-system-prompt.ts`
- Modify: `src/lib/ai/prompts/story-examples/01-friendship-3-5.ts`
- Modify: `src/lib/ai/prompts/story-examples/02-school-5-7.ts`
- Modify: `src/lib/ai/prompts/story-examples/03-eid-6-8.ts`
- Modify: `tests/unit/story-schema.test.ts` (existing test fixture uses old field)

- [ ] **Step 1: Update the test fixture to use `scene` instead of `illustrationPrompt`**

In `tests/unit/story-schema.test.ts`, edit `VALID_BASE.pages` so each page uses `scene` instead of `illustrationPrompt`. Concrete diff:

```ts
// BEFORE
{
  number: 1,
  act: "setup" as const,
  emotionalBeat: "joyful anticipation",
  moralMoment: false,
  text: "كان في يوم مشمس، هُنَا صحيت بدري عشان عيد ميلادها.",
  illustrationPrompt: "Egyptian girl waking up excitedly on her birthday in a Cairo apartment bedroom, watercolor warm light",
},

// AFTER
{
  number: 1,
  act: "setup" as const,
  emotionalBeat: "joyful anticipation",
  moralMoment: false,
  text: "كان في يوم مشمس، هُنَا صحيت بدري عشان عيد ميلادها.",
  scene: "Hena waking up excitedly in her bedroom at dawn, sunlight through the curtain",
},
```

Apply this rename to all 4 page entries in the fixture. Replace each `illustrationPrompt` value with a 1–2 sentence *scene-only* description.

- [ ] **Step 2: Update the story Zod schema**

In `src/lib/ai/schemas/story.ts`, replace the `illustrationPrompt` field on `storyPageSchema` with:

```ts
  scene: z
    .string()
    .min(15, "scene must be ≥15 chars — short scene addendum, not a full prompt")
    .max(280, "scene must be ≤280 chars — keep it tight; the Bible carries the rest")
    .describe(
      "Short English scene addendum for THIS page. 1–2 sentences max. Describe ONLY what is unique to this page (action, location-within-setting, emotional moment). DO NOT include character description, style, or setting details — those come from the Bible. Example: 'Hena gathers kahk biscuits from a metal tray on the coffee table' — NOT 'Egyptian girl in apartment, watercolor style, gathering biscuits from a tray.'",
    ),
```

Also shrink the `coverDescription` field to a similar scene-only register:

```ts
  coverDescription: z
    .string()
    .min(20)
    .max(280)
    .describe(
      "Short English scene description for the COVER page. Iconic + emotional summary of the whole story — 1–2 sentences. DO NOT include character/style/setting boilerplate (those come from the Bible). Example: 'Hena holding a tray of kahk surrounded by friends in her living room, golden afternoon light.'",
    ),
```

- [ ] **Step 3: Update the story system prompt**

In `src/lib/ai/prompts/story-system-prompt.ts`, find the `# Per-page metadata` section and replace the `illustrationPrompt` bullet with:

```ts
- \`scene\` — ENGLISH (not Arabic) — 1–2 sentence scene-only description: action + immediate location + emotional beat for THIS page. **DO NOT** include character description (hair, skin, clothes), art style (watercolor, palette), or setting boilerplate (Cairo apartment) — those come from the Bible and are added automatically when prompts are assembled. Aim for 60–200 characters. Example GOOD: "Hena gathers kahk from a metal tray on the coffee table." Example BAD: "Egyptian girl with curly hair in a Cairo apartment, watercolor warm tones, gathering kahk biscuits from a tray on a coffee table — feeling joyful."
```

Also update the `# Output` section to mention the field is `scene` not `illustrationPrompt` if it's named.

Update the `# Anti-patterns to avoid` section to add:

```ts
- \`scene\` field including character description, art style, or setting boilerplate (those come from the Bible — keep scene addendums tight)
```

Update the `7. **Cover is iconic, not literal**` bullet's reference to `coverDescription` to clarify the new shorter scope.

- [ ] **Step 4: Update few-shot example 1 (Friendship + Kindness, 3-5)**

In `src/lib/ai/prompts/story-examples/01-friendship-3-5.ts`, for every page, replace the `illustrationPrompt` field with `scene` and rewrite to scene-only. Concrete diff for page 1:

```ts
// BEFORE
illustrationPrompt:
  "Egyptian girl ~4 years old in a Cairo neighborhood park sandbox, holding a small red bucket happily, watercolor warm afternoon light, sense of cherished possession",

// AFTER
scene: "Layla sits in a sandbox holding her small red bucket happily, scooping sand with cherished pride",
```

Apply the same rewrite to all 8 pages and to `coverDescription`. The new lines are scene-only — no character/style/setting boilerplate.

- [ ] **Step 5: Update few-shot example 2 (School + Courage, 5-7)**

Same treatment — every `illustrationPrompt` → `scene` with scene-only content. Use the existing rich page text + emotional beat as your guide for what's unique to each page.

- [ ] **Step 6: Update few-shot example 3 (Eid + Generosity, 6-8)**

Same treatment.

- [ ] **Step 7: Run schema + examples + system prompt tests**

```bash
pnpm test tests/unit/story-schema.test.ts tests/unit/story-examples.test.ts tests/unit/story-system-prompt.test.ts
```

Expected: all tests pass. The schema-test fixture matches new shape; the examples-test validates the new shape; the system-prompt-test still passes (its assertions about moralStatement + cover composition are unchanged; we may need to remove any assertion about `illustrationPrompt` if it exists — verify).

- [ ] **Step 8: Run typecheck — catch all consumers of the renamed field**

```bash
pnpm typecheck
```

Expected: clean. If any code outside the AI module references `.illustrationPrompt` on a story page, it will fail here. Most likely consumer: `src/lib/pdf/render-book.ts` already uses a separate field (`book_pages.illustrationPrompt` is its OWN column on the DB, not the one we're renaming — verify by reading the existing code) — so PDF should not break.

- [ ] **Step 9: Run full test suite**

```bash
pnpm test
```

Expected: all tests pass.

- [ ] **Step 10: Commit (single transactional commit — type system depends on lockstep change)**

```bash
git add src/lib/ai/schemas/story.ts \
        src/lib/ai/prompts/story-system-prompt.ts \
        src/lib/ai/prompts/story-examples/01-friendship-3-5.ts \
        src/lib/ai/prompts/story-examples/02-school-5-7.ts \
        src/lib/ai/prompts/story-examples/03-eid-6-8.ts \
        tests/unit/story-schema.test.ts
git commit -m "$(cat <<'EOF'
refactor(ai): rename illustrationPrompt → scene on story pages

Per docs/design/specs/2026-05-03-illustration-pipeline-redesign-spec.md
§5.4 — story now produces SCENE addendums (1-2 sentences, action +
location-within-setting + emotional beat) instead of full standalone
illustration prompts. The Bible owns character/setting/style/cultural
context; the prompt assembler concatenates Bible + scene per page.

Story Zod schema, system prompt, all 3 few-shot examples updated in
lockstep. coverDescription similarly shortened to scene-only.

Validates against updated storyOutputSchema.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

# PHASE B — Database migration

Goal: add the `bible_json` column so subsequent phases can persist Bibles. One small isolated change.

## Task 5: Add `bible_json` column to generations table

**Files:**
- Create: `src/db/migrations/0006_add_bible_json.sql`
- Modify: `src/db/schema.ts`

- [ ] **Step 1: Read current generations table definition**

```bash
grep -A 30 "export const generations" src/db/schema.ts
```

Note the existing columns and table name. The migration must be additive only (no breaking changes).

- [ ] **Step 2: Create the migration file**

Create `src/db/migrations/0006_add_bible_json.sql`:

```sql
-- Add bible_json (locked character/setting/style description) and
-- bible_regenerated_at (track admin re-rolls of just the Bible).
-- Per docs/design/specs/2026-05-03-illustration-pipeline-redesign-spec.md §5.6.

ALTER TABLE generations
  ADD COLUMN bible_json jsonb,
  ADD COLUMN bible_regenerated_at timestamp;

-- Partial index for faster admin queries filtering "has Bible" / "no Bible"
-- (used by future analytics and by reroll handlers that need to know
-- whether a generation predates the Bible system).
CREATE INDEX IF NOT EXISTS idx_generations_bible_present
  ON generations ((bible_json IS NOT NULL));
```

- [ ] **Step 3: Update `src/db/schema.ts`**

In `src/db/schema.ts`, locate the `generations` table definition and add the two new columns. Concrete addition (insert near other timestamp/json columns; preserve existing column order):

```ts
  bibleJson: jsonb("bible_json"),
  bibleRegeneratedAt: timestamp("bible_regenerated_at"),
```

- [ ] **Step 4: Apply the migration to dev DB**

```bash
pnpm db:migrate
```

Expected output: migration `0006_add_bible_json` applied. (If `db:migrate` errors, check `drizzle.config.ts` for the migrations path — should be `src/db/migrations`.)

- [ ] **Step 5: Verify schema in DB matches**

```bash
cat > _verify.mjs <<'EOF'
import 'dotenv/config';
import postgres from 'postgres';
const sql = postgres(process.env.DATABASE_URL, { max: 1 });
const cols = await sql`
  SELECT column_name, data_type FROM information_schema.columns
  WHERE table_name='generations' AND column_name IN ('bible_json','bible_regenerated_at')
  ORDER BY column_name
`;
console.log(cols);
await sql.end();
EOF
node _verify.mjs
rm _verify.mjs
```

Expected: 2 rows — `bible_json` (jsonb) and `bible_regenerated_at` (timestamp without time zone).

- [ ] **Step 6: Run typecheck**

```bash
pnpm typecheck
```

Expected: clean. The Drizzle schema update should give us full type safety for `db.update(generations).set({ bibleJson: ... })` etc.

- [ ] **Step 7: Run full test suite to confirm no regression**

```bash
pnpm test
```

Expected: 42+ tests still pass. (The new test files from Phase A should be there too — total ~65+.)

- [ ] **Step 8: Commit**

```bash
git add src/db/migrations/0006_add_bible_json.sql src/db/schema.ts
git commit -m "$(cat <<'EOF'
feat(db): migration 0006 — add bible_json + bible_regenerated_at

Per docs/design/specs/2026-05-03-illustration-pipeline-redesign-spec.md
§5.6. New top-level column on generations stores the Bible separately
from story_json so admin can re-roll illustrations without regenerating
the Bible (and vice versa).

Partial index for "has Bible" / "no Bible" queries (legacy generations
predating the new pipeline have NULL).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

# PHASE C — Bible generator

Goal: produce validated Bibles from story + wizard inputs. Two paths: no-photo (uses persona description), with-photo (uses gpt-4o vision).

## Task 6: Implement Bible generator (no-photo path)

**Files:**
- Create: `src/lib/ai/prompts/bible-system-prompt.ts`
- Create: `src/lib/ai/bible-generator.ts`
- Create: `tests/unit/bible-generator.test.ts`

- [ ] **Step 1: Write the failing test**

Create `tests/unit/bible-generator.test.ts`:

```ts
import { describe, expect, it, vi } from "vitest";
import { generateBible } from "../../src/lib/ai/bible-generator.js";
import type { StoryOutput } from "../../src/lib/ai/schemas/story.js";

const SAMPLE_STORY: StoryOutput = {
  title: "هُنَا وَعيد ميلادها",
  dedication: "إلى هُنَا — قلبك الكبير هو أحلى هدية.",
  coverDescription: "Hena holding a tray of kahk surrounded by friends in her living room",
  parentDiscussionQuestion: "إزاي ممكن نساعد بعض في الاحتفال؟",
  moralStatement: "وفي الآخر، عرفت هُنَا إن التعاون هو السر.",
  pages: [
    {
      number: 1, act: "setup", emotionalBeat: "joyful anticipation",
      moralMoment: false,
      text: "كان في يوم مشمس، هُنَا صحيت بدري عشان عيد ميلادها.",
      scene: "Hena waking up at dawn excitedly",
    },
  ],
};

const SAMPLE_INPUT = {
  story: SAMPLE_STORY,
  wizardData: {
    childName: "هُنَا",
    childAgeBand: "3-5" as const,
    childAgeExact: 4,
    childGender: "girl" as const,
    theme: "العيد",
    moralValue: "التعاون",
    photoUrl: null,
    personaId: "curly-girl-young",
  },
};

// Mock the Vercel AI SDK's generateObject to avoid real API calls in unit tests.
vi.mock("ai", () => ({
  generateObject: vi.fn(),
}));

import { generateObject } from "ai";

describe("generateBible — no photo (persona path)", () => {
  it("produces a valid Bible from persona seed", async () => {
    (generateObject as any).mockResolvedValue({
      object: {
        characterBible: {
          mainChild: {
            name: "هُنَا",
            age: 4,
            gender: "girl",
            appearance: {
              hair: "dark curly hair shoulder-length pulled into two pigtails with red ribbons",
              skin: "warm medium-olive skin",
              eyes: "large round dark-brown eyes with thick lashes",
              distinguishing: "small dimple on left cheek, slight gap between front teeth",
            },
            outfit: {
              default: "yellow cotton sundress with daisy print, white cardigan, brown sandals",
              variations: [],
            },
            personalityVisual: "energetic posture, often mid-motion",
          },
          supportingCharacters: [],
        },
        settingBible: {
          primaryLocation: "Hena's family apartment in Maadi, Cairo",
          primaryLocationDetails:
            "terracotta tile floors, cream walls with framed family photos, teal velvet sofa, ceiling fan, balcony with potted basil",
          secondaryLocations: [],
        },
        styleBible: {
          medium: "soft watercolor on cream paper with visible brush strokes",
          palette: "warm cream backgrounds, terracotta accents, soft sage greens",
          light: "golden afternoon light",
          negativeStyle: "NOT photorealistic, NOT 3D, NOT Disney-cartoon, NOT anime",
          compositionAnchors: "subject in upper two-thirds; neutral lower third",
        },
        culturalNotes: ["Story takes place during Eid el-Fitr — kahk biscuits on table"],
      },
      usage: { promptTokens: 1500, completionTokens: 800 },
    });

    const bible = await generateBible(SAMPLE_INPUT);
    expect(bible.characterBible.mainChild.name).toBe("هُنَا");
    expect(bible.characterBible.mainChild.gender).toBe("girl");
    expect(bible.styleBible.medium).toContain("watercolor");
  });

  it("includes culturalNotes derived from story content", async () => {
    (generateObject as any).mockResolvedValue({
      object: {
        characterBible: { mainChild: { name: "هُنَا", age: 4, gender: "girl",
          appearance: { hair: "dark curly hair shoulder-length two pigtails", skin: "warm medium-olive skin", eyes: "almond-shaped large brown eyes", distinguishing: "" },
          outfit: { default: "yellow cotton sundress with white daisy print", variations: [] },
          personalityVisual: "energetic posture, mid-motion",
        }, supportingCharacters: [] },
        settingBible: {
          primaryLocation: "Hena's family apartment in Maadi, Cairo",
          primaryLocationDetails: "terracotta tile floors, cream walls, teal velvet sofa, ceiling fan, balcony with potted basil",
          secondaryLocations: [],
        },
        styleBible: {
          medium: "soft watercolor on cream paper with visible brush strokes",
          palette: "warm cream, terracotta, soft sage greens",
          light: "golden afternoon",
          negativeStyle: "NOT photorealistic NOT 3D NOT Disney-cartoon",
          compositionAnchors: "subject in upper two-thirds; neutral lower third",
        },
        culturalNotes: ["Eid el-Fitr — kahk biscuits, NOT chocolate cookies"],
      },
      usage: { promptTokens: 1500, completionTokens: 800 },
    });

    const bible = await generateBible(SAMPLE_INPUT);
    expect(bible.culturalNotes.length).toBeGreaterThanOrEqual(1);
    expect(bible.culturalNotes.some((n) => n.includes("kahk"))).toBe(true);
  });

  it("throws when persona is missing AND no photo provided", async () => {
    await expect(
      generateBible({
        ...SAMPLE_INPUT,
        wizardData: { ...SAMPLE_INPUT.wizardData, personaId: null, photoUrl: null },
      }),
    ).rejects.toThrow(/persona.*or.*photo/i);
  });
});
```

- [ ] **Step 2: Create the Bible system prompt**

Create `src/lib/ai/prompts/bible-system-prompt.ts`:

```ts
// System prompt for the Bible generator. Instructs gpt-4o-mini to produce
// the locked character/setting/style/cultural anchors that all 17 illustration
// prompts will inherit from. Generated AFTER the story is written so the
// Bible can reference story-specific details (e.g. moral concept, special
// occasion, location).
//
// Per docs/design/specs/2026-05-03-illustration-pipeline-redesign-spec.md §5.1.

import type { Persona } from "../personas.js";
import type { GlossaryEntry } from "../cultural-glossary.js";

interface BuildBibleSystemPromptArgs {
  persona: Persona | null;
  photoDescription: string | null;
  childName: string;
  childAgeExact: number;
  childGender: "boy" | "girl";
  themeAr: string;
  moralValueAr: string;
  glossaryEntries: GlossaryEntry[];
}

export function buildBibleSystemPrompt(args: BuildBibleSystemPromptArgs): string {
  const seedAppearance = args.photoDescription
    ? `## Visual seed — derived from uploaded photo

The customer uploaded a photo of their child. A vision model has described what it sees:

> ${args.photoDescription}

Lock the appearance fields to match this description. The customer expects the Bible to reflect THEIR child, not a generic persona.`
    : args.persona
      ? `## Visual seed — selected persona

The customer chose this starter persona: **${args.persona.label}**

Default appearance:
- Hair: ${args.persona.appearance.hair}
- Skin: ${args.persona.appearance.skin}
- Eyes: ${args.persona.appearance.eyes}
- Distinguishing: ${args.persona.appearance.distinguishing || "(none specified)"}

Default outfit: ${args.persona.outfit}

Refine these descriptions to fit ${args.childName} (age ${args.childAgeExact}). Keep the persona's overall character but personalize the details (e.g. add ribbon colors that suit the child's name vibe, adjust slightly for exact age). Do NOT depart radically from the persona — they were picked deliberately.`
      : `## Visual seed — none

NO persona chosen and NO photo uploaded. Invent a coherent appearance for ${args.childName} (age ${args.childAgeExact}, ${args.childGender}). Default to warm Egyptian features unless context dictates otherwise.`;

  const glossaryReference =
    args.glossaryEntries.length === 0
      ? "(no relevant cultural-glossary entries triggered for this story)"
      : args.glossaryEntries
          .map(
            (e) =>
              `- **${e.ar} (${e.latin})**: ${e.description}\n  Anti-patterns: ${e.notExamples.join("; ")}`,
          )
          .join("\n");

  return `You are an art-direction Bible generator for an Egyptian personalized children's-book platform. Your job is to produce a STRUCTURED, LOCKED description of a single book's character + setting + style + cultural anchors. The illustration model (Flux 1.1 Pro via Fal.ai) will receive this Bible PLUS a per-page scene addendum on every one of 17 illustration calls — so anything you put in the Bible is rendered IDENTICALLY on every page. Be specific, be visual, be detailed.

## The story already exists

The story has been generated. The wizard inputs were:
- Child: ${args.childName}, age ${args.childAgeExact}, ${args.childGender}
- Theme: ${args.themeAr}
- Moral: ${args.moralValueAr}

You will receive the full story (title, pages, dedication, etc.) in the user message. Your job is NOT to modify the story — only to produce the Bible that will guide its illustrations.

${seedAppearance}

## Style anchor — locked watercolor (Hadouta MVP)

The brand is committed to a single visual register: soft watercolor with visible brush strokes, warm Egyptian palette, golden afternoon light. Your styleBible block must reflect this. Examples of what this looks like:

- Medium: "soft watercolor on cream paper, visible brush strokes, gentle wet-edge bleeds, no hard digital lines"
- Palette: "warm cream backgrounds, terracotta accents, soft sage greens, golden afternoon light"
- NegativeStyle: "NOT photorealistic, NOT 3D-rendered, NOT Disney-cartoon, NOT anime, NOT vector-flat, NOT sharp digital lines"

The negativeStyle is CRITICAL because Flux honors negative prompts strongly. Be explicit about what this is NOT.

## Setting — Cairo middle-class apartment by default

Unless the story dictates otherwise (e.g. school, park, mosque), the primary location is a Cairo middle-class apartment. Lock the visual details specifically — terracotta tile floors, cream walls, etc. The more details you lock in primaryLocationDetails, the more consistent the apartments look across pages. 50+ characters.

## Cultural glossary entries triggered for this story

${glossaryReference}

For each entry above, decide whether it appears in the story (read the user message) and add it to culturalNotes if so. Be VERY explicit ("During Eid el-Fitr — kahk biscuits on table, NOT chocolate chip cookies"). Flux will see this exact text in every illustration prompt.

## Output

Produce the Bible JSON object matching the bibleSchema. Every field must be filled. supportingCharacters and secondaryLocations should be EMPTY ARRAYS for MVP.`;
}
```

- [ ] **Step 3: Create the Bible generator**

Create `src/lib/ai/bible-generator.ts`:

```ts
// Bible generator — the "Step 2" of the AI pipeline (after story generation).
// Produces a validated Bible from the story + wizard inputs, optionally using
// a vision-model description of the customer's uploaded photo.
//
// Per docs/design/specs/2026-05-03-illustration-pipeline-redesign-spec.md §5.

import { generateObject } from "ai";
import { resolveTextModel } from "./router.js";
import { bibleSchema, type Bible } from "./schemas/bible.js";
import { buildBibleSystemPrompt } from "./prompts/bible-system-prompt.js";
import { getPersonaById } from "./personas.js";
import {
  findRelevantGlossaryEntries,
  type GlossaryEntry,
} from "./cultural-glossary.js";
import type { StoryOutput } from "./schemas/story.js";

export interface GenerateBibleInput {
  story: StoryOutput;
  wizardData: {
    childName: string;
    childAgeBand: "3-5" | "5-7" | "6-8";
    childAgeExact: number;
    childGender: "boy" | "girl";
    theme: string;
    moralValue: string;
    photoUrl: string | null;
    personaId: string | null;
    /** Optional: vision-model description if photoUrl is set. Filled by call site (Task 7). */
    photoDescription?: string | null;
    /** Optional: free-form child description from wizard (the "describe my own" escape). */
    childDescription?: string | null;
  };
  /** AI router model id — defaults to gpt-4o-mini for Bible. */
  modelId?: string;
}

export async function generateBible(
  input: GenerateBibleInput,
): Promise<Bible> {
  const { wizardData, story } = input;

  if (!wizardData.personaId && !wizardData.photoUrl && !wizardData.childDescription) {
    throw new Error(
      "[bible-generator] need either persona id, photo URL, or child description — got none",
    );
  }

  const persona = wizardData.personaId
    ? getPersonaById(wizardData.personaId) ?? null
    : null;

  // Find glossary entries triggered by story + wizard inputs.
  const haystack = [
    story.title,
    story.dedication,
    story.coverDescription,
    ...story.pages.map((p) => p.text),
    ...story.pages.map((p) => p.scene),
    wizardData.theme,
    wizardData.moralValue,
  ];
  const glossaryEntries: GlossaryEntry[] = findRelevantGlossaryEntries(haystack);

  const systemPrompt = buildBibleSystemPrompt({
    persona,
    photoDescription: wizardData.photoDescription ?? null,
    childName: wizardData.childName,
    childAgeExact: wizardData.childAgeExact,
    childGender: wizardData.childGender,
    themeAr: wizardData.theme,
    moralValueAr: wizardData.moralValue,
    glossaryEntries,
  });

  const userPromptParts: string[] = [
    "## Story to generate Bible for:\n",
    `### Title\n${story.title}\n`,
    `### Dedication\n${story.dedication}\n`,
    `### Cover description\n${story.coverDescription}\n`,
    `### Moral statement\n${story.moralStatement}\n`,
    "### Pages",
    ...story.pages.map((p) => `Page ${p.number} [${p.act}]: ${p.text}\n  Scene: ${p.scene}`),
  ];
  if (wizardData.childDescription) {
    userPromptParts.unshift(
      `### Customer's free-form child description\n${wizardData.childDescription}\n`,
    );
  }
  const userPrompt = userPromptParts.join("\n");

  const modelId = input.modelId ?? "gpt-4o-mini";
  const model = resolveTextModel(modelId);

  const result = await generateObject({
    model,
    schema: bibleSchema,
    system: systemPrompt,
    prompt: userPrompt,
    temperature: 0.6,
  });

  return result.object;
}
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
pnpm test tests/unit/bible-generator.test.ts
```

Expected: 3 tests pass. (Mocked `generateObject` returns canned bible objects; the validate-and-return path is exercised.)

- [ ] **Step 5: Run full test suite**

```bash
pnpm test
```

Expected: 70+ tests pass total.

- [ ] **Step 6: Commit**

```bash
git add src/lib/ai/bible-generator.ts \
        src/lib/ai/prompts/bible-system-prompt.ts \
        tests/unit/bible-generator.test.ts
git commit -m "$(cat <<'EOF'
feat(ai): bible generator (no-photo + persona / free-form path)

Step 2 of the new illustration pipeline. Produces a validated Bible
from story + wizard inputs using gpt-4o-mini + structured-output.
Persona seeds appearance when chosen; free-form description seeds it
otherwise; vision-model description (Task 7) takes precedence.

Cultural glossary entries are auto-detected from story content via
findRelevantGlossaryEntries() — concrete Egyptian anchors appear in
every illustration prompt.

Per docs/design/specs/2026-05-03-illustration-pipeline-redesign-spec.md
§5.1 + §5.4.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

## Task 7: Add vision-conditional Bible path (uploaded photo)

**Files:**
- Modify: `src/lib/ai/bible-generator.ts`
- Modify: `tests/unit/bible-generator.test.ts`

- [ ] **Step 1: Add a failing test for the photo path**

Append to `tests/unit/bible-generator.test.ts`:

```ts
describe("generateBible — photo path", () => {
  it("calls vision model to describe the photo before generating Bible", async () => {
    (generateObject as any).mockResolvedValue({
      object: {
        characterBible: { mainChild: { name: "هُنَا", age: 4, gender: "girl",
          appearance: {
            hair: "wavy dark hair just past shoulders, simple front fringe, photo-described",
            skin: "warm medium-fair olive skin, photo-described",
            eyes: "almond-shaped honey-brown, photo-described",
            distinguishing: "single dimple on right cheek, photo-described",
          },
          outfit: { default: "soft pink cotton dress, white tights, sneakers", variations: [] },
          personalityVisual: "calm posture, gentle smile",
        }, supportingCharacters: [] },
        settingBible: {
          primaryLocation: "Hena's apartment in Cairo",
          primaryLocationDetails:
            "terracotta floors, cream walls, teal velvet sofa, ceiling fan, balcony with potted basil — Cairo middle class",
          secondaryLocations: [],
        },
        styleBible: {
          medium: "soft watercolor on cream paper", palette: "warm cream, terracotta, sage",
          light: "golden afternoon", negativeStyle: "NOT photorealistic NOT 3D NOT cartoon",
          compositionAnchors: "subject upper two-thirds; neutral lower third",
        },
        culturalNotes: ["Eid el-Fitr — kahk on table NOT chocolate cookies"],
      },
      usage: { promptTokens: 1500, completionTokens: 800 },
    });

    // The vision-call mock — it should be invoked once before the bible generateObject.
    const visionMock = vi.fn().mockResolvedValue({
      text: "wavy dark hair just past shoulders, simple front fringe, warm fair olive skin, almond-shaped honey-brown eyes, single dimple on right cheek, calm composed expression",
    });
    (generateObject as any).mockClear();

    const bible = await generateBible(
      {
        ...SAMPLE_INPUT,
        wizardData: {
          ...SAMPLE_INPUT.wizardData,
          personaId: null,
          photoUrl: "https://res.cloudinary.com/example/child.jpg",
        },
      },
      { _visionCallOverride: visionMock as any },
    );
    expect(visionMock).toHaveBeenCalledTimes(1);
    expect(bible.characterBible.mainChild.appearance.hair).toContain("wavy");
  });
});
```

- [ ] **Step 2: Run the test — it will fail**

```bash
pnpm test tests/unit/bible-generator.test.ts
```

Expected: the new photo-path test fails (no vision integration yet).

- [ ] **Step 3: Update `bible-generator.ts` to call vision model when photo is present**

Modify `src/lib/ai/bible-generator.ts`. Add a helper that calls gpt-4o vision via the AI SDK's `generateText` with an image content part. Apply this addition above `export async function generateBible`:

```ts
import { generateText, type LanguageModel } from "ai";

interface BibleGeneratorInternalOptions {
  /** For unit tests: override the vision call entirely. */
  _visionCallOverride?: (photoUrl: string) => Promise<{ text: string }>;
}

async function describePhoto(
  photoUrl: string,
  model: LanguageModel,
): Promise<string> {
  const result = await generateText({
    model,
    messages: [
      {
        role: "user",
        content: [
          {
            type: "text",
            text:
              "Describe the child in this photo for a children's book illustrator. Focus on: hair (color, type, length, style), skin tone, eye color/shape, distinguishing features (dimples, freckles, glasses, gap teeth, etc.). Do NOT include the background or the photographer's intent. Output 1–3 sentences in ENGLISH only. Do NOT include the child's name. Do NOT speculate about emotion or personality. Just visual facts that anchor identity across illustrated scenes.",
          },
          { type: "image", image: photoUrl },
        ],
      },
    ],
    temperature: 0.2,
  });
  return result.text.trim();
}
```

Modify the `generateBible` function signature + implementation to:
1. Call `describePhoto` when `wizardData.photoUrl` is set (and `photoDescription` not pre-supplied)
2. Pass the resulting description through to `buildBibleSystemPrompt`
3. Accept the test-override

Concrete diff for the function signature + body (top of function):

```ts
export async function generateBible(
  input: GenerateBibleInput,
  internal: BibleGeneratorInternalOptions = {},
): Promise<Bible> {
  const { wizardData, story } = input;

  if (!wizardData.personaId && !wizardData.photoUrl && !wizardData.childDescription) {
    throw new Error(
      "[bible-generator] need either persona id, photo URL, or child description — got none",
    );
  }

  const modelId = input.modelId ?? "gpt-4o-mini";
  const model = resolveTextModel(modelId);

  // If photoUrl set and no pre-supplied description, call vision model.
  let photoDescription = wizardData.photoDescription ?? null;
  if (wizardData.photoUrl && !photoDescription) {
    photoDescription = internal._visionCallOverride
      ? (await internal._visionCallOverride(wizardData.photoUrl)).text
      : await describePhoto(wizardData.photoUrl, model);
  }

  const persona = wizardData.personaId
    ? getPersonaById(wizardData.personaId) ?? null
    : null;

  // ...rest unchanged, but pass photoDescription into the system-prompt builder
```

Update the `buildBibleSystemPrompt` call to pass `photoDescription` (it already accepts it).

- [ ] **Step 4: Run tests**

```bash
pnpm test tests/unit/bible-generator.test.ts
```

Expected: all 4 tests pass (3 from Task 6 + 1 new photo-path test).

- [ ] **Step 5: Commit**

```bash
git add src/lib/ai/bible-generator.ts tests/unit/bible-generator.test.ts
git commit -m "$(cat <<'EOF'
feat(ai): bible generator vision path — describe uploaded photo first

When the customer uploaded a child photo, gpt-4o-vision is called first
to extract visual facts (hair, skin, eyes, distinguishing features) into
a 1-3 sentence English description. That description is then passed to
the Bible system prompt as the seed instead of the persona library.

Result: when a photo is uploaded, illustrations are anchored in the real
child's features (still text-only at this stage; PuLID identity injection
comes in Task 10).

Internal _visionCallOverride parameter added for unit-test mocking.

Per docs/design/specs/2026-05-03-illustration-pipeline-redesign-spec.md §5.1.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

# PHASE D — Illustration prompt assembly + Fal.ai

Goal: build per-page prompts and ship them to Fal.ai (Flux + optional PuLID). After this phase, illustrations can be generated end-to-end given a Bible + scene.

## Task 8: Implement `build-illustration-prompt.ts`

**Files:**
- Create: `src/lib/ai/prompts/build-illustration-prompt.ts`
- Create: `tests/unit/build-illustration-prompt.test.ts`

- [ ] **Step 1: Write the failing test**

Create `tests/unit/build-illustration-prompt.test.ts`:

```ts
import { describe, expect, it } from "vitest";
import { buildIllustrationPrompt } from "../../src/lib/ai/prompts/build-illustration-prompt.js";
import type { Bible } from "../../src/lib/ai/schemas/bible.js";

const SAMPLE_BIBLE: Bible = {
  characterBible: {
    mainChild: {
      name: "هُنَا",
      age: 4,
      gender: "girl",
      appearance: {
        hair: "dark curly hair shoulder-length pulled into two pigtails with red ribbons",
        skin: "warm medium-olive skin",
        eyes: "almond-shaped large brown eyes with thick lashes",
        distinguishing: "small dimple on left cheek, slight gap between front teeth",
      },
      outfit: {
        default:
          "yellow cotton sundress with white daisy print, white short-sleeved cardigan, brown leather sandals",
        variations: [],
      },
      personalityVisual: "energetic posture, often mid-motion, expressive eyebrows",
    },
    supportingCharacters: [],
  },
  settingBible: {
    primaryLocation: "Hena's family apartment in Maadi, Cairo",
    primaryLocationDetails:
      "terracotta tile floors, cream walls with framed family photos, teal velvet sofa, ceiling fan, balcony with potted basil",
    secondaryLocations: [],
  },
  styleBible: {
    medium: "soft watercolor on cream paper, visible brush strokes, gentle wet-edge bleeds",
    palette: "warm cream backgrounds, terracotta accents, soft sage greens, golden afternoon light",
    light: "golden afternoon light through soft window curtains",
    negativeStyle: "NOT photorealistic, NOT 3D-rendered, NOT Disney-cartoon, NOT anime, NOT vector-flat",
    compositionAnchors: "subject in upper two-thirds of frame, neutral lower third, no embedded text or signage in scene",
  },
  culturalNotes: [
    "During Eid el-Fitr — kahk biscuits on table, NOT chocolate chip cookies",
    "Pasta dish if shown is makarona bashamel (béchamel-baked layered pasta) — NOT spaghetti",
  ],
};

describe("buildIllustrationPrompt", () => {
  it("includes character appearance details", () => {
    const { positive } = buildIllustrationPrompt({
      bible: SAMPLE_BIBLE,
      scene: "Hena gathers kahk from a metal tray on the coffee table",
      pageNumber: 5,
    });
    expect(positive).toContain("dark curly hair");
    expect(positive).toContain("yellow cotton sundress");
  });

  it("includes setting primaryLocationDetails", () => {
    const { positive } = buildIllustrationPrompt({
      bible: SAMPLE_BIBLE,
      scene: "Hena gathers kahk",
      pageNumber: 5,
    });
    expect(positive).toContain("terracotta tile floors");
  });

  it("includes scene-specific text", () => {
    const { positive } = buildIllustrationPrompt({
      bible: SAMPLE_BIBLE,
      scene: "Hena gathers kahk from a metal tray",
      pageNumber: 5,
    });
    expect(positive).toContain("Hena gathers kahk from a metal tray");
  });

  it("includes culturalNotes", () => {
    const { positive } = buildIllustrationPrompt({
      bible: SAMPLE_BIBLE,
      scene: "Hena at the table",
      pageNumber: 5,
    });
    expect(positive).toContain("kahk biscuits");
    expect(positive).toContain("NOT chocolate chip cookies");
  });

  it("returns negative prompt from styleBible.negativeStyle", () => {
    const { negative } = buildIllustrationPrompt({
      bible: SAMPLE_BIBLE,
      scene: "Hena at the table",
      pageNumber: 5,
    });
    expect(negative).toContain("NOT photorealistic");
  });

  it("uses outfit variation when page number matches", () => {
    const bibleWithVariation: Bible = {
      ...SAMPLE_BIBLE,
      characterBible: {
        ...SAMPLE_BIBLE.characterBible,
        mainChild: {
          ...SAMPLE_BIBLE.characterBible.mainChild,
          outfit: {
            default: SAMPLE_BIBLE.characterBible.mainChild.outfit.default,
            variations: [
              { pageNumbers: [13, 14], description: "wearing a red Eid dress with gold embroidery" },
            ],
          },
        },
      },
    };
    const { positive: variantPrompt } = buildIllustrationPrompt({
      bible: bibleWithVariation,
      scene: "Hena celebrates",
      pageNumber: 13,
    });
    const { positive: defaultPrompt } = buildIllustrationPrompt({
      bible: bibleWithVariation,
      scene: "Hena reads",
      pageNumber: 5,
    });
    expect(variantPrompt).toContain("red Eid dress");
    expect(defaultPrompt).toContain("yellow cotton sundress");
  });

  it("for cover (pageNumber=0), uses no outfit variation", () => {
    const { positive } = buildIllustrationPrompt({
      bible: SAMPLE_BIBLE,
      scene: "Hena holding a tray of kahk surrounded by friends",
      pageNumber: 0,
    });
    expect(positive).toContain("yellow cotton sundress");
  });
});
```

- [ ] **Step 2: Run the test — it fails**

```bash
pnpm test tests/unit/build-illustration-prompt.test.ts
```

Expected: tests fail because file doesn't exist.

- [ ] **Step 3: Create the prompt builder**

Create `src/lib/ai/prompts/build-illustration-prompt.ts`:

```ts
// Deterministically assembles a per-page illustration prompt from
// Bible + scene. The Bible owns character/setting/style/cultural anchors;
// the scene addendum says "what's unique on this page."
//
// This function is the bridge between the structured Bible and the text
// prompt the image model expects. Pure function — no AI calls.
//
// Per docs/design/specs/2026-05-03-illustration-pipeline-redesign-spec.md §5.4.

import type { Bible } from "../schemas/bible.js";

export interface BuildIllustrationPromptArgs {
  bible: Bible;
  scene: string;
  /** 0 = cover; 1..N = body pages. Used to apply outfit variations. */
  pageNumber: number;
}

export interface IllustrationPrompt {
  positive: string;
  negative: string;
}

export function buildIllustrationPrompt(
  args: BuildIllustrationPromptArgs,
): IllustrationPrompt {
  const { bible, scene, pageNumber } = args;

  // Character block — locked appearance.
  const child = bible.characterBible.mainChild;
  const outfit = resolveOutfit(child.outfit, pageNumber);
  const characterBlock = [
    `Egyptian ${child.gender}, ${child.age} years old`,
    `hair: ${child.appearance.hair}`,
    `skin: ${child.appearance.skin}`,
    `eyes: ${child.appearance.eyes}`,
    child.appearance.distinguishing
      ? `distinguishing features: ${child.appearance.distinguishing}`
      : null,
    `wearing ${outfit}`,
    `personality cues: ${child.personalityVisual}`,
  ]
    .filter(Boolean)
    .join(", ");

  // Setting block.
  const settingBlock = [
    `setting: ${bible.settingBible.primaryLocation}`,
    bible.settingBible.primaryLocationDetails,
  ].join(" — ");

  // Style block.
  const styleBlock = [
    bible.styleBible.medium,
    `palette: ${bible.styleBible.palette}`,
    `light: ${bible.styleBible.light}`,
  ].join(", ");

  // Cultural notes.
  const cultureBlock =
    bible.culturalNotes.length > 0
      ? `Cultural anchors (CRITICAL — render exactly as described): ${bible.culturalNotes.join(". ")}.`
      : "";

  // Composition anchors apply per page.
  const compositionBlock = bible.styleBible.compositionAnchors;

  const positive = [
    styleBlock,
    characterBlock,
    settingBlock,
    `scene: ${scene}`,
    cultureBlock,
    `composition: ${compositionBlock}`,
  ]
    .filter((s) => s && s.length > 0)
    .join(". ");

  return {
    positive,
    negative: bible.styleBible.negativeStyle,
  };
}

function resolveOutfit(
  outfit: Bible["characterBible"]["mainChild"]["outfit"],
  pageNumber: number,
): string {
  if (pageNumber === 0) return outfit.default;
  for (const variation of outfit.variations) {
    if (variation.pageNumbers.includes(pageNumber)) {
      return variation.description;
    }
  }
  return outfit.default;
}
```

- [ ] **Step 4: Run tests**

```bash
pnpm test tests/unit/build-illustration-prompt.test.ts
```

Expected: 7 tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/lib/ai/prompts/build-illustration-prompt.ts \
        tests/unit/build-illustration-prompt.test.ts
git commit -m "$(cat <<'EOF'
feat(ai): per-page illustration prompt assembler (Bible + scene)

Pure function that deterministically builds a positive + negative prompt
for the image model from a Bible + scene addendum + page number. The
character / setting / style / cultural anchors come from the Bible;
only the scene varies per page. Outfit variations applied when the
page number matches.

Per docs/design/specs/2026-05-03-illustration-pipeline-redesign-spec.md §5.4.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

## Task 9: Add Fal.ai client wrapper + Flux 1.1 Pro for cover (no PuLID)

**Files:**
- Modify: `src/lib/ai/router.ts` (add `flux-*` prefix)
- Modify: `src/lib/ai/illustration-generator.ts` (rewrite — drop Gemini, add Fal.ai cover path)
- Create: `tests/unit/illustration-generator.test.ts`

**Implementer note:** before writing the Fal.ai-specific code, run `mcp__plugin_context7_context7__query-docs` (or read `https://fal.ai/models/fal-ai/flux-pro/v1.1` directly) to confirm the exact endpoint name, parameter names (`prompt`, `negative_prompt`, `image_size`, etc.), and response shape. The code below uses the documented shape as of writing; small renames per current Fal.ai API are expected.

- [ ] **Step 1: Verify Fal.ai endpoint signature**

```bash
# In the conversation:
# mcp__plugin_context7_context7__resolve-library-id  ("fal-ai/flux-pro")
# mcp__plugin_context7_context7__query-docs           (selected library)
```

Confirm:
- Endpoint name: typically `fal-ai/flux-pro/v1.1` for Flux 1.1 Pro
- Input fields: `prompt`, `negative_prompt`, `image_size`, `num_inference_steps`, `guidance_scale`, etc.
- Response: `{ images: [{ url: string, content_type: string, ... }], ... }`

If the API has shifted, adjust the implementation below accordingly.

- [ ] **Step 2: Add `flux-*` prefix to the AI router**

In `src/lib/ai/router.ts`, find the prefix-based model resolver and the `COST_TABLE`. Add (preserving existing patterns):

- `flux-pro-1.1` cost: `$0.04` per image
- The router doesn't need to return a Vercel-AI-SDK model for Flux (it's not a text model), so add a separate exported helper `isFluxModel(modelId: string): boolean { return modelId.startsWith("flux-"); }` and a `getFluxCostCents(): number { return 4; }`. The illustration generator will call Fal.ai directly, not via the router's text model resolver.

- [ ] **Step 3: Write the failing test**

Create `tests/unit/illustration-generator.test.ts`:

```ts
import { describe, expect, it, vi } from "vitest";
import * as falClient from "@fal-ai/client";
import { generateCoverIllustration } from "../../src/lib/ai/illustration-generator.js";

vi.mock("@fal-ai/client", () => ({
  fal: {
    config: vi.fn(),
    subscribe: vi.fn(),
  },
  config: vi.fn(),
}));

describe("generateCoverIllustration", () => {
  it("calls Flux 1.1 Pro with positive + negative prompt", async () => {
    (falClient.fal.subscribe as any).mockResolvedValue({
      data: {
        images: [{ url: "https://fal.ai/example.png", content_type: "image/png" }],
      },
    });

    const result = await generateCoverIllustration({
      orderId: "order-123",
      positivePrompt: "watercolor scene of an Egyptian girl in Cairo",
      negativePrompt: "NOT photorealistic NOT 3D",
    });

    expect(falClient.fal.subscribe).toHaveBeenCalledWith(
      "fal-ai/flux-pro/v1.1",
      expect.objectContaining({
        input: expect.objectContaining({
          prompt: "watercolor scene of an Egyptian girl in Cairo",
        }),
      }),
    );
    expect(result.url).toContain("fal.ai/example.png");
  });

  it("throws if no image returned", async () => {
    (falClient.fal.subscribe as any).mockResolvedValue({
      data: { images: [] },
    });

    await expect(
      generateCoverIllustration({
        orderId: "order-123",
        positivePrompt: "x",
        negativePrompt: "y",
      }),
    ).rejects.toThrow(/no image/i);
  });
});
```

- [ ] **Step 4: Run the test — it fails**

```bash
pnpm test tests/unit/illustration-generator.test.ts
```

Expected: tests fail (Gemini code still in place; new exports missing).

- [ ] **Step 5: Rewrite `src/lib/ai/illustration-generator.ts`**

This is a significant rewrite. The file currently imports `@google/genai` and uses Gemini directly. Replace with Fal.ai. Concrete shape:

```ts
// Illustration generator — Flux 1.1 Pro via Fal.ai (replaces Gemini 2.5 Flash Image
// per docs/design/specs/2026-05-03-illustration-pipeline-redesign-spec.md §5.5).
//
// Pipeline:
//   - Cover: Flux only (no reference yet).
//   - Body pages: Flux + optional PuLID (face injection from customer photo)
//                 + reference_image_url = generated cover URL (Edit-based pipeline).
//
// All uploads to Cloudinary as before (preserve existing storage path and
// folder convention for backward compatibility with admin UI image lookups).

import { fal } from "@fal-ai/client";
import { uploadImage } from "../cloudinary.js";

const FLUX_PRO_ENDPOINT = "fal-ai/flux-pro/v1.1";
// PuLID endpoint per Fal.ai docs at implementation time (verify).
const FLUX_PULID_ENDPOINT = "fal-ai/flux-pulid";

let _falConfigured = false;
function ensureFalConfigured(): void {
  if (_falConfigured) return;
  const key = process.env.FAL_KEY;
  if (!key) {
    throw new Error("FAL_KEY not set — cannot generate illustrations.");
  }
  fal.config({ credentials: key });
  _falConfigured = true;
}

export interface CoverInput {
  orderId: string;
  positivePrompt: string;
  negativePrompt: string;
}

export interface IllustrationResult {
  url: string;
  contentType: string;
  fileSize: number;
  modelId: string;
  durationMs: number;
}

export async function generateCoverIllustration(
  input: CoverInput,
): Promise<IllustrationResult> {
  ensureFalConfigured();
  const startedAt = Date.now();

  const result = await fal.subscribe(FLUX_PRO_ENDPOINT, {
    input: {
      prompt: input.positivePrompt,
      negative_prompt: input.negativePrompt,
      image_size: "portrait_4_3",
      num_inference_steps: 28,
      guidance_scale: 3.5,
      enable_safety_checker: true,
    },
    logs: false,
  });

  const durationMs = Date.now() - startedAt;
  const image = result.data?.images?.[0];
  if (!image?.url) {
    throw new Error(
      `Flux returned no image for cover. Response: ${JSON.stringify(result.data ?? null).slice(0, 500)}`,
    );
  }

  // Download image from Fal.ai's CDN and re-upload to Cloudinary.
  // Cloudinary path matches existing convention so admin UI displays correctly.
  const buffer = await downloadAsBuffer(image.url);
  const uploaded = await uploadImage(
    buffer,
    input.orderId,
    "illustration_cover",
    image.content_type ?? "image/png",
  );

  return {
    url: uploaded.url,
    contentType: uploaded.contentType,
    fileSize: uploaded.fileSize,
    modelId: "flux-pro-1.1",
    durationMs,
  };
}

async function downloadAsBuffer(url: string): Promise<Buffer> {
  const res = await fetch(url);
  if (!res.ok) {
    throw new Error(`Failed to download generated image: ${res.status}`);
  }
  return Buffer.from(await res.arrayBuffer());
}
```

Keep the previous batch-orchestration function (`generateAllIllustrations`) but split it into two: cover (this task) + body pages (Task 10). For now, the body-page generator is a stub.

- [ ] **Step 6: Run the test**

```bash
pnpm test tests/unit/illustration-generator.test.ts
```

Expected: 2 tests pass.

- [ ] **Step 7: Run typecheck**

```bash
pnpm typecheck
```

Expected: clean. (If existing call sites in `src/jobs/generate-book.ts` reference the old `generateAllIllustrations` shape, leave them broken at this point — Task 11 fixes orchestration.)

- [ ] **Step 8: Commit**

```bash
git add src/lib/ai/router.ts \
        src/lib/ai/illustration-generator.ts \
        tests/unit/illustration-generator.test.ts
git commit -m "$(cat <<'EOF'
feat(ai): switch cover illustration to Flux 1.1 Pro via Fal.ai

Drops Gemini 2.5 Flash Image; cover generated via fal-ai/flux-pro/v1.1
endpoint, downloaded, re-uploaded to Cloudinary preserving existing
folder convention. Adds flux-* prefix to AI router cost-table for
per-book cost tracking.

Body pages (Task 10) still pending — orchestrator broken until then.

Per docs/design/specs/2026-05-03-illustration-pipeline-redesign-spec.md §5.5.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

## Task 10: Body-page illustration with cover-as-reference + optional PuLID

**Files:**
- Modify: `src/lib/ai/illustration-generator.ts`
- Modify: `tests/unit/illustration-generator.test.ts`

- [ ] **Step 1: Add failing tests**

Append to `tests/unit/illustration-generator.test.ts`:

```ts
import { generateBodyIllustration, generateAllIllustrations } from "../../src/lib/ai/illustration-generator.js";

describe("generateBodyIllustration", () => {
  it("uses cover as reference + no PuLID when no photoUrl", async () => {
    (falClient.fal.subscribe as any).mockResolvedValue({
      data: { images: [{ url: "https://fal.ai/page1.png", content_type: "image/png" }] },
    });

    await generateBodyIllustration({
      orderId: "order-123",
      pageNumber: 1,
      positivePrompt: "scene 1",
      negativePrompt: "no flat",
      coverImageUrl: "https://example.com/cover.png",
      customerPhotoUrl: null,
    });

    // Body pages without photo go to Flux 1.1 Pro (cover-conditioned via Fal.ai
    // image-to-image option) rather than the PuLID endpoint.
    const lastCall = (falClient.fal.subscribe as any).mock.calls.at(-1);
    expect(lastCall[0]).toBe("fal-ai/flux-pro/v1.1");
    expect(lastCall[1].input).toMatchObject({
      prompt: "scene 1",
      image_url: "https://example.com/cover.png",  // image-to-image conditioning
    });
  });

  it("uses PuLID endpoint when photoUrl provided", async () => {
    (falClient.fal.subscribe as any).mockResolvedValue({
      data: { images: [{ url: "https://fal.ai/page2.png", content_type: "image/png" }] },
    });

    await generateBodyIllustration({
      orderId: "order-123",
      pageNumber: 2,
      positivePrompt: "scene 2",
      negativePrompt: "no flat",
      coverImageUrl: "https://example.com/cover.png",
      customerPhotoUrl: "https://example.com/photo.jpg",
    });

    const lastCall = (falClient.fal.subscribe as any).mock.calls.at(-1);
    expect(lastCall[0]).toBe("fal-ai/flux-pulid");
    expect(lastCall[1].input).toMatchObject({
      prompt: "scene 2",
      reference_image_url: "https://example.com/cover.png",
      face_image_url: "https://example.com/photo.jpg",
    });
  });
});

describe("generateAllIllustrations (orchestrator)", () => {
  it("generates cover first, then bodies in parallel with concurrency cap", async () => {
    let callCount = 0;
    (falClient.fal.subscribe as any).mockImplementation(async () => {
      callCount++;
      return {
        data: { images: [{ url: `https://fal.ai/img-${callCount}.png`, content_type: "image/png" }] },
      };
    });

    const result = await generateAllIllustrations({
      orderId: "order-123",
      cover: { positivePrompt: "cover", negativePrompt: "no flat" },
      pages: Array.from({ length: 3 }, (_, i) => ({
        pageNumber: i + 1,
        positivePrompt: `page ${i + 1}`,
        negativePrompt: "no flat",
      })),
      customerPhotoUrl: null,
    });

    expect(result.cover.url).toBeTruthy();
    expect(result.pages).toHaveLength(3);
    expect(callCount).toBe(4); // 1 cover + 3 pages
  });
});
```

- [ ] **Step 2: Run tests — fail expected**

```bash
pnpm test tests/unit/illustration-generator.test.ts
```

- [ ] **Step 3: Add `generateBodyIllustration` and `generateAllIllustrations`**

In `src/lib/ai/illustration-generator.ts`, add:

```ts
export interface BodyInput {
  orderId: string;
  pageNumber: number;
  positivePrompt: string;
  negativePrompt: string;
  coverImageUrl: string;
  customerPhotoUrl: string | null;
}

export async function generateBodyIllustration(
  input: BodyInput,
): Promise<IllustrationResult> {
  ensureFalConfigured();
  const startedAt = Date.now();

  const usePuLID = !!input.customerPhotoUrl;

  let result;
  if (usePuLID) {
    result = await fal.subscribe(FLUX_PULID_ENDPOINT, {
      input: {
        prompt: input.positivePrompt,
        negative_prompt: input.negativePrompt,
        reference_image_url: input.coverImageUrl,
        face_image_url: input.customerPhotoUrl,
        image_size: "portrait_4_3",
        num_inference_steps: 28,
        guidance_scale: 3.5,
        // Per research: weight 0.7-0.8 sweet spot, inject during middle steps.
        pulid_weight: 0.75,
        pulid_start: 0.0,
        pulid_end: 0.65,
        enable_safety_checker: true,
      },
      logs: false,
    });
  } else {
    // Image-to-image conditioning on cover. Flux's image_url parameter conditions
    // generation on the reference image without requiring PuLID.
    result = await fal.subscribe(FLUX_PRO_ENDPOINT, {
      input: {
        prompt: input.positivePrompt,
        negative_prompt: input.negativePrompt,
        image_url: input.coverImageUrl,
        image_size: "portrait_4_3",
        num_inference_steps: 28,
        guidance_scale: 3.5,
        strength: 0.8, // higher = more divergence from reference; 0.8 keeps style/character
        enable_safety_checker: true,
      },
      logs: false,
    });
  }

  const durationMs = Date.now() - startedAt;
  const image = result.data?.images?.[0];
  if (!image?.url) {
    throw new Error(
      `Flux returned no image for page ${input.pageNumber}. Response: ${JSON.stringify(result.data ?? null).slice(0, 500)}`,
    );
  }

  const buffer = await downloadAsBuffer(image.url);
  const uploaded = await uploadImage(
    buffer,
    input.orderId,
    `illustration_page_${input.pageNumber}`,
    image.content_type ?? "image/png",
  );

  return {
    url: uploaded.url,
    contentType: uploaded.contentType,
    fileSize: uploaded.fileSize,
    modelId: usePuLID ? "flux-pulid" : "flux-pro-1.1",
    durationMs,
  };
}

const ILLUSTRATION_CONCURRENCY = 5;

export interface BatchInput {
  orderId: string;
  cover: { positivePrompt: string; negativePrompt: string };
  pages: Array<{ pageNumber: number; positivePrompt: string; negativePrompt: string }>;
  customerPhotoUrl: string | null;
}

export interface BatchResult {
  cover: IllustrationResult;
  pages: Array<IllustrationResult & { pageNumber: number }>;
  totalDurationMs: number;
}

export async function generateAllIllustrations(
  input: BatchInput,
): Promise<BatchResult> {
  const startedAt = Date.now();

  const cover = await generateCoverIllustration({
    orderId: input.orderId,
    positivePrompt: input.cover.positivePrompt,
    negativePrompt: input.cover.negativePrompt,
  });

  const pages = await runWithConcurrency(input.pages, ILLUSTRATION_CONCURRENCY, async (page) => {
    const result = await generateBodyIllustration({
      orderId: input.orderId,
      pageNumber: page.pageNumber,
      positivePrompt: page.positivePrompt,
      negativePrompt: page.negativePrompt,
      coverImageUrl: cover.url,
      customerPhotoUrl: input.customerPhotoUrl,
    });
    return { ...result, pageNumber: page.pageNumber };
  });

  return {
    cover,
    pages,
    totalDurationMs: Date.now() - startedAt,
  };
}

async function runWithConcurrency<T, U>(
  items: T[],
  concurrency: number,
  fn: (item: T) => Promise<U>,
): Promise<U[]> {
  const results: U[] = new Array(items.length);
  let cursor = 0;
  async function worker() {
    while (true) {
      const i = cursor++;
      if (i >= items.length) return;
      results[i] = await fn(items[i]);
    }
  }
  await Promise.all(Array.from({ length: Math.min(concurrency, items.length) }, () => worker()));
  return results;
}
```

- [ ] **Step 4: Run tests**

```bash
pnpm test tests/unit/illustration-generator.test.ts
```

Expected: 5 tests pass total (2 from Task 9, 3 new in Task 10).

- [ ] **Step 5: Run full suite**

```bash
pnpm test
pnpm typecheck
```

Expected: tests pass. typecheck may complain at `src/jobs/generate-book.ts` because the orchestrator-call signature changed (`cover.prompt` → `cover.positivePrompt`/`negativePrompt`). That's expected — Task 11 fixes it.

- [ ] **Step 6: Commit**

```bash
git add src/lib/ai/illustration-generator.ts tests/unit/illustration-generator.test.ts
git commit -m "$(cat <<'EOF'
feat(ai): body-page illustrations — cover-as-reference + optional PuLID

generateBodyIllustration() routes per page based on whether a customer
photo was uploaded:
- With photo: fal-ai/flux-pulid endpoint, face_image_url = photo,
              reference_image_url = cover, pulid_weight 0.75, mid-window
              injection (pulid_start/end 0/0.65) per research sweet spot
- Without photo: fal-ai/flux-pro/v1.1 image-to-image with image_url = cover
                 (preserves character + style without PuLID overhead)

generateAllIllustrations() preserves existing batch shape with
concurrency cap raised to 5 (Fal.ai is more permissive than Google direct).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

# PHASE E — Pipeline orchestration

Goal: wire the existing `generate-book.ts` orchestrator to call Bible generation between story and illustrations, and persist `bibleJson` to the new column.

## Task 11: Update `src/jobs/generate-book.ts` orchestrator

**Files:**
- Modify: `src/jobs/generate-book.ts`

This file is fragile (it's the production-critical pipeline). Read it carefully before editing. Make changes minimally.

- [ ] **Step 1: Read the existing file end-to-end**

```bash
wc -l src/jobs/generate-book.ts
cat src/jobs/generate-book.ts
```

Note where `generateAllIllustrations` is called and what shape it expects.

- [ ] **Step 2: Insert Bible generation after story generation**

In `src/jobs/generate-book.ts`, find the section where the story is generated and persisted (look for `storyJson:` set on a generations update). Right AFTER that, BEFORE the call to `generateAllIllustrations`, insert:

```ts
import { generateBible } from "../lib/ai/bible-generator.js";
import { buildIllustrationPrompt } from "../lib/ai/prompts/build-illustration-prompt.js";
// ...within the orchestrator:

// Step 2: Bible generation
const bible = await generateBible({
  story,
  wizardData: {
    childName: order.childName ?? "",
    childAgeBand: order.childAgeBand as "3-5" | "5-7" | "6-8",
    childAgeExact: order.childAgeExact ?? 4,
    childGender: order.childGender as "boy" | "girl",
    theme: theme?.titleAr ?? "",
    moralValue: moralValue?.nameAr ?? "",
    photoUrl: order.mainChildPhotoUrl ?? null,
    personaId: order.mainChildPersonaId ?? null,
    childDescription: order.mainChildDescription ?? null,
  },
});

await db.update(generations).set({
  bibleJson: bible,
  bibleRegeneratedAt: new Date(),
  updatedAt: new Date(),
}).where(eq(generations.id, generationId));

console.log(`[jobs/generate-book] bible done, generation=${generationId}`);
```

- [ ] **Step 3: Replace the call to `generateAllIllustrations` with the new shape**

The existing call passes `prompt` strings derived from `story.pages[].illustrationPrompt`. Now we build prompts from Bible + scene per page:

```ts
const coverPrompts = buildIllustrationPrompt({
  bible,
  scene: story.coverDescription,
  pageNumber: 0,
});

const pagePrompts = story.pages.map((p) => ({
  pageNumber: p.number,
  ...buildIllustrationPrompt({ bible, scene: p.scene, pageNumber: p.number }),
}));

const illustrations = await generateAllIllustrations({
  orderId: order.id,
  cover: { positivePrompt: coverPrompts.positive, negativePrompt: coverPrompts.negative },
  pages: pagePrompts.map((p) => ({
    pageNumber: p.pageNumber,
    positivePrompt: p.positive,
    negativePrompt: p.negative,
  })),
  customerPhotoUrl: order.mainChildPhotoUrl ?? null,
});
```

Note: this assumes `orders.mainChildPhotoUrl`, `orders.mainChildPersonaId`, `orders.mainChildDescription` columns exist. If `mainChildPersonaId` doesn't exist yet (it'll be added when the wizard updates in Task 14), guard with `?? null` so the orchestrator is forward-compatible. The Bible generator handles `null` gracefully.

- [ ] **Step 4: Run typecheck**

```bash
pnpm typecheck
```

Expected: clean. If `mainChildPersonaId` column reference doesn't compile, leave it as a TODO comment for Task 14 to fix:

```ts
// TODO(Task 14): once schema migration adds main_child_persona_id, drop the cast.
personaId: ((order as { mainChildPersonaId?: string | null }).mainChildPersonaId) ?? null,
```

- [ ] **Step 5: Smoke-test against an existing dev generation**

Use the same backfill pattern as the PDF redesign verification — find an `awaiting_review` generation, manually trigger generation for a fresh order in the dev database. Or, simpler: create an integration test that mocks both AI calls.

```bash
# Manual smoke test (skip if you'd rather wait until Phase H verification)
# Place a dev order via the wizard, watch Railway logs for:
#   [jobs/generate-book] bible done, generation=...
#   [jobs/generate-book] illustrations done: 17 images, ...
```

- [ ] **Step 6: Run full test suite**

```bash
pnpm test
```

Expected: 80+ tests pass.

- [ ] **Step 7: Commit**

```bash
git add src/jobs/generate-book.ts
git commit -m "$(cat <<'EOF'
feat(orchestrator): wire Bible generation between story + illustrations

Per docs/design/specs/2026-05-03-illustration-pipeline-redesign-spec.md
§4 — generate-book.ts now does:
1. story  →  storyJson (existing)
2. bible  →  bibleJson on generations row (NEW)
3. prompts → built from Bible + scene per page (NEW)
4. illustrations → Flux 1.1 Pro + optional PuLID (NEW shape)

Customer photo URL threads through to PuLID injection. Persona ID +
free-form description threaded into Bible generator.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

# PHASE F — Admin reject/reroll

Goal: let admin re-roll illustrations (default), or Bible too, or everything.

## Task 12: New `POST /api/admin/generations/:id/reroll` endpoint

**Files:**
- Modify: `src/routes/admin-generations.ts`
- Create: `tests/integration/admin-reroll.test.ts`

- [ ] **Step 1: Write the integration test**

Create `tests/integration/admin-reroll.test.ts`. Mirror the pattern of existing `tests/integration/auth.test.ts` (same `import "dotenv/config"` etc.). The test exercises:
- Reject with `scope: "illustrations"` — returns 200, generation status flips to `queued`, `bibleJson` preserved
- Reject with `scope: "bible"` — returns 200, status flips to `queued`, `bibleJson` and pages get cleared
- Reject with `scope: "story"` — returns 200, status flips to `queued`, everything cleared
- Reject without admin auth — returns 401/403

(Test code: ~150 lines following the auth-test pattern. Use a fresh test generation row inserted at test setup; assert state after each call.)

- [ ] **Step 2: Run tests — fail expected**

- [ ] **Step 3: Add the endpoint**

In `src/routes/admin-generations.ts`, add a new POST route:

```ts
// POST /api/admin/generations/:id/reroll  body: { scope: "illustrations" | "bible" | "story" }
adminGenerationsRouter.post("/:id/reroll", requireAdmin, async (c) => {
  const { id } = c.req.param();
  const body = await c.req.json<{ scope?: string }>();
  const scope = body.scope;
  if (!["illustrations", "bible", "story"].includes(scope as string)) {
    return c.json({ error: "scope must be illustrations | bible | story" }, 400);
  }

  // Locate the generation
  const [gen] = await db.select().from(generations).where(eq(generations.id, id)).limit(1);
  if (!gen) return c.json({ error: "generation not found" }, 404);

  // Reset based on scope
  const updates: Partial<typeof generations.$inferInsert> = {
    status: "queued",
    updatedAt: new Date(),
    rejectionCategory: null,
    rejectionReason: null,
    errorLog: null,
  };
  if (scope === "bible" || scope === "story") {
    updates.bibleJson = null;
    updates.bibleRegeneratedAt = null;
  }
  if (scope === "story") {
    updates.storyJson = null;
  }
  // Always clear book_pages so they regenerate.
  await db.delete(bookPages).where(eq(bookPages.generationId, id));

  await db.update(generations).set(updates).where(eq(generations.id, id));

  // Re-trigger the orchestrator (fire-and-forget)
  void runGenerationPipeline(gen.id, gen.orderId).catch((err) => {
    console.error(`[admin/reroll] pipeline failed for ${gen.id}:`, err);
  });

  return c.json({ ok: true, scope });
});
```

(Note: import `runGenerationPipeline` from `../jobs/generate-book.js` if not already imported.)

- [ ] **Step 4: Run tests — pass expected**

- [ ] **Step 5: Commit**

```bash
git add src/routes/admin-generations.ts tests/integration/admin-reroll.test.ts
git commit -m "$(cat <<'EOF'
feat(admin): reroll endpoint with scope { illustrations | bible | story }

Per docs/design/specs/2026-05-03-illustration-pipeline-redesign-spec.md §5.7.
Admin can reject and immediately re-trigger the pipeline at three
scopes, defaulting to illustrations-only (cheapest, keeps Bible).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

## Task 13: Admin UI — reject modal scope selector

**Files:**
- Modify: `hadouta-admin/src/app/orders/[id]/_order-detail.tsx`

- [ ] **Step 1: In the existing `RejectModal` component, add a scope selector (radio group: illustrations / bible / story) above the category dropdown.** Default selection is `illustrations`.

- [ ] **Step 2: When admin confirms reject + reroll, the existing `reject(category, reason)` handler also POSTs to the new `/reroll` endpoint with the chosen scope.**

(Concrete code: ~50 lines of TSX update inside `RejectModal` + `reject()` async function. Uses existing `api.post()` helper.)

- [ ] **Step 3: Manually verify in admin app** (after `pnpm dev` in hadouta-admin):
  - Reject an order, pick "regenerate illustrations only" → see status flip to queued, bibleJson preserved in DB
  - Reject an order, pick "regenerate bible too" → see bibleJson go null
  - Reject an order, pick "regenerate everything" → see storyJson go null

- [ ] **Step 4: Commit (in hadouta-admin repo, separate from backend)**

```bash
cd /home/ahmed/Desktop/hadouta/hadouta-admin
git add src/app/orders/\[id\]/_order-detail.tsx
git commit -m "feat(admin): reject-modal scope selector for reroll"
cd /home/ahmed/Desktop/hadouta/hadouta-backend
```

---

# PHASE G — Wizard persona picker

Goal: replace free-form description with persona grid.

## Task 14: Wizard persona picker component

**Files:**
- Create: `hadouta-web/src/components/wizard/persona-picker.tsx`
- Modify: `hadouta-web/src/app/wizard/[step]/page.tsx` (step 2)
- Modify: backend `orders` table (if it doesn't already have `main_child_persona_id` column)

- [ ] **Step 1: Add `main_child_persona_id` to `orders` if missing**

Check the schema: `grep -i persona src/db/schema.ts`. If absent, add migration `0007_add_persona_id.sql`:

```sql
ALTER TABLE orders ADD COLUMN main_child_persona_id text;
```

And update `src/db/schema.ts`:

```ts
mainChildPersonaId: text("main_child_persona_id"),
```

- [ ] **Step 2: Create persona-picker component**

`hadouta-web/src/components/wizard/persona-picker.tsx`. Grid of 6 cards (one per persona from a frontend mirror of `personas.ts` — copy the array shape into a frontend file). Each card shows the Arabic label + a small representative SVG/illustration placeholder + selected-state outline.

- [ ] **Step 3: Wire into wizard step 2**

Replace the existing free-form description textarea with a "Choose a persona" tab + "Describe my own (advanced)" tab. Picked persona's `id` is sent as `mainChildPersonaId` on the draft-order PATCH; if user uses the free-form path, `mainChildDescription` is sent instead.

- [ ] **Step 4: Manual verify the wizard end-to-end** with both paths.

- [ ] **Step 5: Commit (in hadouta-web)**

```bash
cd /home/ahmed/Desktop/hadouta/hadouta-web
git add ...
git commit -m "feat(wizard): persona picker for step 2 (replaces free-form)"
```

---

# PHASE H — Verification + docs

Goal: run a real generation end-to-end, confirm each spec criterion, write ADR-024, update tracker.

## Task 15: End-to-end real generation verification

- [ ] **Step 1: Place a fresh order via the wizard** (or backfill a test order in DB)
- [ ] **Step 2: Watch Railway logs for the new pipeline steps**
- [ ] **Step 3: Inspect the generated PDF visually**:
  - Same character on every page (consistency)
  - Watercolor style adherent
  - Egyptian setting intact
  - Cultural anchors correct (kahk = biscuits, makarona = béchamel-baked)
  - If photo uploaded: child's actual face recognizable
- [ ] **Step 4: Document any visual gaps as Sprint 3.1 followups in the sprint tracker**

## Task 16: ADR-024 + sprint tracker

- [ ] **Step 1: Write `docs/decisions/ADR-024-bible-driven-illustration-pipeline.md`** capturing:
  - Context (4 failure modes, structural cause)
  - Decision (Bible + Flux + PuLID pipeline)
  - Consequences (cost, latency, quality, complexity)
  - Implementation commits referenced

- [ ] **Step 2: Update `docs/sprints/sprint-tracker.md`** in the umbrella repo:
  - Add Sprint 3 entry "Illustration pipeline redesigned ✅"
  - Reference the spec, plan, and ADR-024

- [ ] **Step 3: Commit both docs**

---

## Self-review checklist

- [ ] **Spec coverage** — each section in the spec has at least one task implementing it (verified)
- [ ] **Placeholder scan** — code blocks contain real code, not pseudo-code
- [ ] **Type consistency** — `IllustrationPrompt`, `Bible`, `BatchInput` shapes consistent across tasks 8-11
- [ ] **Open question handling** — Fal.ai endpoint signatures noted as "verify against docs at impl time"; no other TBDs in critical paths
- [ ] **Migrations are forward-only** — Task 5 + (maybe) Task 14 add columns, never drop
- [ ] **Phase ordering preserves correctness** — schemas → DB → generators → orchestrator → UX → verification
- [ ] **Tests precede implementation** — every code task has its failing-test step first

---

## Execution handoff

**Plan complete and saved to `docs/design/specs/2026-05-03-illustration-pipeline-implementation-plan.md`.**

Two execution options:

1. **Inline execution (recommended for Hadouta)** — task-by-task in this session using `superpowers:executing-plans`. Matches your `feedback_direct_implementation` preference and the pattern we used for the PDF redesign.

2. **Subagent-driven** — fresh subagent per task with two-stage review. Higher overhead; reserve for genuinely senior-tier complexity. This plan is well-scoped enough that inline execution is the right tool.

**Default: inline execution.**
