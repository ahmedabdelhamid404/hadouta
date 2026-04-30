# Sprint 4 — Customer Ordering Flow

**Window**: Weeks 9–12 of build
**Status**: ⏸️ Skeletoned (full detail when sprint starts)

---

## Sprint goal

End-to-end customer-facing experience: a real Egyptian mom can land on hadouta.com, design her child's book (theme + photos + supporting characters + interest tag), pay via Paymob, and have her book generated in the background. Delivery via WhatsApp + email when ready.

---

## Acceptance criteria

- ✅ Customer flow pages all live: landing → preview → customize step 1 (main character) → customize step 2 (supporting) → customize step 3 (interests + theme details) → preview cover → checkout → confirmation
- ✅ Photo upload via signed R2 URLs (frontend uploads directly, backend never touches bytes)
- ✅ Better-Auth signup/signin flows polished (email + Google OAuth + magic link)
- ✅ Paymob integration: card / Vodafone Cash / InstaPay / Fawry options live
- ✅ Order created in DB on payment success → triggers AI pipeline (built in Sprint 3)
- ✅ Twilio WhatsApp Business API integrated; "your book is ready" notification sent on delivery
- ✅ Resend email delivery with PDF attachment + web reader link
- ✅ Web reader: branded responsive view of generated book (mobile-first, RTL Arabic typography)
- ✅ Privacy: photo upload UI explicit consent, "auto-delete after 30 days" promise
- ✅ Refund/regenerate request form for customers (within 7-day window)
- ✅ Conversion funnel measurable in PostHog (preview → customize → upload → checkout → pay)

---

## Key tasks

### Customer ordering UI
- Theme picker (FDS only for now, but UI ready for multiple)
- Main character form (name, gender, age, photo upload, interest tag)
- Supporting characters form (up to 2, optional)
- Avatar customization for any character without photo (skin/hair/hijab/clothing options)
- Cover preview generation (auto-prompted on input)
- Checkout step with price + Paymob iframe
- Order confirmation + waiting screen

### Backend services
- Order creation endpoint (validates inputs, creates DB row, triggers Trigger.dev job)
- Photo upload signed-URL issuance
- Payment webhook handler (Paymob → order.paid event → workflow trigger)
- Delivery service (called on workflow completion → sends WhatsApp + email)
- Regen request endpoint

### Web reader
- Component for displaying generated book (paginated, swipeable on mobile)
- Same template Puppeteer uses for PDF (single source of truth)
- Share button (WhatsApp share, copy link)

### Privacy & legal
- Privacy policy page (Arabic + English) with explicit photo handling promises
- Terms of Service page
- Cookie consent banner (light, GDPR-style)

---

## Manager delegation

| Task | Primary | Reviewer |
|---|---|---|
| Customer ordering UX | Frontend Developer | Code Reviewer |
| Photo upload flow + signed URLs | Backend Architect | Security Engineer |
| Paymob integration | Backend Architect | Security Engineer |
| Web reader component | Frontend Developer | Code Reviewer |
| Privacy policy text | Technical Writer | (manager + Ahmed legal review) |
| WhatsApp + email delivery | Backend Architect | Code Reviewer |
| Code review all | Code Reviewer | (manager) |

---

## Out of scope (defer)

- Admin review queue UI (Sprint 5)
- Print upgrade flow (v1.5)
- B2B / wholesale features
- Loyalty / referral program

Full task breakdown when Sprint 4 starts.
