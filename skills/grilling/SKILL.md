---
name: grilling
description: Grill the user relentlessly about a plan, decision, or idea, persisting what you learn after every round so a compaction can't erase it. Use when the user wants to stress-test their thinking, or uses any 'grill' trigger phrases.
---

Interview the user relentlessly until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it.

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled: the questions you can ask _now_ without guessing at answers you haven't heard yet. Ask the whole frontier in one round: number each question and give your recommended answer. Then wait for the user's answers before the next round.

Format a round like so:

```
❓ **Q1** - **<question title>**: <question body, might be multiple paragraphs, including multiple choices>

➡️ <your recommended answer>

---

❓ **Q2** - **<question title>**: <question body, might be multiple paragraphs, including multiple choices>

➡️ <your recommended answer>
```

Word each question so "yes" accepts your recommended answer.

Each round the user answers reshapes the tree: settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and ask the next round. A question whose answer depends on another question still open in this round belongs to a _later_ round, not this one.

Finding _facts_ is your job, never the user's. When a frontier question needs a fact from the environment (filesystem, tools, etc.), dispatch a sub-agent with a fresh context window to find it; don't ask the user for anything you could look up yourself. Don't block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait for the sub-agent to report; ask the rest of the frontier now. The _decisions_ are the user's: put each to them and wait.

The session is done when the frontier is empty: every branch of the design tree visited, nothing left silently assumed. Do not act on it until the user confirms you have reached a shared understanding.

## Persistent state

Everything you learn is only safe once it is on disk. Context can be compacted or lost between rounds; the state file is what survives. Treat it as the authoritative record of the grill, not as a summary you write at the end.

**Location.** Find the project root: the nearest ancestor of the working directory containing `.git`, `AGENTS.md` or `.agents/`. Write to `<root>/.agents/grilling/<slug>.md`, where `<slug>` is a short kebab-case name derived from what is being grilled. If there is no project root, fall back to `~/.agents/grilling/<slug>.md`. Never silently resolve to `$HOME` when a project root exists. If asked to grill in a bare home directory, say where the file will go.

This file is the **only** thing grilling writes. Everything else stays read-only until the user confirms the shared understanding.

**Start of every invocation.** Read the state file first, before any question. If a block matches what the user is asking about, ask whether to **resume** it or start fresh — never assume, and never silently reuse a slug (use `<slug>-2`). On resume, the stored decisions count as settled: recompute the frontier from there and do not re-ask anything already answered. If you detect you are resuming after a context loss, say so in one line: `Resuming "<slug>" from <path> — round N.`

**Checkpoint after every round.** When the user answers a round, re-read the file from disk (it may have changed or be the only surviving record), merge the new answers in, and write it back. Record for each answered question: what was asked, what was answered, and whether the recommendation was accepted or overridden. Do not wait for the session to end to persist anything.

**Before every round of questions.** Re-read `<slug>.md` from disk again, even mid-session and even if nothing was just written: context may have been compacted since the last turn. Everything it holds counts as settled, so the frontier this round is computed from the file, never from recollection. If the read is what keeps the round honest, say nothing about it and just work from the file.

**Ask each round with the `question` tool.** Do not just print the round as text. Open the round with the 3–6 line restate below, then call the agent's `question` tool once with **every question of the current open frontier in the same call**, one entry per question in its `questions` array. Each entry: `question` = the `❓ Qn` title and body, `header` = a short label, `options` = the choices with your recommended one **first**, and its description stating it is your recommendation. The round ends inside that one call; wait for the answers before persisting and computing the next frontier. Use it for every round, not only the first, and also for the resume/keep-or-discard choices above. If the running agent has no `question` tool, fall back to the plain text format and say nothing about it.

**End of the session.** When the frontier is empty, consolidate the file: a final `## Shared understanding` block (objective, decisions, constraints, open assumptions). Updating `<slug>.md` to `status: complete` is always allowed — that file is yours to write. Everything else in the project stays untouched: still wait for the user's explicit confirmation before creating, editing or deleting any other file. When the grill is complete, do **not** delete the block: offer to keep or remove it and let the user decide.

**Block format.** One block per grill session, appended to the file so the project keeps its history of grillings:

```
## Grill: <slug>

topic: <one line>
started: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
status: in progress | complete
root: <root path>
round: <N>

### Objective
<!-- What the user wants, in their own words. Accumulates as it is refined; never replaced. -->

### Constraints
- <hard limits: budget, deadline, stack, platform, compatibility, things ruled out>
  <!-- Same rule as objective: in the user's own words, accumulated, never replaced. -->

### Settled decisions
- **<decision>** — <chosen answer>. Asked in round N; <accepted recommendation | user override>.
  <!-- Keep the exact values: paths, names, numbers, versions, IDs, commands. -->

### Open frontier
- <question> — waiting on: <what it depends on>

### Revisions
- YYYY-MM-DD: **<decision>** changed from <old> to <new>. Reason: <why the user said>.

### Open assumptions
- <anything unresolved, unconfirmed or guessed — never silently assumed>

## Shared understanding
<!-- Written once when the frontier is empty. The consolidated record the user confirms. -->
- **Objective**: <what the user wants, in their own words>
- **Constraints**: <hard limits that survived the whole grill>
- **Decisions**: <settled decision> — <chosen answer>
- **Open assumptions**: <what remains unresolved, if anything>
```

## Writing rules

These exist so a grill never gets dumber than it was.

- **Never overwrite or truncate in bulk.** Every write is a merge: whatever is already in the file survives, and any section you don't mention this round stays exactly as it was.
- **Objectives and constraints are recorded in the user's own words** (quoted verbatim) alongside your synthesized version. When the objective gets refined, **accumulate it line by line** rather than replacing it — the older wording is how you know what the newer one replaced.
- **Concrete values never get summarized away.** Paths, file names, numbers, versions, IDs and exact commands are what a compaction destroys first; they stay literal in the state file.
- **Never fill gaps by inventing.** Anything not settled goes in `### Open assumptions`, not into the record as fact.
- **Contradictions are added, not erased.** If the user reverses a settled decision, keep the old value visible as a `### Revisions` entry with the date, the reason, and both values.
- **If your rewrite would leave the block shorter than what was there, you are losing understanding.** Stop and merge properly instead.

**Restate at the start of each round.** Before the questions, open with 3–6 lines of *what we have so far*: the objective plus the settled decisions that this round builds on. This re-injects accumulated context into every turn, so even a compaction that beats the checkpoint still can't take the shared understanding with it.
