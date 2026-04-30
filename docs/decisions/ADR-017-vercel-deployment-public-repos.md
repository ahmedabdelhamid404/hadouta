# ADR-017: Vercel Deployment + Public Repos

**Status**: Accepted
**Date**: 2026-05-01
**Decision-makers**: Ahmed, Claude

## Context

Sprint 0 initially specified Cloudflare Pages for frontend deployment and treated repos as "private GitHub". Ahmed updated both: deploy frontend to **Vercel** (better Next.js integration, made by same team as Vercel AI SDK already in our stack); make repos **public** (open by default, may attract early supporters / beta sign-ups).

## Decision

### Deployment
- **Frontend** (`hadouta-web`): deploy to **Vercel** (free Hobby tier for MVP, $20/mo Pro when traffic justifies).
- **Backend** (`hadouta-backend`): unchanged — Railway (Hono runs as a Node service; Vercel Functions don't fit our long-running Trigger.dev pattern).

### Repo visibility
- Both repos PUBLIC on GitHub from day 1.
- Umbrella docs repo also public.

## Rationale

### Vercel over Cloudflare Pages
- Native Next.js 16 + React 19 support (Vercel built Next.js)
- First-class Vercel AI SDK + AI Gateway integration (already in stack)
- Simpler preview-deploy workflow per PR
- Free Hobby tier covers MVP traffic
- Trade-off: 100GB/month bandwidth on free tier vs Cloudflare's effectively unlimited; we accept this since heavy assets (book images, PDFs) flow through Cloudflare R2 + CDN, not Vercel

### Public repos
- Open by default = transparent build process; future contributors / advisors can read code
- AI usage / scope / decisions become visible — accountability incentive
- LICENSE file required (proprietary "all rights reserved" since this is a real business; code visible but not free for redistribution)
- Secrets discipline becomes mandatory: never commit `.env`, API keys, customer photos, or PII. `.gitignore` already covers this; double-check before each commit
- Marketing-friendly READMEs (people may stumble onto the repo and become customers)

## Consequences

- **Sprint 1 deploy step changes**: Vercel deploy via `vercel --prod` after linking the repo. Same DNS pattern (`hadouta.com` → Vercel; `api.hadouta.com` → Railway).
- **Vercel-specific features become available**: Server Actions, ISR, Partial Prerendering, Vercel Analytics free tier
- **Need LICENSE file** at umbrella + each sub-repo
- **READMEs must be public-facing** (marketing-aware copy, not just internal notes)
- **Secrets audit before every commit** — review `git diff` for accidental key leaks
- **Vercel env var setup** in dashboard for production
- **Vercel-Cloudflare R2 split**: assets through R2 + CDN; code/HTML/API responses through Vercel — both free tiers used optimally

## References

- Original ADR-007 (Frontend stack — Cloudflare Pages was assumed there; this ADR overrides only the deployment layer)
- Vercel Hobby tier pricing (Apr 2026)
- Sprint 1 plan deploy step (now updated)
