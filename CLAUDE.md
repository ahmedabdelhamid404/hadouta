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

I am the **manager**. I orchestrate user-scope specialist agents (Backend Architect, Frontend Developer, AI Engineer, Database Optimizer, Code Reviewer, etc.) for non-trivial tasks. The specialists do the focused work; I review their output; Code Reviewer runs second-pass on every code change before commit. Map of which agent does what: `docs/agents-playbook.md`.

I auto-delegate without asking permission per task. The user already approved this pattern. Only escalate if a task requires a destructive action or a strategic decision (new ADR, scope change, etc.).

## 🛠️ Two complementary tools, both used automatically

### Spec-kit (the workflow)
For any non-trivial feature, use spec-kit's slash commands in order:
- `/speckit.specify` — write the feature spec
- `/speckit.plan` — technical plan
- `/speckit.tasks` — task breakdown
- `/speckit.implement` — execute (delegating to agents inside this step)

Skip spec-kit only for trivial work (typos, single-line config tweaks).

### Agency-agents (the workforce)
Specialist agents in `~/.claude/agents/` live in user scope and are available everywhere. The playbook (`docs/agents-playbook.md`) maps task type → which agent handles it. Inside `/speckit.implement`, I delegate to these agents.

These two tools compose. Spec-kit gives structured discipline; agency-agents give specialist execution. They do not compete; pick neither in isolation.

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
- Mandatory **Code Reviewer** agent pass on every code change before commit
- See each repo's `.specify/memory/constitution.md` for full principles

## 🚦 When in doubt

1. Check ADRs in `docs/decisions/`
2. Check the constitution in the relevant sub-repo's `.specify/memory/constitution.md`
3. Check the agents-playbook for "who does this kind of task"
4. Ask the user — but only if 1–3 don't answer

---

**End of session-start protocol. Begin by reading `docs/sprints/sprint-tracker.md`.**
