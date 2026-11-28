---
name: handoff
description: >-
  Escalate a task to a frontier web model and apply the returned contract
  locally. Builds a self-contained briefing and staged prompts; proposes
  escalating and never starts silently.
---

# Handoff: Local Agent ⇄ Frontier Web Model

Package the current session into a self-contained briefing plus staged prompts
for a frontier web chat model (which has **no tools, no repo, and no memory
beyond what you paste**), then bring its answer back and apply it locally.

General-purpose across agents (OpenCode, Claude Code, Cursor, Codex, …) and
models. Talk to the user in their language; write briefings, prompts, and
contracts in **English** (unless localized UI/docs copy is required).

See [references/contracts.md](references/contracts.md) for the exact schemas of
`SYSTEM.md`, `handoff.md`, `Step Format`, `Return Contract`, and `Executor Rules`.

---

## 1. Delivery Strategy & Modes

Label every outgoing block clearly (`PASTE IN — STEP 1`, `PASTE IN — STEP 2`, …):

- **New chat / model switch:** emit the complete self-contained `# Handoff Briefing`.
- **Same chat thread:** emit only the **delta** (new outputs, `I_NEED` answers,
  or critique) wrapped in the next stage's prompt. Never ask the user to
  manually splice sections into earlier blocks.
- **Modes** (declare out loud):
  - **quick** (default for config, scripts, single-subsystem changes):
    1. Comprehension + Plan → 2. Implementation → 3. Code Audit → Apply.
  - **full** (default for architecture, multi-file changes, or high-risk
    system areas like display server, bootloader, drivers, package manager):
    1. Comprehension → 2. Plan → 3. Plan Audit → 4. Implementation →
    5. Code Audit → 6. Apply.

Infer the mode from scope, declare it out loud (`Mode: full — touches 6 files`),
and accept an override at any time.

## 2. Stages & Intent Weighting

| # | Stage | Output |
| --- | --- | --- |
| 1 | Comprehension | `MENTAL_MODEL`, `ASSUMPTIONS`, `I_NEED` |
| 1.5 | Evidence Loop *(local read-only)* | Delta packet with exact command/file outputs |
| 2 | Plan | `ALTERNATIVES`, `CHOICE`, `PLAN` (atomic steps, max 7) |
| 3 | Plan Audit | `RISKS`, `OBJECTIONS`, `BLOCKERS` |
| 4 | Implementation | Exact `SEARCH/REPLACE` or full file blocks |
| 5 | Code Audit | `FINDINGS`, `BLOCKERS`, patched contract (injects `[REJECTED]`) |
| 6 | Local Execution *(after approval)* | Applied changes + updated `handoff.md` |

State task intent in one line and weight stages accordingly:
- **auditing:** prioritised findings first; no code until final stage.
- **optimisation:** demand real-environment baseline, end-to-end bottleneck
  evidence, and behaviour-preservation proof.
- **debugging:** demand a falsifiable hypothesis and experiment first.

For any other intent, decide the weighting yourself and state why.

Between stages, **critique** the web model's output before forwarding; flag any
contradiction with repo conventions or existing decisions.

## 3. Permissions, Scope & Redaction

- **Clarify first:** resolve blocking scope questions with the user *before*
  emitting `PASTE IN — STEP 1`.
- **Stages 1–5 are strictly read-only:** only read files, inspect git, and run
  read-only diagnostics for evidence. The only files written during Stages 1–5
  are `<root>/.agents/handoff/handoff.md` and `~/.agents/handoff/SYSTEM.md`.
- **Stage 6 (Apply & Verify):** runs only after explicit user approval of the
  plan/contract, obeying the Executor Rules in [references/contracts.md](references/contracts.md).
- **Secret redaction:** replace all `.env` values, tokens, and keys with
  `<REDACTED_SECRET_NAME>`.
