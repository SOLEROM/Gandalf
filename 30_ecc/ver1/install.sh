#!/usr/bin/env bash
# install.sh — Install ECC toolkit into a running Claude Code instance
# Usage: bash install.sh [--no-rules] [--no-mcp]

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
red()    { printf '\033[31m%s\033[0m\n' "$*"; }
bold()   { printf '\033[1m%s\033[0m\n' "$*"; }
dim()    { printf '\033[2m%s\033[0m\n' "$*"; }

# ── Resolve source directory (where this script lives) ───────────────────────
ECC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Flags ─────────────────────────────────────────────────────────────────────
INSTALL_RULES=true
INSTALL_MCP=false   # off by default — requires manual token placeholders

for arg in "$@"; do
  case "$arg" in
    --no-rules) INSTALL_RULES=false ;;
    --mcp)      INSTALL_MCP=true ;;
    --help|-h)
      echo "Usage: bash install.sh [options]"
      echo ""
      echo "Options:"
      echo "  --no-rules   Skip appending rules to ~/.claude/CLAUDE.md"
      echo "  --mcp        Also show MCP server config (manual step — tokens required)"
      echo "  --help       Show this help"
      exit 0
      ;;
  esac
done

# ── Prerequisites ─────────────────────────────────────────────────────────────
bold "=== ECC Toolkit Installer ==="
dim "Source: $ECC_DIR"
echo ""

if ! command -v claude &>/dev/null; then
  red "ERROR: 'claude' CLI not found. Install Claude Code first."
  exit 1
fi

