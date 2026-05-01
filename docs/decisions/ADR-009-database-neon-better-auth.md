# ADR-009: Database — Neon + Better-Auth + Cloudflare R2 (NOT Supabase)

**Status**: Accepted
**Date**: 2026-04-30
**Decision-makers**: Ahmed, Claude

## Context

Initial recommendation was Supabase (DB + Auth + Storage + Realtime bundled). Ahmed raised concerns: scaling cost spikes, weak customer support reputation, charges-extra-for-backups complaints. Research validated several concerns; alternative stacks were evaluated.

## Decision

**Database**: Neon Postgres (with pgvector extension for active-learning embeddings).
**Auth**: Better-Auth (open-source, runs in our Hono backend, stores users in Neon).
**Object storage**: Cloudflare R2 (zero egress fees, S3-compatible).
**Realtime**: Not needed for MVP; defer.

Supabase is rejected as a primary DB+Auth+Storage bundle.

## Rationale

- Neon's scale-to-zero compute = $0 idle cost during dev (better than Supabase's free-tier auto-pause)
- Neon includes point-in-time recovery (PITR) in base pricing; Supabase charges $100/mo extra
- Better-Auth eliminates vendor lock-in (vs Clerk's $25/mo + $0.02/MAU which becomes ~$2K/month at 100K MAU)
- Cloudflare R2 zero egress kills the biggest Supabase scaling-cost vector pre-emptively
- Three best-of-breed services > one bundled platform with concerning support track record at scale
- Cost at 1000 books/mo: ~$25-30/mo (Neon stack) vs $40-60/mo (Supabase Pro)

## Consequences

- 3 services to wire instead of 1 bundle (more setup but cleaner long-term)
- Better-Auth requires Resend SMTP for email verification (already in stack)
- pgvector enabled in Neon for active-learning embeddings
- All photos + book images + PDFs flow through R2 (signed URL upload pattern)
- No realtime in MVP; revisit if admin queue UX needs live updates (likely Sprint 5)

## References

- DB research fork (2026-04-30): Supabase concerns validated; Neon recommended
- Better-Auth vs Clerk vs Supabase Auth 2026 daily.dev guide
- Design doc § 3.2: Component diagram

## Addendum (2026-05-01, session 4)

This ADR specifies the auth library (Better-Auth) but did not specify the auth *strategy* (which factors, in what order, with what UX flow). The Sprint 0 scaffold used the library default (email-password + Google OAuth + email verification), which session 4 identified as strategically misaligned with the Egyptian market.

**Auth strategy is now defined by ADR-018: phone-first WhatsApp OTP with multi-tier fallback and invisible accounts.** ADR-018 does not replace this ADR — Better-Auth + Neon + R2 remain the underlying stack. ADR-018 specifies how that stack is exposed to users.
