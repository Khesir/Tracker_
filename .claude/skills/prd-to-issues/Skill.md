# prd-to-issues

Reads `issues/prd.md` and breaks it into individual local issue files.
Issues are placed in folders that represent their Kanban status.
Maintains `issues/kanban.md` as the overview board.

Do not submit GitHub issues. Do not call any external service.
Everything stays local.

---

## Step 1 — Read the PRD

Read `issues/prd.md` in full before doing anything.
If `issues/prd.md` does not exist, stop and tell the user to run /create-prd first.

Identify every distinct unit of work from the Modules and Implementation Decisions sections.
Each module or meaningful implementation decision becomes one issue.

---

## Step 2 — Set up the folder structure

Create any of these that do not already exist:

```
issues/
  backlog/
  ready/
  in-progress/
  qa/
  done/
```

Find the highest existing issue number across all folders to continue numbering correctly.
If no issues exist yet, start from 001.

---

## Step 3 — Identify priorities and blockers

For each issue, determine:

**Priority:**
- P1: Must be done first. Nothing else works without it.
- P2: Can start after P1 issues are done.
- P3: Can be done anytime but lower impact.

**Blockers:** List issue numbers this issue depends on.

**Starting folder:**
- No blockers → `issues/ready/`
- Has blockers → `issues/backlog/`

---

## Step 4 — Write the issue files

Place each file in the correct starting folder.
Name each file: `NNN-short-name.md`
- NNN is a zero-padded number: 001, 002, 003...
- short-name is lowercase and hyphenated

Use this exact template:

<issue_template>

# [NNN] [Issue Title]

**Priority:** P1 / P2 / P3
**Blockers:** None / [list issue numbers e.g. 001, 002]

---

## Description

What needs to be built or changed. Plain language, no fluff.

---

## Acceptance Criteria

- [ ] [Specific, testable condition]
- [ ] [Specific, testable condition]

---

## Tests Required

Yes / No — [what to test if yes, taken from PRD testing decisions]

---

## Notes

Anything relevant from the PRD: constraints, patterns to follow, decisions already made.

---

## Log

_Updated as work progresses._

</issue_template>

---

## Step 5 — Write the Kanban board

Write `issues/kanban.md` by scanning the actual folder contents.
Always reflect what is physically in each folder — never hardcode.

Use this exact template:

<kanban_template>

# Kanban Board

_Last updated: [date]_

---

## Backlog
Issues with unresolved blockers.

| Issue | Title | Priority | Blockers |
|-------|-------|----------|----------|
| [001](backlog/001-name.md) | [Title] | P1 | 002, 003 |

---

## Ready
No blockers. Ready to be picked up.

| Issue | Title | Priority |
|-------|-------|----------|
| [002](ready/002-name.md) | [Title] | P1 |

---

## In Progress
Currently being implemented.

| Issue | Title | Priority |
|-------|-------|----------|

---

## QA
Implementation done. Tests pass. Waiting for your review.

| Issue | Title | Priority |
|-------|-------|----------|

---

## Done
Approved and complete.

| Issue | Title | Priority |
|-------|-------|----------|

</kanban_template>

---

## Step 6 — Report and stop

Tell the user:
- How many issues were created
- Which ones are in ready/ (can start now)
- Which ones are in backlog/ (blocked)
- Where the Kanban board is

Then stop. Do not begin implementation.