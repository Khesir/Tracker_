# qa

Runs automated QA on all issues in `issues/qa/` and generates a visual QA checklist
for everything that requires human eyes. Does not move issues to done/ — that is the
user's job after visual review.

---

## Before starting

Scan `issues/qa/` — if empty, stop and tell the user there is nothing to QA.
Read every issue file in `issues/qa/` before doing anything.

---

## Phase 1 — Automated QA (per issue)

For each issue in `issues/qa/`, run the following in order.
Do not skip any step. Report results per issue.

**Step 1 — Build check**
Run the project build.
If it fails, stop automated QA for that issue immediately and flag it.

**Step 2 — Test suite**
Run all tests.
Report: passed, failed, skipped.
If any tests fail, flag the issue.

**Step 3 — Lint check**
Run the linter.
Report any new errors or warnings introduced by this issue's changes.
Ignore pre-existing lint issues that were there before this issue.

**Step 4 — Code review**
Read the implementation files touched by this issue.
Check for:
- Follows existing patterns in the codebase
- No shortcuts or hacks that defer problems
- No scope creep — only what the issue required was changed
- No dead code, commented-out blocks, or console.logs left behind
- Naming is clear and consistent with the rest of the codebase
- No obvious performance or security concerns

Report findings honestly. Flag anything that needs attention.

**Step 5 — Acceptance criteria check**
Read the issue's acceptance criteria.
For each criterion, verify whether it is provably met by the code and tests.
Mark each one: ✅ verified by code / 👁 needs visual check / ❌ not met

---

## Phase 2 — Visual QA checklist (per issue)

For every acceptance criterion marked 👁 needs visual check, and for any
UI-related description in the issue, generate a specific checklist item.

Be specific — not "check the UI looks right" but exactly what to look at,
where to find it, and what it should look like or do.

Use this exact template per issue:

<visual_qa_template>

## Visual QA — [NNN] [Issue Title]

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | [Specific element or interaction] | [Where in the UI] | [Exactly what you should see or happen] |
| 2 | [Specific element or interaction] | [Where in the UI] | [Exactly what you should see or happen] |

**Edge cases to manually test:**
- [ ] [Specific edge case]
- [ ] [Specific edge case]

</visual_qa_template>

---

## Phase 3 — QA Report

After running automated QA on all issues, produce a single report:

<qa_report_template>

# QA Report

_Date: [date]_

---

## Automated QA Results

| Issue | Title | Build | Tests | Lint | Code Review | Result |
|-------|-------|-------|-------|------|-------------|--------|
| [001](qa/001-name.md) | [Title] | ✅ / ❌ | ✅ / ❌ | ✅ / ❌ | ✅ / ⚠️ | Pass / Fail |

---

## Issues with automated failures

List any issues that failed automated QA.
These need to be fixed before visual review.
Do not include them in the visual QA checklist below.

---

## Visual QA Checklist

[Insert visual QA tables here — one per issue that passed automated QA]

---

## How to sign off

For each issue you visually verify:
- Approved → run `/qa-approve [issue number]`
- Something is wrong → run `/qa-reject [issue number] [what you saw]`

</qa_report_template>

Write the report to `issues/qa-report.md`.
Tell the user the report is ready and where it is.
Then stop. Visual QA and sign-off is the user's job.

---

## What NOT to do

- Do not move any files — that is /qa-approve and /qa-reject's job
- Do not fix anything you find — flag it, report it, stop
- Do not mark issues as done
- Do not skip the code review step even if tests pass