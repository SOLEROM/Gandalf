# Superpowers Dev Toolkit v5.0.7 — General-Purpose Extract

A curated extraction of the [Superpowers](https://github.com/obra/superpowers) Claude plugin, containing every general-purpose development workflow tool. Covers the full lifecycle from initial design through branch completion, plus meta-tooling for extending the system.

## What This Is

Superpowers is a plugin for Claude Code that installs skills, agents, commands, and hooks that teach Claude structured software engineering workflows. This extract keeps everything that applies to general development work and removes platform-specific files (Cursor, Windows batch scripts) and the test-only MCP demo server.

See `CURATION.md` for the full curation log and `install.md` for installation steps.

---

## Directory Tree

```
ver1/
├── README.md                          # this file
├── usage.md                           # best-practice workflow guide
├── install.md                         # installation instructions
├── security.md                        # security assessment of executable scripts
├── CURATION.md                        # curation log
├── agents/
│   └── code-reviewer.md               # subagent: plan-aligned code reviewer
├── commands/
│   ├── brainstorm.md                  # deprecated alias → brainstorming skill
│   ├── execute-plan.md                # deprecated alias → executing-plans skill
│   └── write-plan.md                  # deprecated alias → writing-plans skill
├── hooks/
│   ├── hooks.json                     # Claude Code hook config (SessionStart)
│   └── session-start                  # bash script: injects using-superpowers at startup
├── skills/
│   ├── brainstorming/                 # design phase: idea → spec → plan
│   ├── dispatching-parallel-agents/   # coordination: parallel independent tasks
│   ├── executing-plans/               # implementation: inline plan execution
│   ├── finishing-a-development-branch/# completion: merge / PR / discard options
│   ├── receiving-code-review/         # review: evaluate and respond to feedback
│   ├── requesting-code-review/        # review: dispatch code-reviewer subagent
│   ├── subagent-driven-development/   # implementation: subagent-per-task execution
│   ├── systematic-debugging/          # debugging: four-phase root-cause process
│   ├── test-driven-development/       # implementation: red-green-refactor cycle
│   ├── using-git-worktrees/           # version-control: isolated workspace setup
│   ├── using-superpowers/             # session/meta: how to find and invoke skills
│   ├── verification-before-completion/# QA: evidence-before-claims gate
│   ├── writing-plans/                 # planning: implementation plan authoring
│   └── writing-skills/               # skill-authoring: TDD-based skill creation
└── test/
    ├── test.md                        # end-to-end scenario document
    └── test.sh                        # unattended test runner
```

---

## Agents

| Agent | Role | How to invoke |
|-------|------|---------------|
| `code-reviewer` | Senior code reviewer — validates implementation against plan and coding standards, categorizes issues as Critical / Important / Minor, and gives structured actionable feedback | Dispatched automatically by `requesting-code-review` or `subagent-driven-development`; can also be invoked directly via the Task tool with `superpowers:code-reviewer` |

---

## Commands

These three slash commands are **deprecated aliases** that redirect to their corresponding skills. They exist for backward compatibility. Use the skills directly.

| Command | Redirects to | Notes |
|---------|-------------|-------|
| `/brainstorm` | `brainstorming` skill | Deprecated alias |
| `/write-plan` | `writing-plans` skill | Deprecated alias |
| `/execute-plan` | `executing-plans` skill | Deprecated alias |

---

## Skills

| Name | Phase | Load it when... |
|------|-------|-----------------|
| `using-superpowers` | session/meta | Starting any conversation — auto-injected by the session-start hook |
| `brainstorming` | design | Creating any feature, component, or behavior change before touching code |
| `writing-plans` | planning | You have a spec or requirements and need a bite-sized implementation plan |
| `using-git-worktrees` | version-control | Starting feature work that needs isolation, or before executing a plan |
| `executing-plans` | implementation | Running a written plan inline in the current session with review checkpoints |
| `test-driven-development` | implementation | Implementing any feature or bugfix — enforces red-green-refactor |
| `subagent-driven-development` | implementation | Executing a plan with independent tasks, using fresh subagents per task |
| `dispatching-parallel-agents` | coordination | Facing 2+ independent tasks or failures that can proceed concurrently |
| `systematic-debugging` | debugging | Encountering any bug, test failure, or unexpected behavior |
| `verification-before-completion` | QA | About to claim work is complete, fixed, or passing |
| `requesting-code-review` | review | Completing tasks, finishing major features, or preparing to merge |
| `receiving-code-review` | review | Receiving code review feedback before implementing suggestions |
| `finishing-a-development-branch` | completion | Implementation is done, tests pass, time to merge / PR / discard |
| `writing-skills` | skill-authoring | Creating or editing skills — applies TDD to process documentation |

---

## Hooks

**`hooks/hooks.json`** — Claude Code hook configuration. Registers a `SessionStart` hook that fires on the `startup`, `clear`, and `compact` events.

**`hooks/session-start`** — Bash script executed by the hook. At session start it reads `skills/using-superpowers/SKILL.md` and injects the full content into the session context wrapped in `<EXTREMELY_IMPORTANT>` tags. This ensures Claude always knows how to find and use skills without consuming context for every conversation manually.

The hook also checks for the legacy `~/.config/superpowers/skills` directory and warns the user to migrate to `~/.claude/skills` if it is found.

---

See `install.md` for installation instructions.
