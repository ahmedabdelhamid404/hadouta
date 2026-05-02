# ADR-020: AI-only generation with Egyptian human review only (Sprint 2 strategic pivot)

**Status**: Accepted (2026-05-02, session 9)
**Supersedes / amends**: ADR-002 (cultural-specificity moat) — production model section
**Date**: 2026-05-02
**Owner**: Ahmed (decision); Claude (implementation)

---

## Context

ADR-002 established Egyptian cultural specificity as Hadouta's moat. The original implementation model assumed:
- Egyptian writers commissioned to seed story templates (~10K EGP per ADR-002)
- Egyptian illustrators commissioned to set the watercolor reference style
- AI scales the human-curated template + reference style across thousands of personalizations
- Egyptian humans review every book before delivery (ADR-013 manual approval gate)

Brand brief codified this as: "AI is the brush, not the artist. Hadouta uses AI to scale Egyptian-led creative direction." Customer-facing copy (landing trust band, FAQ) makes the same claim: "كتّاب ورسامين مصريين بيصمموا قوالب حكاياتنا" / "Egyptian writers and illustrators design our story templates."

By session 9 (2026-05-02), Ahmed decided to drop the human writer/illustrator commissions for the MVP. Reasons (Ahmed-stated):
- Operating as a solo founder; no budget for human creative talent right now
- AI capability has progressed enough that prompt-engineered "Egyptian-ness" is achievable without hand-curated templates (per Sonnet 4.6 + Nano Banana Pro maturity)
- Time-to-launch matters; sourcing + onboarding 2-3 Egyptian creators delays Sprint 2 by weeks

## Decision

**Sprint 2 ships an AI-only generation pipeline. The only humans in the loop are the review/approval gate (Ahmed initially; expanded team eventually).**

Concretely:
- ✅ AI generates **story text** (Claude Sonnet 4.6 / Haiku 4.5 per ADR-006)
- ✅ AI generates **illustrations** (Nano Banana 2/Pro via fal.ai per ADR-006; GPT Image 2 fallback)
- ✅ AI generates **theme templates** (system prompts + few-shot examples engineered for Egyptian cultural authenticity)
- ✅ AI generates **moral lessons within stories**
- ❌ NO Egyptian writer commissions for story seed templates
- ❌ NO Egyptian illustrator commissions for watercolor reference style
- ✅ Egyptian human review still mandatory before delivery (ADR-013 unchanged)

**Cultural-authenticity moat shifts** from "human-curated templates" to a three-part claim:
1. **Egyptian-tuned AI prompts** — system prompts include explicit Egyptian-context anchors (Cairo apartments, Egyptian Arabic register, brand brief's three-worlds image set, religious-neutral pan-Egyptian theme palette, anti-tourist/anti-Gulf stance)
2. **Validators framework** (ADR-012) — flag culturally-wrong outputs before they reach review queue
3. **Egyptian human review** (ADR-013) — final gate; reviewer rejects culturally-wrong output and feeds rejection categories back into validator regeneration loop

## Consequences

### Customer-facing copy MUST change

The brand brief and landing page currently make claims that become FALSE under this pivot:

| Surface | Current claim | Status | Action |
|---|---|---|---|
| Brand brief — Cultural-authenticity foundation | "Our writers and illustrator references are Egyptian. Per ADR-002, content production includes Egyptian writers + illustrators (~10K EGP partnerships)." | ❌ false | Replace with AI-tuned-prompts + human-review claim |
| Brand brief — same section | "AI is the brush, not the artist. Hadouta uses AI to scale Egyptian-led creative direction." | ⚠️ misleading | Replace; AI is now both brush AND artist; humans review |
| Landing trust band item 1 | "كتّاب ورسامين مصريين بيصمموا قوالب حكاياتنا" | ❌ false | Replace with output-describing claim |
| Landing FAQ "إزاي بتعملوا الحدوتة؟" answer | "بنبني الحدوتة على قوالب صممها كتّاب ورسامين مصريين" | ❌ false | Drop; lead with review claim |
| Landing how-it-works step 3 | "بناءً على قوالب صممها كتّاب ورسامين مصريين" | ❌ false | Drop; describe care + review |

### Quiet middle path on AI honesty STILL applies

Customer-facing copy still:
- Doesn't lead with "AI generated"
- Never claims hand-painted or manually written
- Leads with: Egyptian human review + 2-3 day care window + designed for Egyptian children (output, not process)

### Manual review gate becomes more critical, not less

ADR-013's manual approval gate remains. Without human creative direction upstream, every AI generation risks cultural drift, tone drift, age-appropriateness drift. The reviewer is the only quality gate. This:
- Increases reviewer workload (every book gets serious attention; can't auto-approve high-confidence outputs as quickly)
- Increases active learning loop importance (each rejection teaches validators something concrete)
- Pushes some commissioned-creator value into prompt engineering (system prompts must be carefully engineered with Egyptian cultural cues)

### Risks introduced by this pivot

1. **Cultural-wrongness rate could be higher** without human-curated templates. Mitigations:
   - Reviewer rejects + feeds back into validator regeneration
   - System prompts iterate based on rejection patterns
   - Validators framework gets prioritized
2. **Brand defensibility weakens** if competitors point out "you're just AI." Mitigation:
   - Lead with the human review claim (which is true and operationally costly)
   - Output-describing language ("Egyptian-tuned story") not process-describing
3. **Quality variance** between books may be higher than human-templated approach. Mitigation:
   - Tighter validator rules
   - Slower acceptance threshold (review every book, not spot-check)

### Future revisitability

If Hadouta scales to a point where reviewer time becomes a bottleneck (~1000+ orders/month) AND budget allows, **commissioning Egyptian writers + illustrators becomes a NATURAL re-introduction** at v2:
- They write a corpus of high-quality reference stories
- Used as few-shot examples in AI prompts (now cheaper to integrate than at MVP)
- Used as auto-approval signal during validator confidence calibration

So this ADR doesn't permanently kill ADR-002's human-creator path; it defers it to "after MVP earns enough revenue to fund it."

## Implementation impact (Sprint 2 onwards)

1. Brand brief patch (this session)
2. Landing page copy patch (this session)
3. AI-honesty memory update (this session)
4. Sprint 2 implementation plan reflects AI-only pipeline (this session)
5. System prompts in `src/lib/ai/prompts/` carry the cultural-authenticity weight (Sprint 2 deliverable)
6. Validators in `src/lib/ai/validators/` enforce cultural rules (Sprint 2-3 deliverable)
7. Reviewer training docs (Sprint 4-5 deliverable, when team grows)

## Related

- ADR-002 (cultural-specificity moat) — superseded for the production-model section; the moat itself remains valid (Egypt-specific positioning)
- ADR-006 (AI stack) — unchanged; same providers (Claude + Nano Banana + GPT Image fallback)
- ADR-012 (validators) — gets more weight under this pivot
- ADR-013 (manual approval gate) — unchanged but more critical
- ADR-019 (multi-style architecture) — unchanged
- Brand brief (v1.2) — patched in same session
