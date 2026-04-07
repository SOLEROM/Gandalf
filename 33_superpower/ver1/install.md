# Installation — Superpowers Dev Toolkit v5.0.7

Install into Claude Code CLI. Replace `/path/to/ver1` with the actual path to this directory throughout.

## Prerequisites

- Claude Code CLI installed and working
- `~/.claude/` directory exists (created automatically by Claude Code)

---

## Step 1 — Agents

```bash
cp /path/to/ver1/agents/*.md ~/.claude/agents/

# Verify
ls ~/.claude/agents/
# Expected: code-reviewer.md
```

---

## Step 2 — Commands

```bash
cp /path/to/ver1/commands/*.md ~/.claude/commands/

# Verify
ls ~/.claude/commands/
# Expected: brainstorm.md  execute-plan.md  write-plan.md
```

Note: these three commands are deprecated aliases that redirect to skills. They are kept for backward compatibility but the skills are the primary interface.

---

## Step 3 — Skills

```bash
mkdir -p ~/.claude/skills

for dir in /path/to/ver1/skills/*/; do
  cp -r "$dir" ~/.claude/skills/
done

# Make executable scripts runnable
chmod +x ~/.claude/skills/brainstorming/scripts/*.sh
chmod +x ~/.claude/skills/systematic-debugging/find-polluter.sh

# Verify
ls ~/.claude/skills/
# Expected: brainstorming  dispatching-parallel-agents  executing-plans
#           finishing-a-development-branch  receiving-code-review
#           requesting-code-review  subagent-driven-development
#           systematic-debugging  test-driven-development
#           using-git-worktrees  using-superpowers
#           verification-before-completion  writing-plans  writing-skills
```

---

## Step 4 — Hooks

```bash
mkdir -p ~/.claude/hooks

cp /path/to/ver1/hooks/session-start ~/.claude/hooks/session-start
chmod +x ~/.claude/hooks/session-start
```

Then add the hook entry to `~/.claude/settings.json`. Open the file and merge the following JSON into the `"hooks"` key (create the key if it does not exist):

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|clear|compact",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" session-start",
            "async": false
          }
        ]
      }
    ]
  }
}
```

**Important:** The hook command references `${CLAUDE_PLUGIN_ROOT}`, which Claude Code sets to the plugin root directory. If you are installing manually (not via the plugin system), replace `${CLAUDE_PLUGIN_ROOT}` with the absolute path to your hooks directory. For example:

```json
"command": "/Users/yourname/.claude/hooks/session-start"
```

```bash
# Verify the hook entry is present
cat ~/.claude/settings.json | grep -A5 hooks
```

---

## Step 5 — Rules

No standalone rules files are included in this toolkit. The upstream `CLAUDE.md` from the Superpowers repository is contributor guidelines for the plugin project itself, not user coding rules. Do not copy it.

If you want project-level rules, create your own `CLAUDE.md` in your project root.

---

## Step 6 — MCP Servers

No MCP servers are included in this toolkit. The upstream `fakechat` server was excluded — it is a test/demo server only, not a development tool.

---

## Verification

After completing all steps, run the test script:

```bash
bash /path/to/ver1/test/test.sh
```

This creates a temporary git repository, invokes Claude for each skill, and reports pass/fail. See `test/test.md` for the full scenario description.

---

## Troubleshooting

**Skills not found by Claude**
Check that skill files are at `~/.claude/skills/<name>/SKILL.md`:
```bash
ls ~/.claude/skills/brainstorming/SKILL.md
```

**Hook not firing at session start**
Verify the hooks JSON format in settings.json. The `"hooks"` key must be at the top level and the `SessionStart` event name must match exactly (capital S, capital S):
```bash
cat ~/.claude/settings.json
```

**Permission denied running session-start**
```bash
chmod +x ~/.claude/hooks/session-start
```

**Brainstorming server won't start**
The server script requires execute permission:
```bash
chmod +x ~/.claude/skills/brainstorming/scripts/*.sh
```
It also requires Node.js to be installed and available as `node` on your PATH.

**Session-start injects wrong content**
The hook reads `${CLAUDE_PLUGIN_ROOT}/skills/using-superpowers/SKILL.md`. If the plugin root path is wrong, the hook will output an error message instead of skill content. Verify `CLAUDE_PLUGIN_ROOT` resolves to the directory containing your `skills/` folder.
