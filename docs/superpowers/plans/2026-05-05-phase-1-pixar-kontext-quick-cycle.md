# Phase 1 Pixar-Kontext Quick-Cycle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Run a 1-day side-by-side A/B between current Nano Banana watercolor pipeline and proposed Flux.1 Kontext + Pixar-3D Style LoRA pipeline on existing customer order, founder annotates results, decision tree picks production direction.

**Architecture:** Add an `'flux-kontext-pixar'` value to the existing `aiSettings.illustrationModel` field (no migration — column already exists). Wire it through `generate-book.ts` orchestrator down to `illustration-generator.ts` which dispatches between the existing Nano Banana code path and a new `fal-ai/flux-pro/kontext/multi` code path that loads an off-the-shelf Civitai Pixar-3D Flux LoRA. New helper in `build-illustration-prompt.ts` appends Pixar-3D style anchor language only when the new provider is selected.

**Tech Stack:** TypeScript, Hono, Drizzle ORM, Vitest, fal.ai client, existing Cloudinary upload helper, Civitai-hosted Flux LoRA.

**Spec:** `docs/superpowers/specs/2026-05-05-phase-1-pixar-kontext-quick-cycle-design.md`

---

## License preflight (verified 2026-05-05)

**Decision:** LH Pixar 3D Style (Civitai 928840, trained on Flux.1 [dev]) is permitted for Phase 1 use under the explicit research/evaluation carve-out in BFL's Flux.1 [dev] License Section 1(c)(ii):

> "(ii) use by commercial or for-profit entities for testing, evaluation, or non-commercial research and development in a non-production environment"

Boundary conditions that MUST hold for the carve-out to apply:

1. **Phase 1 outputs are NOT delivered to end users.** The 3 test images from Task 5 stay as internal evaluation artifacts (Cloudinary URLs known only to founder + admin). They are NOT served to حنين's family or any other customer. The original Nano Banana watercolor output for that order was already delivered to customer; Phase 1 outputs are post-hoc internal A/B comparison only.
2. **No revenue-generating activity uses Phase 1 outputs.** No re-listing in catalog, no marketing material, no sample books for sales pitches.
3. **If Phase 1 verdict is "ship Path D to production,"** we re-license BEFORE ship. Either: pay BFL for commercial license (`licensing@blackforestlabs.ai`), switch base to Flux.1 [schnell] (Apache-2.0), or commission a custom LoRA on commercially-licensed weights. ADR-026 records this commitment explicitly.

License source: https://huggingface.co/black-forest-labs/FLUX.1-dev/blob/main/LICENSE.md

---

## File Structure

| File | Status | Responsibility |
|---|---|---|
| `hadouta-backend/src/lib/ai/illustration-generator.ts` | Modify | Provider dispatch — Nano Banana (existing) vs Flux Kontext + Pixar LoRA (new) |
| `hadouta-backend/src/lib/ai/prompts/build-illustration-prompt.ts` | Modify | New optional Pixar-3D style anchor that overlays on Bible-driven prompt |
| `hadouta-backend/src/jobs/generate-book.ts` | Modify | Read `aiSettings.illustrationModel`, pass provider down to illustration generator |
| `hadouta-backend/tests/unit/build-illustration-prompt.test.ts` | Modify | Add tests for `appendPixarStyleAnchor()` |
| `hadouta-backend/tests/unit/illustration-generator.test.ts` | Modify | Add tests for `flux-kontext-pixar` provider dispatch |
| `hadouta-backend/.env.example` | Modify | Document new `PIXAR_STYLE_LORA_URL` env var |
| `hadouta-backend/.env` | Modify | Set actual LoRA URL (local dev) |
| `hadouta-backend/src/scripts/verify-fal-kontext-lora.ts` | Create | One-off de-risk script: ping Kontext-Multi with `loras` param, log response |
| `hadouta-backend/src/scripts/run-phase-1-test-generation.ts` | Create | One-off: regenerate 3 pages of order `36e86090-...` with `flux-kontext-pixar` provider |
| `docs/decisions/ADR-026-phase-1-pixar-kontext-outcome.md` | Create | Verdict ADR — written after founder reviews the test pages |

**Note on `aiSettings.illustrationModel`:** The column already exists in `src/db/schema.ts:336-338` as `text("illustration_model")` with default `"gemini-2.5-flash-image"`. No migration needed — we add `'flux-kontext-pixar'` as a new accepted value and wire dispatch.

---

## Task 0: De-risk fal.ai Kontext-Multi LoRA support

**Why this task exists:** Per spec §4.5, if `fal-ai/flux-pro/kontext/multi` doesn't accept the `loras` array parameter, we fall back to prompt-only Pixar styling. Knowing this in 30 minutes prevents wasted hours on Task 3.

**Files:**
- Create: `hadouta-backend/src/scripts/verify-fal-kontext-lora.ts`

- [ ] **Step 1: Create the verification script**

```typescript
// hadouta-backend/src/scripts/verify-fal-kontext-lora.ts
//
// One-off script: ping fal-ai/flux-pro/kontext/multi with a `loras` parameter
// to confirm the endpoint accepts LoRA loading. Prints the response.
//
// Run: pnpm tsx src/scripts/verify-fal-kontext-lora.ts
//
// Expected outcomes:
//   - Image returned with no parameter-rejected error → LoRA support confirmed
//   - Error mentioning unknown parameter `loras` → fall back to prompt-only Pixar
//   - Image returned but unchanged from no-LoRA baseline → silent no-op (treat as no support)

import "dotenv/config";
import { fal } from "@fal-ai/client";

const KONTEXT_MULTI = "fal-ai/flux-pro/kontext/multi";

// A free-licensed test LoRA URL on Hugging Face (replace with chosen Pixar LoRA
// URL once Task 1 picks one — for de-risk this just probes API parameter shape).
const TEST_LORA_URL =
  "https://huggingface.co/XLabs-AI/flux-RealismLora/resolve/main/lora.safetensors";

// A simple test reference image already public.
const TEST_IMAGE_URL = "https://fal.ai/files/dog.jpg";

async function main(): Promise<void> {
  const key = process.env.FAL_KEY;
  if (!key) throw new Error("FAL_KEY not set in .env");
  fal.config({ credentials: key });

  console.log("Probing", KONTEXT_MULTI, "with `loras` param...");

  try {
    const result = await fal.subscribe(KONTEXT_MULTI, {
      input: {
        prompt: "a smiling dog in 3d pixar animated style",
        image_urls: [TEST_IMAGE_URL],
        loras: [{ path: TEST_LORA_URL, scale: 0.8 }],
        aspect_ratio: "1:1",
        output_format: "png",
        num_images: 1,
      },
      logs: false,
    });
    const data = (result as { data?: { images?: Array<{ url?: string }> } })
      .data;
    const imageUrl = data?.images?.[0]?.url ?? null;
    if (imageUrl) {
      console.log("✅ Kontext-Multi accepted `loras` param.");
      console.log("   Output image:", imageUrl);
      console.log(
        "   Verify visually that the image differs from a no-LoRA call.",
      );
    } else {
      console.log("⚠️  No image in response — inspect:");
      console.log(JSON.stringify(result, null, 2));
    }
  } catch (err) {
    console.error("❌ Kontext-Multi rejected the request.");
    console.error(err);
    console.error(
      "\nFall back to prompt-only Pixar styling per spec §4.5 Fallback A.",
    );
    process.exit(2);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
```

