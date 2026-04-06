# gstack — Installation Guide

How to install gstack into a running Claude Code instance.

---

## Prerequisites

| Requirement | Check |
|-------------|-------|
| Claude Code CLI | `claude --version` |
| Bun ≥ 1.0 | `bun --version` |
| macOS (for cookie import) | `uname` = Darwin |
| Git | `git --version` |

If Bun is not installed:
```bash
curl -fsSL https://bun.sh/install | bash
```

---

## Step 1 — Copy skills into Claude Code

Each subdirectory under `skills/` is an independent skill. Copy them all into `~/.claude/skills/`:

```bash
cp -r /path/to/gstack/ver1/skills/* ~/.claude/skills/
```

Verify:
```bash
ls ~/.claude/skills/browse ~/.claude/skills/qa ~/.claude/skills/retro
# Expected: directories exist
```

---

## Step 2 — Install browser dependencies

The `browse` skill runs a Bun server at runtime and needs Playwright as a dependency. Install it inside the browse skill directory:

```bash
cd ~/.claude/skills/browse
bun init -y          # creates package.json if not present
bun add playwright
```

Verify:
```bash
ls ~/.claude/skills/browse/node_modules/playwright
# Expected: directory exists
```

> **Note:** Playwright's Chromium browser (~170MB) is downloaded to `~/.cache/ms-playwright/` the first time the browse server starts, not during `bun add`.

---

## Step 3 — Verify the browser binary

The compiled `browse` binary ships pre-built in `dist/`. Check it is present and executable:

```bash
ls -lh ~/.claude/skills/browse/dist/browse
# Expected: file exists, ~100MB

~/.claude/skills/browse/dist/browse status
# Expected: server not running (clean state)
```

If the binary is missing or fails, rebuild it (requires the full source tree with `package.json`):
```bash
cd ~/.claude/skills/browse
bun build --compile src/cli.ts --outfile dist/browse
```

---

## Step 4 — Make shell shims executable

```bash
chmod +x ~/.claude/skills/browse/bin/find-browse
chmod +x ~/.claude/skills/browse/bin/remote-slug
```

Verify:
```bash
~/.claude/skills/browse/bin/find-browse
# Expected: path to the browse binary
```

---

## Step 5 — Verify skills are visible to Claude Code

Claude Code loads every subdirectory of `~/.claude/skills/` that contains a `SKILL.md` as a skill.

```bash
ls ~/.claude/skills/*/SKILL.md
```

Expected (one line per skill):
```
~/.claude/skills/browse/SKILL.md
~/.claude/skills/plan-ceo-review/SKILL.md
~/.claude/skills/plan-eng-review/SKILL.md
~/.claude/skills/qa/SKILL.md
~/.claude/skills/retro/SKILL.md
~/.claude/skills/review/SKILL.md
~/.claude/skills/setup-browser-cookies/SKILL.md
~/.claude/skills/ship/SKILL.md
```

---

## Step 6 — Test the browser (optional but recommended)

```bash
~/.claude/skills/browse/dist/browse goto https://example.com
~/.claude/skills/browse/dist/browse text
~/.claude/skills/browse/dist/browse stop
```

Expected: page text from example.com, then clean shutdown.

---

## Agents, commands, rules, hooks, MCP

gstack ships none of these. No additional steps needed for those categories.

---

## Troubleshooting

### `bun: command not found`

Bun was not installed or not added to PATH. Re-run the install script and start a new shell:
```bash
curl -fsSL https://bun.sh/install | bash
source ~/.bashrc  # or ~/.zshrc
```

### `browse binary not found` / `NEEDS_SETUP`

The pre-built binary is missing. Rebuild:
```bash
cd ~/.claude/skills/browse
bun build --compile src/cli.ts --outfile dist/browse
```

### Chromium fails to launch

Playwright's Chromium is not yet downloaded. It downloads automatically on first use, or trigger it manually:
```bash
cd ~/.claude/skills/browse && bun x playwright install chromium
```

### `bun add playwright` fails with native module errors

gstack uses only Bun-native APIs. If you see gyp errors, they come from a transitive dependency not used at runtime. Ignore and proceed.

### Cookie import fails (macOS)

Keychain access requires macOS. On Linux, use `cookie-import` with a manually exported JSON file:
```bash
$B cookie-import /path/to/cookies.json
```

### Server fails to start / port in use

Check for a stale state file:
```bash
cat .gstack/browse.json
kill <pid from file>
rm .gstack/browse.json
```

Then retry. gstack will start a fresh server on the next command.
