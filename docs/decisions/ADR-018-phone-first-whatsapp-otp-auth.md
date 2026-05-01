# ADR-018: Authentication — Phone-first WhatsApp OTP with multi-tier fallback and invisible accounts

**Status**: Accepted
**Date**: 2026-05-01
**Decision-makers**: Ahmed, Claude
**Supersedes**: implicit auth-strategy assumption from ADR-009 (does not replace ADR-009; adds the missing strategy layer)

## Context

ADR-009 chose Better-Auth as the auth library but did not specify the authentication *strategy* (which factors, in what order, with what UX flow). The Sprint 0 scaffold defaulted to email + password + Google OAuth + Resend email verification — a defensible default for global B2B but a poor fit for our actual market.

Re-examining in session 4 surfaced three problems with the implicit default:

1. **Email is a poor primary identifier for Egyptian parents.** Smartphone penetration is 94%; mobile connections are 121M (102% of population). WhatsApp is the dominant communication channel. Email accounts often go unchecked for days; phone numbers are universal and remembered. (Source: DataReportal Digital 2026: Egypt.)

2. **`requireEmailVerification: NODE_ENV === "production"` is conversion-hostile.** Forcing users to switch to email and click a verification link before they can buy compounds with the next problem.

3. **"Sign up before purchase" loses 24% of shoppers.** (Source: Salesforce 2026 Ecommerce Checkout Best Practices.) For a personalized-product funnel that depends on paid ad traffic, that's a tax on every ad impression.

The phone column on the user table is already collected (Better-Auth custom field added in session 3) but unused for authentication. Twilio environment variables are already in `.env.example` (planned for Sprint 3). Better-Auth has a first-party `phone-number` plugin (1.4+) that supports a `sendOTP(phoneNumber, code)` callback pattern.

The decision is whether to keep the email-first scaffold or pivot to a phone-first identity model **before** wiring Sentry/PostHog and starting paid ad traffic, while the change is still cheap.

## Decision

**Adopt a phone-first authentication strategy with multi-tier fallback, invisible account creation, and lazy verification.**

### Identity model

- **Phone number is the canonical user identity.** It is what we use for marketing (WhatsApp campaigns about new themes), order tracking, delivery (Bosta), and support lookups.
- **Email and Google OAuth are linked alternative login methods**, not separate identities. Better-Auth's `account` table maps multiple `(provider, providerAccountId)` rows back to one canonical `user.id`.
- **A single user can have multiple linked methods.** Adding a method is a settings-page action; losing one method does not lose the account.

### Login channel hierarchy

| Tier | Channel | Use | Implementation |
|---|---|---|---|
| 1 | **WhatsApp OTP** | Default for all signin/signup | Twilio BSP → Meta WhatsApp Business API, Better-Auth `phone-number` plugin |
| 2 | **SMS OTP** | Auto-fallback if WhatsApp delivery fails after ~30s | Twilio SMS, same Better-Auth plugin with channel-switch in `sendOTP` |
| 3 | **Google OAuth** | Alternative path; recovery if phone access lost | Better-Auth Google provider (already wired) |
| 4 | **Email OTP** | Last-resort recovery; receipts and important notifications | Better-Auth `email-otp` plugin, Resend transport |
| 5 | **Customer support** | Edge-case recovery if all above unavailable | Manual; acceptable given our fraud profile |

### Account creation: invisible accounts (lazy registration)

- **No "sign up" step before purchase.** First-time buyers enter phone + child info + payment in one flow.
- On payment success, the backend atomically creates a Better-Auth user with the phone as the primary `account` row, links the order to that user, and sets a session cookie immediately. The user is logged in without ever seeing a "signup" page.
- **Phone verification happens after payment**, post-hoc, via a WhatsApp OTP that doubles as the order-confirmation message. Users can ignore it for the immediate happy path; it gates only sensitive future actions (refund, change phone, etc.).
- Returning users sign in via the tier hierarchy above.

### Verification policy: lazy, not eager

