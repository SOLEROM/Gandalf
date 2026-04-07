# Context Engineering Toolkit — ver1

A portable, installable package of Context Engineering tools for Claude Code. Drop this on any host, run `install.sh`, and you have the full PRP workflow available in every Claude Code session.

> **Context Engineering is 10x better than prompt engineering and 100x better than vibe coding.**

## What's Inside

```
ver1/
├── install.sh               ← one-command installer
├── README.md                ← this file
├── usage.md                 ← workflow guide
├── install.md               ← detailed install reference
├── CLAUDE.md                ← project rules template (customize per project)
├── INITIAL.md               ← feature request template
│
├── commands/                ← slash commands (→ ~/.claude/commands/)
│   ├── generate-prp.md      research codebase + create implementation blueprint
│   ├── execute-prp.md       implement a PRP end-to-end with validation loops
│   ├── primer.md            prime Claude with project context
│   ├── fix-github-issue.md  analyze issue, fix, test, create PR
│   ├── prep-parallel.md     set up N parallel git worktrees
│   └── execute-parallel.md  run N agents building the same feature in parallel
│
├── agents/                  ← subagents (→ ~/.claude/agents/)
│   ├── documentation-manager.md  sync docs after code changes
│   └── validation-gates.md       run tests + iterate until all pass
│
├── hooks/                   ← lifecycle hooks (→ ~/.claude/hooks/ + settings.json)
│   ├── log-tool-usage.sh    log every file edit with timestamp
│   ├── example-hook-config.json  ready-to-use hook config (4 hooks)
│   └── README.md            hook documentation
│
└── prp-templates/           ← PRP template (→ ~/.claude/prp-templates/)
    └── prp_base.md          base template for creating PRPs
```

## Quick Start

```bash
# 1. Install to this host
bash install.sh

# 2. In any project, copy the templates
cp ~/.claude/prp-templates/prp_base.md ./PRPs/templates/
cp ~/.claude/INITIAL.md.template ./INITIAL.md

# 3. Fill in INITIAL.md with what you want to build

# 4. Start Claude Code and run:
/generate-prp INITIAL.md

# 5. Then implement:
/execute-prp PRPs/your-feature.md
```

## The Core Workflow

```
INITIAL.md  →  /generate-prp  →  PRPs/feature.md  →  /execute-prp  →  working code
(what to build)  (research + blueprint)  (rich context doc)  (implement + validate)
```

### INITIAL.md → Feature Request
Fill in 4 sections:
- **FEATURE** — what to build (be specific)
- **EXAMPLES** — code patterns to follow from `examples/`
- **DOCUMENTATION** — API docs URLs, library guides
- **OTHER CONSIDERATIONS** — gotchas, constraints, requirements

### /generate-prp → Implementation Blueprint
Claude researches the codebase, fetches documentation, and produces a PRP (Product Requirements Prompt) — a comprehensive document with:
- All needed context and documentation links
- Step-by-step task list
- Validation commands Claude can run and iterate on

### /execute-prp → Working Code
Claude loads the PRP, creates a task plan, implements everything, runs validation commands, and iterates until all pass.

## Agents

| Agent | When to use |
|-------|------------|
| `documentation-manager` | After code changes — keeps docs in sync |
| `validation-gates` | After implementation — runs tests, fixes failures, iterates |

Invoke with: `use the documentation-manager agent to update docs for the changes in src/auth.py`

## Commands Reference

| Command | Args | What it does |
|---------|------|-------------|
| `/generate-prp` | `INITIAL.md` | Research + generate PRP |
| `/execute-prp` | `PRPs/feature.md` | Implement PRP end-to-end |
| `/primer` | — | Analyze project structure and explain it |
| `/fix-github-issue` | `#123` | Fix GitHub issue, test, create PR |
| `/prep-parallel` | `feature-name N` | Create N git worktrees |
| `/execute-parallel` | `feature-name plan.md N` | Run N agents in parallel |

## See Also

- `usage.md` — full workflow guide with anti-patterns
- `install.md` — detailed installation reference
- `hooks/README.md` — hook configuration guide
