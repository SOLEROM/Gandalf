# Task: Curate a Claude Code Asset Library Into a General-Purpose Dev Toolkit

## Objective

Given any directory containing Claude Code assets (agents, commands, rules, skills, hooks, mcp configs), strip it down to only the assets that are:
- Language-agnostic — not tied to a single programming language or framework
- Useful across any software development process — planning, design, architecture, code review, testing, refactoring, documentation

The result is a lean, install-ready toolkit that works for any project regardless of stack.

---

## Input

A source directory containing some or all of these standard Claude Code asset types:
```
agents/       — subagent .md definitions
commands/     — slash command .md definitions
rules/        — coding standards, possibly split into common/ + per-language/
skills/       — skill packs (each a directory with a SKILL.md)
hooks/        — hooks.json lifecycle automations + README
mcp-configs/  — mcp-servers.json
```

---

## Steps

### 1. Explore and inventory

Read every file. For each asset record:
- What it does
- Whether it is language/framework-specific or general-purpose
- Which dev workflow phase it supports: plan / design / review / test / refactor / docs / session / meta

### 2. Curate — keep only general-purpose assets

Apply this filter to each category:

**Agents — keep if:**
- Supports a workflow phase that applies to any language (planning, architecture, code review, security, testing, refactoring, documentation, orchestration)
- Does not name a specific language, framework, or runtime in its role

**Agents — delete if:**
- Named for a specific language (e.g. `python-reviewer`, `go-reviewer`, `typescript-reviewer`)
- Named for a specific framework or tool (e.g. `django-`, `spring-`, `flutter-`)
- Named for a specific infrastructure tool (e.g. database engine, email system)
- A build error resolver for a specific language/toolchain

**Commands — keep if:**
- Applies to any codebase regardless of language (planning, review, testing, refactoring, session management, learning, orchestration)
- Does not invoke a language-specific build tool or linter

**Commands — delete if:**
- Named for a specific language build/test/review cycle (e.g. `go-build`, `rust-test`, `kotlin-review`)
- Wraps a tool that only exists in one ecosystem (e.g. `gradle-build`, `pm2`)
- Is a harness-specific REPL or interactive tool not tied to the dev workflow

**Rules — keep:** only the `common/` subdirectory (or equivalent language-agnostic rules). These are universal and apply to every project.

**Rules — delete:** all per-language subdirectories (any directory named after a programming language).

**Skills — keep if:**
- Covers a methodology, pattern, or technique applicable in any language (TDD, verification, API design, backend/frontend architecture, code quality, context management, learning, evaluation)
- Contains general workflow automation scripts (observers, compact suggesters, stocktake scanners)

**Skills — delete if:**
- Named for a specific language (e.g. `python-patterns`, `golang-testing`, `rust-patterns`)
- Named for a specific framework (e.g. `django-tdd`, `laravel-patterns`, `springboot-verification`)
- Named for a specific platform (e.g. `android-clean-architecture`, `compose-multiplatform-patterns`)
- A presentation or slide template with no workflow function

### 3. Delete the excluded files

Use `rm -f` for individual files, `rm -rf` for directories.

### 4. Write documentation files at the repo root

**`README.md`** — overview of what remains. Include: directory structure, agent list with one-line roles, commands grouped by workflow phase, rules summary, skills table with "load it when..." guidance, hooks summary, MCP server list.

**`usage.md`** — best-practice guide organized by dev workflow phase: before coding, writing code, before commit, post-merge, testing, orchestration, session management, learning, documentation. For each tool: when to use it, exact invocation syntax, notable behaviors, anti-patterns to avoid. End with a quick-reference situation→tool table.

**`install.md`** — step-by-step installation into a running Claude Code instance. Cover each asset type:
- Agents: `cp *.md ~/.claude/agents/`
- Commands: `cp *.md ~/.claude/commands/`
- Skills: `cp -r <dir> ~/.claude/skills/` for each skill directory; `chmod +x` any shell scripts
- Rules: append to `~/.claude/CLAUDE.md` (Claude Code's native user-level instruction file)
- Hooks: explain whether hook scripts are self-contained or require an external plugin; provide at minimum two standalone inline hooks that work without external dependencies
- MCP servers: add to `~/.claude.json` under `"mcpServers"`

Include verification commands after each step and a troubleshooting section covering the most common failure modes.

**`security.md`** — review every executable script (.sh, .py, .js). For each script flag:
- Any network calls or data exfiltration
- Any autonomous process spawning
- Any local data recording (what is stored, where, how long)
- Any external URL acceptance (import from URL)
- Any auto-download behavior (npx -y, pip install, etc.)

Include a clean/no-issue list for everything that passed review, and a quick-disable reference for anything flagged.

**`CURATION.md`** — the full curation log. For each category: what was kept, what was removed, and the reason. Include before/after counts.

---

## Output

A cleaned directory with only general-purpose assets plus five documentation files at the root:

```
README.md      — what's here and why
usage.md       — when and how to use each tool
install.md     — how to install into Claude Code
security.md    — security review of all executable scripts
CURATION.md    — full log of what was kept and removed
```

---

## Guiding Principles

- **When in doubt, remove.** A smaller set of high-confidence general tools is better than a large set with questionable relevance.
- **Rules go in CLAUDE.md.** Claude Code's native mechanism for persistent instructions is `~/.claude/CLAUDE.md`, not a `rules/` directory. Append rules there on install.
- **Hook scripts need their dependencies.** If hooks reference external scripts that are not present in this directory, document that clearly in `install.md` rather than pretending they work.
- **Cap MCP servers at 10.** Each active MCP adds context overhead. Document which ones are highest value and should be installed first.
- **Flag autonomous behaviors.** Any asset that spawns background processes, records tool I/O, or modifies behavior without explicit per-invocation consent must be documented in `security.md` — even if it is not malicious.
