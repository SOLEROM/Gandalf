# Claude Code CLI — Tools & Workflows Guide

Everything available inside a Claude Code session: built-in tools, skills, commands, agents, hooks, and installable plugins.

---

## Built-in Tools (always available)

These are Claude's native capabilities in every session.

| Tool | What it does | When to use |
|------|-------------|-------------|
| `Read` | Read a file with line numbers | Before editing any file |
| `Edit` | Exact-string replacement in a file | Targeted code changes |
| `Write` | Create or fully overwrite a file | New files only |
| `Glob` | Find files by pattern (`**/*.ts`) | Locating files by name |
| `Grep` | Search file contents by regex | Finding where code lives |
| `Bash` | Run shell commands | Anything requiring the terminal |
| `Agent` | Spawn a subagent for a subtask | Parallel/isolated work |
| `WebFetch` | Fetch a URL | Checking docs or APIs |
| `WebSearch` | Search the web | Research, finding packages |
| `Skill` | Load and invoke a skill | Triggering any workflow skill |
| `TaskCreate/Update/Get` | Track in-session todos | Managing multi-step work |

---

## Skills (Superpowers Dev Toolkit v5.0.7)

Skills are structured workflow guides that override Claude's default ad-hoc behavior. Invoke via the `Skill` tool — never by reading files directly.

**Location:** `~/.claude/skills/`

### Full skill reference

| Skill | Phase | Trigger condition |
|-------|-------|-------------------|
| `using-superpowers` | session/meta | Auto-injected at session start — teaches Claude to check for skills before acting |
| `brainstorming` | design | Any new feature, component, or behavior change — hard gate before code |
| `writing-plans` | planning | Have a spec or approval, need a detailed bite-sized implementation plan |
| `using-git-worktrees` | isolation | Starting feature work or before executing a plan — creates an isolated branch |
| `executing-plans` | implementation | Running a written plan inline, with review checkpoints |
| `test-driven-development` | implementation | Implementing any feature or bugfix — enforces red→green→refactor |
| `subagent-driven-development` | implementation | Executing a plan using fresh subagents per task (higher quality than inline) |
| `dispatching-parallel-agents` | coordination | 2+ independent failures or tasks that can run concurrently |
| `systematic-debugging` | debugging | Any bug, test failure, or unexpected behavior — four-phase root-cause process |
| `verification-before-completion` | QA | Before claiming anything is done — run proof command, read output, then claim |
| `requesting-code-review` | review | After completing a task or feature — dispatches code-reviewer subagent |
| `receiving-code-review` | review | Got review feedback — verify claims before agreeing, push back if wrong |
| `finishing-a-development-branch` | completion | Tests pass, ready to integrate — structured 4-option menu (merge/PR/keep/discard) |
| `writing-skills` | meta | Creating or editing skills — TDD applied to process docs |

### Iron Laws
- No code before a failing test (`test-driven-development`)
- No fix without a root cause (`systematic-debugging`)
- No "done" without running proof (`verification-before-completion`)
- No implementation before design approval (`brainstorming`)

---

## Slash Commands

Type `/command-name` in the prompt. Deprecated aliases redirect to their corresponding skill; plugin commands are fully featured.

### Superpowers (deprecated aliases — use skills directly)

| Command | Redirects to |
|---------|-------------|
| `/brainstorm` | `brainstorming` skill |
| `/write-plan` | `writing-plans` skill |
| `/execute-plan` | `executing-plans` skill |

### Commit Commands plugin

| Command | What it does |
|---------|-------------|
| `/commit` | Analyzes changes, drafts a commit message matching repo style, stages files, commits |
| `/commit-push-pr` | Full workflow: commit → push → create PR with summary and test plan (requires `gh`) |
| `/clean_gone` | Removes local branches whose remote has been deleted; handles associated worktrees |

---

## Agents

Subagents invoked via the `Agent` tool or dispatched automatically by skills.

| Agent | How invoked | Role |
|-------|-------------|------|
| `code-reviewer` | Auto by `requesting-code-review` / `subagent-driven-development`; or directly via Agent tool with `superpowers:code-reviewer` | Senior code reviewer: plan alignment, code quality, architecture, issue categorization (Critical / Important / Minor) |

### PR Review Toolkit agents (installable plugin)

Six specialized review agents, each focused on one aspect:

