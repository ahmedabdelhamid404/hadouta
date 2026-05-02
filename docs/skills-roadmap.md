# Hadouta — Skills Roadmap

Patterns to watch for during the build. When a pattern repeats **3+ times**, codify it as a skill in `~/.claude/skills/` so future sessions don't redo the discovery work.

**Principle**: don't write skills preemptively. A skill written too early is just another premature abstraction. Wait for the pattern to prove itself, *then* codify.

---

## High-priority candidates (likely to repeat fast)

### 1. `resume-hadouta-session`
- **Pattern**: at session start, read `docs/sprints/sprint-tracker.md` → read latest entry in `docs/session-notes/` → read current sprint plan → confirm "Resume here" task
- **When to write**: after 3 sessions
- **What it does**: automates the session-start protocol so no manual reading of 3 separate files

### 2. `wrap-up-hadouta-session`
- **Pattern**: at session end, update sprint-tracker.md with progress + new "Resume here" + write new session note + commit docs
- **When to write**: after 3 sessions
- **What it does**: automates session-end protocol

### 3. `add-validator-test-case`
- **Pattern**: take a real rejection, structure it as a test case, add to `tests/validator-regression-suite/`, run regression suite to confirm it catches the issue
- **When to write**: after 5+ test cases added manually
- **What it does**: standardizes test case format + ensures all cases run cleanly

### 4. `add-hadouta-theme`
- **Pattern**: when adding a new theme post-MVP — create `content/themes/<theme-slug>/` with system-prompt.md, few-shot-examples.json, validator-rules.json, reference-stories/; add theme entry to DB seed; update frontend theme selector
- **When to write**: when starting theme #2 (Eid Al-Adha)
- **What it does**: scaffolds new theme from a single command + ensures nothing is forgotten

### 5. `write-adr`
- **Pattern**: capture an architectural decision as a numbered ADR file in `docs/decisions/` with consistent structure
- **When to write**: after 5+ ADRs written manually (so the pattern is well-established)
- **What it does**: scaffolds new ADR with template + auto-numbers + updates sprint-tracker reference

### 6. `kickoff-sprint`
- **Pattern**: when starting a new sprint, expand its skeleton plan into detailed day-by-day tasks based on the sprint goal + acceptance criteria
- **When to write**: when starting Sprint 3 (after running Sprints 1-2 manually)
- **What it does**: turns a skeleton sprint plan into a detailed plan with delegation assignments

---

## Medium-priority candidates

### 7. `delegate-to-agent`
- **Pattern**: format a delegation brief for a specialist agent (context + requirements + reviewers + acceptance criteria)
- **When to write**: after 10+ delegations (the brief structure stabilizes)
- **What it does**: standardizes how I prepare delegations so output quality is consistent

### 8. `mandatory-code-review`
- **Pattern**: after any specialist agent commits code, automatically run Code Reviewer with project-specific style guide reference
- **When to write**: when this becomes a mechanical post-commit hook
- **Note**: could also be a Claude Code hook (PostToolUse on Write|Edit) instead of a skill — evaluate both options when codifying

### 9. `sync-openapi-types`
- **Pattern**: regenerate `hadouta-web/lib/api/api-types.ts` from `hadouta-backend/openapi.json` whenever backend schemas change
- **When to write**: after 3+ API schema changes
- **What it does**: one command that pulls OpenAPI spec + regenerates TypeScript types + verifies frontend still type-checks
- **Note**: this is also automatable via a `pnpm` script in the frontend package.json, which is simpler

### 10. `ad-creative-generator`
- **Pattern**: generate 3-creative × 3-price-tier × 3-language Facebook ad variants for a new theme launch
- **When to write**: when launching theme #3 (after manually doing theme 1 and 2)
- **What it does**: takes theme metadata → produces ad copy variants + creative briefs

---

## Low-priority / speculative candidates

### 11. `cost-monitor-report`
- **Pattern**: at end of week, pull AI provider costs + Cloudflare R2 + Trigger.dev usage + Neon usage; format weekly report
- **When to write**: post-launch only

### 12. `customer-feedback-triage`
- **Pattern**: classify an incoming customer regen request into structured categories + decide auto-approve vs needs-review
- **When to write**: post-launch when feedback volume grows

### 13. `validator-prompt-update`
- **Pattern**: take recent rejections + update validator system prompt with new few-shot examples + run regression suite + deploy if green
- **When to write**: when validator iteration becomes routine (likely Sprint 5+)

### 14. `validate-drizzle-migration` (flagged session 3, reinforced session 5)
- **Pattern**: pre-flight a generated migration SQL against a scratch DB before committing — catches CASCADE-redundant DROPs and similar Postgres-dependency-semantic gotchas that schema-syntax review misses
- **When to write**: after the next 1-2 schema migrations bite. Session 5's `0002_phone_otp_and_multi_style.sql` was hand-written (drizzle-kit interactive prompt unavailable); same family of risk
- **What it does**: takes a generated migration → spins up a scratch Postgres → applies migration → reports any errors (constraint redundancy, type-cast issues, default-value semantics)

### 15. `rotate-leaked-credential` (flagged session 5)
- **Pattern**: when a credential leaks to chat: revoke at provider dashboard → create replacement with same scopes → update `.env.local` → propagate to all deployed env vars (Railway, Vercel, etc.) → smoke-test → verify old token now 401s
- **When to write**: after 3+ rotations. We've done 3 already (Vercel CLI session 4, Sentry + PostHog session 5)
- **What it does**: takes provider name + credential name → walks the rotation steps → confirms downstream env-var propagation

### 16. `bypass-mcp-via-rest-api` (flagged session 5)
- **Pattern**: when a hosted MCP server fails (OAuth bug, scope mismatch, protocol gap), build a `scripts/<service>/` wrapper directory + a runbook that wraps common queries against the service's REST API using a personal API key in `.env.local`
- **When to write**: when this happens for a 3rd service (currently Sentry + PostHog; Figma may be next)
- **What it does**: scaffolds the runbook + .env.example + a few starter scripts based on a provider name + auth pattern

---

## Anti-patterns (don't write these as skills)

- ❌ `set-up-new-project` — too project-specific, every project is different
- ❌ `pick-the-right-agent` — already covered by agents-playbook.md, no automation needed
- ❌ `commit-message-formatter` — git commit messages are best written from context, not templated

---

## How to actually write a skill (when the time comes)

1. Recognize the pattern repeating (note in session notes)
2. Confirm 3+ instances of the same workflow
3. Use the `skill-creator` skill from user-scope: `/skill-creator:skill-creator`
4. Test the skill on a 4th instance to verify it works
5. Update this roadmap to mark the skill as ✅ written

---

**Last updated**: 2026-05-02 (session 5) by Claude — added candidates #14-16 (validate-drizzle-migration, rotate-leaked-credential, bypass-mcp-via-rest-api). All flagged but none yet at 3-instance threshold for codification.
