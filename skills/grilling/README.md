# grilling

Grill the user relentlessly about a plan, decision or idea — one round of
questions at a time — while writing what you learn to disk after every round,
so a context compaction can't erase the shared understanding.

## Origin

This is a derivative of the `grilling` skill by **Matt Pocock (Matbock)**,
from [mattpocock/skills](https://github.com/mattpocock/skills)
(`skills/productivity/grilling`), published under the MIT License.

| | |
| --- | --- |
| Upstream | https://github.com/mattpocock/skills |
| Upstream skill | `skills/productivity/grilling` |
| Upstream author | Matt Pocock — Copyright (c) 2026 |
| Upstream license | MIT |
| This version | modifications Copyright (c) 2026 JoshuaCidbit, MIT — see [LICENSE](LICENSE) |

The interview method is intact: design tree, frontier, rounds, sub-agents for
facts, and waiting for the user on every decision. Everything added here is
about **not losing** what the interview produces.

## What was added, and why

The original holds the whole grill in the conversation. That works until the
context is compacted mid-interview: the agreed decisions, the user's own
wording of the goal, and the exact paths and numbers they gave disappear, and
the grill starts asking questions it already got answers to.

Added:

- **Persistent state file** — `<root>/.agents/grilling/<slug>.md`, one block per
  grill, with objective, settled decisions, open frontier, revisions and open
  assumptions. Falls back to `~/.agents/grilling/` outside a project.
- **Checkpoint every round** — after each round of answers the file is
  re-read from disk, merged and rewritten. Nothing waits for the end of the
  session to be persisted.
- **Resume** — at the start of any invocation the state file is read first; if
  a block matches, the skill asks whether to resume or start fresh. Stored
  decisions count as settled, so already-answered questions are not re-asked.
- **Restate per round** — every round opens with 3–6 lines of "what we have so
  far", re-injecting accumulated context even if a checkpoint were missed.
- **Anti-loss writing rules** — every write is a merge, never a truncation; the
  objective accumulates in the user's own words instead of being replaced;
  reversals are recorded as revisions rather than erased; exact values survive
  summarization; gaps go to open assumptions, never invented.

## Install

```bash
npx skills add JoshuaCidbit/skills --skill grilling
```

Installs into `.agents/skills/grilling` and records it in `skills-lock.json`.

## Safety

Read-only except for one file: it writes and updates its state block in
`.agents/grilling/<slug>.md` (or `~/.agents/grilling/<slug>.md`). It never
overwrites or deletes an existing block — contradictions are appended as
revisions — and it asks before discarding a completed one. It does not install,
run or modify anything else, and it does not act on the shared understanding
until the user confirms it.

## License

MIT. Includes and preserves the upstream copyright notice — see [LICENSE](LICENSE).
