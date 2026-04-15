# Installation Guide — Context Engineering Toolkit

## Prerequisites

- Claude Code installed (`claude --version` should work)
- Git (for parallel worktree commands)
- `gh` CLI (only needed for `/fix-github-issue`)
- `jq` (for hooks — `apt install jq` / `brew install jq`)

## One-Command Install

From the `ver1/` directory:

```bash
bash install.sh
```

Preview without writing anything:
```bash
bash install.sh --dry-run
```

---

## What Gets Installed Where

### Commands → `~/.claude/commands/`

```bash
cp commands/*.md ~/.claude/commands/
```

After this, every Claude Code session has these slash commands:
- `/generate-prp` — generate a PRP from INITIAL.md
- `/execute-prp` — implement a PRP end-to-end
- `/primer` — prime Claude with project context
- `/fix-github-issue` — fix a GitHub issue and open a PR
- `/prep-parallel` — create N parallel git worktrees
- `/execute-parallel` — run N agents building in parallel

**Verify**:
```bash
ls ~/.claude/commands/
# Should show: generate-prp.md, execute-prp.md, primer.md, ...
```

---

### Agents → `~/.claude/agents/`

```bash
cp agents/*.md ~/.claude/agents/
```

Installs:
- `documentation-manager` — syncs docs after code changes
- `validation-gates` — runs tests, fixes failures, iterates

**Verify**:
```bash
ls ~/.claude/agents/
# Should show: documentation-manager.md, validation-gates.md
```

---

### Hooks → `~/.claude/hooks/` and `~/.claude/settings.json`

```bash
mkdir -p ~/.claude/hooks
cp hooks/log-tool-usage.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/log-tool-usage.sh
```

If you don't have a `~/.claude/settings.json` yet:
```bash
cp hooks/example-hook-config.json ~/.claude/settings.json
```

If you already have `settings.json`, manually merge the `"hooks"` key from `hooks/example-hook-config.json` into your existing file.

The hooks installed:
- **log-tool-usage** (PostToolUse) — logs every file edit to `.claude/logs/tool-usage.log`
- **block-dangerous-commands** (PreToolUse) — blocks `rm *`, `.env` deletion, credential commands
- **validation-gates-log** (SubagentStop) — logs when validation-gates agent completes
- **test-reminder** (UserPromptSubmit) — reminds to validate when testing is mentioned

**Verify**:
```bash
ls ~/.claude/hooks/
# Should show: log-tool-usage.sh
cat ~/.claude/settings.json | grep -c '"hooks"'
# Should show: 1
```

---

### PRP Template → `~/.claude/prp-templates/`

```bash
mkdir -p ~/.claude/prp-templates
cp prp-templates/prp_base.md ~/.claude/prp-templates/
```

**Verify**:
```bash
ls ~/.claude/prp-templates/
# Should show: prp_base.md
```

---

### CLAUDE.md Template → `~/.claude/CLAUDE.md.context-eng-template`

The installer copies `CLAUDE.md` as a template. For each project:

**Option A — project-level rules** (recommended):
```bash
cp ~/.claude/CLAUDE.md.context-eng-template ./CLAUDE.md
# Edit CLAUDE.md for your project's language/stack/conventions
```

**Option B — user-level rules** (applies to all projects):
```bash
cat ~/.claude/CLAUDE.md.context-eng-template >> ~/.claude/CLAUDE.md
```

---

### INITIAL.md Template → `~/.claude/INITIAL.md.template`

For each new feature:
```bash
cp ~/.claude/INITIAL.md.template ./INITIAL.md
# Fill in FEATURE, EXAMPLES, DOCUMENTATION, OTHER CONSIDERATIONS
```

---

## Per-Project Setup

After installing to `~/.claude/`, do this for each project:

```bash
cd /your/project

# 1. Copy project rules template
cp ~/.claude/CLAUDE.md.context-eng-template ./CLAUDE.md
# Edit CLAUDE.md for your stack (language, framework, test commands, etc.)

# 2. Set up PRP directory
mkdir -p PRPs/templates
cp ~/.claude/prp-templates/prp_base.md PRPs/templates/

# 3. Create a feature request
cp ~/.claude/INITIAL.md.template INITIAL.md
# Edit INITIAL.md with your feature

# 4. Open Claude Code and start
/primer
/generate-prp INITIAL.md
```

---

## Verify the Full Installation

After running `install.sh`, open Claude Code in any project and run:

```
/primer
```

If Claude reads your project structure and explains it back — installation is working.

Then try:
```
/generate-prp INITIAL.md
```

If Claude researches the codebase and produces a PRP file at `PRPs/your-feature.md` — the command pipeline is working.

---

## Troubleshooting

**Slash commands not found**
- Commands must be in `~/.claude/commands/` (user-wide) or `.claude/commands/` (project-level)
- Restart Claude Code after adding new commands

**`/fix-github-issue` fails with auth error**
```bash
gh auth login
```

**Hook errors in Claude Code logs**
- Ensure `jq` is installed: `jq --version`
- Ensure `log-tool-usage.sh` is executable: `chmod +x ~/.claude/hooks/log-tool-usage.sh`
- Check `~/.claude/settings.json` is valid JSON: `jq . ~/.claude/settings.json`

**PRP template not found by /generate-prp**
- The template path is referenced as `PRPs/templates/prp_base.md` inside commands
- Copy it into each project: `cp ~/.claude/prp-templates/prp_base.md PRPs/templates/`

**Agents not available**
- Agents live in `~/.claude/agents/` — verify the files are there
- Invoke explicitly: `use the validation-gates agent to...`
