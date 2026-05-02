# Observability Runbook — Sentry + PostHog

**Status**: Active. Sprint-1 minimal viable.
**Last updated**: 2026-05-02
**Audience**: Anyone querying Hadouta error/analytics data from CLI

## Why this exists

Claude Code's HTTP-MCP OAuth flow has a known bug ([anthropics/claude-code#12077](https://github.com/anthropics/claude-code/issues/12077)) that breaks the standard `/mcp` browser auth for Sentry + PostHog. The bearer-token alternative also has issues — Sentry's MCP gateway is a separate auth realm from their REST API and rejects user-created auth tokens. Rather than burn more time debugging, we **bypass MCP entirely** and hit the REST APIs directly via the helper scripts in `scripts/observability/`.

This runbook documents:
- How to set up local credentials (`.env.local`)
- Which scripts exist and what each does
- Common workflows (find recent errors, query events, etc.)
- Token rotation policy
- Open setup TODOs

When MCP integration becomes viable (Claude Code bug fix + token-format alignment), we revisit. Until then the REST-API approach is canonical.

## Setup

### One-time

1. **Copy the template**:
   ```bash
   cp .env.example .env.local
   ```
   `.env.local` is gitignored — actual secrets live there.

2. **Sentry credentials** — at https://sentry.io/settings/account/api/auth-tokens/:
   - Create token, name it `hadouta-ops`
   - Scopes: `org:read`, `project:read`, `event:read`, `team:read` (read-only is enough for runbook scripts)
   - Paste into `.env.local` as `SENTRY_AUTH_TOKEN`
   - Set `SENTRY_ORG_SLUG` (currently `my-company-4vi`; find at https://sentry.io/settings/<org>/)

3. **PostHog credentials** — Hadouta is on the **EU instance** at https://eu.posthog.com:
   - Create personal API key at https://eu.posthog.com/settings/user-api-keys
   - Scopes: `read` on insights/events/persons/feature-flags
   - Paste into `.env.local` as `POSTHOG_PERSONAL_API_KEY`
   - `POSTHOG_HOST=https://eu.posthog.com` (do NOT use us.posthog.com — different region, returns 401)
   - `POSTHOG_PROJECT_ID` is the numeric project ID (currently 170756); find via `./scripts/observability/posthog-list-projects.sh` after the personal API key is set

### Per-project — Sentry DSNs

Each Sentry project has a separate DSN — that's what goes in the SDK init code (`SENTRY_DSN` for the backend, `NEXT_PUBLIC_SENTRY_DSN` for the frontend).

- **hadouta-web** (frontend, exists): DSN populated in `.env.local` as `SENTRY_DSN_HADOUTA_WEB`. Set this as `NEXT_PUBLIC_SENTRY_DSN` on Vercel.
- **hadouta-backend** (NOT YET CREATED): create via Sentry dashboard, then add DSN to `.env.local` and set as `SENTRY_DSN` on Railway. See the "Open TODOs" section below.

### Per-project — PostHog frontend key

PostHog distinguishes **personal API keys** (`phx_*` — for management API queries from this runbook) from **project API keys** (`phc_*` — for browser-side event capture).

- `POSTHOG_PERSONAL_API_KEY` (`phx_*`) → used by the scripts in this runbook
- `POSTHOG_PROJECT_API_KEY` (`phc_*`) → goes in the frontend's `NEXT_PUBLIC_POSTHOG_KEY` Vercel env var (PostHog SDK uses this to capture events)

Don't confuse them. The `phc_` is meant to be public (it's in browser bundles). The `phx_` must stay private.

## Scripts

All in `scripts/observability/`. Each reads from `.env.local` and outputs newline-delimited records that pipe cleanly to `grep`/`awk`/`jq`.

### `./scripts/observability/sentry-list-issues.sh [project] [limit]`
Recent unresolved errors in a Sentry project (last 24h).

```bash
./scripts/observability/sentry-list-issues.sh hadouta-web 5
# →  2026-05-02T12:34:56Z  ERROR  [3 ev / 1 users]  Cannot read properties of undefined (reading 'foo')
```

Defaults: `project=hadouta-web`, `limit=10`.

### `./scripts/observability/sentry-list-projects.sh`
Every project in the org with its platform + numeric ID.

```bash
./scripts/observability/sentry-list-projects.sh
# →  hadouta-web  javascript-nextjs  (id: 4511319736189008)
# →  hadouta-backend  node  (id: ...)        ← when you create it
```

### `./scripts/observability/posthog-recent-events.sh [limit]`
Most recent events in the PostHog project.

```bash
./scripts/observability/posthog-recent-events.sh 30
# →  2026-05-02T12:34:56Z  $pageview  distinct_id=anon-12345  https://hadouta-web.vercel.app/
# →  2026-05-02T12:34:55Z  waitlist_submit  distinct_id=anon-67890
```

### `./scripts/observability/posthog-list-projects.sh`
PostHog projects with their IDs + frontend `phc_*` keys.

