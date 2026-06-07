---
name: validate-idea
description: >
  Load this skill when the user presents a new idea, feature, or change.
  Triggered by /skill understand-project followed by an idea description
  or an idea.txt file. Claude reads the codebase in context of that specific
  idea and validates it — how it fits, what's relevant, how it will be done.
  Never audits, never over-engineers, never suggests unrequested changes.
---

# Understand Project

The user has presented an idea, feature, or change they want to build.
Your job is to read the codebase through the lens of that specific idea
and validate it — not audit the whole project.

---

## What to do

**Step 1 — Read the idea**
The user either typed it inline or provided an idea.txt file.
Read it fully before touching any code files.

**Step 2 — Read the codebase relevant to this idea**
Only read what is necessary to understand how this idea fits.
Do not read the entire project for the sake of it.
Ask yourself: what files, modules, or patterns are directly touched
by or relevant to what the user described?

**Step 3 — Validate and present your understanding**
Return a short, clear response in this structure:

### What I understand
One short paragraph. Restate the idea in your own words so the user
can confirm you got it right. No extra commentary.

### How it fits the project
What already exists that is relevant. What the idea builds on,
extends, or changes. Keep it to what actually matters for this idea.

### How we will do it
A plain-language approach. Not a full plan yet — just the direction.
Which parts of the codebase will be involved. Any natural constraints
or patterns in the existing code the implementation should follow.

### One flag (only if genuinely relevant)
If there is something about the codebase that directly affects
this idea — a constraint, a pattern, a dependency — mention it once.
Not a list of issues. Not a code review. One thing, only if it matters.
If nothing is genuinely relevant, skip this section entirely.

---

## What NOT to do

- Do not suggest improvements to unrelated parts of the code.
- Do not list every file you read.
- Do not produce a full implementation plan — that comes later.
- Do not ask clarifying questions yet — validate first, questions come after
  if the user confirms your understanding is correct.
- Do not over-explain. If the idea is simple, the response should be short.
- Do not say "great idea" or add filler praise.
- Do not recommend libraries, tools, or approaches that weren't asked about.

---

## Output length

Be concise.
Match the complexity of the idea.
Simple idea = short response.
Complex idea = slightly longer, but never exhaustive.
When in doubt, write less.

---

## After your response

Stop. Wait for the user to confirm your understanding or correct it.
Do not proceed to planning. Do not write code.
The next step is theirs.