| Agent | Focus |
|-------|-------|
| `comment-analyzer` | Comment accuracy vs actual code; detects stale/misleading docs |
| `pr-test-analyzer` | Test coverage quality, behavioral gaps, edge cases |
| `silent-failure-hunter` | Silent catch blocks, missing error logging, bad fallbacks |
| *(+3 more)* | Type design, code quality, simplification |

Trigger phrases: `"Check if the tests are thorough"`, `"Review error handling in this PR"`, etc.

---

## Hooks

Hooks run shell scripts automatically on Claude Code events. Configured in `~/.claude/settings.json`.

### Currently installed

**`session-start`** (`~/.claude/hooks/session-start`)
- **Event:** `SessionStart` — fires on `startup`, `clear`, and `compact`
- **What it does:** Reads `skills/using-superpowers/SKILL.md` and injects its content into the session context, so Claude always knows to check for skills
- **Why this matters:** Without it, Claude will not reliably check for skills before responding

### Adding hooks

Use the **Hookify plugin** (`/hookify`) to create custom hooks without editing JSON:

```
/hookify Warn me when I use rm -rf commands
/hookify Don't let Claude use console.log in TypeScript files
/hookify          ← (no args) analyze recent conversation for unwanted patterns
```

Hookify creates `.claude/hookify.<name>.local.md` files. Rules take effect on the next tool use — no restart needed.

---

## Installable Plugins (Official Marketplace)

Plugins extend Claude Code with new skills, commands, and agents. Listed at `~/.claude/plugins/marketplaces/claude-plugins-official/`.

### Development workflow plugins

| Plugin | Key feature | Invoke |
|--------|-------------|--------|
| **feature-dev** | 7-phase structured feature workflow: discovery → exploration → clarification → design → implementation → testing → review | `/feature-dev Add user auth` |
| **commit-commands** | `/commit`, `/commit-push-pr`, `/clean_gone` (see Commands section) | `/commit` |
| **pr-review-toolkit** | 6 specialized PR review agents (comments, tests, errors, types, quality, simplification) | Natural language: `"Review test coverage for this PR"` |
| **code-simplifier** | Reviews changed code for reuse, quality, efficiency; fixes issues found | `/simplify` |
| **hookify** | Create Claude Code hooks from plain English without editing JSON | `/hookify <description>` |

### Building AI / MCP plugins

| Plugin | Key feature | Invoke |
|--------|-------------|--------|
| **mcp-server-dev** | Design and build MCP servers — picks deployment model (remote HTTP / MCPB / local stdio) and scaffolds the project | `"help me build an MCP server"` or `/mcp-server-dev:build-mcp-server` |
| **agent-sdk-dev** | Scaffold and verify Claude Agent SDK apps in Python or TypeScript | `/new-sdk-app my-project` |
| **skill-creator** | Create, improve, and run evals on skills | `"create a skill for X"` |

### LSP / language server plugins

Provide code intelligence (go-to-definition, type checking, diagnostics) via LSP integration:

`clangd-lsp`, `csharp-lsp`, `gopls-lsp`, `jdtls-lsp`, `kotlin-lsp`, `lua-lsp`, `php-lsp`, `pyright-lsp`, `ruby-lsp`, `rust-analyzer-lsp`, `swift-lsp`, `typescript-lsp`

### Integration plugins (MCP-based)

Connect Claude to external services via MCP servers. Must be installed and authenticated separately:

`github`, `gitlab`, `linear`, `slack`, `discord`, `firebase`, `supabase`, `terraform`, `playwright`, `asana`, `context7`, `greptile`, `serena`

---

## Quick-Decision Reference

| Situation | Use |
|-----------|-----|
| New feature idea | `brainstorming` skill |
| Have a spec, need steps | `writing-plans` skill |
| Need isolated branch | `using-git-worktrees` skill |
| Run a plan inline | `executing-plans` skill |
| Run a plan with subagents | `subagent-driven-development` skill |
| Implementing any code | `test-driven-development` skill |
| Bug or failing test | `systematic-debugging` skill |
| About to say "done" | `verification-before-completion` skill |
| Commit changes | `/commit` |
| Commit + push + open PR | `/commit-push-pr` |
| Review a PR thoroughly | `pr-review-toolkit` agents |
| Build an MCP server | `mcp-server-dev` plugin |
| Build an Agent SDK app | `agent-sdk-dev` plugin |
| Create a custom hook | `hookify` plugin |
| Clean stale branches | `/clean_gone` |
