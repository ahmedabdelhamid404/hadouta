# ADR-008: Backend — Node + Hono + TypeScript

**Status**: Accepted
**Date**: 2026-04-30
**Decision-makers**: Ahmed, Claude

## Context

Ahmed has 1.5y .NET experience and senior Angular TypeScript skill. Initial recommendation kept .NET 10 for skill reuse. After "neglect prior knowledge" directive, backend was re-evaluated for AI-heavy workload.

## Decision

Backend: **Node.js 22 + Hono framework + TypeScript** (strict mode). Vercel AI SDK for orchestration. Drizzle ORM. Better-Auth for authentication.

## Rationale

- TypeScript end-to-end: backend Zod schemas double as frontend form validators (one source of truth)
- Hono cold starts: 50-100ms vs ASP.NET Core's 500-2000ms (matters for serverless deploys)
- Vercel AI SDK is TypeScript-native; .NET's Semantic Kernel lags meaningfully in 2026 AI ecosystem maturity
- Anthropic + fal.ai SDKs have first-class TypeScript support (.NET SDKs are community-maintained, less mature)
- Migration cost from .NET: ~1-2 weeks ramp; Ahmed's TypeScript fluency carries 70%+ of patterns
- Senior Angular skill = TypeScript senior; backend skill gap is smaller than it looks

## Consequences

- Both repos share the same language runtime → easier mental model, easier debugging across the stack
- `.NET 10 + Semantic Kernel` decision from previous chat is overturned
- Hono + Trigger.dev integration is well-documented; production deployments via Railway are straightforward
- Vendor lock-in to JS ecosystem accepted; mitigated by Vercel AI SDK's provider-swap abstraction

## References

- Stack research fork (2026-04-30): Node + Hono recommended for AI-heavy app
- Brainstorming Q12-Q13: tech stack
