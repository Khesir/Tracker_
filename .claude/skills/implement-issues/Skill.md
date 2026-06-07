# implement-issues

Reads `issues/ready/` and implements all open issues using a TDD multi-agent loop.
Issues physically move between folders as they progress.
Runs until every issue is in qa/ or done/. Does not stop to ask the user unless truly blocked.

---

## Before starting

Read `issues/kanban.md` in full.
Scan all folders: backlog/, ready/, in-progress/, qa/, done/.
Build a full picture of the dependency graph before touching any code.

If `issues/ready/` does not exist or is empty and `issues/backlog/` is also empty, stop and tell the user there is nothing to implement.

---

## Folder rules

| Folder | Meaning |
|--------|---------|
| backlog/ | Has unresolved blockers. Do not touch. |
| ready/ | No blockers. Pick these up. |
| in-progress/ | Currently being worked on by a sub-agent. |
| qa/ | Implementation done. Tests pass. Waiting for human. |
| done/ | Human approved. Fully complete. |

---

## The loop

Repeat until ready/ and backlog/ and in-progress/ are all empty:

1. Scan `issues/ready/` — collect all issue files
2. Sort by priority: P1 first, then P2, then P3
3. Move each file from `ready/` to `in-progress/` — physically move the file
4. Update `issues/kanban.md` to reflect the move
5. Dispatch a sub-agent per issue in in-progress/ (parallel where possible)
6. Each sub-agent follows the TDD cycle below
7. When an issue passes all tests, move the file from `in-progress/` to `qa/`
8. Update `issues/kanban.md` to reflect the move
9. Scan `issues/backlog/` — check if any blockers are now in qa/ or done/
10. Move newly unblocked issues from `backlog/` to `ready/`
11. Update `issues/kanban.md` to reflect any moves
12. Repeat

---

## TDD cycle (each sub-agent follows this)

**Step 1 — Read the issue**
Read the issue file fully. Understand acceptance criteria and test requirements before writing anything.

**Step 2 — Read relevant code**
Read only the files relevant to this issue. Do not assume what exists — verify.

**Step 3 — Write tests first**
Write the tests described in the issue before writing any implementation.
Tests should fail at this point. That is correct and expected.

**Step 4 — Implement**
Write the minimum code to make the tests pass.
Do not over-engineer. Do not add things not in the issue.
Follow existing patterns in the codebase.

**Step 5 — Verify**
Run the tests. All must pass before moving on.
If tests fail, fix the implementation — never change the tests to force them to pass.

**Step 6 — Move to qa/**
Append a short log entry to the issue file (2-3 lines: what was implemented).
Physically move the file from `in-progress/` to `qa/`.
Update `issues/kanban.md` to reflect the move and update _Last updated_ date.

---

## Scope discipline

Each sub-agent touches only files relevant to its issue.
If an agent notices something unrelated that needs fixing, it appends a `## Flagged` section to the issue file.
It does not fix it. It does not go out of scope.

---

## No assumptions

Before claiming a file exists, read it.
Before claiming a function works, verify it.
If something is missing that the issue depends on, append a `## Flagged` section to the issue file, move it back to `backlog/`, and update the kanban. Do not guess or invent.

---

## When the loop ends

When ready/, backlog/, and in-progress/ are all empty, print a final summary:
- What was built
- Which files were touched
- All issues now in qa/ waiting for your review
- Anything flagged during implementation

Then stop. QA is your job.

---

## Handling rejected issues (issues returning from QA)

When picking up an issue from `ready/` that contains a `## Bug` section,
it means this issue was previously rejected during visual QA.

In this case:

1. Read the `## Bug` section carefully before anything else
2. Treat the bug as the primary thing to fix — not a new feature, a correction
3. Follow TDD: write a failing test that reproduces the bug first
4. Fix the implementation until the test passes
5. Re-verify all original acceptance criteria still pass
6. Append to the Log: `Bug fixed on [date]. [Short description of what was changed].`
7. Move to `qa/` as normal

Do not remove the `## Bug` section from the file — leave it as history.