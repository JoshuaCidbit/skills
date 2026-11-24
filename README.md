# skills

[![skills.sh](https://skills.sh/b/JoshuaCidbit/skills?style=for-the-badge)](https://skills.sh/JoshuaCidbit/skills)

Agent skills for finding, vetting and installing things safely. Every skill here
reports real options, labels each one by how much was verified, and never
installs or runs anything without your explicit confirmation.

## Skills

| Skill | What it does |
| ----- | ------------ |
| [`skills-finder`](skills/skills-finder/SKILL.md) | Finds, vets and compares agent skills from [skills.sh](https://skills.sh), then installs the one you pick — only after you confirm. Checks the source repository, every file in the skill folder, and the security audit shown by skills.sh. |
| [`mcp-finder`](skills/mcp-finder/SKILL.md) | Finds, vets and compares MCP (Model Context Protocol) servers using the [official MCP Registry](https://registry.modelcontextprotocol.io) as the source of trust. Reviews identity, repository, package, install scripts and risk, then explains how to add a server. |
| [`handoff`](skills/handoff/SKILL.md) | Escalates a task from the local agent to a frontier web model and brings the result back: builds a self-contained briefing plus an ordered sequence of prompts, then applies the answer as `SEARCH/REPLACE` blocks. Proposes escalating — never starts one silently — when a plan keeps failing or a high-risk area comes next. |

## Install

Requires Node.js 22.20 or later. Skills install at project level by default;
add `-g` for a global install.

```bash
# Both skills, with interactive selection of what and where
npx skills add JoshuaCidbit/skills

# One skill at a time
npx skills add JoshuaCidbit/skills --skill skills-finder
npx skills add JoshuaCidbit/skills --skill mcp-finder
npx skills add JoshuaCidbit/skills --skill handoff
```

Skills are installed into `.agents/skills/<name>` and recorded in
`skills-lock.json`. List what is installed with:

```bash
npx skills list
```

## Safety

- **Nothing is installed or executed without explicit confirmation.** Both
  skills stop and ask before acting.
- `mcp-finder` never installs, runs or configures a candidate. It only reads
  public data and explains how to add a server after you choose one.
- `skills-finder` reads every file in a skill folder at a pinned commit before
  recommending it. High-risk findings are listed as discarded, never
  recommended.
- `handoff` produces guidance only until you approve it, then executes the
  approved plan locally on your machine: it writes `handoff.md` and `SYSTEM.md`
  in the project and runs the plan's commands. Every step has a precondition,
  an expected result and a rollback; on any mismatch it stops and reports instead
  of improvising.
- These skills run with your agent's full permissions. Review the files before
  keeping them.

## Credits

`skills-finder` is a substantially rewritten derivative of the `find-skills`
skill from [vercel-labs/skills](https://github.com/vercel-labs/skills)
(MIT License); security tiers were added by JoshuaCidbit. `mcp-finder` extends
the same approach to MCP servers. `handoff` is original work by JoshuaCidbit.
See [LICENSE](LICENSE).

## License

[MIT](LICENSE)
