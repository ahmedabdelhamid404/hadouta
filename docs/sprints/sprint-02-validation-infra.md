# Sprint 2 — Validation Infrastructure & Content Production Kickoff

**Window**: Weeks 3–4 of build
**Status**: ⏸️ Skeletoned (full detail when sprint starts)

---

## Sprint goal

Optimize ad campaign on best-performing message + price; recruit nano/micro influencers for Week 5-6 launch; commission Egyptian children's writer for First Day of School story templates; commission watercolor illustrator for reference scenes; reach 200+ waitlist signups.

---

## Acceptance criteria

- ✅ Final pricing tier locked (250 or 300 EGP digital) based on Week 1-2 ad data
- ✅ Best-performing ad creative identified; budget reallocated to scale
- ✅ 5–10 nano/micro Egyptian mom influencers signed (free book + 500 EGP per post)
- ✅ Egyptian children's writer commissioned for 5 reference FDS story templates (~3-5K EGP)
- ✅ Watercolor illustrator commissioned for 5–10 reference scenes (~5K EGP)
- ✅ Demo book mockups (3 finished, polished) for landing page + ads
- ✅ Validator regression test suite framework scaffolded in `tests/validator-regression-suite/`
- ✅ Initial ~30 hand-crafted ethics test cases (50% rejected examples, 50% approved)
- ✅ Print partner shortlisted (best 1-2 from Cairo quotes)
- ✅ ≥200 waitlist signups
- ✅ Cost-per-signup data: best channel, best creative, best price documented

---

## Key tasks

### Track A — Code

- Validator regression suite framework (Vitest + JSON test case loader + LLM-as-judge runner)
- Initial test cases for universal validators
- Database schema sketch: full schema design (orders, generations, validator_runs, rejections, story_embeddings)
- Helicone integration (request tagging + dataset setup)

### Track B — Business

- Influencer outreach + briefing kit (sample books, brand assets, posting guidelines)
- Egyptian writer outreach (target: someone who has written for Diwan / Nahdet Misr)
- Illustrator outreach (target: kids' book illustrator with watercolor style)
- Print partner negotiation (sample order for 1 book)
- Pricing decision finalized; landing page + ads updated to single price

---

## Out of scope (defer to Sprint 3)

- AI generation pipeline implementation
- Image generation integration
- PDF assembly
- Customer ordering flow

---

## Manager delegation

| Task | Agent |
|---|---|
| Validator framework architecture | AI Engineer + Software Architect |
| Database schema full design | Database Optimizer + Backend Architect |
| Helicone integration patterns | Backend Architect |
| Code review (all changes) | Code Reviewer |

Full task breakdown to be expanded when Sprint 2 starts (post Sprint 1 completion).