- **Drop `requireEmailVerification: NODE_ENV === "production"`** (current Better-Auth setting from session 3). Email verification becomes optional and only triggered when the user adds an email as a backup method.
- **Phone is verified once via the post-purchase WhatsApp OTP.** A successfully-completed OTP marks `phone_verified_at`; subsequent logins via the same phone do not require re-OTP unless we detect a risk signal (new device, geo-anomaly).
- Email verification, where it happens, is a single OTP-by-email step at the time of email linking — not a recurring per-login challenge.

### OTP timing — phased with the product roadmap

- **Sprint 1–v1.0 (digital books, ADR-004)**: post-purchase OTP. Fraud cost is near-zero (digital delivery has no marginal cost for a fake phone number); convenience wins. The OTP doubles as order confirmation.
- **v1.5 (print upgrade, ADR-004)**: switch to **mid-checkout OTP** (between card details and charge). Bosta delivery to a fake phone is a real cost; verifying mid-checkout adds 10s of friction in exchange for eliminating fake-phone fraud-spam against the print fulfillment cost.

### Risk-based step-up (architectural orientation, not Sprint 1 implementation)

Long-lived session cookies (default 30-day rolling, sliding renewal) handle the routine path. **Re-OTP is required at the moment of**:
- Refund request
- Phone number change
- Email/OAuth method change or removal
- Login from a new device or new IP-region cluster
- (Future) Subscription/recurring-billing setup

This mirrors industry-standard risk-based authentication and is built incrementally — each sensitive endpoint gates itself with an `await requireRecentVerification(user)` middleware at the moment we add the endpoint.

### Provider choice: Twilio + Meta

- **Twilio is the BSP (Business Solution Provider)**; Meta owns WhatsApp and is non-optional. Meta verification is a required upstream step regardless of which BSP we pick.
- BSP choice is between Twilio, MessageBird, 360dialog, Vonage. We default to Twilio because the env scaffold already references it, the API is the most ergonomic of the four, and the Twilio sandbox accelerates dev iteration.
- **Hard rule: never use unofficial WhatsApp APIs** (`whatsapp-web.js`, "free WhatsApp APIs" from third-party providers). Numbers used with these get permanently banned by Meta. Production must go through the official path.
- **Branded display name** ("Hadouta" or "حدوتة") and **registered Egyptian commercial register + tax card** are non-negotiable inputs to FB Business Verification.

### Future-readiness (deferred, but architected for)

- **Passkeys (WebAuthn).** 2026 industry trend is "passkey-first UX" especially for fintech. Better-Auth's passkey plugin is mature; we add it as an *additional* linked method in Sprint 4–5, not a replacement for any tier above. Egyptian smartphone penetration (94%) is high enough that passkey adoption is realistic.
- **Multi-language OTP templates.** OTP templates support per-language variants (Arabic-RTL primary, English fallback for expat users). Set up Arabic at template-approval time.

## Rationale

### Why phone-first

