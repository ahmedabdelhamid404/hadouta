# ADR-011: Two Repos with OpenAPI Type Sync

**Status**: Accepted
**Date**: 2026-04-30
**Decision-makers**: Ahmed, Claude

## Context

Initial recommendation was a monorepo with shared `/packages/schemas/` Zod definitions. Ahmed preferred two separate repos (one for frontend, one for backend) for cleaner separation, independent deploy cycles, and forward-compatibility with team growth.

## Decision

**Two separate git repos**: `hadouta-backend` and `hadouta-web`, both inside `/home/ahmed/Desktop/hadouta/`. Type sharing via **OpenAPI**: backend auto-generates spec via `@hono/zod-openapi`; frontend regenerates TypeScript types via `openapi-typescript`.

## Rationale

- Cleaner separation of concerns for deployments, CI, version history
- Forward-compatible if Ahmed eventually hires for one side
- OpenAPI is industry-standard contract; works with any future client (mobile, partners)
- `pnpm sync-types` script in frontend regenerates types from backend spec in seconds — friction is minimal for solo dev

## Consequences

- API change workflow: edit Zod in backend → backend dev server regenerates `openapi.json` → frontend runs `pnpm sync-types` → frontend type-checks against new types
- 5-second extra step per API change (acceptable for solo dev)
- Lose monorepo's hot-reload-across-boundaries; gain repo isolation
- Each repo has its own `.claude/`, `.specify/`, `package.json` — slightly duplicated config
- Validator regression test suite + content/themes folder live in backend repo (where they're consumed)

## References

- Brainstorming Q14: monorepo decision overturned by user preference
- Design doc § 3.3: Repository structure
