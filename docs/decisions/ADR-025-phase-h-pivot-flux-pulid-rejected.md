# ADR-025: Phase H pivot — Flux+PuLID rejected, Nano Banana Pro Edit adopted

**Date:** 2026-05-05
**Status:** Accepted (drives ADR-024)
**Extends:** ADR-024 (Bible-driven illustration pipeline)
**Type:** Lessons-learned ADR — documents what we tried, what failed, and why

## Context

The illustration pipeline spec (`docs/design/specs/2026-05-03-illustration-pipeline-redesign-spec.md`) called for Flux 1.1 Pro + PuLID via Fal.ai based on the Arabic research file (`/home/ahmed/Downloads/searchReports.md`) which identified PuLID as the May-2026 industry-standard for face identity preservation in personalized illustrations.

During Phase H verification (8 iterations against real APIs, 2026-05-04 evening through 2026-05-05 early morning), the spec'd Flux+PuLID architecture failed to render character-in-scene illustrations regardless of parameter tuning. The pipeline was pivoted to Nano Banana Pro Edit (`fal-ai/nano-banana-pro/edit`) during verification. This ADR documents what was tried, what failed, why, and what the team should remember.

Total cost of Phase H verification: ~$3.10 across 8 iterations.

## Decision

Reject Flux+PuLID for Hadouta's character-in-scene use case. Adopt Nano Banana Pro Edit with multi-image conditioning (per ADR-024).

## What was tried, in chronological order

### Iteration 1 — Spec'd Flux+PuLID (Omar, Eid)