- **Market fit**: 94% smartphone, 102% mobile connections, dominant WhatsApp culture
- **Channel quality**: WhatsApp OTP achieves 90-95% open rates within 3 minutes vs SMS 70-80% vs email 20-30% (Source: MojoAuth 2026)
- **Speed**: <2s WhatsApp delivery vs 5-30s SMS; OTP entry stays sub-10s end-to-end
- **Cost**: WhatsApp is 40-60% cheaper per message than SMS at our scale (Twilio's own published comparison)
- **Identity unification**: same phone number is auth identifier AND marketing channel — single source of truth, no email/phone divergence to maintain

### Why invisible accounts

- **24%-abandon-at-forced-registration tax** is well-documented (Salesforce 2026)
- Personalized-product funnels (kid's name, photo, theme) inherently produce stable identity post-payment without an explicit signup step
- Lazy registration is industry-standard 2026 practice for e-commerce; aligns with "invisible payments" trend
- Egyptian users may be account-averse for cultural/PDPL reasons; not asking for an account upfront is a trust gesture

### Why drop email verification

- It gates conversion on a behavior (checking email) that doesn't reliably happen for our demographic
- Email is no longer the canonical identity, so the "prove you own this email" check matters less
- Lazy verification at the point of use (when adding an email method, when doing email-OTP login) preserves the security check where it's actually relevant
- Removing the gate eliminates a Sprint-1-era support burden ("I didn't get the email!")

### Why keep Google OAuth + Email OTP as fallbacks

- Phone access loss is a real failure mode (lost phone, sim-swap, number change, WhatsApp account ban)
- Provides a recovery path without needing customer support intervention
- Google OAuth is already wired (session 3); marginal cost to retain
- Email OTP via Resend is already wired; placeholder API key on Railway can be promoted to a real one when needed
- The "expat gifter" persona (someone abroad buying a Hadouta book for an Egyptian relative) needs a non-Egyptian-WhatsApp path

### Why phased OTP timing

- Pre-purchase OTP is a fraud-prevention pattern; relevant only when fake-phone-number fraud has marginal cost
- Digital books have zero marginal cost per fake order — fraud cost is the AI-generation compute, which is too small to justify pre-purchase friction
- Print books (v1.5) have non-trivial Bosta delivery cost per fake order — at that point, mid-checkout OTP makes sense
- Phasing the timing with the product avoids "build it twice"

## Consequences

### What changes

- New Better-Auth plugin: `phone-number` (with custom `sendOTP` calling Twilio)
- New Better-Auth plugin: `email-otp` (replaces `requireEmailVerification` link flow)
- Schema additions: `phoneVerifiedAt`, `phoneNumber` (already partial), `phoneE164` normalized form, `lastVerifiedAt` for risk-based step-up
- New env vars on Railway: `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_WHATSAPP_FROM`, `TWILIO_SMS_FROM`, `TWILIO_MESSAGING_SERVICE_SID` (the messaging service handles channel fallback declaratively)
- Frontend signup form rework: phone field primary, secondary "Continue with Google" / "Use email instead" links
- Order flow: `createOrder` mutation also creates the user atomically when the phone has no existing account
- Drop the `requireEmailVerification` flag in `src/auth/index.ts`
- Sprint 1 acceptance criteria reinterpreted: "Better-Auth signup/signin works" → tested via phone-OTP, not email-password

### What's added in operational complexity

- **Meta-side**: FB Business Verification (Egyptian commercial register + tax card), WhatsApp Business display-name approval, ~5 message templates (auth OTP, order confirmation, "new theme available", abandoned-cart re-engagement, shipping notification for v1.5)
- **Twilio-side**: WhatsApp sender registration, SMS sender ID registration with NTRA (Egypt regulator) for tier-2 fallback
- **Code-side**: rate limiting (already in Better-Auth core), OTP TTL config (10 min recommended), channel-fallback timer logic in `sendOTP`
- **Monitoring**: Sentry+PostHog (separate ADR / track A15-A16) needs `auth.otp_sent`, `auth.otp_verified`, `auth.otp_failed`, `auth.method_linked` events

### What gets safer

- Long-lived sessions (30-day rolling) reduce per-login friction without weakening security; risk-based step-up handles sensitive ops
- Multi-method linkage means account loss requires losing *all* linked methods, not just one
- Phone-as-canonical means less email-account-compromise blast radius (email is just one of several methods, not the master key)

### What gets riskier

- Phone-number portability / SIM-swap (low base rate; mitigated by step-up at sensitive ops)
- Twilio outage = OTP outage (mitigated by SMS fallback within Twilio; future option: secondary BSP)
- Meta WABA quality-rating drops can throttle marketing-template sends (mitigated by conservative template content + monitoring)

### What we accept as known unknowns

- The 92% WhatsApp-OTP completion rate quoted earlier is a pooled global figure; Egypt-specific numbers may differ. We'll measure via PostHog once wired.
- FB Business Verification can be rejected on first attempt for documentary reasons; budget 1-2 retry cycles in the timeline.
- WhatsApp template approval can be rejected on creative-content grounds (especially marketing templates with promotional language); plan for 2-3 revision cycles per marketing template.

### Migration / rollout plan

| Phase | Work | Owner | Estimated effort |
|---|---|---|---|
| 0 | **Start FB Business Verification** (parallel, long pole) | Ahmed | 30 min to apply, 3-7 days to approve |
| 0 | Sign up for Twilio if not already; collect Egyptian commercial register + tax card | Ahmed | 30 min |
| 1 | Wire Better-Auth `phone-number` plugin + `email-otp` plugin; drop `requireEmailVerification` | Claude | 2-3 hours |
| 1 | Implement `sendOTP` callback that posts to Twilio WhatsApp (sandbox first) | Claude | 1 hour |
| 1 | Frontend signup form: phone-primary, secondary buttons, OTP entry component (auto-fill aware) | Claude | 2-3 hours |
| 1 | Vitest integration tests for phone-OTP signup, signin, account linking, lazy email link | Claude | 1-2 hours |
| 2 | Order flow: invisible-account-at-purchase logic | Claude | 1-2 hours (when order flow lands in Sprint 4 — pulled forward partially for waitlist→order migration) |
| 2 | Switch from Twilio sandbox to production Twilio + WhatsApp number (post-FB-Business-Verify) | Ahmed + Claude | 30 min config |
| 2 | Submit ~5 message templates for Meta approval | Ahmed | 1 hour to draft, 24-48h Meta review |
| 3 | (Sprint 4-5) Add passkey plugin as additional linked method | Claude | 2-3 hours |

Total Sprint 1 impact: roughly **6-9 hours** of code work, blocked behind Ahmed's FB Business Verification (3-7 days) for actual production WhatsApp messaging. Dev work proceeds against the Twilio sandbox in the meantime.

## References

### Validation sources (queried 2026-05-01)

- [WhatsApp Business — One-Time Passwords Guide](https://business.whatsapp.com/blog/one-time-password-otp-guide)
- [MojoAuth — SMS vs Email vs WhatsApp OTP Comparison](https://mojoauth.com/white-papers/sms-otp-vs-email-otp-vs-whatsapp-otp/)
- [Authgear — SMS OTP vs WhatsApp OTP](https://www.authgear.com/post/sms-otp-vs-whatsapp-otp)
- [Twilio — SMS vs WhatsApp for Business](https://www.twilio.com/en-us/blog/insights/best-practices/sms-vs-whatsapp-for-business)
- [DataReportal — Digital 2026: Egypt](https://datareportal.com/reports/digital-2026-egypt)
- [Authsignal — 5 Authentication Trends for 2026](https://www.authsignal.com/blog/articles/5-authentication-trends-that-will-define-2026-our-founders-perspective)
- [Salesforce — Ecommerce Checkout: 10 Best Practices for 2026](https://www.salesforce.com/commerce/online-payment-solution/checkout-guide/?bc=OTH)
- [Corbado — E-Commerce Authentication: 2026 Benchmark](https://www.corbado.com/blog/ecommerce-authentication)
- [UI Patterns — Lazy Registration design pattern](https://ui-patterns.com/patterns/LazyRegistration)
- [Better Auth — Phone Number Plugin Documentation](https://better-auth.com/docs/plugins/phone-number)
- [Better Auth — 1.4 Release Notes](https://better-auth.com/blog/1-4)
- [Quali-D — WhatsApp Business API in Egypt: Complete 2025 Guide](https://quali-d.com/blog/whatsapp-api-egypt-guide)
- [Twilio — WhatsApp Business Platform Documentation](https://www.twilio.com/docs/whatsapp/api)

### Related ADRs

- ADR-004 — Digital-first MVP, optional print upgrade in v1.5 (drives the phased OTP-timing decision)
- ADR-009 — Database + Better-Auth + R2 (this ADR fills in the auth-strategy layer ADR-009 left implicit)
- ADR-013 — Active learning loop with manual approval gate (depends on stable user identity, validated by phone-as-canonical)
- ADR-014 — Pricing A/B test (PostHog feature-flag use case downstream of stable phone identity)
- ADR-016 — Distribution channels phased (FB+IG paid traffic depends on conversion-friendly auth)

### Internal context

- Session-3 note (2026-05-01): Better-Auth wired with email-password + Google OAuth + Resend; this ADR pivots that to phone-first while preserving Google OAuth and adding email OTP as fallback
- Session-4 note (2026-05-01): live deploys + this ADR's discovery that the email-first scaffold is strategically misaligned with the Egyptian market
