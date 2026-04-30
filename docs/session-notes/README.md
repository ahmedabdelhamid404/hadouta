# Session Notes — Hadouta

This folder logs every session of work on Hadouta. The newest note is always the resume point for the next session.

---

## 🔖 Session-start protocol

When you (Claude or Ahmed) start a new session:

1. **Read `docs/sprints/sprint-tracker.md`** — see current state
2. **Read the most recent file in this folder** (highest date + number) — see what last happened
3. **Read the current sprint plan** at `docs/sprints/sprint-NN-<name>.md`
4. **Begin from "Resume here"** in the tracker

---

## 🔖 Session-end protocol

Before closing a session:

1. Update `docs/sprints/sprint-tracker.md`:
   - Mark completed tasks
   - Update "Resume here (next concrete action)"
   - Update sprint status if changed
2. Write a new session note in this folder using the template below
3. Commit docs changes (`git add docs/ && git commit -m "session: <date>-<n>"`)

---

## 📝 Session note template

Copy this for each new session note:

```markdown
# Session YYYY-MM-DD — N

**Duration**: ~X hours
**Sprint**: <sprint number and name>
**Manager**: Claude
**Participant**: Ahmed

## What we did
- [bullet list of major actions]

## Decisions made
- [decision] → see ADR-NNN
- (or "none new this session")

## Code/files changed
- `path/to/file.ts` — what changed
- `path/to/other.ts` — what changed

## Agents delegated to
- Backend Architect: implemented X
- Frontend Developer: implemented Y
- Code Reviewer: reviewed all PRs

## Tests / verification
- ✅ pnpm test passes
- ✅ pnpm typecheck passes
- ✅ Live verification: <what was tested in the running app>

## Open issues to address next session
- [issue] — context

## Where to resume
[Specific file/line/task — make this concrete enough that the next session can immediately act on it]

## Notes / observations
[Any patterns noticed, friction points, things to consider for skills-roadmap.md]
```

---

## File naming

`YYYY-MM-DD-N.md` where N is the session number that day (1, 2, 3...). Examples:
- `2026-04-30-session-1.md` — first session that day
- `2026-04-30-session-2.md` — second session same day (resumed after break)
- `2026-05-01-session-1.md` — next day

---

## Why this matters

Without session notes, every new session starts from zero. With them, you (or any future Claude) can:
- See exactly what happened
- Avoid re-deciding settled questions
- Pick up an unfinished task with full context
- Track velocity and identify blockers across sprints

Treat this folder as a project journal. Future-you will thank present-you for being thorough.
