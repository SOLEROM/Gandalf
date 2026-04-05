# Installation Guide

How to install this curated ECC toolkit into your running Claude Code instance.

---

## What Goes Where

| Asset | Source | Destination |
|---|---|---|
| Agents | `agents/*.md` | `~/.claude/agents/` |
| Commands | `commands/*.md` | `~/.claude/commands/` |
| Skills | `skills/<name>/` | `~/.claude/skills/<name>/` |
| Rules | `rules/common/*.md` | `~/.claude/CLAUDE.md` (appended) |
| Hooks | `hooks/hooks.json` | requires full ECC plugin scripts — see Step 5 |
| MCP servers | `mcp-configs/mcp-servers.json` | `~/.claude.json` → `mcpServers` |

---

## Prerequisites

- Claude Code CLI installed and working (`claude --version`)
- Node.js ≥18 (for hook scripts)
- `npx` available on PATH

Set the source directory once — all commands below use it:

```bash
export ECC_DIR="/data/proj/agents/gandalf/30_ecc/ver1"
```

---

## Step 1 — Agents

Copy all agent definitions into your user-level agents directory:

```bash
mkdir -p ~/.claude/agents
cp "$ECC_DIR"/agents/*.md ~/.claude/agents/
```

Verify:

```bash
ls ~/.claude/agents/
# Expected: architect.md, code-reviewer.md, docs-lookup.md, doc-updater.md,
#           e2e-runner.md, loop-operator.md, planner.md, refactor-cleaner.md,
#           security-reviewer.md, tdd-guide.md
```

These are available immediately — no restart needed. Invoke via the Agent tool or a command that references them.

---

## Step 2 — Commands

Copy all slash commands:

```bash
mkdir -p ~/.claude/commands
cp "$ECC_DIR"/commands/*.md ~/.claude/commands/
```

Verify (should be 53 files):

```bash
ls ~/.claude/commands/ | wc -l
```

Commands are available immediately as `/command-name` in the Claude Code CLI. If you already have custom commands in `~/.claude/commands/`, none will be overwritten — new files are additive.

---

## Step 3 — Skills

Skills are directories, not single files. Copy each one preserving the directory structure:

```bash
mkdir -p ~/.claude/skills

cp -r "$ECC_DIR"/skills/ai-regression-testing   ~/.claude/skills/
cp -r "$ECC_DIR"/skills/api-design               ~/.claude/skills/
cp -r "$ECC_DIR"/skills/backend-patterns         ~/.claude/skills/
cp -r "$ECC_DIR"/skills/coding-standards         ~/.claude/skills/
cp -r "$ECC_DIR"/skills/configure-ecc            ~/.claude/skills/
cp -r "$ECC_DIR"/skills/e2e-testing              ~/.claude/skills/
cp -r "$ECC_DIR"/skills/eval-harness             ~/.claude/skills/
cp -r "$ECC_DIR"/skills/frontend-patterns        ~/.claude/skills/
cp -r "$ECC_DIR"/skills/iterative-retrieval      ~/.claude/skills/
cp -r "$ECC_DIR"/skills/mcp-server-patterns      ~/.claude/skills/
cp -r "$ECC_DIR"/skills/plankton-code-quality    ~/.claude/skills/
cp -r "$ECC_DIR"/skills/project-guidelines-example ~/.claude/skills/
cp -r "$ECC_DIR"/skills/skill-stocktake          ~/.claude/skills/
cp -r "$ECC_DIR"/skills/strategic-compact        ~/.claude/skills/
cp -r "$ECC_DIR"/skills/tdd-workflow             ~/.claude/skills/
cp -r "$ECC_DIR"/skills/verification-loop        ~/.claude/skills/
```

### Special: continuous-learning and continuous-learning-v2

These skills include shell scripts and a Python utility. Copy them the same way, then make their scripts executable:

```bash
cp -r "$ECC_DIR"/skills/continuous-learning      ~/.claude/skills/
cp -r "$ECC_DIR"/skills/continuous-learning-v2   ~/.claude/skills/

chmod +x ~/.claude/skills/continuous-learning/evaluate-session.sh
chmod +x ~/.claude/skills/continuous-learning-v2/agents/*.sh
chmod +x ~/.claude/skills/continuous-learning-v2/hooks/observe.sh
chmod +x ~/.claude/skills/continuous-learning-v2/scripts/*.sh
```