- [ ] **Step 2: Run the script and capture output**

```bash
cd /home/ahmed/Desktop/hadouta/hadouta-backend
pnpm tsx src/scripts/verify-fal-kontext-lora.ts
```

Expected outcomes (record which one fired):
- ✅ "Kontext-Multi accepted `loras` param" + image URL → continue with full LoRA path
- ❌ Error printed → switch Task 3 to prompt-only Pixar (spec §4.5 Fallback A) before proceeding

- [ ] **Step 3: Visually inspect the output image (manual)**

Open the image URL printed by the script in a browser. Compare conceptually to a typical Flux dog photo. If the LoRA had no visible effect (image looks photographic, not "Pixar-stylized") then `loras` is silently ignored — also fall back to prompt-only.

- [ ] **Step 4: Commit the script (so the result is reproducible later)**

```bash
git add hadouta-backend/src/scripts/verify-fal-kontext-lora.ts
git commit -m "$(cat <<'EOF'
chore(ai): de-risk script for fal.ai Kontext-Multi LoRA support

One-off probe to confirm fal-ai/flux-pro/kontext/multi accepts
the `loras` array parameter before committing Task 3 implementation
to the LoRA path. Outcome documented inline in PR description.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 1: License-check + host Civitai Pixar LoRA + set env var

**Why this task exists:** Spec §4.4 selects "LH Pixar 3D Style" (Civitai 928840) as the Phase 1 placeholder LoRA. This task confirms commercial-use license and gets the LoRA into a fal.ai-loadable URL.

**Files:**
- Modify: `hadouta-backend/.env.example`
- Modify: `hadouta-backend/.env`

- [ ] **Step 1: Confirm Phase 1 use is within BFL's research carve-out**

License preflight at top of this plan already established that LH Pixar 3D Style (Civitai 928840) is permissible under BFL Flux.1 [dev] License §1(c)(ii) for testing/evaluation in non-production. This step is a final pre-flight confirmation:

- Read the License preflight section at the top of this plan
- Confirm the three boundary conditions hold for Phase 1:
  - Phase 1 test outputs will NOT be delivered to حنين or any customer
  - No revenue-generating activity will use Phase 1 outputs
  - If Phase 1 verdict is "ship Path D," we re-license BEFORE shipping (pay BFL, switch to Flux.1 [schnell] base, or commission custom LoRA)
- If any boundary condition is at risk: STOP and consult founder before proceeding

- [ ] **Step 2: If license OK, download the LoRA `.safetensors` file**

```bash
mkdir -p /tmp/hadouta-lora
cd /tmp/hadouta-lora
# Download from Civitai — copy the direct download URL from the model page's
# Download button, then:
curl -L -o lh-pixar-3d-style-v1.safetensors '<civitai-direct-download-url>'
# Verify file size is > 100MB (typical Flux LoRA size)
ls -lh lh-pixar-3d-style-v1.safetensors
```

Expected: file size between ~100MB and ~600MB.

- [ ] **Step 3: Mirror the LoRA to a fal.ai-loadable URL**

Easiest path: upload to Hugging Face under your account.

```bash
# Install HF CLI if not present
pip install --user huggingface_hub
huggingface-cli login  # paste write token from huggingface.co/settings/tokens

# Create a private model repo
huggingface-cli repo create hadouta-pixar-3d-style --type model --private

# Push the file
cd /tmp/hadouta-lora
huggingface-cli upload <your-hf-username>/hadouta-pixar-3d-style \
  lh-pixar-3d-style-v1.safetensors lora.safetensors
```

Resulting public-resolvable URL pattern:
`https://huggingface.co/<your-hf-username>/hadouta-pixar-3d-style/resolve/main/lora.safetensors`

- [ ] **Step 4: Verify the URL is reachable (anonymous)**

```bash
curl -I 'https://huggingface.co/<your-hf-username>/hadouta-pixar-3d-style/resolve/main/lora.safetensors'
```

Expected: HTTP 200 (or 302 redirect to a CDN URL).

If repo is private, change to public via:
```bash
huggingface-cli repo update <your-hf-username>/hadouta-pixar-3d-style --type model --visibility public
```

(Off-the-shelf Civitai LoRAs are public artifacts; redistributing on a public HF repo is permitted under most CreativeML licenses. License must allow this.)

- [ ] **Step 5: Add the URL to `.env.example` and `.env`**

Append to `hadouta-backend/.env.example`:

```bash
# Phase 1 (2026-05-05) — Pixar-3D style LoRA URL for fal-ai/flux-pro/kontext/multi.
# Source: Civitai 928840 "LH Pixar 3D Style", mirrored to Hugging Face for fal.ai loading.
# Sprint 4+ replaces with custom Hadouta-Egyptian-Pixar LoRA. See ADR-024 deferred section.
PIXAR_STYLE_LORA_URL=
```

Append to `hadouta-backend/.env`:

```bash
PIXAR_STYLE_LORA_URL=https://huggingface.co/<your-hf-username>/hadouta-pixar-3d-style/resolve/main/lora.safetensors
```

- [ ] **Step 6: Commit `.env.example` only (never `.env`)**

```bash
cd /home/ahmed/Desktop/hadouta/hadouta-backend
git add .env.example
git commit -m "$(cat <<'EOF'
chore(env): document PIXAR_STYLE_LORA_URL for Phase 1 Kontext path

Off-the-shelf Civitai 928840 mirrored to HF as fal.ai-loadable URL.
Sprint 4+ replaces with custom Hadouta-Egyptian-Pixar LoRA.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Add `appendPixarStyleAnchor()` to build-illustration-prompt.ts

**Files:**
- Modify: `hadouta-backend/src/lib/ai/prompts/build-illustration-prompt.ts`
- Modify: `hadouta-backend/tests/unit/build-illustration-prompt.test.ts`

- [ ] **Step 1: Write the failing test**

Append to `hadouta-backend/tests/unit/build-illustration-prompt.test.ts`:

```typescript
import { describe, it, expect } from "vitest";
import {
  buildIllustrationPrompt,
  appendPixarStyleAnchor,
} from "../../src/lib/ai/prompts/build-illustration-prompt.js";
import type { Bible } from "../../src/lib/ai/schemas/bible.js";

