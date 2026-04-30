# Claude Code — Session Start Protocol for Hadouta

**You (Claude) just opened a session in the Hadouta umbrella folder. Read this entire file before responding to the user, then follow the protocol below.**

---

## 🔖 Mandatory session-start reads

Before answering ANY user request, read these files in this exact order:

1. `docs/sprints/sprint-tracker.md` — current state, current sprint, "Resume here" pointer
2. The most recent file in `docs/session-notes/` (highest date, then highest #) — what last happened
3. The current sprint plan referenced by the tracker (e.g. `docs/sprints/sprint-01-foundation.md`)

After reading those three, you have full context: project goal, locked decisions (in `docs/decisions/ADR-*.md` if needed), tech stack, sprint status, and exact next concrete action.

## ⚙️ How I work on this project

**Default mode: I implement directly.** Read context (constitution, ADRs, sprint plan, in-flight work), implement, verify (`pnpm typecheck` + tests), self-review against the constitution, commit, update the tracker + write a session note. One agent (me), one pass.

I bring in a specialist agent only when a task is genuinely senior-tier — novel AI pipeline architecture, cross-cutting validator framework design (Sprint 3+), security-critical flows beyond standard auth, threat-modeling sensitive flows — **and** doing it solo would risk a wrong call that costs hours to undo. The bar is high. Standard auth, CRUD, deploy config, frontend pages, observability wiring, schema additions → me, direct. Agent-to-task reference and the criteria for when delegation is actually justified live in `docs/agents-playbook.md`.

Pause and ask the user before: destructive operations (data deletion, force-push, applying production migrations), decisions that require a new ADR, scope changes beyond the current sprint, genuinely ambiguous intent.

## 🛠️ Tools available — used selectively, not by default

### Spec-kit
Slash commands `/speckit.specify`, `/speckit.plan`, `/speckit.tasks`, `/speckit.implement` are wired in both repos. Reach for them only when (a) the user explicitly asks, or (b) the task has genuine ambiguity (no ADR, no sprint-plan task, contradictory requirements). For routine sprint work, the constitution + ADRs + sprint plan + tracker already constitute the spec — running spec-kit on top is documentation overhead without changed outcomes.

### Agency-agents
Specialist agents in `~/.claude/agents/` are user-scope and globally available. They are tools for the rare senior-tier cases described above — not a default workforce. See `docs/agents-playbook.md` for the agent-to-task reference and the criteria for when delegation is justified.

## 📂 Folder map

```
hadouta/                            ← you are here (umbrella, public git repo)
├── README.md                       project overview
├── CLAUDE.md                       ← THIS FILE
├── LICENSE                         license terms
├── docs/                           SHARED docs (versioned in this repo)
│   ├── design/                     master design spec
│   ├── sprints/                    sprint plans + tracker (READ FIRST)
│   ├── decisions/                  ADRs (architectural decisions)
│   ├── session-notes/              session continuity logs
│   ├── agents-playbook.md          agent delegation map
│   └── skills-roadmap.md           skill candidates
├── hadouta-backend/                separate git repo (Node + Hono)
└── hadouta-web/                    separate git repo (Next.js + shadcn)
```

The two sub-repos are independent — they have their own git history. Don't accidentally commit them inside the umbrella. The umbrella `.gitignore` excludes them.

## 🌐 Deployment

- **Frontend** (`hadouta-web`): deployed to **Vercel** (free Hobby tier MVP → Pro at scale)
- **Backend** (`hadouta-backend`): deployed to **Railway** (free trial → $10–20/mo Pro)
- **Database**: Neon Postgres (free tier → Launch tier when paid traffic arrives)
- **Storage**: Cloudflare R2 (free 10GB)

## 📜 Code style & quality

- Both repos use **TypeScript strict mode** — no `any`
- Backend: **Zod** at every boundary (HTTP, LLM, queue, DB)
- Frontend: **shadcn/ui** components in RTL Arabic mode by default
- Self-review every code change against the relevant constitution before commit; **Code Reviewer agent is opt-in**, reserved for senior-tier changes where a fresh pair of eyes is genuinely worth the cost
- See each repo's `.specify/memory/constitution.md` for full principles

## 🚦 When in doubt

1. Check ADRs in `docs/decisions/`
2. Check the constitution in the relevant sub-repo's `.specify/memory/constitution.md`
3. Check the agents-playbook for "who does this kind of task"
4. Ask the user — but only if 1–3 don't answer

---

**End of session-start protocol. Begin by reading `docs/sprints/sprint-tracker.md`.**