The `continuous-learning-v2` instinct CLI requires Python:

```bash
# Verify the instinct CLI is accessible
python3 ~/.claude/skills/continuous-learning-v2/scripts/instinct-cli.py --help
```

Verify all skills installed:

```bash
ls ~/.claude/skills/ | wc -l   # should be 18
```

---

## Step 4 — Rules

Claude Code natively loads `~/.claude/CLAUDE.md` as user-level instructions for every session. The 9 common rule files should be appended there.

### Check if you already have a CLAUDE.md

```bash
cat ~/.claude/CLAUDE.md 2>/dev/null || echo "(no CLAUDE.md yet)"
```

### Append all common rules

```bash
# Create a header section
cat >> ~/.claude/CLAUDE.md << 'EOF'

---
# ECC Common Rules
# Source: rules/common/ — universal guidelines applied to every project

EOF

# Append each rule file with a heading
for f in "$ECC_DIR"/rules/common/*.md; do
  name=$(basename "$f" .md)
  echo "## $name" >> ~/.claude/CLAUDE.md
  echo "" >> ~/.claude/CLAUDE.md
  cat "$f" >> ~/.claude/CLAUDE.md
  echo "" >> ~/.claude/CLAUDE.md
  echo "---" >> ~/.claude/CLAUDE.md
  echo "" >> ~/.claude/CLAUDE.md
done
```

Verify the rules were appended:

```bash
grep "^## " ~/.claude/CLAUDE.md
# Should include: coding-style, git-workflow, testing, security,
#                 performance, patterns, agents, hooks, development-workflow
```

### Alternative: project-level rules only

If you want rules to apply to a specific project only (not globally), append them to `.claude/CLAUDE.md` in the project root instead of `~/.claude/CLAUDE.md`.

---

## Step 5 — Hooks

> **Important:** The `hooks/hooks.json` in this folder references scripts from the full ECC plugin installation (`${CLAUDE_PLUGIN_ROOT}/scripts/hooks/...`). Those scripts are not included in this working set. The hooks will not function without them.

You have two options:

---

### Option A — Install the full ECC plugin (recommended)

The ECC plugin ships the scripts and sets `CLAUDE_PLUGIN_ROOT` automatically. Once installed, it reads `hooks.json` from the plugin directory.

```bash
# Install via Claude Code plugin marketplace
claude plugin install everything-claude-code
```

After the plugin installs, it will manage hook activation automatically. Your agents, commands, skills, and rules from Steps 1–4 sit on top and take precedence.

---

### Option B — Manual minimal hooks (no plugin required)

If you don't want the full ECC plugin, add only the hooks that work without the plugin scripts. Open `~/.claude/settings.json` and merge the following into the `"hooks"` section:

**1. Block `--no-verify` git flag** (uses `npx`, no scripts needed — highest value hook):

```json
{
  "PreToolUse": [
    {
      "matcher": "Bash",
      "hooks": [
        {
          "type": "command",
          "command": "npx block-no-verify@1.1.2"
        }
      ],
      "description": "Block --no-verify git flag to protect pre-commit hooks"
    }
  ]
}
```

**2. Require test files alongside new source files** (inline Node.js, no scripts needed):

```json
{
  "matcher": "Write",
  "hooks": [{
    "type": "command",
    "command": "node -e \"const fs=require('fs');let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{const i=JSON.parse(d);const p=i.tool_input?.file_path||'';if(/src\\/.*\\.(ts|js)$/.test(p)&&!/\\.test\\.|\\.spec\\./.test(p)){const testPath=p.replace(/\\.(ts|js)$/,'.test.$1');if(!fs.existsSync(testPath)){console.error('[Hook] No test file for: '+p+' — consider /tdd')}}console.log(d)})\""
  }],
  "description": "Remind to write tests when adding new source files"
}
```

To add these, edit `~/.claude/settings.json` directly and merge them into the existing `"hooks"` object. Use `jq` if available to avoid breaking the JSON:

```bash
# Back up first
cp ~/.claude/settings.json ~/.claude/settings.json.bak

# Then edit manually
$EDITOR ~/.claude/settings.json
```

---

## Step 6 — MCP Servers

MCP servers are configured in `~/.claude.json` (the main Claude config, distinct from `~/.claude/settings.json`).

