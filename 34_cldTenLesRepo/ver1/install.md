# Installation Guide

## Prerequisites

- Claude Code CLI installed and authenticated (`claude --version`)
- Python 3.8+ (for supporting scripts)
- `~/.claude/` directory exists (created automatically by Claude Code on first run)

---

## Automated Install (Recommended)

```bash
bash install.sh
```

This copies all four skill directories to `~/.claude/skills/` and makes any `.sh` scripts executable.

---

## Manual Install

### Skills

Each skill is a directory containing a `SKILL.md`. Copy each one to `~/.claude/skills/`:

```bash
cp -r claude-md      ~/.claude/skills/
cp -r code-review    ~/.claude/skills/
cp -r refactor       ~/.claude/skills/
cp -r doc-generator  ~/.claude/skills/
```

Verify:
```bash
ls ~/.claude/skills/
# Expected: claude-md  code-review  doc-generator  refactor
```

Make any shell scripts executable (if present):
```bash
find ~/.claude/skills/ -name "*.sh" -exec chmod +x {} \;
```

### Supporting Python Scripts

The Python scripts ship inside their skill directories and are invoked directly — no installation needed beyond copying the skill directory above.

```bash
# Verify a script is callable
python ~/.claude/skills/refactor/scripts/detect-smells.py --help
```

### Rules (CLAUDE.md)

This toolkit ships no global rules file. Use the `claude-md` skill to create or update your `~/.claude/CLAUDE.md`:

```
/claude-md create ~/.claude/CLAUDE.md
```

---

## Verify the Installation

Run the test suite after installing:

```bash
bash test/test.sh
```

A passing run looks like:

```
[1/4] claude-md ................ PASS
[2/4] code-review-specialist ... PASS
[3/4] code-refactor ............. PASS
[4/4] api-documentation-generator PASS

SUMMARY
  PASS: 4   FAIL: 0   SKIP: 0
Report written to ./testReport.log
```

Each skill is invoked via `claude --print` against a temporary git repo with realistic content. The test validates that Claude's output contains expected keywords for that skill type.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `SKILL.md missing` during install | Corrupted source directory | Re-clone or re-download the toolkit |
| Skill not triggering in Claude | SKILL.md not in `~/.claude/skills/<name>/SKILL.md` | Check path exactly — directory name must match |
| `claude: command not found` in test.sh | Claude Code CLI not on PATH | Add Claude Code install directory to PATH or run with full path |
| Test times out | `claude --print` blocked waiting for user input | The non-interactive preamble is prepended automatically; check that SKILL.md doesn't have an unguarded `AskUserQuestion` |
| Python script errors with `ModuleNotFoundError` | Trying to use a third-party library | All scripts use stdlib only; check you're running the right Python (`python3 --version`) |
