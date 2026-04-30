# ADR-007: Frontend — Next.js 15 + shadcn/ui

**Status**: Accepted
**Date**: 2026-04-30
**Decision-makers**: Ahmed, Claude

## Context

Ahmed has senior Angular skill (5y). Initial recommendation favored Angular for skill reuse. After fresh stack research with explicit "neglect prior knowledge" directive, alternatives were evaluated objectively for AI-heavy app + admin panel + RTL Arabic.

## Decision

Frontend: **Next.js 15 + React 19 + shadcn/ui + Tailwind 4 + next-intl**. Single Next.js app handles both customer flow and admin panel (`/admin/*` guarded routes).

## Rationale

- Vercel AI SDK is React-first — richest streaming hooks and primitives
- shadcn/ui is the gold-standard admin-panel component library in 2026 (no Angular equivalent at this quality)
- next-intl has the most polished Arabic RTL handling
- React Server Components stream AI responses natively
- Larger AI ecosystem + more training data → I (Claude) write higher-quality React than Angular
- Angular skill carries over partially (TypeScript, component thinking, dependency injection patterns)

## Consequences

- Ahmed needs ~2-3 weeks ramp on React + Next.js App Router + JSX
- I (Claude) handle most code writing; Ahmed reviews
- Single repo for customer + admin reduces deployment complexity
- shadcn copy-paste model means we own the components (good for customization, requires diligence on updates)

## References

- Stack research fork (2026-04-30): TypeScript-everywhere + AI ecosystem maturity wins
- Brainstorming Q12-Q13: tech stack decisions