- **Scope isolation:** read skills/agents only from `<root>/.agents/`; never
  read `~/.agents/skills/` into a project briefing (unless explicitly working
  inside `~/.agents/skills/<skill>`). The only file read from `$HOME` is
  `~/.agents/handoff/SYSTEM.md`.

Prefer evidence over recollection: an exact error trace beats "tests fail".

## 4. Size Policy (Structural, No Padding)

- **Include:** active decisions and why, verbatim literals (IDs, URLs, errors,
  symbols, versions), constraints, repo conventions, touched files, exact
  traces, and any `SKILL.md` explicitly named by the user.
- **Exclude:** chat narrative, pleasantries, untouched files, unrelated
  toolchain versions, `SYSTEM.md` sections whose stack tags do not match the
  project, and `[REJECTED]` attempts (save those for Stage 5).
- **Trim order (only if needed):** 1. narrative → 2. untouched files → 3.
  related files collapsed to paths.

## 5. Briefing Template

Omit non-applicable sections except `## Agent environment` (mandatory):

```markdown
# Handoff Briefing

## Objective
## Intent
## Requirements and constraints
## Decisions
## Literal values
## Evidence
## Repo conventions
## Agent environment
- harness: <name> <version>
- instruction files: AGENTS.md at <path> | none found
- skills (project scope only): <name> — <one-line description> (<path>) | (none)
- referenced skills: <name> -> full SKILL.md attached below | (none)
- agents: <names> | (none)
- MCP servers: <names> | (none)
- project stack tags: <tags>
## System snapshot
<!-- tag-filtered extract from ~/.agents/handoff/SYSTEM.md -->
## Referenced skills
## Files
## Important context
## State
## Missing / uncertain
```

## 6. Stage Prompt Wrappers

* **Stage 1:** *"Analyze the briefing below. Do NOT write code yet. Output ONLY three sections: `MENTAL_MODEL` (restate problem and constraints), `ASSUMPTIONS` (what you are assuming), and `I_NEED` (exact read-only shell commands or file paths I must provide before planning)."*
* **Stage 2:** *"Based on the confirmed context, output ONLY: `ALTERNATIVES` (2–3 approaches with concrete trade-offs), `CHOICE` (recommended option and why), and `PLAN`. Every step must be atomic and follow the Step Format (`goal`, `precondition`, `action`, `expect`, `on_mismatch`, `rollback`). Use only commands, paths and versions present in the briefing; if a fact is missing, put it in `I_NEED` instead of guessing."*
* **Stage 3:** *"Act as an adversarial reviewer. Attack the plan below. Output ONLY: `RISKS`, `OBJECTIONS` (wrong assumptions or over-engineering), and `BLOCKERS` (must-fix flaws before writing code)."*
* **Stage 4:** *"Implement the approved plan. Output ONLY exact `=== <path> ===` blocks (`<<<<<<< SEARCH ... ======= ... >>>>>>> REPLACE` for existing files, full content for new files, closed by `=== END ===`) followed by `SUMMARY`, `COMMANDS`, `RISKS`, and `NEXT`."*
* **Stage 5:** *"Audit the implementation against the briefing, repo conventions, and previously rejected approaches. Output ONLY: `FINDINGS` (prioritised bugs/edge cases), `BLOCKERS`, and if fixes are needed, updated `=== <path> ===` blocks."*

## 7. Escalation Triggers (Local Agent)

Propose a handoff (never start silently) when:

* The same step hits `on_stop` twice in a row → suggest **quick** mode at Stage 2 with raw outputs and `[REJECTED]` attempts.
* A design decision spans multiple subsystems → suggest **full** mode.
* The next action touches high-risk system state without an audited plan → suggest **full** mode (or Stage 3 audit first).

## 8. Hard Rules

* Never guess which model runs a step, suggest model assignments, or tailor prompts to a specific brand; if you have no evidence about what a model is better at, say "I don't know".
* Never invent commands, paths, versions, or outputs.
* Output **one single, complete, ready-to-copy block** per turn; wrap blocks containing fenced code in four backticks (``````).