```bash
./scripts/observability/posthog-list-projects.sh
# →  170756  Default project  phc_y59bscmseKNNfJjXyWoqNMbMwX7hwFyg4xXiCTmTBgtL
```

## Common workflows

### Did the last deploy break anything?
```bash
./scripts/observability/sentry-list-issues.sh hadouta-web 20 | head -10
```
Anything in the output dated within ~5 minutes of a deploy timestamp is a regression candidate.

### How many waitlist signups today?
PostHog event for the waitlist form (assuming you've added a `waitlist_submit` capture call):
```bash
./scripts/observability/posthog-recent-events.sh 100 | grep waitlist_submit | wc -l
```

For more sophisticated queries (funnels, retention, etc.), use the PostHog dashboard at https://eu.posthog.com — the runbook scripts cover ad-hoc CLI queries, not analytics dashboards.

### Find the DSN to put in Vercel/Railway
```bash
grep SENTRY_DSN .env.local
grep POSTHOG .env.local | grep -E '(PROJECT_API_KEY|INGEST_HOST)'
```

## Token rotation policy

Both `SENTRY_AUTH_TOKEN` and `POSTHOG_PERSONAL_API_KEY` are durable plain-text credentials sitting in `.env.local`. Rotate at end of build period or any time:
- A token has been pasted to chat (already happened this Sprint — both tokens are on the rotation list in `docs/sprints/sprint-tracker.md`)
- A teammate joins/leaves
- Quarterly hygiene cycle

Rotation is one minute per service:
1. Visit provider settings → revoke old token
2. Create new token with same scopes
3. Update `.env.local`
4. Smoke-test by running `./scripts/observability/sentry-list-projects.sh` (etc.)

## Open setup TODOs

- [ ] **Create `hadouta-backend` Sentry project** at https://my-company-4vi.sentry.io/settings/projects/ (Platform: Node.js, Name: `hadouta-backend`). After creating, fetch its DSN with `curl -s -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" "https://sentry.io/api/0/projects/$SENTRY_ORG_SLUG/hadouta-backend/keys/" | jq` and put in `.env.local` as `SENTRY_DSN_HADOUTA_BACKEND`. Set as `SENTRY_DSN` on Railway.

- [ ] **Set Vercel env vars** for the frontend (Sentry + PostHog SDK init):
  ```
  NEXT_PUBLIC_SENTRY_DSN=<SENTRY_DSN_HADOUTA_WEB from .env.local>
  NEXT_PUBLIC_POSTHOG_KEY=<POSTHOG_PROJECT_API_KEY from .env.local>
  NEXT_PUBLIC_POSTHOG_HOST=<POSTHOG_INGEST_HOST from .env.local>
  ```
  Until these are set, the SDKs in code are no-ops (DSN/key unset → init returns early). Real production data starts flowing only after Vercel env vars are populated and the next deploy redeploys with them baked in.

- [ ] **Frontend PostHog host bug** — the current `instrumentation-client.ts` defaults `api_host` to `https://us.i.posthog.com`, but Hadouta's PostHog account is EU (`https://eu.i.posthog.com`). Either set the env var on Vercel (overrides default) or update the SDK default. See [hadouta-web/instrumentation-client.ts](../../hadouta-web/instrumentation-client.ts).

- [ ] **Rename PostHog project** from "Default project" to "Hadouta" — at https://eu.posthog.com/settings/project. Cosmetic; not blocking.

- [ ] **Revisit MCP integration** when one of:
  - Claude Code resolves [#12077](https://github.com/anthropics/claude-code/issues/12077)
  - Sentry MCP starts accepting user auth tokens
  - We hit data volume that justifies chat-based queries (likely Sprint 3+)

## Why we deferred MCP

For posterity — the MCP failure modes we hit during Sprint 1 setup, so future-us doesn't relitigate:

- **OAuth flow** (`claude mcp add ...` + `/mcp`): both Sentry + PostHog rejected with "Invalid redirect URI" — Claude Code bug #12077.
- **Bearer token (Sentry)**: 401 invalid_token at `https://mcp.sentry.dev/mcp` — same token works against `https://sentry.io/api/0/` though. MCP gateway is a separate auth realm.
- **Bearer token (PostHog)**: token IS accepted by MCP, but the JSON-RPC handshake fails on missing `Mcp-Session-Id` header — likely another Claude Code MCP-client bug. Real tools never load.

REST-API approach has worked first try with the same tokens. Ship the runbook, move on.

## Related

- ADR-018 — phone-first WhatsApp OTP (PostHog-tracked auth events come from this flow)
- ADR-019 — multi-style architecture (style-related metrics will eventually live in PostHog)
- `docs/sprints/sprint-tracker.md` — Sprint 1 acceptance checks Sentry+PostHog wired
- `hadouta-backend/src/instrumentation.ts` — Sentry init for backend
- `hadouta-web/instrumentation.ts` + `instrumentation-client.ts` — Sentry init for frontend
- `hadouta-web/src/components/providers/PostHogProvider.tsx` — PostHog init
