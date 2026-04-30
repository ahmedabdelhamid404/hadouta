# Sprint 5 — Admin Review Queue & Closed Beta Prep

**Window**: Weeks 13–16 of build
**Status**: ⏸️ Skeletoned (full detail when sprint starts)

---

## Sprint goal

Admin panel with review queue functional + 100 internal test books generated and reviewed + 20-customer closed beta launched with free books to top waitlist members + validator calibrated on real rejection data.

---

## Acceptance criteria

- ✅ Admin panel routes (`/admin/*`) guarded by Better-Auth role check (admin only)
- ✅ Orders list (AG Grid): paginated, filterable by status/date, search by customer email/phone
- ✅ Review queue: shows pending books with story preview + image gallery
- ✅ Approve / Reject / Regenerate UI with structured rejection categories (8 categories + free-text)
- ✅ On approve: workflow resumes, customer gets WhatsApp + email
- ✅ On reject: workflow regenerates with feedback embedded; rejection stored in DB + Helicone
- ✅ Customer support panel: lookup order by email/phone, handle regen requests
- ✅ Metrics dashboard: orders by day/week/month, approval rate, regen rate, validator failure breakdown by category
- ✅ 100+ internal test books generated and manually reviewed; validator calibration data captured
- ✅ 20 closed-beta customers receive free books; manual review on each
- ✅ Bug fixes from beta feedback integrated
- ✅ Refund/regenerate flow tested end-to-end
- ✅ Validator regression suite expanded to 200+ cases

---

## Key tasks

### Admin panel UI
- Layout with sidebar navigation
- Orders list with AG Grid (sorting, filtering, batch actions)
- Order detail view (split: story + images)
- Review action buttons + structured rejection modal
- Customer support order lookup
- Metrics dashboard (charts via shadcn-charts or recharts)

### Backend admin endpoints
- Orders list endpoint (with role guard)
- Order detail endpoint
- Approve/reject/regen action endpoints (resolve Trigger.dev waitpoint)
- Metrics aggregation endpoint
- Customer support helpers

### Beta operations
- Manual outreach to top 20 waitlist members
- Free book offer + feedback survey
- Manual review pipeline live during beta
- Categorize all rejections; update validator prompts based on patterns

---

## Manager delegation

| Task | Primary | Reviewer |
|---|---|---|
| Admin UI | Frontend Developer | Code Reviewer |
| Admin backend endpoints | Backend Architect | Code Reviewer |
| AG Grid integration | Frontend Developer | Code Reviewer |
| Metrics dashboard | Frontend Developer | Code Reviewer |
| Validator calibration | AI Engineer | (manager) |
| Beta customer support | (Ahmed direct) | (manager) |

---

## Out of scope

- Theme editor UI (defer to v1.5)
- Validator rule editor UI (defer to v1.5)
- Print upgrade flow (defer to v1.5)
- Marketplace / B2B features

Full task breakdown when Sprint 5 starts.
