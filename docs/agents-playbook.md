# Hadouta — Agents Playbook

How Claude (manager) orchestrates user-scope specialist agents during the build.

---

## The Manager Pattern

I (Claude) act as the **manager** for this project. For non-trivial work, I:

1. **Decompose** the task using spec-kit (`/speckit.specify` → `/speckit.plan` → `/speckit.tasks`)
2. **Delegate** each subtask to the right specialist agent (per the table below)
3. **Review** the agent's output (read code, validate against requirements)
4. **Run Code Reviewer** as a mandatory second-pass on any code changes
5. **Reconcile** any conflicts between specialist + reviewer
6. **Commit** with a clear message
7. **Update** sprint-tracker.md and session notes

This is the orchestrator-worker pattern. I preserve user intent and high-level coherence; specialists do narrow verifiable subtasks; reviews catch issues before they ship.

---

## Tier model (junior / mid / senior)

For solo-dev with AI assistance, "tiering" maps to task complexity, not seniority titles:

| Tier | What it means | Who handles |
|---|---|---|
| **Junior** | Boilerplate, scaffolding, simple CRUD, copy-paste-rename | Claude (manager) directly |
| **Mid** | Feature work following established patterns, integration tasks | Specialist agents (Backend Architect, Frontend Developer, etc.) |
| **Senior** | Architecture decisions, complex problems, novel design | Software Architect + AI Engineer + Backend Architect |
| **Review** | Always | Code Reviewer (mandatory) + manager final pass |

---

## Agent assignments by task type

### Backend (hadouta-backend)

| Task type | Primary agent | Reviewer |
|---|---|---|
| API route design (Hono) | Backend Architect | Code Reviewer |
| Database schema design / migrations (Drizzle) | Database Optimizer | Backend Architect |
| AI pipeline implementation (Vercel AI SDK + Trigger.dev) | AI Engineer | Backend Architect |
| Validator system implementation | AI Engineer | Code Reviewer |
| Auth flows (Better-Auth) | Senior Developer | Security Engineer |
| Payment integration (Paymob) | Backend Architect | Security Engineer |
| WhatsApp / email integrations (Twilio, Resend) | Backend Architect | Code Reviewer |
| Background jobs (Trigger.dev) | AI Engineer | Backend Architect |
| API integration tests | API Tester | Code Reviewer |
| Performance / profiling | Performance Benchmarker | Senior Developer |
| Security audit (auth flows, photo uploads, payment) | Security Engineer | (manager) |

### Frontend (hadouta-web)

| Task type | Primary agent | Reviewer |
|---|---|---|
| Page layouts, components | Frontend Developer | Code Reviewer |
| Customer flow UX (ordering, photo upload, checkout) | Frontend Developer | Code Reviewer |
| Admin panel (review queue, AG Grid, dashboards) | Frontend Developer | Code Reviewer |
| RTL Arabic + i18n implementation | Frontend Developer | Code Reviewer |
| Form validation (Zod schemas) | Frontend Developer | Code Reviewer |
| Auth integration (Better-Auth client) | Senior Developer | Code Reviewer |
| OpenAPI type sync | Frontend Developer | (manager) |
| Performance / Core Web Vitals | Performance Benchmarker | Frontend Developer |
| Accessibility audit | Accessibility Auditor | (manager) |

### Cross-cutting

| Task type | Primary agent | Reviewer |
|---|---|---|
| Architectural decisions (write new ADR) | Software Architect | (manager) |
| Documentation | Technical Writer | (manager) |
| Code review (every PR-style change) | Code Reviewer | (manager final) |
| Sprint retro / postmortem | (manager) | — |
| Threat modeling for sensitive flows | Security Engineer | (manager) |
| Test results analysis | Test Results Analyzer | (manager) |

---

## Concrete delegation examples

### Example 1: Implementing the photo upload signed-URL flow

**Manager decomposes**: "Need a Hono route that issues a signed R2 PUT URL when frontend wants to upload a child's photo. Includes auth check + size limit + content-type whitelist."

**Delegates to**: Backend Architect (with brief: requirements, integrate with Better-Auth session, R2 SDK already in deps, Zod schema for request validation, write a Vitest integration test).

**Reviews output**: Reads the route code + tests. Checks: auth guard correct, MIME type whitelist enforced, signed URL has appropriate expiry, no PII logged.

**Then Code Reviewer**: Second-pass review for security + style + edge cases.

**Manager final**: Reads both reviews, accepts or asks for changes, commits.

### Example 2: Designing the validator regression test framework

**Manager decomposes**: "Need a way to run 100+ ethics test cases against any validator prompt change. Test cases stored as JSON. Runner outputs pass/fail per case + aggregate metrics."

**Delegates to**: AI Engineer (knows LLM-as-judge patterns + Vitest) + Software Architect (test architecture).

**Reviews output**: Reads architecture doc + initial framework code. Checks: clean separation of test data vs runner, output format machine-readable, easy to add new cases.

**Then Code Reviewer**: Style + maintainability.

**Manager final**: Commit.

### Example 3: Adding a new Egyptian theme (post-MVP)

**Manager decomposes**: "Adding 'Eid Al-Adha' theme. Needs: 5 reference story templates, theme system prompt, theme-specific validator rules, settings library entries, marketing landing page copy."

**Delegates** in parallel:
- Technical Writer: theme system prompt + few-shot example structure
- AI Engineer: theme-specific validator rules
- Frontend Developer: theme selector UI updates

External (Ahmed-coordinated): Egyptian children's writer for the 5 reference stories, Egyptian illustrator for new settings reference scenes.

**Reviews output**: Run validator regression suite. Check stories for cultural accuracy (manual). Verify UI shows new theme correctly.

**Manager final**: Commit + announce in next session note.

---

## Code Reviewer is mandatory

Every code change to either repo gets reviewed by **Code Reviewer agent** before commit. No exceptions. This is the second-pair-of-eyes that catches what the implementing agent missed.

Code Reviewer checks:
- Correctness vs requirements
- Security (especially auth, photos, payment, AI prompts)
- Performance red flags
- Style consistency with the repo's existing patterns
- Test coverage of the change

If Code Reviewer flags issues → fix and re-review (or, if the issue is trivial, fix in-place and proceed).

---

## When to skip agent delegation

For genuinely trivial tasks, manager (Claude) handles directly without delegation:

- Editing a typo
- Renaming a variable
- Adding a single comment
- Fixing a 1-line config
- Updating sprint-tracker.md or session notes

The bar for delegation is: **does this need specialist judgment?** If yes, delegate. If no, just do it.

---

## When parallel delegation makes sense

When subtasks are independent + don't share state, dispatch multiple agents in a single tool-call message. Examples:

- Implementing backend API route + writing the corresponding frontend client function
- Writing tests + writing documentation for the same feature
- Researching multiple options for the same architectural decision

Don't parallelize if subtasks share data or depend on each other's output — sequential is safer there.

---

**Last updated**: 2026-04-30 by Claude