# ── Step 1: Agents ────────────────────────────────────────────────────────────
bold "Step 1/5 — Agents"
mkdir -p ~/.claude/agents
cp "$ECC_DIR"/agents/*.md ~/.claude/agents/
count=$(ls "$ECC_DIR"/agents/*.md | wc -l)
green "  Copied $count agent definitions → ~/.claude/agents/"

# ── Step 2: Commands ──────────────────────────────────────────────────────────
bold "Step 2/5 — Commands"
mkdir -p ~/.claude/commands
cp "$ECC_DIR"/commands/*.md ~/.claude/commands/
count=$(ls "$ECC_DIR"/commands/*.md | wc -l)
green "  Copied $count commands → ~/.claude/commands/"

# ── Step 3: Skills ────────────────────────────────────────────────────────────
bold "Step 3/5 — Skills"
mkdir -p ~/.claude/skills

SKILLS=(
  ai-regression-testing
  api-design
  backend-patterns
  coding-standards
  configure-ecc
  continuous-learning
  continuous-learning-v2
  e2e-testing
  eval-harness
  frontend-patterns
  iterative-retrieval
  mcp-server-patterns
  plankton-code-quality
  project-guidelines-example
  skill-stocktake
  strategic-compact
  tdd-workflow
  verification-loop
)

for skill in "${SKILLS[@]}"; do
  src="$ECC_DIR/skills/$skill"
  if [[ -d "$src" ]]; then
    rm -rf ~/.claude/skills/"$skill"
    cp -r "$src" ~/.claude/skills/
    dim "  + $skill"
  else
    yellow "  WARNING: skill directory not found: $src"
  fi
done

# Make continuous-learning scripts executable
if [[ -f ~/.claude/skills/continuous-learning/evaluate-session.sh ]]; then
  chmod +x ~/.claude/skills/continuous-learning/evaluate-session.sh
fi
if [[ -d ~/.claude/skills/continuous-learning-v2 ]]; then
  find ~/.claude/skills/continuous-learning-v2 -name "*.sh" -exec chmod +x {} \;
fi

count=$(ls ~/.claude/skills/ | wc -l)
green "  Installed $count skill packs → ~/.claude/skills/"

# ── Step 4: Rules ─────────────────────────────────────────────────────────────
bold "Step 4/5 — Rules"
if [[ "$INSTALL_RULES" == "true" ]]; then
  mkdir -p "$HOME/.claude/rules"
  rm -rf "$HOME/.claude/rules/common"
  cp -r "$ECC_DIR/rules/common" "$HOME/.claude/rules/common"
  count=$(ls "$ECC_DIR/rules/common/"*.md | wc -l)
  green "  Copied $count rule files → ~/.claude/rules/common/"
else
  dim "  Skipped (--no-rules)"
fi

# ── Step 5: Hooks ─────────────────────────────────────────────────────────────
bold "Step 5/5 — Hooks"

# 5a: Copy scripts to ~/.claude/scripts (sets CLAUDE_PLUGIN_ROOT = ~/.claude)
ECC_SCRIPTS_DEST="$HOME/.claude"
rm -rf "$ECC_SCRIPTS_DEST/scripts"
cp -r "$ECC_DIR/scripts" "$ECC_SCRIPTS_DEST/scripts"
green "  Copied scripts/ → ~/.claude/scripts/"

# 5b: Merge hooks/hooks.json into ~/.claude/settings.json
#     Replace ${CLAUDE_PLUGIN_ROOT} with the actual install path so no env var is needed
SETTINGS="$HOME/.claude/settings.json"
HOOKS_SRC="$ECC_DIR/hooks/hooks.json"

if ! command -v node &>/dev/null; then
  yellow "  WARNING: node not found — skipping hooks merge. Add hooks manually from hooks/hooks.json."
else
  node - "$SETTINGS" "$HOOKS_SRC" "$ECC_SCRIPTS_DEST" << 'NODEJS'
const fs = require('fs');
const [,, settingsPath, hooksSrc, pluginRoot] = process.argv;

const settings = fs.existsSync(settingsPath)
  ? JSON.parse(fs.readFileSync(settingsPath, 'utf8'))
  : {};

const incoming = JSON.parse(
  fs.readFileSync(hooksSrc, 'utf8').replace(/\$\{CLAUDE_PLUGIN_ROOT\}/g, pluginRoot)
);

// Merge: for each hook event, append entries not already present (match on description)
const merged = { ...settings };
merged.hooks = merged.hooks || {};
for (const [event, entries] of Object.entries(incoming.hooks || {})) {
  merged.hooks[event] = merged.hooks[event] || [];
  const existing = new Set(merged.hooks[event].map(e => e.description));
  for (const entry of entries) {
    if (!existing.has(entry.description)) {
      merged.hooks[event].push(entry);
    }
  }
}

fs.writeFileSync(settingsPath, JSON.stringify(merged, null, 2) + '\n');
NODEJS
  green "  Merged hooks → ~/.claude/settings.json"
fi

# ── MCP Servers (optional) ────────────────────────────────────────────────────
if [[ "$INSTALL_MCP" == "true" ]]; then
  bold "MCP Servers (manual step)"
  echo ""
  echo "Add to ~/.claude.json under \"mcpServers\":"
  echo ""
  cat << 'MCPEOF'
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp", "--browser", "chrome"]
    }
  }
}
MCPEOF
  echo ""
  yellow "  Replace token placeholders before adding GitHub or other API-key servers."
fi

# ── Verification ──────────────────────────────────────────────────────────────
echo ""
bold "=== Verification ==="

pass=0; fail=0

check() {
  local label="$1"; local cmd="$2"
  if eval "$cmd" &>/dev/null; then
    green "  [OK] $label"
    pass=$((pass + 1))
  else
    red "  [FAIL] $label"
    fail=$((fail + 1))
  fi
}

check "Agents installed"   "ls ~/.claude/agents/architect.md"
check "Commands installed" "ls ~/.claude/commands/*.md"
check "tdd-workflow skill" "ls ~/.claude/skills/tdd-workflow/SKILL.md"
check "api-design skill"   "ls ~/.claude/skills/api-design/SKILL.md"
check "verification-loop"  "ls ~/.claude/skills/verification-loop/SKILL.md"
check "Scripts installed"  "ls ~/.claude/scripts/hooks/session-start.js"
check "Hooks in settings"  "grep -q 'block-no-verify' ~/.claude/settings.json"
if [[ "$INSTALL_RULES" == "true" ]]; then
  check "Rules dir" "ls ~/.claude/rules/common/coding-style.md"
fi

echo ""
if [[ $fail -eq 0 ]]; then
  green "All checks passed ($pass/$((pass+fail))). ECC toolkit is ready."
  echo ""
  dim "Quick test: open a Claude Code session and run:  /plan add a simple health-check endpoint"
else
  red "$fail check(s) failed. Review output above."
  exit 1
fi
