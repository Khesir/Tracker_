# create-prd

This command runs after /validate-idea has been completed and the user has confirmed understanding.

Your job is to interview the user deeply, understand the full scope of the feature, map the codebase, and produce a PRD written to `issues/prd.md`.

Do not write the PRD until you have reached full shared understanding with the user.
Do not submit a GitHub issue. Do not call any external service.
Create the `issues/` directory if it does not exist.

---

## Phase 1 — Verify current state of the codebase

Before asking the user anything, read the parts of the codebase relevant to this feature.
Verify what actually exists — do not assume. Check:
- What modules or files will be touched
- What patterns are already in place
- What dependencies exist between those parts

Report back briefly what you found. One short paragraph. Then move to Phase 2.

---

## Phase 2 — Interview the user

Ask questions one at a time. Wait for the answer before asking the next.
Do not batch questions. Do not rush to the PRD.

Your goal is to walk down every branch of the design until nothing is ambiguous.
Resolve dependencies between decisions one by one before moving on.

Cover these areas through the interview — in whatever order feels natural:

- What problem is this solving exactly, and for whom
- What the user expects to happen (from their perspective, not technical)
- Edge cases and failure states
- What is explicitly out of scope
- Any constraints: performance, security, compatibility, existing patterns to follow
- Which modules need to be built vs modified
- For each module: does it encapsulate a lot of functionality behind a simple interface (deep module)? Or is it thin glue code?
- Which modules the user wants tests written for, and what kind of tests
- Any decisions that have already been made and should not be reopened

Keep asking until you have a complete picture. Do not move to Phase 3 until you do.

When you feel you have enough, say:
"I think I have a full picture. Here's my understanding before I write the PRD:"
Then summarize in plain language. Ask the user to confirm or correct.

---

## Phase 3 — Sketch the modules

Before writing the PRD, present the major modules:
- What needs to be built or modified
- Which ones are deep modules (rich functionality, simple interface, testable in isolation)
- Which ones the user wants tests for

Check with the user that this matches their expectation.
Adjust based on feedback. Do not proceed until confirmed.

---

## Phase 4 — Write the PRD

Once the user confirms the module sketch, write the PRD.

Use this exact template:

<prd_template>

# PRD: [Feature Name]

**Status:** Draft
**Date:** [today's date]
**Author:** [ask user if unknown]

---

## Problem

What problem does this solve? Who has this problem? Why does it matter now?

---

## Scope

What is included in this feature. Keep it tight.

---

## Out of Scope

What is explicitly not being built. Be direct.

---

## User Stories

- As a [user], I want to [action] so that [outcome].

---

## Solution

Plain-language description of how this works from the user's perspective.
Not implementation detail — what does it do, how does the user experience it.

---

## Modules

| Module | Build or Modify | Description | Deep Module? | Tests? |
|--------|----------------|-------------|--------------|--------|
| [name] | Build | [what it does] | Yes / No | Yes / No |
| [name] | Modify | [what changes] | Yes / No | Yes / No |

---

## Implementation Decisions

- **[Decision]:** [Reasoning]

---

## Testing Decisions

- **[Module]:** [What to test and why]

---

## Further Notes

Anything that didn't fit above. Edge cases, open questions, future considerations.

</prd_template>

Save the completed PRD to `issues/prd.md`.
Create the `issues/` directory if it does not exist.
After saving, tell the user the file was written and where it is.
Then stop. Do not begin implementation.