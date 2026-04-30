# ADR-010: Workflow — Trigger.dev v3 with Waitpoints

**Status**: Accepted
**Date**: 2026-04-30
**Decision-makers**: Ahmed, Claude

## Context

Hadouta's pipeline (story → validators → image gen → PDF assembly → manual approval gate → delivery) needs durable workflow orchestration with: retry-on-failure, async fan-out for parallel image generation, and a way to pause indefinitely for human approval before delivery.

## Decision

Use **Trigger.dev v3** (Hobby tier free, 5K runs/mo, all features) for workflow orchestration. The **waitpoint** feature handles the manual approval gate.

## Rationale

- Waitpoints let workflow pause until external trigger (admin clicks ✅), then auto-resume — eliminates building a custom approval-state-machine + polling + DB-backed queue (saves 1-2 weeks)
- Free tier covers 5K runs/month = ~1000 books/month at 4-5 runs each (covers MVP launch with headroom)
- Built-in dashboard + retry UI = observability without custom tooling
- TypeScript-native; integrates cleanly with Hono + Vercel AI SDK
- Production track record (ad pipelines, image gen at scale)

## Consequences

- Vendor dependency on Trigger.dev cloud; mitigated by Hatchet OSS as documented fallback
- Workflow definitions live in `hadouta-backend/src/trigger/`
- Admin approval flow becomes: HTTP POST to backend → backend resolves waitpoint via Trigger.dev SDK → workflow resumes
- Queue traffic visible in Trigger.dev dashboard for solo-dev monitoring

## References

- Stack research fork (2026-04-30): Trigger.dev recommended over Inngest, BullMQ, Hangfire
- Trigger.dev waitpoints docs
