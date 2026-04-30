# Sprint 6 — Soft Launch & Public Launch Prep

**Window**: Weeks 17–22 of build (final stretch before September 2026 public launch)
**Status**: ⏸️ Skeletoned (full detail when sprint starts)

---

## Sprint goal

Paid soft launch to top 100 waitlist members → bug fixes + UX polish from real paying customers → public launch on/around September 1, 2026 with macro influencer push + hero ad creative live.

---

## Acceptance criteria

- ✅ Soft launch: top 100 waitlist members receive purchase invitation; ≥30% conversion rate (~30 paying customers)
- ✅ Manual approval gate active for every soft-launch book; quality bar verified
- ✅ All P0/P1 bugs from soft launch fixed
- ✅ Public launch site live with full marketing copy
- ✅ Macro influencer (1-2) campaigns scheduled for launch week
- ✅ Hero ad creative + budget scaled (10K-25K EGP launch week)
- ✅ Press / media outreach to 5+ Egyptian parenting blogs / sites
- ✅ Email sequence to remaining waitlist (welcome + product story + launch announcement)
- ✅ ≥100 paid orders in launch month
- ✅ Refund rate <12% (acceptable for launch, target <10% by month 3)
- ✅ Validator approval rate ≥85%

---

## Key tasks

### Pre-launch polish
- Performance pass (Core Web Vitals, image lazy loading, bundle analysis)
- Accessibility audit (WCAG AA targets where feasible)
- Copy polish (Arabic native speaker review of all customer-facing text)
- Mobile UX final pass (most Egyptian traffic is mobile)
- Email template polish (transactional + delivery + regen confirmations)

### Soft launch operations
- Top-100 waitlist outreach campaign (personalized email + WhatsApp from Ahmed)
- Live monitoring dashboard for orders, approval queue, payments, errors
- Daily review queue clearance (manager workflow)
- Customer feedback survey on every delivered book

### Public launch
- Landing page final copy + press kit
- Macro influencer briefing kit + sample books
- Hero ad creative production (best-performing concept from earlier sprints)
- Public launch announcement post in Egyptian mom Facebook groups (organic, with influencer signal-boosting)
- Anthropic API rate-limit increase request (in case of viral moment)

---

## Risks at launch

- **Traffic spike crashes backend** — load test in Sprint 6 first; Railway auto-scaling configured
- **AI provider rate limit hit** — pre-arrange higher tier with Anthropic + fal.ai
- **Refund flood from bad batch** — pause intake, manually review, fix validator
- **Negative review viral** — have customer support response ready (WhatsApp business hours, refund/regen offer)

---

## Manager delegation

Most work in Sprint 6 is operational + polish. Heavy on Frontend Developer (UX polish), Performance Benchmarker (load testing), and Ahmed (customer-facing comms).

---

## Post-launch (out of scope for this sprint)

- Print upgrade flow (v1.5, Q4 2026)
- Additional themes (Eid, Birthday, New Sibling — v1.5)
- Subscription tier (deferred indefinitely)
- Free-form custom story (v2)
- Diaspora market (v2)

Full task breakdown when Sprint 6 starts.
