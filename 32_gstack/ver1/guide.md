# Claude Code Session Tools Guide

A practical reference for the non-trivial tools available in this session.

---

## Skills (Slash Commands)

Invoke with: `/<skill-name>` in the prompt

### `/ship`
Full release workflow in one command.
- Merges main, runs tests, reviews diff, bumps VERSION, updates CHANGELOG, commits, pushes, creates PR.
- **Use when:** you're ready to land a feature branch.

### `/review`
Pre-landing PR review before merging.
- Checks diff against main for SQL safety, LLM trust boundary violations, conditional side effects.
- **Use when:** you want a final safety check before `/ship`.

### `/qa [mode]`
Systematically QA test a web app.
- Modes: `diff-aware` (auto on feature branches), `full`, `quick` (30s smoke), `regression`
- Produces health score, screenshots, repro steps.
- **Use when:** you've deployed or changed a UI and want bugs surfaced.

### `/browse`
Headless browser for testing and dogfooding (~100ms/command).
- Navigate URLs, interact with elements, take screenshots, check responsive layouts, test forms.
- **Use when:** you need to verify a deployment or test a user flow without opening a browser.

### `/setup-browser-cookies`
Imports cookies from your real browser (Chrome, Arc, Brave, etc.) into the headless browse session.
- **Use before** `/browse` or `/qa` when testing authenticated pages.

### `/plan-ceo-review`
CEO/founder-mode plan review — rethinks the problem, finds 10-star product, challenges premises.
- Modes: `SCOPE EXPANSION`, `HOLD SCOPE`, `SCOPE REDUCTION`
- **Use when:** you want to validate whether you're solving the right problem.

### `/plan-eng-review`
Eng manager-mode plan review — locks in execution: architecture, data flow, edge cases, test coverage.
- **Use when:** you have a plan and want rigorous implementation review before starting.

### `/retro`
Weekly engineering retrospective.
- Analyzes commit history, work patterns, code quality. Team-aware with per-person breakdowns.
- **Use when:** doing a weekly or sprint retrospective.

### `/simplify`
Reviews recently changed code for reuse, quality, and efficiency — then fixes issues found.
- **Use after** writing code to tighten it up.

### `/schedule`
Create, update, list, or run scheduled remote agents on a cron schedule.
- **Use when:** you want to automate a recurring Claude Code task (e.g., nightly reports).

### `/loop [interval] [command]`
Runs a prompt or slash command on a recurring interval.
- Example: `/loop 5m /qa` — runs QA every 5 minutes.
- Default interval: 10m.
- **Use when:** you want to poll for status or monitor something over time.

### `/update-config`
Configures Claude Code settings.json / settings.local.json.
- Handles hooks, permissions, env vars, automated behaviors ("whenever X do Y").
- **Use when:** you want to add permissions, set env vars, or wire up hooks.

### `/claude-api`
Scaffold apps using the Claude API or Anthropic SDK.
- Triggered automatically when code imports `anthropic` / `@anthropic-ai/sdk`.
- **Use when:** building AI-powered apps with Claude as the backend.

---

## MCP: Gmail Tools

Available as `mcp__claude_ai_Gmail__*`. Claude calls these directly — you just ask naturally.

| Tool | What it does |
|------|-------------|
| `gmail_get_profile` | Get your Gmail account info |
| `gmail_list_labels` | List all Gmail labels/folders |
| `gmail_search_messages` | Search messages (supports Gmail query syntax: `from:`, `subject:`, `after:`, etc.) |
| `gmail_read_message` | Read a specific message by ID |
| `gmail_read_thread` | Read a full email thread |
| `gmail_list_drafts` | List your drafts |
| `gmail_create_draft` | Create a new draft |

**Example prompts:**
- "Search my Gmail for emails from alice@example.com this week"
- "Read my latest unread thread"
- "Draft a reply to the last email from Bob about the invoice"

---

## Special Workflow Tools

These are invoked by Claude internally but you can request them explicitly.

### Plan Mode (`EnterPlanMode` / `ExitPlanMode`)
Switches Claude into a planning-only mode — no code is written until the plan is approved.
- **Use when:** you want to review the approach before any changes are made.
- Prompt: "Enter plan mode and design the new auth flow"

### Worktree (`EnterWorktree` / `ExitWorktree`)
Runs work in an isolated git worktree so your main branch stays clean.
- **Use when:** you want risky or experimental changes isolated.
- Prompt: "Do this in a worktree"

### Task Tools (`TaskCreate` / `TaskUpdate` / `TaskList`)
Claude's internal task tracker for multi-step work.
- Breaks big jobs into tracked steps with status (pending → in-progress → done).
- Automatically used for complex tasks; you can ask: "show me your task list"

### Cron (`CronCreate` / `CronList` / `CronDelete`)
Schedule recurring jobs at the session level.
- **Use when:** you want a background cron that triggers during this session.

### `RemoteTrigger`
Fires a remote agent trigger manually (paired with `/schedule`).

### `WebFetch` / `WebSearch`
- `WebFetch`: Fetch and read the content of a URL.
- `WebSearch`: Search the web for current information.
- **Use when:** you need up-to-date info or docs not in the codebase.

---

## Quick Reference Cheatsheet

```
Ship code          →  /ship
Review before ship →  /review
Test UI            →  /qa  or  /browse
Auth UI testing    →  /setup-browser-cookies  then  /qa
Plan (big picture) →  /plan-ceo-review
Plan (eng detail)  →  /plan-eng-review
Tighten code       →  /simplify
Retrospective      →  /retro
Automate a task    →  /schedule  or  /loop
Config / hooks     →  /update-config
Gmail access       →  just ask ("search my email for X")
```
