---
name: implement-spec
description: "Implement `.scratch/<feature>/spec.md` and its tickets using TDD slices, an integration branch, and final code review."
disable-model-invocation: true
---

You have been provided a spec (`.scratch/<feature>/spec.md`) and tickets (`.scratch/<feature>/issues/*.md`, or issues on a tracker if explicitly used) describing how to implement the spec.

The goal is the entire spec implemented on a single **integration branch** (or directly in the working tree if the project does not use git), with every ticket resolved and verified.

The tickets are not a list of steps. They are a **task graph** with blocking relationships between them. This means there is always a **frontier** of tickets which are ready to be grabbed.

Start every subagent with a fresh context window.

Communication to and from subagents should be sparse. Communicate primarily through **context pointers**: to the spec, tickets, research notes, and previous commits. Don't duplicate information already available via pointers.

**Implementer subagents** should be run in the background where possible for maximum concurrency.

Resolve `<feature>` from `.flow-feature` (if `opencode-flow` is active), the current git branch slug, or a short kebab-case slug from the request.

## Steps

1. Read the spec and tickets to understand the task graph. Record the base commit (`BASE_SHA=$(git rev-parse HEAD)` before branching) so `code-review` has an explicit fixed point in step 7.

2. (optional) Use an **exploration subagent** to conduct any exploration required by the tickets - relevant codebase files or external documentation. Ensure the exploration subagent can save files - it should save its markdown notes in a directory outside the repo (or inside `.scratch/<feature>/`), accessible by all future subagents. This lets **implementer subagents** focus on implementation rather than exploration.

3. Create the integration branch (when working in a git repository). If the user asks for a PR, open a draft PR after the first merge in step 5 (a branch with no commits ahead of main can't open one), marked as closing the spec.

4. Use a fresh **implementer subagent** for each ticket, each in its own worktree on its own branch (when git worktrees are available; otherwise execute sequentially on the working branch). Each implementer subagent:
  - confirms its worktree is based on the integration branch before starting, and resets onto it if not;
  - builds the ticket test-first in vertical slices (use the `tdd` skill if available in the environment; otherwise write a failing seam test first, implement minimal code to pass, and avoid mocking internals);
  - merges the integration branch tip into its own branch before reporting done.

5. Once an **implementer subagent** completes, merge its work to the integration branch with a **merger subagent** and mark the local ticket file (`Status: done` and checked criteria) or close the tracker issue.

6. If this changes the **frontier** of available tickets, kick off more **implementer subagents** to work on the new tickets. This allows for maximum concurrency.

7. Once all tickets are complete, call the Skill tool with `code-review` passing the explicit fixed point (`BASE_SHA` or `git merge-base main HEAD`) and the spec path (`.scratch/<feature>/spec.md`). Fix all issues raised by the code review in a single fresh **implementer subagent**.

8. If a draft PR exists, mark it ready for review. Otherwise, report the integration branch and verification results.

9. Clean up all **implementer subagent** worktrees.
