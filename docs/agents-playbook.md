# Hadouta — Agents Playbook

How and when Claude reaches for a specialist agent on this project. **The default is direct implementation, not delegation.**

> **Operating-mode change**: as of 2026-05-01 (Sprint 1 session 3), this project switched from the manager-delegation default to a direct-implementation default. The previous manager-pattern playbook lives in this file's git history if ever needed. Reasoning recorded in `docs/session-notes/2026-05-01-session-3.md`.

---

## Default mode: direct implementation

For ~95% of Hadouta work, Claude:

1. Reads the structure (constitution, ADRs, sprint plan, in-flight work, tracker)
2. Implements directly
3. Verifies (`pnpm typecheck` + relevant tests)
4. Self-reviews the diff against the constitution
5. Commits with a clear message
6. Updates `docs/sprints/sprint-tracker.md` and writes a session note in `docs/session-notes/`

One agent (Claude), one pass. No spec-kit ceremony, no parallel reviewers, no Code-Reviewer-mandatory pass.

---

## When Claude DOES bring in a specialist agent

The bar is high: only when **both** of the following are true:

1. The task is genuinely senior-tier — novel architecture, cross-cutting design, AI pipeline design, security-critical flows beyond standard auth, threat modeling.
2. Doing it solo would risk a wrong call that costs hours of rework.

### Examples that DO clear the bar
- Validator regression-test framework design (Sprint 3) — novel pattern + cross-cutting
- AI pipeline architecture (Sprint 3) — multiple coupled providers + Trigger.dev workflows + cost discipline
- Threat-modeling photo-upload + payment flows (Sprint 4)
- Active-learning loop design with pgvector embeddings (Sprint 3+)

### Examples that do NOT clear the bar (Claude does these directly)
- Standard auth integration (Better-Auth) — proven in Sprint 1
- CRUD endpoints, schema additions, standard Drizzle migrations
- Frontend pages, RTL setup, shadcn/ui composition
- Deploy config, env wiring, observability instrumentation (Sentry, PostHog)
- Documentation, README, ADRs (Claude drafts; user approves)
- Bug fixes, typo fixes, dependency bumps

---

## When Claude pauses and asks the user

Auto-action is the default for everything that clears the day-to-day bar, but pause and confirm before:

- **Destructive operations**: data deletion, force-push, applying production migrations, dropping tables, mass file deletion
- **Decisions requiring a new ADR**: technology substitutions, architectural changes, scope shifts
- **Scope changes** beyond the current sprint
- **Genuinely ambiguous intent** where the wrong choice would waste hours

---

## If you DO need a specialist — agent reference

(Use only when the senior-tier bar above is cleared.)

| Task type | Agent | When |
|---|---|---|
| AI pipeline architecture | AI Engineer | Sprint 3+ |
| Validator framework design | AI Engineer + Software Architect | Sprint 3 |
| Threat modeling sensitive flows | Security Engineer | Sprints 3–4 |
| Performance hot-path profiling | Performance Benchmarker | as discovered |
| Accessibility full audit | Accessibility Auditor | pre-launch (Sprint 6) |
| Core Web Vitals audit | Performance Benchmarker | pre-launch (Sprint 6) |
| New ADR drafting (when requested) | Software Architect | as needed |
| Senior-tier code review | Code Reviewer | when self-review is genuinely insufficient |

For the original (longer) per-task agent map and concrete delegation examples, see this file's git history before 2026-05-01.

---

## Code review

**Self-review is the default before commit.** Run `pnpm typecheck` + tests, re-read the diff, verify it matches the sprint-plan task and respects the constitution.

The **Code Reviewer agent is opt-in**, used when:
- The change is senior-tier (validator framework, payment integration, complex AI orchestration)
- The change touches security-sensitive code paths beyond standard patterns
- Self-review feels genuinely insufficient (rare; trust your judgment)

Standard auth, CRUD, frontend pages, deploy config, observability wiring → self-review only.

---

## Spec-kit

`/speckit.specify` → `/speckit.plan` → `/speckit.tasks` → `/speckit.implement` is **opt-in**.

Reach for it only when:
- The user explicitly asks
- The task has genuine ambiguity (no ADR, no sprint-plan task, contradictory requirements)

For routine sprint work, the constitution + ADRs + sprint-plan task + tracker already pin the spec. Running spec-kit on top regenerates documents without changing the outcome.

---

## When parallel agents make sense (rare)

Only when subtasks are **both** independent (no shared files, no dependencies on each other's output) **and** each crosses the senior-tier bar above. The "implementer + reviewer in parallel" pattern was tested in Sprint 1 session 3 and found to be heavyweight for the value delivered — don't reach for it unless the decomposition genuinely warrants it.

---

**Last updated**: 2026-05-01 (Sprint 1 session 3) by Claude. Operating mode shifted to direct-implementation default.
