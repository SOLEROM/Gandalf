# Claude Code Hooks

This directory contains hooks for Claude Code that add deterministic behavior to your AI coding workflow.

## What are Hooks?

Hooks are user-defined shell commands that execute at specific points in Claude Code's lifecycle. They provide control over Claude's behavior, ensuring certain actions always happen rather than relying on the AI to choose to run them.

## Files

- **log-tool-usage.sh** — PostToolUse hook that logs file edits to `.claude/logs/tool-usage.log`
- **example-hook-config.json** — Ready-to-use hook configuration with 4 hooks

## Hooks in example-hook-config.json

| Hook | Event | What it does |
|------|-------|-------------|
| log-tool-usage | PostToolUse (Edit/Write/MultiEdit) | Logs every file edit with timestamp |
| block-dangerous-commands | PreToolUse (Bash) | Blocks `rm *`, `.env` deletion, credential commands |
| validation-gates-log | SubagentStop | Logs when validation-gates subagent completes |
| test-reminder | UserPromptSubmit | Reminds to use validation-gates when testing is mentioned |

## Installation

**Project-specific** (only this project):
```bash
cp hooks/example-hook-config.json .claude/settings.json
cp hooks/log-tool-usage.sh .claude/hooks/
chmod +x .claude/hooks/log-tool-usage.sh
```

**User-wide** (all Claude Code sessions):
```bash
cp hooks/example-hook-config.json ~/.claude/settings.json
mkdir -p ~/.claude/hooks
cp hooks/log-tool-usage.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/log-tool-usage.sh
```

## Available Hook Events

- **PreToolUse** — Before tool execution (can block tools by returning `{"action": "block", "message": "reason"}`)
- **PostToolUse** — After successful tool completion
- **UserPromptSubmit** — When user submits a prompt
- **SubagentStop** — When a subagent completes
- **Stop** — When main agent finishes responding
- **Notification** — During system notifications
- **PreCompact** — Before context compaction
- **SessionStart** — At session initialization

## Debugging

```bash
claude --debug
```

This shows which hooks are triggered, their input/output, and any errors.
