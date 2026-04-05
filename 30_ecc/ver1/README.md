# ECC ver1 — General-Purpose SW Dev Assets

A curated subset of the Everything Claude Code (ECC) collection.
**Filter criterion:** language-agnostic assets that apply to any software development process — planning, architecture, design, code review, testing, refactoring, documentation.

See `CURATION.md` for the full curation rationale and what was removed.

---

## Structure

```
ver1/
├── agents/       10 specialized AI collaborators
├── commands/     53 CLI-style slash commands
├── rules/        common/ only — 9 universal coding standards
├── skills/       18 deep reference skill packs
├── hooks/        lifecycle automation (hooks.json + README)
├── mcp-configs/  MCP server configurations
├── CURATION.md   Full curation log (what was kept, removed, and why)
└── README.md     This file
```

---

## Agents

Specialized subagents for focused tasks. Invoke via the Agent tool.

| Agent | Role |
|---|---|
| `planner.md` | Breaks features into implementation steps, maps dependencies and risks |
| `architect.md` | System design, scalability decisions, ADRs — uses Opus model |
| `code-reviewer.md` | Senior quality + security review for any PR |
| `security-reviewer.md` | OWASP Top 10, injection, SSRF, secrets, unsafe crypto |
| `tdd-guide.md` | Enforces Red-Green-Refactor, targets 80%+ coverage |
| `refactor-cleaner.md` | Removes dead code and consolidates duplicates |
| `e2e-runner.md` | Runs end-to-end test suites |
| `loop-operator.md` | Monitors autonomous agent loops, detects stalls |
| `doc-updater.md` | Keeps documentation in sync after code changes |
| `docs-lookup.md` | Looks up external docs without polluting the main context |

---

## Commands

Slash commands for the Claude Code CLI. Group by workflow phase:

### Planning & Design
`plan` · `multi-plan` · `evolve` · `aside`

### Architecture & Orchestration
`orchestrate` · `devfleet` · `multi-workflow` · `multi-execute` · `multi-backend` · `multi-frontend` · `update-codemaps` · `rules-distill`

### Code Review & Quality
`code-review` · `verify` · `quality-gate` · `checkpoint`

### Testing
`tdd` · `e2e` · `test-coverage` · `eval` · `learn-eval`

### Build & Error Recovery
`build-fix`

### Refactoring & Cleanup
`refactor-clean` · `prune`

### Documentation
`docs` · `update-docs`

### Session & Context Management
`save-session` · `resume-session` · `sessions` · `context-budget` · `prompt-optimize` · `model-route` · `loop-start` · `loop-status`

### Learning & Continuous Improvement
`learn` · `instinct-export` · `instinct-import` · `instinct-status`

### Meta / Harness
`skill-create` · `skill-health` · `harness-audit` · `projects` · `setup-pm` · `promote`

---

## Rules

`rules/common/` contains 9 universal standards applied to every project:

| File | Covers |
|---|---|
| `coding-style.md` | Immutability, file organization, error handling, input validation |
| `git-workflow.md` | Branching, commit conventions, PR discipline |
| `testing.md` | Test organization, coverage targets, test types |
| `security.md` | Universal security principles |
| `performance.md` | Performance considerations |
| `patterns.md` | General design patterns |
| `agents.md` | When and how to use agents |
| `hooks.md` | Hook configuration guidelines |
| `development-workflow.md` | End-to-end development workflow |

Language-specific rule overrides (TypeScript, Python, Go, Rust, etc.) were removed — add them back per-project as needed from the full ECC source.

---

## Skills

Deep reference packs with actionable how-to guides and patterns.

| Skill | What It Covers |
|---|---|
| `tdd-workflow/` | Red-Green-Refactor methodology, test-first discipline |
| `verification-loop/` | Structured verification methodology after changes |
| `e2e-testing/` | E2E test patterns, setup, and runner integration |
| `ai-regression-testing/` | Regression testing in AI-assisted codebases |
| `eval-harness/` | Setting up evaluation harnesses for correctness testing |
| `api-design/` | REST/API design principles and conventions |
| `backend-patterns/` | Service layers, repositories, general backend architecture |
| `frontend-patterns/` | Component architecture, state management patterns |
| `coding-standards/` | General coding standards across languages |
| `plankton-code-quality/` | Code quality metrics and measurement |
| `iterative-retrieval/` | Retrieval patterns for context-heavy tasks |
| `strategic-compact/` | Context compaction strategy for long sessions |
| `skill-stocktake/` | Skill inventory and health management |
| `continuous-learning/` | Pattern capture and cross-session learning |
| `continuous-learning-v2/` | Updated learning methodology with observer loop |
| `mcp-server-patterns/` | Building and using MCP servers |
| `project-guidelines-example/` | Template for project-level guidelines |
| `configure-ecc/` | ECC harness configuration patterns |

---

## Hooks

`hooks/hooks.json` — lifecycle automations that run at PreToolUse, PostToolUse, SessionStart, Stop, and PreCompact events. Covers: quality gates, build analysis, context/session persistence, token tracking, security monitoring, learning capture.

See `hooks/README.md` for setup and customization.

---

## MCP Configs

`mcp-configs/mcp-servers.json` — server configurations. General-purpose servers included: `github`, `confluence`, `playwright`, `devfleet`, `memory`, `sequential-thinking`, `token-optimizer`, `context7`, `filesystem`, `exa-web-search`, `insaits`.

---

## What Was Removed

~128 files covering language/framework-specific content:
- **18 agents**: per-language code reviewers and build resolvers (TS, Python, Go, Rust, Java, Kotlin, C++, Flutter), PostgreSQL reviewer, email/comms agent
- **16 commands**: per-language build/review/test commands (cpp, go, kotlin, rust, python, gradle), NanoClaw REPL, PM2
- **55 rule files**: 11 language-specific rule directories (cpp, csharp, golang, java, kotlin, perl, php, python, rust, swift, typescript)
- **30 skill directories**: language patterns and testing (Python, Go, Rust, C++, Java, Kotlin, Perl), framework packs (Django, Laravel, Spring Boot, Android, Compose), and other specific packs

Full curation log with rationale: `CURATION.md`.
