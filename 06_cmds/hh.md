---
name: what-can-i-do
description: Audits the current Claude Code install and lists all non-default capabilities — custom commands, skills, plugins, MCP servers, subagents, hooks, and tool permissions — so you know exactly what this agent can do right now.
allowed-tools: Bash(find:*), Bash(ls:*), Bash(cat:*), Bash(echo:*), Bash(claude:*), Bash(jq:*), Bash(test:*)
allowed-tools: Bash
disable-model-invocation: true
---


# What Can I Do?

Your job is to perform a **complete capability audit** of this Claude Code installation and produce a clean, human-readable report. You are cataloguing *non-trivial, non-default* features only — skip things that every Claude Code install has out of the box.

## Step 1 — Discover all configuration paths

Run the following to map what exists:

```bash
# Global config
ls ~/.claude/ 2>/dev/null
ls ~/.claude/commands/ 2>/dev/null
ls ~/.claude/skills/ 2>/dev/null
ls ~/.claude/agents/ 2>/dev/null
ls ~/.claude/plugins/ 2>/dev/null
ls ~/.claude/hooks/ 2>/dev/null

# Project config (cwd)
ls .claude/ 2>/dev/null
ls .claude/commands/ 2>/dev/null
ls .claude/skills/ 2>/dev/null
ls .claude/agents/ 2>/dev/null
ls .claude/plugins/ 2>/dev/null
ls .claude/hooks/ 2>/dev/null

# Settings files
cat ~/.claude/settings.json 2>/dev/null
cat .claude/settings.json 2>/dev/null
cat .claude/settings.local.json 2>/dev/null
```

## Step 2 — Read every custom command and skill

For each `.md` file found in any `commands/` or `skills/` directory (both `~/.claude/` and `.claude/`), read its frontmatter `description` field (or first meaningful line if no frontmatter). Record:
- Command name (the filename or `name:` field)
- Scope: **global** (from `~/.claude/`) or **project** (from `.claude/`)
- One-line description of what it does

## Step 3 — Inventory MCP servers

```bash
# Check settings for mcpServers
cat ~/.claude/settings.json 2>/dev/null | jq '.mcpServers // {}' 2>/dev/null || grep -A5 '"mcpServers"' ~/.claude/settings.json 2>/dev/null
cat .claude/settings.json 2>/dev/null | jq '.mcpServers // {}' 2>/dev/null || grep -A5 '"mcpServers"' .claude/settings.json 2>/dev/null

# Also list any MCP prompts that become slash commands
claude mcp list 2>/dev/null || true
```

For each MCP server, record: server name, transport type (url/stdio), and what category of tools it provides.

## Step 4 — Inventory subagents

```bash
find ~/.claude/agents .claude/agents -name "*.md" 2>/dev/null | while read f; do
  echo "=== $f ==="; head -20 "$f"; echo
done
```

## Step 5 — Read hooks

```bash
cat ~/.claude/settings.json 2>/dev/null | jq '.hooks // {}' 2>/dev/null
cat .claude/settings.json 2>/dev/null | jq '.hooks // {}' 2>/dev/null
```

For each hook, record: event (PreToolUse, PostToolUse, etc.) and what it does.

## Step 6 — Read non-default tool permissions

```bash
cat ~/.claude/settings.json 2>/dev/null | jq '{permissions: .permissions, allowedTools: .allowedTools, deniedTools: .deniedTools}' 2>/dev/null
cat .claude/settings.json 2>/dev/null | jq '{permissions: .permissions, allowedTools: .allowedTools, deniedTools: .deniedTools}' 2>/dev/null
```

## Step 7 — Check for plugins

```bash
find ~/.claude/plugins .claude/plugins -maxdepth 2 -name "*.json" -o -name "plugin.md" 2>/dev/null | head -30
```

## Step 8 — Check CLAUDE.md files for declared capabilities

```bash
cat ~/.claude/CLAUDE.md 2>/dev/null | head -60
cat CLAUDE.md 2>/dev/null | head -60
```

Note any tools, integrations, or workflows explicitly declared in these files.

---

## Output Format

After gathering all the above, produce a report using **exactly this structure**. Only include sections that have actual findings. Omit sections with nothing to show.

---

### 🛠️ Custom Commands & Skills

List each one as:
`/command-name` [scope: global | project] — Description

---

### 🤖 Subagents

List each custom subagent with its name and specialty.

---

### 🔌 MCP Servers & Their Tools

For each server: name, what domain it covers, and any slash commands it exposes (format: `/mcp__servername__promptname`).

---

### 🪝 Hooks

For each hook: when it fires and what it does.

---

### 🔑 Non-Default Tool Permissions

List any tools that are explicitly allowed or denied beyond defaults, and any `allowedTools` overrides.

---

### 🧩 Plugins

List any installed plugins with a brief description.

---

### 📋 Summary

End with a one-paragraph plain-English summary of what this agent can do that a vanilla Claude Code install cannot. Be specific about the most powerful or unusual capabilities found.

---

**Important:** If a section has nothing to show (e.g. no hooks configured), skip it entirely — do not print empty sections. If nothing non-default is found anywhere, say so honestly.