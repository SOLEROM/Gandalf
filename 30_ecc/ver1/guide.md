# Claude Code Tool Guide

A practical reference for every tool available in this session — what each does, when to use it, and how to combine them effectively.

---

## Table of Contents

1. [Core File Tools](#1-core-file-tools)
2. [Bash — Shell Execution](#2-bash--shell-execution)
3. [Web Tools](#3-web-tools)
4. [Agent System](#4-agent-system)
5. [Skills System](#5-skills-system)
6. [Task Management](#6-task-management)
7. [Planning System](#7-planning-system)
8. [Scheduling & Automation](#8-scheduling--automation)
9. [Worktrees — Isolated Workspaces](#9-worktrees--isolated-workspaces)
10. [Gmail MCP Integration](#10-gmail-mcp-integration)
11. [NotebookEdit — Jupyter Cells](#11-notebookedit--jupyter-cells)
12. [Best Practices & Workflows](#12-best-practices--workflows)

---

## 1. Core File Tools

These are your primary tools for reading and modifying the filesystem. **Always prefer these over Bash equivalents** (no `cat`, `grep`, `find` in shell).

### Read
**Purpose:** Read file contents with line numbers.

```
Read /path/to/file.py
Read /path/to/file.py  # offset: 50, limit: 100  (read lines 50-149)
```

- Use before any Edit — required by the Edit tool
- For large files, use `offset` + `limit` to read only what you need
- Reads images (PNG, JPG), PDFs (use `pages: "1-5"`), and Jupyter notebooks too

### Write
**Purpose:** Create new files or completely rewrite existing ones.

```
Write /path/to/newfile.ts  (provide full content)
```

- For new files only, or full rewrites
- If the file already exists, you must Read it first
- Prefer Edit for partial changes — Write sends the entire file

### Edit
**Purpose:** Precise string replacement inside an existing file.

```
Edit /path/to/file.py
  old_string: "def foo():\n    pass"
  new_string: "def foo():\n    return 42"
```

- Must Read the file at least once before editing
- `old_string` must be unique in the file — add surrounding context if needed
- Use `replace_all: true` for renaming a variable everywhere in the file
- Sends only the diff, not the whole file — much more efficient than Write

### Glob
**Purpose:** Find files by name pattern.

```
Glob "**/*.ts"              # all TypeScript files
Glob "src/components/**"    # everything under src/components
Glob "*.test.*"             # all test files
```

- Returns paths sorted by modification time (newest first)
- Use when you know the filename pattern but not the location
- Much faster than `find` via Bash

### Grep
**Purpose:** Search file contents with regex.

```
Grep "useState"                     # find files containing useState
Grep "function\s+\w+" type:"ts"     # regex in TypeScript files
Grep "TODO" output_mode:"content" -C:2   # show 2 lines of context
Grep "import.*from" glob:"src/**/*.ts" output_mode:"count"
```

**Output modes:**
- `files_with_matches` (default) — just file paths
- `content` — matching lines (supports `-A`, `-B`, `-C` for context)
- `count` — number of matches per file

**Key flags:**
- `-i: true` — case-insensitive
- `type: "ts"` — filter by file type
- `glob: "**/*.tsx"` — filter by glob pattern
- `multiline: true` — match across lines

---

## 2. Bash — Shell Execution

Reserve Bash **exclusively** for things the dedicated tools cannot do: running tests, starting servers, git commands, package installs, system operations.

### Parallel vs Sequential

```bash
# Independent commands — run in parallel (one message, multiple Bash calls):
git status
npm test

# Dependent commands — chain with &&:
npm install && npm run build

# Ignore failures — use ;:
npm run lint ; npm run test
```

### Background Jobs

```bash
# Start a long-running process and continue working:
npm run dev   # with run_in_background: true
```

You'll be notified when it completes. Do NOT poll or sleep-wait.

### Timeout

Default timeout is 2 minutes. Override with `timeout: 300000` (milliseconds) for long builds.

### Golden Rule

| Task | Use |
|------|-----|
| Read a file | Read tool |
| Edit a file | Edit tool |
| Find files | Glob tool |
| Search content | Grep tool |
| Run tests | Bash |
| Git operations | Bash |
| Install packages | Bash |

---

## 3. Web Tools

### WebFetch
**Purpose:** Fetch a specific URL and return its content.

```
WebFetch https://docs.example.com/api/auth
```

- Use when you have an exact URL and need its content
- Good for reading API docs, checking a specific page
- Returns rendered text, not raw HTML

### WebSearch
**Purpose:** Search the web with a query.

```
WebSearch "react useEffect cleanup async"
WebSearch "site:docs.anthropic.com tool use"
```

- Use for discovery when you don't have a specific URL
- Combine: search first → then WebFetch the most relevant result

### Pattern: Research Workflow

```
1. WebSearch "library X authentication setup"
2. WebFetch the official docs URL from results
3. Implement based on confirmed docs
```

---

## 4. Agent System

Agents are specialized Claude instances with focused tools and system prompts. Launch them via the `Agent` tool.

### How to Launch

```
Agent(
  subagent_type: "code-reviewer",
  description: "Review auth module",
  prompt: "Review /src/auth/login.ts for security issues..."
)
```

### Parallel Launch (Independent Tasks)

Send **one message with multiple Agent tool calls** — they run in parallel:

```
# In a single response, launch all three at once:
Agent: security-reviewer → check auth module
Agent: tdd-guide → write tests for payment flow
Agent: doc-updater → sync README after API changes
```

### Available Agents & When to Trigger

| Agent | Trigger Condition | Model |
|-------|-------------------|-------|
| `planner` | Complex features, new initiatives, multi-phase work | Sonnet |
| `architect` | System design decisions, scalability questions, ADRs | Opus |
| `tdd-guide` | Any new feature or bug fix — write tests FIRST | Sonnet |
| `code-reviewer` | Immediately after writing or modifying code | Sonnet |
| `security-reviewer` | Code touching auth, user input, APIs, sensitive data | Sonnet |
| `refactor-cleaner` | Dead code cleanup, removing duplicates | Sonnet |
| `doc-updater` | After API or interface changes | Sonnet |
| `e2e-runner` | Critical user flows, before releases | Sonnet |
| `loop-operator` | When an autonomous agent loop stalls or seems stuck | Sonnet |
| `docs-lookup` | "How do I use library X?" — keeps main context clean | Sonnet |

### Isolation Mode (Worktree)

Add `isolation: "worktree"` to give the agent its own git branch:

```
Agent(
  subagent_type: "refactor-cleaner",
  isolation: "worktree",
  prompt: "Remove all dead code from src/utils/..."
)
```

The worktree is cleaned up automatically if no changes are made.

### Background Agents

Set `run_in_background: true` for long-running agents. You'll be notified when done — use `TaskOutput` to read results.

---

## 5. Skills System

Skills are expanded prompt templates that activate specialized behavior. They're invoked as slash commands.

### How to Invoke

Type `/skill-name` as a prompt, or use the `Skill` tool internally:

```
/plan          # structured implementation planning
/tdd           # test-driven development workflow
/code-review   # review recently changed code
/save-session  # persist current session state
```

### Skills by Category

#### Planning & Architecture
| Skill | What It Does |
|-------|--------------|
| `/plan` | Restate requirements, assess risks, create step-by-step plan. Waits for confirmation before touching code |
| `/multi-plan` | Multi-model collaborative planning (Opus + Sonnet perspectives) |
| `/prompt-optimize` | Analyze a draft prompt and output an optimized version |

#### Development Workflow
| Skill | What It Does |
|-------|--------------|
| `/tdd` | Enforce test-first: scaffold interface → generate tests → implement → verify 80%+ coverage |
| `/tdd-workflow` | Full TDD reference with patterns and anti-patterns |
| `/build-fix` | Build and iteratively fix compilation errors |
| `/multi-workflow` | Multi-model collaborative development pipeline |
| `/multi-execute` | Multi-model execution with verification |

#### Code Quality
| Skill | What It Does |
|-------|--------------|
| `/code-review` | Senior code review: quality, security, maintainability |
| `/simplify` | Review changed code for reuse/quality then fix issues |
| `/refactor-clean` | Dead code cleanup and consolidation |
| `/verify` | Comprehensive verification of current work |
| `/quality-gate` | Run quality gate checks before committing |
| `/verification-loop` | Systematic verification loop pattern |

#### Testing
| Skill | What It Does |
|-------|--------------|
| `/e2e` | Generate + run E2E tests with Playwright; captures screenshots/videos |
| `/test-coverage` | Analyze and improve test coverage |
| `/eval` | Run evaluation harness for AI-assisted code |
| `/ai-regression-testing` | Regression test strategies for AI-generated code |

#### Session Management
| Skill | What It Does |
|-------|--------------|
| `/save-session` | Save session state to `~/.claude/session-data/` for later resumption |
| `/resume-session` | Load most recent session and resume with full context |
| `/sessions` | Manage session history, aliases, metadata |
| `/checkpoint` | Checkpoint current work state mid-session |
| `/strategic-compact` | Suggest manual compaction at logical intervals |

#### Learning & Instincts
| Skill | What It Does |
|-------|--------------|
| `/learn` | Extract reusable patterns from current session |
| `/learn-eval` | Extract + self-evaluate before saving (quality gate) |
| `/continuous-learning-v2` | Hook-based pattern capture with confidence scoring |
| `/instinct-status` | Show learned instincts (project + global) |
| `/instinct-import` | Import instincts from file or URL |
| `/instinct-export` | Export instincts to file |
| `/evolve` | Analyze instincts and suggest promoted structures |
| `/promote` | Promote project instincts to global scope |
| `/prune` | Delete stale pending instincts (>30 days) |

#### Documentation
| Skill | What It Does |
|-------|--------------|
| `/docs` | Look up current docs via Context7 MCP |
| `/update-docs` | Update project documentation |
| `/update-codemaps` | Regenerate `docs/CODEMAPS/*` files |
| `/doc-updater` | Full documentation sync after code changes |

#### Configuration & Meta
| Skill | What It Does |
|-------|--------------|
| `/update-config` | Configure settings.json, hooks, permissions, env vars |
| `/keybindings-help` | Customize keyboard shortcuts |
| `/configure-ecc` | Interactive ECC installer |
| `/context-budget` | Analyze context window usage, find optimization opportunities |
| `/skill-health` | Portfolio health dashboard with analytics |
| `/skill-stocktake` | Audit skill quality (quick scan or full) |
| `/harness-audit` | Full ECC harness audit |
| `/model-route` | Model routing decisions |

#### Scheduling
| Skill | What It Does |
|-------|--------------|
| `/schedule` | Create/manage scheduled remote agents on cron |
| `/loop` | Run a prompt on a recurring interval (e.g., `/loop 5m /verify`) |

#### Patterns & Standards
| Skill | What It Does |
|-------|--------------|
| `/api-design` | REST API design patterns and best practices |
| `/backend-patterns` | Node.js/Express/Next.js backend patterns |
| `/frontend-patterns` | React/Next.js frontend patterns |
| `/coding-standards` | Universal TypeScript/JS coding standards |
| `/mcp-server-patterns` | Build MCP servers with Node/TypeScript SDK |
| `/tdd-workflow` | TDD reference implementation |

#### Multi-Agent Orchestration
| Skill | What It Does |
|-------|--------------|
| `/devfleet` | Orchestrate parallel agents via Claude DevFleet |
| `/orchestrate` | Sequential and tmux/worktree orchestration |
| `/multi-frontend` | Frontend-focused multi-model development |
| `/multi-backend` | Backend-focused multi-model development |

#### Utilities
| Skill | What It Does |
|-------|--------------|
| `/aside` | Answer a quick side question without losing current task context |
| `/projects` | List known projects with instinct statistics |
| `/loop-status` | Check status of running loops |
| `/loop-start` | Start a monitoring loop |
| `/skill-create` | Generate SKILL.md from git history patterns |
| `/rules-distill` | Extract cross-cutting principles into rules |

---

## 6. Task Management

Tasks track progress on multi-step work within a session. They appear in the UI as a checklist.

### Core Operations

```
TaskCreate  title:"Implement auth" description:"JWT login flow"
TaskList                            # see all tasks + status
TaskGet     id:"task-123"          # details on one task
TaskUpdate  id:"task-123" status:"completed"
TaskStop    id:"task-123"          # cancel a running task
TaskOutput  id:"task-123"          # read output from background agent
```

### When to Use

- Break long implementations into discrete steps
- Mark each step `completed` as you finish it (don't batch)
- Use `TaskOutput` to read results from background agents

### Status Values

`pending` → `in_progress` → `completed` / `cancelled` / `failed`

---

## 7. Planning System

Plan mode forces a research-first, no-code-until-approved workflow.

### When to Use

- Complex features with unclear scope
- Architectural decisions
- Anything touching multiple files or systems
- When you want to review an approach before implementation starts

### Invoking

Type `/plan` as a prompt, or let Claude automatically enter plan mode for complex requests.

### The 5-Phase Workflow

```
Phase 1: Explore  →  Launch up to 3 Explore agents in parallel to understand the codebase
Phase 2: Design   →  Launch a Plan agent to design the implementation
Phase 3: Review   →  Read critical files, clarify with AskUserQuestion if needed
Phase 4: Write    →  Write the plan to ~/.claude/plans/<name>.md
Phase 5: Exit     →  Call ExitPlanMode — user approves before any code is touched
```

### Plan File Format

```markdown
# Plan: Feature Name

## Context
Why this change is being made, what problem it solves.

## Approach
Step-by-step implementation plan with file paths.

## Files to Modify
- src/auth/login.ts — add JWT validation
- src/middleware/auth.ts — update guard logic

## Verification
How to test: run `npm test`, check endpoint X, etc.
```

---

## 8. Scheduling & Automation

### Cron Tools (Direct API)

```
CronCreate  schedule:"0 9 * * 1-5"  command:"/verify"  description:"Daily quality check"
CronList                              # see all scheduled jobs
CronDelete  id:"cron-abc123"         # remove a job
```

### RemoteTrigger

Trigger a one-off remote agent run:

```
RemoteTrigger  command:"/code-review"  context:"Review PR #42"
```

### Skills as Higher-Level Interface

For most scheduling needs, use the skills instead of raw cron tools:

```
/schedule   →  interactive guided setup for recurring remote agents
/loop 5m /verify   →  run /verify every 5 minutes in current session
```

### Common Patterns

```
# Morning quality gate — runs weekdays at 9am:
CronCreate schedule:"0 9 * * 1-5" command:"/quality-gate"

# Loop to monitor a deploy in progress:
/loop 2m /loop-status

# One-time: trigger a remote security review:
RemoteTrigger command:"/code-review" context:"post-deploy security scan"
```

---

## 9. Worktrees — Isolated Workspaces

Worktrees give you a separate git checkout so changes don't affect your main branch until you're ready.

### Via Agent Tool (Recommended)

```
Agent(
  subagent_type: "refactor-cleaner",
  isolation: "worktree",
  prompt: "..."
)
```

- Automatically creates + cleans up the worktree
- If the agent makes no changes, the worktree is deleted
- If changes are made, you get back the worktree path + branch name

### Direct Worktree Tools

```
EnterWorktree  branch:"feature/my-change"
# ... do work ...
ExitWorktree
```

### When to Use

- Risky refactors you want to validate before merging
- Parallel feature branches without stashing
- Running agents that might make many file changes
- Experimenting without polluting the working tree

---

## 10. Gmail MCP Integration

Full Gmail access via MCP. All tools require the `mcp__claude_ai_Gmail__` prefix (handled automatically).

### Available Tools

| Tool | What It Does |
|------|-------------|
| `gmail_get_profile` | Check which Gmail account is authenticated |
| `gmail_list_labels` | List all labels/folders in the account |
| `gmail_search_messages` | Search emails using Gmail query syntax |
| `gmail_read_message` | Read a specific message by its ID |
| `gmail_read_thread` | Read a full email thread/conversation |
| `gmail_list_drafts` | List current draft emails |
| `gmail_create_draft` | Compose and save a new draft |

### Gmail Query Syntax (for search)

```
from:boss@company.com              # from a specific sender
subject:invoice after:2024/01/01   # subject filter + date
is:unread label:important          # unread + labeled
has:attachment filename:pdf        # emails with PDF attachments
```

### Typical Workflow

```
1. gmail_get_profile                    → confirm authenticated account
2. gmail_search_messages "is:unread"    → find relevant emails
3. gmail_read_thread  id:"thread-xyz"   → read full conversation
4. gmail_create_draft  to/subject/body  → compose a response
```

---

## 11. NotebookEdit — Jupyter Cells

Edit cells in Jupyter notebooks (`.ipynb` files).

### How to Use

```
1. Read the notebook file to see cell structure and IDs
2. NotebookEdit  notebook_path:"/path/to/notebook.ipynb"
                 cell_id:"cell-abc"
                 new_source:"print('Hello, world!')"
```

### Operations

- Edit cell source (code or markdown)
- Change cell type (code ↔ markdown)
- Insert new cells at a position
- Delete cells

### Notes

- Always Read the notebook first — cell IDs are required
- Output cells (results of running code) are read-only
- Use Bash to run `jupyter nbconvert` if you need to execute cells

---

## 12. Best Practices & Workflows

### The Golden Rules

1. **Use dedicated tools, not Bash**, for file operations — Read/Write/Edit/Glob/Grep
2. **Parallel tool calls** for independent operations — send multiple tool calls in one message
3. **Read before Edit** — always required, prevents stale-context edits
4. **Agents for complexity** — don't pack complex multi-step logic into a single prompt
5. **Skills for standards** — don't describe processes inline; invoke the skill

### Parallel Tool Calls

When operations are independent, do them in a single message:

```
# GOOD: In one response, call multiple tools at once
Read src/auth/login.ts
Read src/auth/middleware.ts
Read src/types/user.ts

# BAD: Sequential reads when they don't depend on each other
Read login.ts → wait → Read middleware.ts → wait → Read types.ts
```

### When Agent vs Direct Tools

| Situation | Approach |
|-----------|----------|
| Simple file read/edit | Direct tools (Read/Edit) |
| Complex multi-file analysis | Explore agent |
| Writing new feature | tdd-guide agent |
| After writing code | code-reviewer agent |
| Architectural question | architect agent |
| Security-sensitive change | security-reviewer agent |
| Parallel independent research | Multiple Explore agents in parallel |

### Context Window Management

- Avoid the last 20% of context for large refactors
- Use `/strategic-compact` to compact at logical breakpoints
- Use `/save-session` before context fills up; `/resume-session` in next session
- Use `/context-budget` to audit what's consuming context
- `docs-lookup` agent keeps library docs out of your main context

### Standard Development Workflow

```
1. Research   /docs "library X"  or  WebSearch → WebFetch
2. Plan       /plan  (or Agent: planner for complex work)
3. Test first Agent: tdd-guide  →  write failing tests
4. Implement  Edit/Write files to pass tests
5. Review     Agent: code-reviewer  (always, immediately after)
6. Security   Agent: security-reviewer  (if touching auth/input/APIs)
7. Commit     git add + git commit (conventional commits format)
8. Learn      /learn-eval  (extract reusable patterns)
```

### Hook-Aware Behavior

The system has active hooks that enforce quality automatically:

- **PreToolUse**: Blocks `--no-verify` git flags, enforces tmux for dev servers
- **PostToolUse**: Auto-formats, TypeScript checks, pattern capture
- **Stop**: Session persistence, cost tracking, continuous learning

If a hook blocks an action, investigate the root cause — don't try to bypass it.

### Commit Message Format

```
feat: add JWT refresh token rotation
fix: handle null user on profile update
refactor: extract auth logic to dedicated service
docs: update API authentication guide
test: add integration tests for payment flow
chore: upgrade dependencies to latest
```

---

## Quick Reference Card

```
File ops:      Read, Write, Edit, Glob, Grep
Shell:         Bash (system commands only)
Web:           WebSearch → WebFetch
Agents:        Agent(subagent_type: "name", ...)
Skills:        /skill-name
Tasks:         TaskCreate / TaskList / TaskUpdate
Planning:      /plan → EnterPlanMode → ExitPlanMode
Scheduling:    CronCreate / CronList / CronDelete / /schedule
Worktrees:     Agent(isolation:"worktree") or EnterWorktree
Gmail:         gmail_search_messages → gmail_read_thread → gmail_create_draft
Notebooks:     Read → NotebookEdit
```
