---
name: handoff
description: >-
  Escalate a task to a frontier web model and bring the result back. Use for
  briefing/dossier requests, a second opinion, or to audit, optimize or debug
  with a stronger model, or when 'handoff' or 'multiagéntica' is mentioned.
  Proposes escalating; never starts one silently.
---

# Handoff: Local Agent ⇄ Frontier Web Model

Turn the current state of a session into a briefing plus an ordered sequence of
prompts that a frontier model running in a web chat can act on, then bring its
answer back and apply it.

The web model has **no tools, no repo and no memory beyond what you paste**. Your
job is to close that gap once, well.

This skill is general-purpose. It must work for any user, project, agent
(OpenCode, Claude Code, Cursor, Codex, …) and any pair of web models. Never
assume a specific model brand, config path or stack.

**Language:** talk to the user in their language. Every artifact this skill
produces (briefing, prompts, contract) is written in **English** — it gives
frontier models the best recall — **unless** the task specifically requires
non-English UI copy, user-facing strings, or localized documentation.

---

## 1. Delivery Strategy (Full vs. Delta)

Label every prompt artifact clearly by step number: `PASTE IN — STEP 2`.

- **Step 1 or New Chat / Model Switch (Self-Contained Packet):** Re-carry the
  full updated `# Handoff Briefing` so the target model has zero missing state.
- **Same Chat Thread (Delta Packet):** By default, assume the user continues in
  the same web thread for subsequent steps. Send **only** the delta (new local
  evidence, answers to `I_NEED`, or critique of the previous output) wrapped in
  the next stage's prompt template. Offer a full re-packaged prompt only if the
  user switches chats or models.
- **Atomic Copy-Paste (Zero Manual Patching):** Never ask the user to manually
  splice, replace, or merge sections into an earlier block. If new user input
  updates the briefing before it is pasted, re-emit the **entire updated
  `PASTE IN` block** as one complete artifact.

Do not ask which model will run each step, and do not suggest assignments. If
you have no evidence about what a given model is better at, do not guess — say
"I don't know".

## 2. Stages & Evidence Loop

| # | Step | Produces |
| --- | --- | --- |
| 1 | Comprehension — restate problem, list assumptions, state what is missing | `MENTAL_MODEL`, `ASSUMPTIONS`, `I_NEED` |
| 1.5 | *(Evidence Loop)* — run read-only commands/reads from `I_NEED` | Delta packet with exact outputs |
| 2 | Plan — 2–3 approaches with trade-offs, recommendation, verifiable steps | `ALTERNATIVES`, `CHOICE`, `PLAN` |
| 3 | Plan audit — adversarial attack, risks, edge cases, wrong assumptions | `RISKS`, `OBJECTIONS`, `BLOCKERS` |
| 4 | Implementation — exact `SEARCH/REPLACE` blocks or full files | Return contract (§8) |
| 5 | Code audit — correctness, security, repo conventions, rejected attempts | `FINDINGS`, `BLOCKERS`, patched contract |
| 6 | *(local, you)* — apply with `write`/`edit`, verify, report back | Updated `handoff.md` |

**Every stage round-trips through the user.** Between stages, do not blindly
forward text: **critique it**. If the web model's plan contradicts an existing
decision or repo constraint, flag it to the user before generating the next
prompt.

### Modes

- **full** — all stages (1 → 2 → 3 → 4 → 5 → 6). Default for architecture,
  multi-file changes, new subsystems, or unclear intent.
- **quick** — 3 stages: comprehension+plan merged → implementation → final audit.
  For bounded changes, single-file fixes, point audits, or clear specs.

Default to **quick** for config, scripts, theming, and single-subsystem changes.
Use **full** only for architecture, multi-file/multi-subsystem changes, or when
a mistake could break the user's session (display server, bootloader, drivers,
package manager state). Stages 3 and 5 are mandatory in full mode and optional
in quick mode unless the plan touches those high-risk areas.