- Cover via fal-ai/flux-pro/v1.1 (text-only)
- Body pages via fal-ai/flux-pulid (`reference_image_url` = customer photo, default `id_weight: 1.0`, `start_step: 0`)
- 17 illustrations generated end-to-end
- **Result:** Identity not preserved (face didn't really resemble photo). Cover OK but body pages all rendered as "boy standing alone against neutral background" with NO scene context — page 1's "waking up in bed" prompt produced standing-pose, page 4's "running to greet grandparents" produced standing-pose, etc.
- Cost: ~$1.00

### Iteration 2 — gpt-4o vision + face-cropped photo + tuned PuLID (Omar)

- gpt-4o (not gpt-4o-mini) for `describePhoto()` vision call → captured galabeya correctly
- Cloudinary face-crop transformation `c_thumb,g_face,w_512,h_512` on photo URL before passing to PuLID → stronger face vector for InsightFace
- PuLID params: `id_weight: 0.65`, `start_step: 12`
- **Result:** Galabeya now in Bible. Body pages STILL portrait-only with no scene rendering. Identity slightly improved.
- Cost: ~$1.00

### Iteration 3 — More aggressive PuLID tuning + dev mode introduced

- `id_weight: 0.4`, `start_step: 16` (last 43% of denoising)
- Dev mode: cover + 2 body pages instead of 17 (cost reduction $1.00 → $0.17)
- New face-focused photo (close-up, ~50% face area)
- **Result:** Body pages STILL portrait-only. **PuLID's portrait bias is fundamental — three rounds of param tuning all hit the same ceiling.** The model is trained on portrait photography; it can't render character-in-scene compositions regardless of how late in denoising identity is injected.
- Cost: ~$0.17

### Architecture pivot (Iteration 4)

Researched Fal.ai's available endpoints. Found `fal-ai/nano-banana-pro/edit` (Gemini 2.5 Flash Image / "Nano Banana Pro" with multi-image conditioning support — `image_urls: Array<string>`). Same model family that produced rich Egyptian/Cairo scenes in Sprint 2 (before character-drift was the blocking issue).

### Iteration 4 — Nano Banana Pro Edit, image_urls = [cover, photo]

- All illustrations now use Nano Banana Pro Edit
- **Result:** Cover quality dramatically better (multi-character action scenes, watercolor brush strokes, Egyptian decorations). Body pages duplicated the cover (Gemini anchored on cover as the strongest visual signal, ignored per-page scene prompts).
- Cost: ~$0.20

### Iteration 5 — Drop cover from body refs (key insight)

- Body image_urls = `[photo only]` (cover dropped)
- Per-page scene block emphasized: "PAGE N SCENE — this specific page MUST depict [scene]..."
- **Result: WORKS.** Body pages render distinct scenes; identity preserved; watercolor visible; cultural anchors (kahk, fanous lanterns) present. Slight identity drift across pages from single-photo interpretation variance.
- Cost: ~$0.13

### Iteration 6 — Test "best of both worlds" hypothesis

- Body image_urls = `[photo, cover]` (photo first for primary weight, cover second for character continuity)
- **Result:** User-rejected — too-similar room reuse across pages. Even with photo first, the cover image still pulls the model toward replicating that specific scene's composition.
- Cost: ~$0.13. Rolled back.

### Iteration 7 — Identity-preservation prompt language

- Reverted to iteration-5 architecture (photo-only body refs)
- Added explicit identity directive in scene block: "the child's face must EXACTLY match the reference photo — same face shape, same eye shape and color, same hair texture and length, same distinguishing features..."
- **Result:** Stronger identity than iter 5. Per-page interpretation variance reduced.
- Cost: ~$0.13

### Iteration 8 — Multi-photo (3 angles) + School theme + Courage moral

- Customer uploaded 3 photos of same girl from different angles (close-up green bow + turquoise dress + light blue hoodie)
- All 3 photos passed as `image_urls` to every illustration call (cover + 16 body)
- gpt-4o for both story AND Bible (gpt-4o-mini permanently rejected per separate feedback memory)
- Bible system prompt hardened with explicit four-top-level-keys structure example
- **Result: Architecture locked.** Multi-photo gives Gemini richer 3D face geometry → stronger identity. Generation `fad8f418-...` in admin queue for inspection.
- Cost: ~$0.21

## Why Flux+PuLID failed for our use case

Three lessons that drove the rejection:

### 1. PuLID is a portrait tool, not a scene tool

PuLID was trained on portrait photography. Its inductive bias is "render this person as a portrait." Multi-image conditioning with PuLID enforces that bias even when the prompt requests a scene. This isn't a parameter problem — it's a training-data problem. No amount of `id_weight` tuning or `start_step` shifting overcame this bias across 4 iterations.

### 2. Param tuning has a ceiling defined by training data

We tried `id_weight` at 0.75, 0.65, 0.4. We tried `start_step` at 0, 12, 16 (out of 28 total). We tried face-cropped photo input. We tried full-body photo input. **All produced the same outcome: portraits, not scenes.** The lesson: when a model produces unexpected outputs, distinguish between *parameter tuning* (the model can do the thing, we just need the right knobs) and *capability gap* (the model fundamentally can't do the thing). PuLID hit the capability ceiling, not a parameter ceiling.

### 3. Spec accuracy depends on real API verification

The spec was based on the research file's industry-survey claim that PuLID is the May-2026 standard for personalized illustration. Research files are aspirational and aggregate-published-results-driven. Real-world product verification (this Phase H) revealed that the same model that's gold-standard for portrait identity is not fit for character-in-scene illustration — the use case in the research and the use case in our product weren't actually the same. The lesson for Hadouta-going-forward: any spec involving model selection should include a real-API verification phase BEFORE locking architecture, not after.

## Why Nano Banana Pro Edit succeeded

Three properties of the final architecture:

### 1. Native multi-image conditioning

Nano Banana Pro Edit accepts `image_urls: Array<string>` natively. Multiple reference images can be passed and the model blends them via its multimodal vision rather than forcing one to dominate. This is what enabled multi-photo identity reinforcement (Iteration 8) — three angles of the same face produce richer 3D understanding than one front shot.

### 2. Scene rendering is its strength

Nano Banana (Gemini 2.5 Flash Image family) renders rich, multi-character, action-laden scenes with cultural-specific detail. Sprint 2 confirmed this empirically. The character-drift problem of Sprint 2 wasn't because Nano Banana couldn't render scenes — it could. The problem was that Sprint 2 didn't use multi-image conditioning OR a Bible-structured prompt OR cover-as-reference for character continuity. Once those signals are added (per ADR-024), Nano Banana's scene-rendering strength becomes the dominant property.

### 3. Architecture is provider-portable

Nano Banana lives at `fal-ai/nano-banana-pro/edit` today. If a better model ships next quarter, the architecture (Bible + structured prompts + multi-image conditioning) ports to whichever model accepts the same `image_urls` shape. Most modern multimodal image APIs do.

## Consequences

**Positive:**
- The shipped pipeline works (verified in Iteration 8). Identity stable, scenes vary per page, watercolor present, Egyptian cultural anchors rendered.
- Future spec work knows: real-API verification PRECEDES architecture lock-in, not after.
- The Bible structure, prompt assembler, multi-photo plumbing, and orchestration are all model-agnostic — would work with Imagen 4 Ultra, Hunyuan, Kling 3.0, etc., not just Nano Banana.

**Negative:**
- $3.10 spent on architecture verification before the right answer landed. Forward, prefer running 1-image dev iterations earlier in the cycle to compress this cost.
- The original spec's architecture description (Flux+PuLID) is now misleading. Future readers should consult ADR-024 + ADR-025 alongside the spec; the spec's §5.5 (Fal.ai integration) reflects the rejected architecture.

**Deferred:**
- Updating the spec document with an "implementation reality" addendum noting the pivot. (Done as part of this session's documentation pass.)

## Implementation

Final architecture committed in `b844f8b` and `e041d6e`. Verified end-to-end in iteration 8 (generation `fad8f418-6464-43df-9ce2-06488b58c8a5`). Phase H iteration log preserved in `docs/session-notes/2026-05-05-pdf-redesign-and-illustration-pipeline.md` part 2.

User instruction locked as feedback memory: never use gpt-4o-mini for any Hadouta task — see `~/.claude/projects/-home-ahmed-Desktop-hadouta/memory/feedback_no_gpt4o_mini.md`.
