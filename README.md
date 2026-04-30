# Hadouta (حدوتة) — Project Umbrella

Egyptian AI personalized children's book platform. Launching September 2026.

This folder is the **umbrella** containing two sibling git repos + shared documentation.

```
/home/ahmed/Desktop/hadouta/
├── README.md                  ← you are here
├── docs/                      ← SHARED docs (sprints, ADRs, session notes, design)
├── hadouta-backend/           ← BACKEND repo (Node + Hono + Drizzle)
└── hadouta-web/               ← FRONTEND repo (Next.js 16 + React 19 + shadcn)
```

## 🔖 Where to start (any new session)

1. **Read `docs/sprints/sprint-tracker.md`** — current state + "resume here"
2. **Read latest in `docs/session-notes/`** — what last happened
3. **Open the current sprint plan** in `docs/sprints/`
4. **Begin from "Resume here"** in the tracker

This sequence is non-negotiable. It guarantees you pick up exactly where the last session stopped, with no re-litigation of settled decisions.

## 📚 Key documents

- **`docs/design/2026-04-30-hadouta-design.md`** — master design spec (4500+ words)
- **`docs/sprints/sprint-tracker.md`** — current state (read every session)
- **`docs/sprints/sprint-NN-*.md`** — per-sprint plans
- **`docs/decisions/ADR-NNN-*.md`** — architectural decision records (16 to start)
- **`docs/session-notes/YYYY-MM-DD-N.md`** — session continuity logs
- **`docs/agents-playbook.md`** — which user-scope agent for which task type
- **`docs/skills-roadmap.md`** — skills to write when patterns repeat

## 🛠️ The two repos

### Backend — `hadouta-backend/`
Node 20 + Hono + Vercel AI SDK + Drizzle (Neon Postgres) + Better-Auth + Trigger.dev. See `hadouta-backend/README.md` for setup.

### Frontend — `hadouta-web/`
Next.js 16 + React 19 + Tailwind 4 + shadcn/ui (RTL Arabic enabled) + next-intl. See `hadouta-web/README.md` for setup.

Each repo has its own `.specify/` (spec-kit) and `.claude/` (project-scope settings + spec-kit skills).

## 🤖 The manager pattern

I (Claude) act as the **manager** for this build. For non-trivial work, I delegate to user-scope specialist agents (Backend Architect, Frontend Developer, AI Engineer, Database Optimizer, etc.) and run mandatory Code Reviewer second-pass on every code change. See `docs/agents-playbook.md` for the assignments.

## 📅 Roadmap

- **Sprint 0** ✅ — Bootstrap (this session)
- **Sprint 1** 🟢 — Foundation (week 1-2)
- **Sprint 2** ⏸️ — Validation infra + content production (week 3-4)
- **Sprint 3** ⏸️ — AI pipeline foundation (week 5-8)
- **Sprint 4** ⏸️ — Customer ordering flow (week 9-12)
- **Sprint 5** ⏸️ — Admin review queue + closed beta (week 13-16)
- **Sprint 6** ⏸️ — Soft launch + public launch (week 17-22, target Sept 1, 2026)

## 📝 Status as of 2026-04-30

✅ Brainstorming complete
✅ Design doc written
✅ All 16 ADRs locked
✅ Both repos bootstrapped
✅ Sprint 1 detailed, Sprints 2-6 skeletoned
🟢 **Sprint 1 ready to begin**

---

*Brand: Hadouta (حدوتة) — "bedtime story" in Egyptian Arabic.*
*Tagline: حدوتة طفلك… وهو البطل (Your child's bedtime story… where they're the hero)*