Infer the mode from scope and declare it out loud ("Mode: full — touches 6
files"). Accept an override at any time.

## 3. Task Intent

State the intent in **one line** — what we are doing, not a rigid category:

- *construction/design* — new features, architecture, service integration
- *debugging* — trace, isolate, fix wrong behaviour
- *optimisation* — speed up or clean internals without changing behaviour
- *audit/quality* — logic errors, security, bad practices
- *testing* — unit/integration coverage
- *maintenance/migration* — legacy systems, dependency bumps, porting
- *deployment/automation* — CI/CD, containers, scripts, monitoring
- *documentation* — guides, comments, system explanations

Infer the real intent and **weight each stage** accordingly:

- auditing → prioritised findings first; no code blocks until the final stage
- optimisation → demand a **baseline measured in the real environment** (real
  dependencies, no stubs), **evidence of where the time actually goes across the
  whole flow** (not just the target function), and **some way to show behaviour
  did not change**. Choose the method that fits the task; if none is possible,
  say so.
- debugging → demand a hypothesis **and** the experiment that would falsify it
- anything else → decide the weighting yourself and state why

## 4. Gathering Context & Permissions

- **Clarify Before Packaging:** If `Missing / uncertain` contains a blocking
  scope question that only the user can answer, ask the user **first** and wait
  for their reply *before* generating `PASTE IN — STEP 1`. Never emit a briefing
  and ask a scope-changing question in the same turn.
- **Stages 1–5 (Strict Read-Only):** You may read files, use `grep`/`glob`, run
  read-only git (`git status --short`, `git diff`, `git log --oneline -n`,
  `git branch`), and run read-only diagnostics (test suite, build, linters)
  **when it produces evidence worth pasting**. Never write project files,
  commit, push, or run commands with side effects. The **only** files you write
  during Stages 1–5 are `handoff.md` (§7) and, once, `SYSTEM.md` (§6.1), both
  under `<project root>/.agents/handoff/`.
- **Stage 6 (Apply & Verify):** Once the user approves the final contract from
  Stage 4 or 5, read-only restrictions lift: apply the file changes locally,
  run the verification commands, and report the outcome.
- **Secret Redaction:** Never paste `.env` contents, API keys, tokens,
  credentials, or private keys into any briefing or prompt. Replace them with
  `<REDACTED_SECRET_NAME>`.

Prefer evidence over recollection: an exact error trace beats "tests fail".

## 5. Size Policy — Structural, No Padding

There is **no token budget and no target length**. Do not pad to reach a size,
and do not count tokens. Selection is **structural**:

- **Always include (Stages 1–4):** active decisions and why, literal values
  (IDs, URLs, exact error strings, symbol names, versions), constraints, repo
  conventions, changed files, evidence (exact trace + version).
- **Leave out (Stages 1–4):** conversation narrative, pleasantries, files
  untouched by the task, and **superseded/rejected attempts** (keep rejected
  attempts stored in `handoff.md` under `Decisions & Rejected Approaches` and
  inject them **only** in Stage 5 per §9).
- **Shrink order (if trimming is necessary — never cut decisions or literals):**
  1. conversational history
  2. untouched files, then their signatures
  3. collapsed to paths only: first related files, then whole directories

If it is long **because of relevant code**, that is fine and expected.

## 6. The Briefing

Write in English Markdown (except localized target strings). Cite only real files
you actually read; if you have not read something, state it explicitly.

```markdown
# Handoff Briefing

## Objective
<!-- 1–2 sentences: what we are trying to accomplish -->

## Intent
<!-- one line: what we are doing and which emphasis it implies -->

## Requirements and constraints
<!-- scope, preferences, hard limits. "- (none)" if none -->

## Decisions
<!-- active decisions: what was decided, why, and the alternative rejected -->

## Literal values
<!-- IDs, URLs, paths, exact error strings, symbol names, versions. Verbatim, secrets redacted. -->

## Evidence
<!-- what was run and what it proved: exact error/trace + version. Never a full log. -->

## Repo conventions
<!-- AGENTS.md/CLAUDE.md rules, lint/format, stack, test command. -->

## System snapshot
<!-- Read from SYSTEM.md (see §6.1). Verbatim, secrets redacted. Always included in Stage 1 and in any new-chat/model-switch packet. -->

## Files
<!-- tree if useful; full content of files the task touches; signatures only for related ones; whole directories by path only -->

## Important context
<!-- non-obvious coupling, gotchas, timing/ordering traps, deliberate quirks -->

## State
<!-- git branch/HEAD/status, what is done, what is blocked -->

## Missing / uncertain
<!-- non-blocking gaps only: technical unknowns for the web model's I_NEED, or assumptions to validate (blocking scope questions must be resolved with the user BEFORE generating Step 1) -->
```

Omit a section only if it does not apply.

### 6.1 `SYSTEM.md` — Environment Snapshot

The local agent generates `SYSTEM.md` once at
`<project root>/.agents/handoff/SYSTEM.md` (root resolution: §7), recording
`updated: <date>` on its first line. If it already exists, attach it as-is;
regenerate only when the user says the system changed or when a command output
contradicts it. Contents, only what applies:

- OS + version + kernel (e.g. `uname -a`, `/etc/os-release`, `sw_vers`, `ver`)
- package manager(s) in use (e.g. pacman/AUR helper, apt, brew, winget)
- shell, terminal, editor; display server/compositor/WM if any, with versions
- hardware relevant to the task (GPU + driver version, etc.)
- key paths (dotfiles repo, config dirs, scripts)
- conventions the user has stated (config language, naming, theming pipeline)

Include only what applies to the task or the user's stack.

Never include secrets. Never include anything that was not actually read from
the system. Stage 1 always attaches it; the web model must treat it as ground
truth over its own assumptions.

## 7. `handoff.md` — Persistent State

Both files this skill writes live in **`<project root>/.agents/handoff/`**:
`handoff.md` and `SYSTEM.md` (§6.1). Never write at the bare project root and
never in `~/.agents/` — state is per project.

**Root resolution:** walk up from the working directory to the first ancestor
containing `.git`, `AGENTS.md` or `.agents/`. If none exists, ask the user
before creating one. Do not confuse `.agents/handoff/` (state) with
`.agents/skills/handoff/` (this skill's own files).

`handoff.md` holds everything that must survive a compaction or new session.
It is the sole **state** file this skill creates or modifies (`SYSTEM.md`,
§6.1, is an environment snapshot, not task state).

**First turn of every invocation:** read `handoff.md` before anything else.
Multiple concurrent tasks = **multiple blocks in the same file**, each with its
own header. If the request matches an existing `## Task:` block, ask whether to
resume it or open a new one — never guess, never silently duplicate a slug,
never silently overwrite. If a genuinely new task needs the same slug, suffix it
`<slug>-2`, `<slug>-3`; never reuse an existing slug.

```markdown
# Handoff

## Task: <slug>
- intent: <one line>
- mode: full | quick
- escalation_reason: <which trigger fired, or "-" if the user asked directly>
- step: comprehension | evidence_loop | plan | plan_audit | implementation | code_audit | executing | completed
- created: <date>
- head: <git HEAD when it started>

### Decisions & Rejected Approaches
- [DECIDED] <what and why>
- [REJECTED] <what was tried/discarded and why — injected in Stage 5>

### Consolidated State (Answers & Evidence)
- <overwrite/condense on each turn so this stays a clean snapshot, not an append-only log>

### Open questions
- <what is still unanswered>

### NEXT_FOR_LOCAL_AGENT
- plan_phase: <n> of <total>
- current_step: <n>
- [ ] STEP 1 — <goal> | done_when: <expect> | result: <raw output, filled by executor>
- [ ] STEP 2 — <goal> | done_when: <expect> | result:
- on_stop: <last mismatch, raw stdout/stderr, filled by executor>
```

When a task reaches `completed`, ask the user whether to delete its block from
`handoff.md` or leave it marked `completed` for reference.

## 8. Stage Prompt Wrappers & Return Contract

Wrap every outgoing prompt with strict output instructions so the web model
does not waste tokens on conversational filler:

- **Stage 1 wrapper:** *"Analyze the briefing below. Do NOT write code yet. Output ONLY three sections: `MENTAL_MODEL` (restate problem and constraints), `ASSUMPTIONS` (what you are assuming), and `I_NEED` (exact read-only shell commands or file paths I must provide before planning)."*
- **Stage 2 wrapper:** *"Based on the confirmed context, output ONLY: `ALTERNATIVES` (2–3 approaches with concrete trade-offs), `CHOICE` (recommended option and why), and `PLAN`. The PLAN will be executed by a weaker local agent that has NO judgment about this system: every step must be atomic and follow the Step Format below exactly. Use only commands, paths and versions present in the briefing or `System snapshot`; if a step needs a fact you don't have, put it in `I_NEED` instead of guessing."*
- **Stage 3 wrapper:** *"Act as an adversarial reviewer. Attack the plan below. Output ONLY: `RISKS`, `OBJECTIONS` (wrong assumptions or over-engineering), and `BLOCKERS` (must-fix flaws before writing code)."*
- **Stage 5 wrapper:** *"Audit the implementation against the briefing, repo conventions, and previously rejected approaches. Output ONLY: `FINDINGS` (prioritised bugs/edge cases), `BLOCKERS`, and if fixes are needed, the updated Return Contract blocks below."*

### Step Format (Stage 2 PLAN)

```text
STEP <n>
- goal: <one sentence>
- precondition: <read-only command> -> <expected output or state>
- action: <exact command, or SEARCH/REPLACE block per the Return Contract>
- expect: <exact output, exit code, or file state after the action>
- on_mismatch: STOP. Paste raw stdout/stderr. Do not retry or improvise.
- rollback: <exact command to undo>
```

Rules: one side effect per step; read-only steps (diagnosis) come first;
never more than 7 steps per plan — if more are needed, split into phases and
plan only the first one.

### Return Contract (Stages 4 & 5)

Every prompt requesting code must enforce this exact, unambiguous format so
changes apply mechanically without relying on fragile line-numbered diffs. Every
block **must** open with `=== <path> ===` and close with `=== END ===`:

```text
=== path/to/existing_file.ts ===
<<<<<<< SEARCH
exact lines from the existing file to match
=======
replacement lines
>>>>>>> REPLACE
=== END ===

=== path/to/new_or_short_file.ts ===
<full file content>
=== END ===
```

Followed by:

- `SUMMARY` — what changed and why
- `COMMANDS` — exact verification commands (fenced block, none invented)
- `RISKS` — what might break
- `NEXT` — what the local agent should do next

Rules for the contract:

- Use `<<<<<<< SEARCH ... ======= ... >>>>>>> REPLACE` for existing files
  (especially large ones) and full content for new or short files.
- Never use line-numbered unified diffs (`@@ -1,4 +1,4 @@`).
- Every block must close with `=== END ===` on its own line so `===` inside file
  contents never breaks parsing.
- No prose between file blocks.

## 9. Extended Context for Stage 5 (Code Audit)

Stage 5 is the highest-leverage quality gate. In addition to the active state,
inject into the Stage 5 prompt:

- How the existing code behaves today and exact runtime/dependency versions.
- All `[REJECTED]` entries from `handoff.md` (approaches already tried or
  discarded, with the exact reason they failed) so the auditor does not suggest
  reverting to broken ideas.

## 10. Rules

- Never assume or ask which model runs a step; every block is model-agnostic.
- Never tailor a prompt to a specific brand (no "as Gemini", no "as Claude").
- Never invent commands, paths, versions, or outputs. Cite only what you read.
- If you don't know, say "I don't know" rather than filling the gap.
- Never include unredacted secrets, tokens, or `.env` values in any artifact.
- The user pastes the answer into the chat; if it also references files, mention
  them explicitly. No other file round-trips.
- Output **one single, complete, ready-to-copy block** per turn. No preamble, no
  "here is your briefing", and never ask the user to manually patch sections.
- Never decide for the user which task continues; always ask when multiple exist.
- When a `PASTE IN` block contains fenced code, wrap the whole block in a longer
  fence (four backticks) so nested fences never break rendering in web chats.

## 11. Executor Rules (Local Agent)

The executor runs only in Stage 6, after the user approves the plan (quick mode)
or the final contract (full mode). Side-effecting actions are never run during
Stages 1–5. Once approved, the Stage 4 SEARCH/REPLACE blocks become the `action`
of the matching STEP. If execution ends in `on_stop` and the task re-enters
planning, `step` returns to `plan` and the Stages 1–5 read-only rules apply again.

When running a plan from `NEXT_FOR_LOCAL_AGENT`:

0. Before executing a plan received from the web model, attack it locally:
   reproduce the baseline, confirm the fixtures/paths/APIs it assumes exist,
   and report any plan defect to the user. Send corrections back as a delta
   packet instead of executing a flawed plan.
1. Execute **one step at a time**. Check `precondition` first; if it fails, STOP.
2. After the action, compare the result against `expect`. Write the **raw**
   stdout/stderr (trimmed only for length, never paraphrased) into `result:`.
   Redact secrets in `result:` and `on_stop:` the same way as in any artifact.
3. If the result matches `expect`, tick the box and continue.
4. If it does not match, STOP. Fill `on_stop:` and report to the user. Do not
   retry, do not fix it yourself, do not skip ahead. The mismatch goes back to
   the planner as a delta packet.
5. Never run a step whose action touches something outside the plan.

## 12. Escalation Triggers (Local Agent)

Propose a handoff to the user (never start one silently) when any of these hold:

- The same step ends in `on_stop` twice in a row.
- The plan needs a design decision across several subsystems.
- The next action touches a high-risk area (display server, drivers, bootloader,
  package manager state) and no audit has run on the plan.

When proposing, state in one line which trigger fired and the suggested mode:

- failure trigger → quick, entering at plan stage with the raw `on_stop`
  outputs and the failed attempts as `[REJECTED]`.
- risk trigger → full, or at minimum Stage 3 before executing anything.

Record the reason in `handoff.md` as `escalation_reason:` under the task header.