Open `~/.claude.json` and add a `"mcpServers"` key with the servers you want. The `mcp-configs/mcp-servers.json` file in this repo contains all available server definitions with placeholder values.

### Recommended general-purpose servers to add first

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"],
      "description": "Live documentation lookup — powers /docs command"
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"],
      "description": "Chain-of-thought structured reasoning"
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"],
      "description": "Persistent memory across sessions"
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp", "--browser", "chrome"],
      "description": "Browser automation — powers /e2e command"
    }
  }
}
```

### Add GitHub access (requires a PAT)

```json
"github": {
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-github"],
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_YOUR_TOKEN_HERE"
  }
}
```

Generate a PAT at GitHub → Settings → Developer Settings → Personal access tokens. Scopes needed: `repo`, `read:org`.

### Full server list

See `mcp-configs/mcp-servers.json` for all available servers with their configuration. Replace all `YOUR_*_HERE` placeholders with real values before adding.

> **Context window warning:** Keep total active MCP servers under 10. Each loaded MCP adds overhead to every request. Start with the 4 above, add others when you have a specific need.

---

## Step 7 — Verify Installation

Run this checklist after completing all steps:

```bash
# 1. Agents
ls ~/.claude/agents/ | grep -E "(architect|planner|code-reviewer|tdd-guide|security-reviewer)"

# 2. Commands — spot check
ls ~/.claude/commands/ | grep -E "(plan|tdd|code-review|verify|quality-gate)"

# 3. Skills — spot check
ls ~/.claude/skills/ | grep -E "(tdd-workflow|api-design|verification-loop)"

# 4. Rules in CLAUDE.md
grep "coding-style\|git-workflow\|testing" ~/.claude/CLAUDE.md

# 5. MCP servers
cat ~/.claude.json | python3 -m json.tool | grep -A1 '"mcpServers"'
```

Then open a new Claude Code session and test:

```bash
claude
> /plan add a simple health-check endpoint
```

You should see the planner agent activate and produce a structured plan. If it doesn't, check that `~/.claude/commands/plan.md` exists and that `~/.claude/agents/planner.md` exists.

---

## Staying Updated

This working set is a snapshot. The upstream ECC project evolves. To pull updates:

```bash
cd "$ECC_DIR"
git pull

# Re-copy agents and commands (safe — overwrites in place)
cp "$ECC_DIR"/agents/*.md ~/.claude/agents/
cp "$ECC_DIR"/commands/*.md ~/.claude/commands/

# Re-copy skills (use -r to overwrite)
for dir in "$ECC_DIR"/skills/*/; do
  name=$(basename "$dir")
  rm -rf ~/.claude/skills/"$name"
  cp -r "$dir" ~/.claude/skills/
done

# Rules: re-run the append block from Step 4
# (trim the old ECC section from CLAUDE.md first to avoid duplicates)
```

---

## Troubleshooting

**Agents not appearing in the Agent tool selector**
- Verify the file is in `~/.claude/agents/` (not a subdirectory)
- Ensure the file has a `.md` extension
- Restart Claude Code

**Commands returning "not found"**
- Verify `~/.claude/commands/<name>.md` exists
- The command filename is the slash command name — `plan.md` → `/plan`
- Restart Claude Code after adding new commands

**Skills not being used**
- Each skill must be a directory containing `SKILL.md` (not a standalone `.md` file)
- Skills are loaded on demand when the topic is relevant — they don't appear in a menu
- You can explicitly load one: "use the tdd-workflow skill for this"

**Rules not being followed**
- Rules in CLAUDE.md are instructions, not hard enforcement — Claude may still need guidance
- Verify the content was actually appended: `wc -l ~/.claude/CLAUDE.md`
- For stricter enforcement, use hooks (Option A from Step 5)

**Hook `${CLAUDE_PLUGIN_ROOT}` errors**
- This means the full ECC plugin scripts are not installed
- Follow Option A in Step 5 (install the plugin) or use Option B (minimal inline hooks)
- Do not set `CLAUDE_PLUGIN_ROOT` manually unless you have the full scripts directory

**MCP servers timing out**
- Each `npx -y` MCP server downloads on first use — this causes a one-time delay
- Pre-cache by running: `npx -y @upstash/context7-mcp@latest --version 2>/dev/null || true`
- If a specific MCP keeps failing, disable it temporarily in `~/.claude.json` by removing its entry