// Test bible — minimal valid shape, suitable for both new + existing tests.
const minimalBible: Bible = {
  title: "Test",
  characterBible: {
    mainChild: {
      name: "Test",
      gender: "girl",
      age: 5,
      appearance: { hair: "black", skin: "olive", eyes: "brown" },
      personalityVisual: "curious",
      outfit: { default: "blue dress", variations: [] },
    },
    supportingCharacters: [],
  },
  settingBible: {
    primaryLocation: "Cairo",
    primaryLocationDetails: "warm Egyptian street",
    secondaryLocations: [],
  },
  styleBible: {
    medium: "watercolor",
    palette: "warm earth tones",
    light: "golden hour",
    compositionAnchors: "child centered",
    negativeStyle: "no photorealistic",
  },
  culturalNotes: [],
};

describe("appendPixarStyleAnchor", () => {
  it("appends Pixar-3D style language to a prompt", () => {
    const original = "watercolor scene of an Egyptian girl";
    const result = appendPixarStyleAnchor(original);
    expect(result).toContain(original);
    expect(result).toContain("Pixar 3D animated style");
    expect(result).toContain("subsurface scattering");
  });

  it("does not duplicate the anchor if already present", () => {
    const already = appendPixarStyleAnchor("base prompt");
    const twice = appendPixarStyleAnchor(already);
    const occurrences = (twice.match(/Pixar 3D animated style/g) ?? []).length;
    expect(occurrences).toBe(1);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /home/ahmed/Desktop/hadouta/hadouta-backend
pnpm vitest run tests/unit/build-illustration-prompt.test.ts -t "appendPixarStyleAnchor"
```

Expected: FAIL with "appendPixarStyleAnchor is not a function" or similar import error.

- [ ] **Step 3: Implement `appendPixarStyleAnchor()`**

Append to `hadouta-backend/src/lib/ai/prompts/build-illustration-prompt.ts` (after `resolveOutfit`):

```typescript
const PIXAR_STYLE_ANCHOR =
  "Render in Pixar 3D animated style — soft volumetric lighting, " +
  "expressive facial features, warm cinematic color grading, smooth " +
  "subsurface scattering on skin, in the visual register of Disney " +
  "Encanto / Coco / Inside Out. Maintain Egyptian cultural specificity " +
  "in costuming, setting, and props as described above.";

/**
 * Append Pixar-3D style anchor language to a prompt string.
 *
 * Used by the `flux-kontext-pixar` illustration provider to overlay a
 * concrete style register on top of the Bible-driven prompt. The Bible
 * itself stays unchanged on disk — the override happens at prompt-assembly
 * time so we don't need to regenerate persisted Bibles for Phase 1.
 *
 * Idempotent: if the anchor is already present, returns the prompt unchanged.
 */
export function appendPixarStyleAnchor(prompt: string): string {
  if (prompt.includes("Pixar 3D animated style")) return prompt;
  return `${prompt}. ${PIXAR_STYLE_ANCHOR}`;
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
pnpm vitest run tests/unit/build-illustration-prompt.test.ts -t "appendPixarStyleAnchor"
```

Expected: 2 tests PASS.

- [ ] **Step 5: Run the full prompt-builder test file (regression)**

```bash
pnpm vitest run tests/unit/build-illustration-prompt.test.ts
```

Expected: ALL tests pass (including pre-existing ones — we didn't touch `buildIllustrationPrompt`).

- [ ] **Step 6: Commit**

```bash
git add hadouta-backend/src/lib/ai/prompts/build-illustration-prompt.ts \
        hadouta-backend/tests/unit/build-illustration-prompt.test.ts
git commit -m "$(cat <<'EOF'
feat(ai): add appendPixarStyleAnchor for Phase 1 Kontext path

Idempotent overlay applied to Bible-driven prompts when illustration
provider is 'flux-kontext-pixar'. Bible JSON stays untouched on disk —
style register is layered at prompt assembly so existing generations
remain valid for re-rendering under either provider.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Add Flux-Kontext-Pixar code path in illustration-generator.ts

**Why this task exists:** This is the architectural change — the existing Nano Banana code path stays untouched, a new Flux Kontext + LoRA path is added, and a `provider` parameter selects between them. Default stays `'nano-banana'` so production isn't disrupted.

**Files:**
- Modify: `hadouta-backend/src/lib/ai/illustration-generator.ts`
- Modify: `hadouta-backend/tests/unit/illustration-generator.test.ts`

- [ ] **Step 1: Write the failing test for Flux-Kontext-Pixar cover generation**

Append to `hadouta-backend/tests/unit/illustration-generator.test.ts`:

```typescript
describe("generateCoverIllustration with provider=flux-kontext-pixar", () => {
  beforeEach(() => {
    process.env.PIXAR_STYLE_LORA_URL =
      "https://example.com/test-pixar-lora.safetensors";
  });

  it("calls fal-ai/flux-pro/kontext/multi with image_urls + loras", async () => {
    (fal.subscribe as unknown as ReturnType<typeof vi.fn>).mockResolvedValue({
      data: {
        images: [{ url: "https://fal.ai/example.png", content_type: "image/png" }],
      },
    });

    const result = await generateCoverIllustration({
      orderId: "order-123",
      positivePrompt: "Egyptian girl in Cairo school courtyard",
      negativePrompt: "NOT photorealistic",
      customerPhotoUrls: [
        "https://res.cloudinary.com/test/photo1.jpg",
        "https://res.cloudinary.com/test/photo2.jpg",
      ],
      provider: "flux-kontext-pixar",
    });

    expect(fal.subscribe).toHaveBeenCalledWith(
      "fal-ai/flux-pro/kontext/multi",
      expect.objectContaining({
        input: expect.objectContaining({
          prompt: expect.stringContaining("Pixar 3D animated style"),
          image_urls: [
            "https://res.cloudinary.com/test/photo1.jpg",
            "https://res.cloudinary.com/test/photo2.jpg",
          ],
          loras: expect.arrayContaining([
            expect.objectContaining({
              path: "https://example.com/test-pixar-lora.safetensors",
            }),
          ]),
        }),
      }),
    );
    expect(result.modelId).toBe("flux-kontext-pixar");
  });

  it("falls back to existing nano-banana path when provider omitted", async () => {
    (fal.subscribe as unknown as ReturnType<typeof vi.fn>).mockResolvedValue({
      data: {
        images: [{ url: "https://fal.ai/example.png", content_type: "image/png" }],
      },
    });
    await generateCoverIllustration({
      orderId: "order-123",
      positivePrompt: "watercolor scene",
      negativePrompt: "NOT 3D",
      customerPhotoUrls: ["https://res.cloudinary.com/test/photo1.jpg"],
    });
    expect(fal.subscribe).toHaveBeenCalledWith(
      "fal-ai/nano-banana-pro/edit",
      expect.any(Object),
    );
  });
});

describe("generateBodyIllustration with provider=flux-kontext-pixar", () => {
  beforeEach(() => {
    process.env.PIXAR_STYLE_LORA_URL =
      "https://example.com/test-pixar-lora.safetensors";
  });

  it("calls fal-ai/flux-pro/kontext/multi with image_urls + loras", async () => {
    (fal.subscribe as unknown as ReturnType<typeof vi.fn>).mockResolvedValue({
      data: {
        images: [{ url: "https://fal.ai/page.png", content_type: "image/png" }],
      },
    });

    const result = await generateBodyIllustration({
      orderId: "order-123",
      pageNumber: 1,
      positivePrompt: "Egyptian girl walking to school",
      negativePrompt: "NOT photorealistic",
      coverImageUrl: "https://res.cloudinary.com/test/cover.png",
      customerPhotoUrls: [
        "https://res.cloudinary.com/test/photo1.jpg",
        "https://res.cloudinary.com/test/photo2.jpg",
      ],
      provider: "flux-kontext-pixar",
    });

    const call = (fal.subscribe as unknown as ReturnType<typeof vi.fn>).mock
      .calls[0];
    expect(call[0]).toBe("fal-ai/flux-pro/kontext/multi");
    expect(call[1].input.prompt).toContain("Pixar 3D animated style");
    expect(call[1].input.image_urls).toEqual([
      "https://res.cloudinary.com/test/photo1.jpg",
      "https://res.cloudinary.com/test/photo2.jpg",
    ]);
    expect(call[1].input.loras[0].path).toBe(
      "https://example.com/test-pixar-lora.safetensors",
    );
    expect(result.modelId).toBe("flux-kontext-pixar");
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /home/ahmed/Desktop/hadouta/hadouta-backend
pnpm vitest run tests/unit/illustration-generator.test.ts -t "flux-kontext-pixar"
```

Expected: FAIL — `provider` not on `CoverInput`/`BodyInput`, or `fal.subscribe` called with wrong endpoint.

- [ ] **Step 3: Add provider type + Pixar import + Flux endpoint constant**

Modify `hadouta-backend/src/lib/ai/illustration-generator.ts`:

Add to top of file (after existing imports):

```typescript
import { appendPixarStyleAnchor } from "./prompts/build-illustration-prompt.js";

const FLUX_KONTEXT_MULTI = "fal-ai/flux-pro/kontext/multi";

export type IllustrationProvider = "nano-banana" | "flux-kontext-pixar";
```

Modify `CoverInput` interface (around line 77):

```typescript
export interface CoverInput {
  orderId: string;
  positivePrompt: string;
  negativePrompt: string;
  /** Optional — when set (1-3 photos), used as reference images so cover reflects the actual child. */
  customerPhotoUrls?: string[];
  /** Provider selector — default 'nano-banana'. 'flux-kontext-pixar' uses Flux Kontext Multi + Pixar style LoRA. */
  provider?: IllustrationProvider;
}
```

Modify `BodyInput` interface (around line 178):

```typescript
export interface BodyInput {
  orderId: string;
  pageNumber: number;
  positivePrompt: string;
  negativePrompt: string;
  coverImageUrl: string;
  customerPhotoUrls: string[];
  /** Provider selector — default 'nano-banana'. 'flux-kontext-pixar' uses Flux Kontext Multi + Pixar style LoRA. */
  provider?: IllustrationProvider;
}
```

- [ ] **Step 4: Add a private helper for Flux-Kontext-Pixar API calls**

Add this function to `illustration-generator.ts` (above `generateCoverIllustration`):

```typescript
/**
 * Phase 1 (2026-05-05) — Flux Kontext Multi + Pixar-3D Style LoRA.
 *
 * Used when ai_settings.illustration_model = 'flux-kontext-pixar'.
 * Falls back to plain `fal-ai/flux-pro/kontext/multi` (no LoRA) if
 * PIXAR_STYLE_LORA_URL is not set in env (per spec §4.5 Fallback A).
 */
async function callFluxKontextPixar(args: {
  positivePrompt: string;
  negativePrompt: string;
  imageUrls: string[];
}): Promise<{
  url: string;
  contentType: string;
}> {
  const enrichedPrompt = appendPixarStyleAnchor(args.positivePrompt);
  const promptWithNegatives = args.negativePrompt
    ? `${enrichedPrompt}. Avoid: ${args.negativePrompt}.`
    : enrichedPrompt;

  const loraUrl = process.env.PIXAR_STYLE_LORA_URL;
  const loras = loraUrl ? [{ path: loraUrl, scale: 0.85 }] : undefined;

  const result = await fal.subscribe(FLUX_KONTEXT_MULTI, {
    input: {
      prompt: promptWithNegatives,
      image_urls: args.imageUrls,
      ...(loras ? { loras } : {}),
      aspect_ratio: "3:4",
      output_format: "png",
      num_images: 1,
    },
    logs: false,
  });

  const image = (result as {
    data?: { images?: Array<{ url?: string; content_type?: string }> };
  }).data?.images?.[0];
  if (!image?.url) {
    throw new Error(
      `Flux Kontext returned no image. Response: ${JSON.stringify(result.data ?? null).slice(0, 500)}`,
    );
  }
  return {
    url: image.url,
    contentType: image.content_type ?? "image/png",
  };
}
```

- [ ] **Step 5: Wire provider dispatch into `generateCoverIllustration`**

Replace the body of `generateCoverIllustration` so it dispatches:

```typescript
export async function generateCoverIllustration(
  input: CoverInput,
): Promise<IllustrationResult> {
  ensureFalConfigured();
  const startedAt = Date.now();
  const provider = input.provider ?? "nano-banana";
  const photoUrls = input.customerPhotoUrls ?? [];

  let imageMeta: { url: string; contentType: string };
  let modelId: string;

  if (provider === "flux-kontext-pixar") {
    if (photoUrls.length === 0) {
      throw new Error(
        "flux-kontext-pixar provider requires at least 1 customer photo for cover.",
      );
    }
    imageMeta = await callFluxKontextPixar({
      positivePrompt: input.positivePrompt,
      negativePrompt: input.negativePrompt,
      imageUrls: photoUrls,
    });
    modelId = "flux-kontext-pixar";
  } else {
    // Existing Nano Banana path — unchanged behavior.
    const promptWithNegatives = input.negativePrompt
      ? `${input.positivePrompt}. Avoid: ${input.negativePrompt}.`
      : input.positivePrompt;
    let result;
    if (photoUrls.length > 0) {
      result = await fal.subscribe(NANO_BANANA_PRO_EDIT, {
        input: {
          prompt: promptWithNegatives,
          image_urls: photoUrls,
          aspect_ratio: "3:4",
          output_format: "png",
          num_images: 1,
        },
        logs: false,
      });
    } else {
      result = await fal.subscribe(NANO_BANANA_PRO, {
        input: {
          prompt: promptWithNegatives,
          aspect_ratio: "3:4",
          output_format: "png",
          num_images: 1,
        },
        logs: false,
      });
    }
    const image = (result as {
      data?: { images?: Array<{ url?: string; content_type?: string }> };
    }).data?.images?.[0];
    if (!image?.url) {
      throw new Error(
        `Nano Banana returned no image for cover. Response: ${JSON.stringify(result.data ?? null).slice(0, 500)}`,
      );
    }
    imageMeta = { url: image.url, contentType: image.content_type ?? "image/png" };
    modelId = photoUrls.length > 0 ? "nano-banana-pro-edit" : "nano-banana-pro";
  }

  const buffer = await downloadAsBuffer(imageMeta.url);
  const uploaded = await uploadImage(
    buffer,
    input.orderId,
    "illustration_cover",
    imageMeta.contentType,
  );

  return {
    url: uploaded.url,
    contentType: uploaded.contentType,
    fileSize: uploaded.fileSize,
    modelId,
    durationMs: Date.now() - startedAt,
  };
}
```

- [ ] **Step 6: Wire provider dispatch into `generateBodyIllustration`**

Replace `generateBodyIllustration`:

```typescript
export async function generateBodyIllustration(
  input: BodyInput,
): Promise<IllustrationResult> {
  ensureFalConfigured();
  const startedAt = Date.now();
  const provider = input.provider ?? "nano-banana";

  // Reference images: prefer customer photos; fall back to cover for nano-banana.
  // For flux-kontext-pixar, multi-photo identity reference is essential — REQUIRE photos.
  let imageUrls: string[];
  if (provider === "flux-kontext-pixar") {
    if (input.customerPhotoUrls.length === 0) {
      throw new Error(
        "flux-kontext-pixar provider requires at least 1 customer photo for body pages.",
      );
    }
    imageUrls = input.customerPhotoUrls;
  } else {
    imageUrls =
      input.customerPhotoUrls.length > 0
        ? input.customerPhotoUrls
        : [input.coverImageUrl];
  }

  let imageMeta: { url: string; contentType: string };
  let modelId: string;

  if (provider === "flux-kontext-pixar") {
    imageMeta = await callFluxKontextPixar({
      positivePrompt: input.positivePrompt,
      negativePrompt: input.negativePrompt,
      imageUrls,
    });
    modelId = "flux-kontext-pixar";
  } else {
    const promptWithNegatives = input.negativePrompt
      ? `${input.positivePrompt}. Avoid: ${input.negativePrompt}.`
      : input.positivePrompt;
    const result = await fal.subscribe(NANO_BANANA_PRO_EDIT, {
      input: {
        prompt: promptWithNegatives,
        image_urls: imageUrls,
        aspect_ratio: "3:4",
        output_format: "png",
        num_images: 1,
      },
      logs: false,
    });
    const image = (result as {
      data?: { images?: Array<{ url?: string; content_type?: string }> };
    }).data?.images?.[0];
    if (!image?.url) {
      throw new Error(
        `Nano Banana returned no image for page ${input.pageNumber}. Response: ${JSON.stringify(result.data ?? null).slice(0, 500)}`,
      );
    }
    imageMeta = { url: image.url, contentType: image.content_type ?? "image/png" };
    modelId = "nano-banana-pro-edit";
  }

  const buffer = await downloadAsBuffer(imageMeta.url);
  const uploaded = await uploadImage(
    buffer,
    input.orderId,
    `illustration_page_${input.pageNumber}`,
    imageMeta.contentType,
  );

  return {
    url: uploaded.url,
    contentType: uploaded.contentType,
    fileSize: uploaded.fileSize,
    modelId,
    durationMs: Date.now() - startedAt,
  };
}
```

- [ ] **Step 7: Wire provider plumbing through `generateAllIllustrations` (orchestrator)**

Modify `BatchInput` to accept provider:

```typescript
export interface BatchInput {
  orderId: string;
  cover: { positivePrompt: string; negativePrompt: string };
  pages: Array<{
    pageNumber: number;
    positivePrompt: string;
    negativePrompt: string;
  }>;
  customerPhotoUrls: string[];
  /** Provider for both cover + body pages. Defaults to 'nano-banana'. */
  provider?: IllustrationProvider;
}
```

Then in `generateAllIllustrations`, pass `input.provider` into both cover + page calls:

```typescript
export async function generateAllIllustrations(
  input: BatchInput,
): Promise<BatchResult> {
  const startedAt = Date.now();
  const cover = await generateCoverIllustration({
    orderId: input.orderId,
    positivePrompt: input.cover.positivePrompt,
    negativePrompt: input.cover.negativePrompt,
    customerPhotoUrls: input.customerPhotoUrls,
    provider: input.provider,
  });

  const pages = await runWithConcurrency(
    input.pages,
    ILLUSTRATION_CONCURRENCY,
    async (page) => {
      const result = await generateBodyIllustration({
        orderId: input.orderId,
        pageNumber: page.pageNumber,
        positivePrompt: page.positivePrompt,
        negativePrompt: page.negativePrompt,
        coverImageUrl: cover.url,
        customerPhotoUrls: input.customerPhotoUrls,
        provider: input.provider,
      });
      return { ...result, pageNumber: page.pageNumber };
    },
  );

  return { cover, pages, totalDurationMs: Date.now() - startedAt };
}
```

- [ ] **Step 8: Run all illustration-generator tests**

```bash
pnpm vitest run tests/unit/illustration-generator.test.ts
```

Expected: ALL tests PASS — both new (flux-kontext-pixar) and pre-existing (nano-banana paths).

- [ ] **Step 9: Run typecheck across the whole backend**

```bash
pnpm typecheck
```

Expected: 0 errors.

- [ ] **Step 10: Commit**

```bash
git add hadouta-backend/src/lib/ai/illustration-generator.ts \
        hadouta-backend/tests/unit/illustration-generator.test.ts
git commit -m "$(cat <<'EOF'
feat(ai): add flux-kontext-pixar provider in illustration-generator

Adds parallel code path using fal-ai/flux-pro/kontext/multi with
multi-image conditioning + Pixar-3D style LoRA from env. Existing
Nano Banana path unchanged; provider switches via 'provider'
parameter (defaults to 'nano-banana'). Per Phase 1 design spec
§4 — quick-cycle A/B before LoRA infrastructure commit.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Wire `aiSettings.illustrationModel` into generate-book.ts

**Why this task exists:** The provider parameter must flow from the singleton `ai_settings` row down through `generate-book.ts` to `illustration-generator.ts`. Without this, flipping `ai_settings.illustration_model = 'flux-kontext-pixar'` in the DB won't have any runtime effect.

**Files:**
- Modify: `hadouta-backend/src/jobs/generate-book.ts`
- Modify (potential): `hadouta-backend/tests/unit/illustration-generator.test.ts` (only if a unit test for the orchestrator is needed)

- [ ] **Step 1: Read the current generate-book.ts to find where `generateAllIllustrations` is called**

```bash
grep -n "generateAllIllustrations\|aiSettings\|illustrationModel" \
  /home/ahmed/Desktop/hadouta/hadouta-backend/src/jobs/generate-book.ts
```

Expected: shows the existing call site for `generateAllIllustrations`. Note line numbers.

- [ ] **Step 2: Add provider read + plumbing**

Find the section in `generate-book.ts` that loads `aiSettings` (likely near the top of the orchestrator function — uses Drizzle to query the singleton row). If it doesn't exist yet, add:

```typescript
import { aiSettings } from "../db/schema.js";
import { db } from "../db/index.js";
import { eq } from "drizzle-orm";

// ... inside the orchestrator function:
const settings = await db
  .select()
  .from(aiSettings)
  .where(eq(aiSettings.id, "singleton"))
  .limit(1)
  .then((rows) => rows[0]);

const illustrationProvider =
  settings?.illustrationModel === "flux-kontext-pixar"
    ? "flux-kontext-pixar"
    : "nano-banana";
```

Then pass into the `generateAllIllustrations` call:

```typescript
const illustrations = await generateAllIllustrations({
  orderId,
  cover: { ... },
  pages: [ ... ],
  customerPhotoUrls,
  provider: illustrationProvider,  // NEW
});
```

(The exact insertion point depends on the existing code — read the file with the Read tool and locate the orchestrator function before editing.)

- [ ] **Step 3: Manually verify by reading the modified file**

```bash
grep -A 20 "generateAllIllustrations" /home/ahmed/Desktop/hadouta/hadouta-backend/src/jobs/generate-book.ts
```

Expected: shows `provider: illustrationProvider` in the call site.

- [ ] **Step 4: Typecheck**

```bash
cd /home/ahmed/Desktop/hadouta/hadouta-backend
pnpm typecheck
```

Expected: 0 errors.

- [ ] **Step 5: Run all backend tests (regression check)**

```bash
pnpm test
```

Expected: ALL tests PASS — no regression.

- [ ] **Step 6: Commit**

```bash
git add hadouta-backend/src/jobs/generate-book.ts
git commit -m "$(cat <<'EOF'
feat(jobs): wire ai_settings.illustration_model to provider switch

Reads singleton ai_settings row at generation start and forwards
the provider selector to generateAllIllustrations. 'flux-kontext-pixar'
value triggers Phase 1 Pixar Kontext path; everything else falls
back to existing Nano Banana behavior.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Run Phase 1 test generation against existing order

**Why this task exists:** This is the actual experiment — generate 3 pages of order `36e86090-...` with the new provider and compare against the existing Nano Banana output already in the admin queue.

**Files:**
- Create: `hadouta-backend/src/scripts/run-phase-1-test-generation.ts`

- [ ] **Step 1: Identify the 3 pages to regenerate**

Open the admin queue for generation `fad8f418-6464-43df-9ce2-06488b58c8a5`:
```
https://hadouta-admin.vercel.app/orders/fad8f418-6464-43df-9ce2-06488b58c8a5
```

Pick:
- **Page 0 (cover)** — always
- **The body page where حنين's face is most prominent** (eye contact, close framing, face fills ≥ 40% of frame). Note the page number.
- **One additional body page** with a different scene class — preferably an action/wide-shot for cross-page consistency check. Note the page number.

Record the chosen page numbers in a comment in the script.

- [ ] **Step 2: Create the test-generation script**

Create `hadouta-backend/src/scripts/run-phase-1-test-generation.ts`:

```typescript
// hadouta-backend/src/scripts/run-phase-1-test-generation.ts
//
// Phase 1 quick-cycle test (2026-05-05) — regenerate 3 pages of an existing
// order using the new flux-kontext-pixar provider. Reuses the persisted Bible
// + customer photos. Output URLs are logged for side-by-side comparison.
//
// Per docs/superpowers/specs/2026-05-05-phase-1-pixar-kontext-quick-cycle-design.md
//
// Run: pnpm tsx src/scripts/run-phase-1-test-generation.ts

import "dotenv/config";
import { db } from "../db/index.js";
import { generations, photos as photosTable } from "../db/schema.js";
import { eq } from "drizzle-orm";
import {
  generateCoverIllustration,
  generateBodyIllustration,
} from "../lib/ai/illustration-generator.js";
import { buildIllustrationPrompt } from "../lib/ai/prompts/build-illustration-prompt.js";
import type { Bible } from "../lib/ai/schemas/bible.js";

// ⚠️ EDIT THESE before running, per Step 1 above:
const TARGET_GENERATION_ID = "fad8f418-6464-43df-9ce2-06488b58c8a5";
const BODY_PAGE_FACE_PROMINENT = 0; // ⚠️ replace with chosen page number
const BODY_PAGE_SECOND = 0; // ⚠️ replace with chosen page number

async function main(): Promise<void> {
  // 1. Load generation row + bible + order
  const gen = await db
    .select()
    .from(generations)
    .where(eq(generations.id, TARGET_GENERATION_ID))
    .limit(1)
    .then((r) => r[0]);
  if (!gen) throw new Error(`Generation ${TARGET_GENERATION_ID} not found.`);
  if (!gen.bibleJson) throw new Error("Generation has no bibleJson — cannot rerun.");
  if (!gen.storyJson) throw new Error("Generation has no storyJson — cannot rerun.");

  const bible = gen.bibleJson as Bible;
  const story = gen.storyJson as { pages: Array<{ pageNumber: number; scene: string }> };
  const orderId = gen.orderId;

  // 2. Load customer photos for the order
  const photos = await db
    .select()
    .from(photosTable)
    .where(eq(photosTable.orderId, orderId));
  const photoUrls = photos.map((p) => p.cloudinaryUrl).filter(Boolean) as string[];
  if (photoUrls.length === 0) {
    throw new Error(`Order ${orderId} has no customer photos.`);
  }
  console.log(`Loaded ${photoUrls.length} customer photos for order ${orderId}.`);

  // 3. Pick the cover scene from story (page 0) — usually a synthesized scene description
  // Use the first body page's scene as a fallback for cover if no separate cover scene is stored.
  const coverScene =
    (gen.storyJson as { coverScene?: string }).coverScene ??
    story.pages[0]?.scene ??
    "Egyptian child opening a magical book.";

  const coverPrompt = buildIllustrationPrompt({
    bible,
    scene: coverScene,
    pageNumber: 0,
  });

  console.log("\n→ Generating Phase 1 cover with flux-kontext-pixar...");
  const coverResult = await generateCoverIllustration({
    orderId,
    positivePrompt: coverPrompt.positive,
    negativePrompt: coverPrompt.negative,
    customerPhotoUrls: photoUrls,
    provider: "flux-kontext-pixar",
  });
  console.log("   Cover URL:", coverResult.url);
  console.log("   Took:", coverResult.durationMs, "ms");

  // 4. Generate 2 chosen body pages
  for (const pageNum of [BODY_PAGE_FACE_PROMINENT, BODY_PAGE_SECOND]) {
    if (pageNum === 0) {
      console.log("\n⚠️ BODY_PAGE_* not configured — skipping. Edit the script.");
      continue;
    }
    const page = story.pages.find((p) => p.pageNumber === pageNum);
    if (!page) {
      console.log(`\n⚠️ Page ${pageNum} not in storyJson.pages — skipping.`);
      continue;
    }
    const pagePrompt = buildIllustrationPrompt({
      bible,
      scene: page.scene,
      pageNumber: pageNum,
    });
    console.log(`\n→ Generating Phase 1 page ${pageNum} with flux-kontext-pixar...`);
    const pageResult = await generateBodyIllustration({
      orderId,
      pageNumber: pageNum,
      positivePrompt: pagePrompt.positive,
      negativePrompt: pagePrompt.negative,
      coverImageUrl: coverResult.url,
      customerPhotoUrls: photoUrls,
      provider: "flux-kontext-pixar",
    });
    console.log("   Page URL:", pageResult.url);
    console.log("   Took:", pageResult.durationMs, "ms");
  }

  console.log("\n✅ Phase 1 test generation complete.");
  console.log(
    "   Compare these URLs side-by-side with the existing pages in the admin queue:",
  );
  console.log(`   https://hadouta-admin.vercel.app/orders/${TARGET_GENERATION_ID}`);
}

main()
  .catch((err) => {
    console.error("❌ Phase 1 generation failed:", err);
    process.exit(1);
  })
  .then(() => process.exit(0));
```

- [ ] **Step 3: Edit the script's TWO TODO constants**

Replace `BODY_PAGE_FACE_PROMINENT = 0` and `BODY_PAGE_SECOND = 0` with the actual page numbers chosen in Step 1. Save.

- [ ] **Step 4: Confirm `.env` has `PIXAR_STYLE_LORA_URL` set (Task 1 step 5)**

```bash
cd /home/ahmed/Desktop/hadouta/hadouta-backend
grep PIXAR_STYLE_LORA_URL .env
```

Expected: shows the HuggingFace URL set in Task 1.

- [ ] **Step 5: Run the test generation**

```bash
pnpm tsx src/scripts/run-phase-1-test-generation.ts
```

Expected output:
- "Loaded N customer photos..."
- "→ Generating Phase 1 cover... Cover URL: https://res.cloudinary.com/..."
- 2× "→ Generating Phase 1 page N... Page URL: https://res.cloudinary.com/..."
- "✅ Phase 1 test generation complete."
- Total spend: ~$0.30 (3 pages × ~$0.10 Flux Kontext call + LoRA download negligible)

If error mentions LoRA URL not loadable on fal.ai side: check Task 1 step 4 (URL must be HTTP 200 anonymously). Re-host or make HF repo public.

- [ ] **Step 6: Commit the script**

```bash
git add hadouta-backend/src/scripts/run-phase-1-test-generation.ts
git commit -m "$(cat <<'EOF'
chore(scripts): Phase 1 test generation runner

One-off script to regenerate 3 pages of generation fad8f418-... with
flux-kontext-pixar provider for side-by-side comparison vs persisted
Nano Banana output. Result URLs logged for founder annotation.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Founder side-by-side review + annotation

**Why this task exists:** This is the human-judgment step. The whole Phase 1 experiment exists to produce annotation data on these 3 pages.

**Files:**
- Create: `docs/decisions/ADR-026-phase-1-pixar-kontext-outcome.md`

- [ ] **Step 1: Open both versions of each page in browser tabs**

Open:
1. **Tab 1:** `https://hadouta-admin.vercel.app/orders/fad8f418-6464-43df-9ce2-06488b58c8a5` — the existing Nano Banana output (control). Locate cover + the 2 chosen body pages. Take note of the existing image URLs.
2. **Tab 2:** Open each new Cloudinary URL printed by Task 5 step 5 in a separate tab.

(Phase 1 doesn't add admin UI for side-by-side. Manual tab management is acceptable for 3 pages.)

- [ ] **Step 2: Annotate each page**

For each of the 3 pages, write down one of:
- 🟢 **wtf** — gut-punch recognition; "that's clearly the child"
- 🟡 **better-not-wtf** — meaningful improvement over control but not wtf-grade
- ⚪ **no-improvement** — comparable to control
- 🔴 **worse** — degraded vs control

- [ ] **Step 3: Determine direction per spec §5.5 decision tree**

Tally the 3 annotations:
- ≥ 2 × 🟢 → **Ship Path D** (Pixar-Kontext locks as production)
- ≥ 2 × 🟡 → **Ship Path D as interim**, plan Phase 2 LoRA for Sprint 4
- ≥ 2 × ⚪ or 🔴 → **Kill Path D**, fast-track Phase 2 in Sprint 3

- [ ] **Step 4: Write ADR-026 with the verdict**

Create `docs/decisions/ADR-026-phase-1-pixar-kontext-outcome.md`:

```markdown
# ADR-026 — Phase 1 Pixar-Kontext Outcome (verdict)

**Date:** 2026-05-05
**Status:** Accepted
**Supersedes:** none
**Extends:** ADR-024 (Bible-driven illustration pipeline)
**Related:** ADR-005 (watercolor — direction TBD by this verdict)

## Context

Phase 1 quick-cycle ran per `docs/superpowers/specs/2026-05-05-phase-1-pixar-kontext-quick-cycle-design.md` to test whether `fal-ai/flux-pro/kontext/multi` + an off-the-shelf Pixar-3D Civitai Flux LoRA + multi-image identity reference materially improves the founder's "wtf" recognition test relative to the deployed Nano Banana watercolor pipeline.

## Test data

- Order: `36e86090-6f28-450a-8a61-812d5f610ed0` (حنين, age 5, First Day at School + Courage)
- Generation: `fad8f418-6464-43df-9ce2-06488b58c8a5`
- 3 pages compared: cover, page X (face-prominent), page Y (action/wide)

## Comparison — Phase 1 (flux-kontext-pixar) vs control (nano-banana-pro-edit)

| Page | Control URL | Test URL | Founder annotation |
|---|---|---|---|
| Cover | <existing url> | <new url> | 🟢/🟡/⚪/🔴 |
| Page X (face-prominent) | <existing url> | <new url> | 🟢/🟡/⚪/🔴 |
| Page Y (action) | <existing url> | <new url> | 🟢/🟡/⚪/🔴 |

## Decision

[Per the decision tree in spec §5.5 — choose the verdict that matches the annotations above:]

- **Ship Path D — Pixar-Kontext locks as production architecture** [if ≥ 2 🟢]
- **Ship Path D as interim, plan Phase 2 LoRA for Sprint 4** [if ≥ 2 🟡]
- **Kill Path D, fast-track Phase 2 in Sprint 3** [if ≥ 2 ⚪ or 🔴]

## Pixar-3D style decision (independent of Path D verdict)

Confirmed adopted regardless of Phase 1 verdict, per session 2026-05-05 brainstorm:
- ADR-005 watercolor anchor superseded.
- Brand brief watercolor → Pixar update scheduled in next session.
- Sprint 4+ replaces off-the-shelf Civitai LoRA with custom Hadouta-Egyptian-Pixar LoRA commissioned from Egyptian illustrators on commercially-licensed weights (Flux.1 [schnell] Apache-2.0 base).

## Licensing posture for Phase 1 (research carve-out)

Phase 1 used LH Pixar 3D Style (Civitai 928840, trained on Flux.1 [dev]) under BFL Flux.1 [dev] License Section 1(c)(ii): "use by commercial or for-profit entities for testing, evaluation, or non-commercial research and development in a non-production environment." The 3 test outputs of generation `fad8f418-...` are internal evaluation artifacts and were NOT delivered to end users. حنين's family received the original Nano Banana watercolor output as the production artifact for that order; the Phase 1 outputs exist only as Cloudinary URLs known to founder + admin reviewer.

**If the verdict above is "Ship Path D" or "Ship Path D as interim," commercial re-licensing is required before any production deployment touches end users.** Options to be evaluated then:
- Pay BFL for a commercial Flux.1 [dev] license (`licensing@blackforestlabs.ai`)
- Switch to Flux.1 [schnell] base (Apache-2.0, fully commercial) — research a [schnell]-trained Pixar LoRA
- Sprint 4+ custom commission as planned (preferred long-term)

## Consequences

[Fill in based on chosen verdict — what changes in Sprint 3, what gets written next.]

## Cost

Phase 1 total spend: ~$X (Task 0 de-risk + Task 5 generation).

## References

- Phase 1 design spec — `docs/superpowers/specs/2026-05-05-phase-1-pixar-kontext-quick-cycle-design.md`
- Phase 1 implementation plan — `docs/superpowers/plans/2026-05-05-phase-1-pixar-kontext-quick-cycle.md`
- ADR-024, ADR-025 — pipeline + Phase H verification-before-commit principle
```

Fill in the placeholders with the actual URLs and the verdict.

- [ ] **Step 5: Update sprint-tracker.md "Resume here" section**

Open `docs/sprints/sprint-tracker.md` and update the "Resume here (next concrete action)" block to reflect Phase 1 verdict. Specifically update the Sprint 3 entry-point priority: validators framework v1 may be promoted, demoted, or unchanged based on whether Path D shipped or Phase 2 LoRA work landed in Sprint 3.

- [ ] **Step 6: Commit ADR-026 + tracker update**

```bash
git add docs/decisions/ADR-026-phase-1-pixar-kontext-outcome.md \
        docs/sprints/sprint-tracker.md
git commit -m "$(cat <<'EOF'
docs(adr): ADR-026 Phase 1 verdict + tracker update

Records the founder annotation on 3-page side-by-side comparison
and locks the Sprint 3 direction. See ADR-026 body for the verdict.
Pixar-3D style adoption is independent and confirmed.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 7: Report completion to founder**

End-of-task: print a 3-line summary of the verdict + what's queued for next session.

---

## Self-Review (run before handoff)

**Spec coverage check:**

| Spec section | Plan task |
|---|---|
| §4.1 Provider switch in illustration-generator | Task 3 |
| §4.2 New flux-kontext-pixar code path | Task 3 (helper + dispatch) |
| §4.3 Pixar-3D style anchor | Task 2 |
| §4.4 Style LoRA selection (LH Pixar 3D Style 928840) | Task 1 |
| §4.5 Fallback if no LoRA support | Task 0 (de-risk) + Task 3 (env-conditional `loras` param) |
| §5.1–5.3 Test data + 3-page selection | Task 5 step 1 |
| §5.4 Founder annotation | Task 6 step 2 |
| §5.5 Decision tree | Task 6 step 3 + ADR-026 template |
| §6 Implementation steps | Tasks 0–6 (mapped 1:1, with No 0 inserted as de-risk before original Step 1) |
| §7 Open questions / risks | Distributed across tasks (LoRA URL hosting, license, reroll endpoint fallback noted in Task 5) |
| §8 Files touched | All listed in File Structure section |
| §9 Outcome documents | ADR-026 in Task 6 |

No spec section unaddressed.

**Placeholder scan:** Two intentional placeholders in Task 5 (`BODY_PAGE_FACE_PROMINENT = 0` and `BODY_PAGE_SECOND = 0`) — explicitly flagged as "⚠️ EDIT THESE" with instructions in Task 5 step 1 + step 3 to fill them. Engineer cannot run the script without filling them. ADR-026 template has documented placeholders (URLs and annotations) that get filled by Task 6 steps 2+4. All other placeholders fixed.

**Type consistency:** `IllustrationProvider` type defined in Task 3 step 3 used consistently in Tasks 3+4. `appendPixarStyleAnchor` named consistently in Tasks 2+3. `flux-kontext-pixar` literal string consistent across schema comment, env var, switch logic, and ADR. `provider` parameter name consistent in `CoverInput`, `BodyInput`, `BatchInput`.

No further fixes needed.

---

## Execution handoff

Plan complete and saved to `docs/superpowers/plans/2026-05-05-phase-1-pixar-kontext-quick-cycle.md`.

Two execution options:

1. **Subagent-Driven (recommended)** — fresh subagent per task, two-stage review between tasks, fast iteration. Best when tasks are independent and the plan is well-specified.
2. **Inline Execution** — all tasks run in this session via executing-plans, batch with checkpoints for review. Best when there's intermediate judgment needed (e.g., Task 6 founder annotation must come from you, not a subagent).

Phase 1 has both kinds of work: Tasks 0–5 are subagent-friendly, Task 6 requires you. Recommendation is **Subagent-Driven for Tasks 0–5**, then I hand off Task 6 to you in the same session.

Which approach?
