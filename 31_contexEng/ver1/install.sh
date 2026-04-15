#!/usr/bin/env bash
# install.sh — Deploy Context Engineering toolkit to Claude Code on this host
# Usage:
#   bash install.sh          # install everything
#   bash install.sh --dry-run # preview what would be installed

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }
fail() { echo -e "${RED}✗${NC} $*" >&2; }
bold() { echo -e "${BOLD}$*${NC}"; }

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    warn "Dry-run mode — no files will be written"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run() {
    if $DRY_RUN; then
        echo "  [would run] $*"
    else
        "$@"
    fi
}

# ─────────────────────────────────────────────
bold "\n=== Context Engineering Toolkit Installer ==="
echo ""

# Detect Claude Code
CLAUDE_DIR="$HOME/.claude"
if [[ ! -d "$CLAUDE_DIR" ]]; then
    warn "~/.claude not found — creating it (Claude Code may not be installed)"
    run mkdir -p "$CLAUDE_DIR"
fi

# ─── Commands ────────────────────────────────
bold "Installing commands..."
run mkdir -p "$CLAUDE_DIR/commands"
for f in "$SCRIPT_DIR/commands/"*.md; do
    name="$(basename "$f")"
    run cp "$f" "$CLAUDE_DIR/commands/$name"
    ok "  commands/$name"
done

# ─── Agents ──────────────────────────────────
bold "Installing agents..."
run mkdir -p "$CLAUDE_DIR/agents"
for f in "$SCRIPT_DIR/agents/"*.md; do
    name="$(basename "$f")"
    run cp "$f" "$CLAUDE_DIR/agents/$name"
    ok "  agents/$name"
done

# ─── Hooks ───────────────────────────────────
bold "Installing hooks..."
run mkdir -p "$CLAUDE_DIR/hooks"
run cp "$SCRIPT_DIR/hooks/log-tool-usage.sh" "$CLAUDE_DIR/hooks/log-tool-usage.sh"
if ! $DRY_RUN; then chmod +x "$CLAUDE_DIR/hooks/log-tool-usage.sh"; fi
ok "  hooks/log-tool-usage.sh (executable)"

# Hook config — merge only if no existing hooks key
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
if [[ ! -f "$SETTINGS_FILE" ]]; then
    run cp "$SCRIPT_DIR/hooks/example-hook-config.json" "$SETTINGS_FILE"
    ok "  settings.json (hook config installed)"
else
    warn "  $SETTINGS_FILE already exists — skipping (merge manually from hooks/example-hook-config.json)"
fi

# ─── PRP Templates ───────────────────────────
bold "Installing PRP templates..."
# Place inside project template directory (user copies to their project)
PRP_DEST="$CLAUDE_DIR/prp-templates"
run mkdir -p "$PRP_DEST"
run cp "$SCRIPT_DIR/prp-templates/prp_base.md" "$PRP_DEST/prp_base.md"
ok "  prp-templates/prp_base.md → ~/.claude/prp-templates/"

# ─── CLAUDE.md ───────────────────────────────
bold "Installing CLAUDE.md template..."
CLAUDEMD_DEST="$CLAUDE_DIR/CLAUDE.md.context-eng-template"
run cp "$SCRIPT_DIR/CLAUDE.md" "$CLAUDEMD_DEST"
ok "  CLAUDE.md template → ~/.claude/CLAUDE.md.context-eng-template"
warn "  To use: copy it to your project root or append to ~/.claude/CLAUDE.md"

# ─── INITIAL.md template ─────────────────────
bold "Installing INITIAL.md template..."
run cp "$SCRIPT_DIR/INITIAL.md" "$CLAUDE_DIR/INITIAL.md.template"
ok "  INITIAL.md template → ~/.claude/INITIAL.md.template"

# ─── Verification ────────────────────────────
echo ""
bold "=== Verification ==="
if ! $DRY_RUN; then
    PASS=true

    check() {
        if [[ -f "$1" ]]; then ok "$1"; else fail "MISSING: $1"; PASS=false; fi
    }

    check "$CLAUDE_DIR/commands/generate-prp.md"
    check "$CLAUDE_DIR/commands/execute-prp.md"
    check "$CLAUDE_DIR/commands/primer.md"
    check "$CLAUDE_DIR/commands/execute-parallel.md"
    check "$CLAUDE_DIR/commands/prep-parallel.md"
    check "$CLAUDE_DIR/commands/fix-github-issue.md"
    check "$CLAUDE_DIR/agents/documentation-manager.md"
    check "$CLAUDE_DIR/agents/validation-gates.md"
    check "$CLAUDE_DIR/hooks/log-tool-usage.sh"
    check "$CLAUDE_DIR/prp-templates/prp_base.md"

    echo ""
    if $PASS; then
        ok "All files installed successfully."
    else
        fail "Some files are missing. Re-run install.sh from the ver1/ directory."
        exit 1
    fi
fi

# ─── Next Steps ──────────────────────────────
echo ""
bold "=== Next Steps ==="
echo ""
echo "  1. Open a project in Claude Code"
echo "  2. Copy prp-templates/prp_base.md into your project's PRPs/templates/ folder"
echo "  3. Copy INITIAL.md to your project root and fill in your feature"
echo "  4. In Claude Code, run:"
echo "       /generate-prp INITIAL.md"
echo "     to create a comprehensive implementation blueprint (PRP)"
echo "  5. Then run:"
echo "       /execute-prp PRPs/your-feature.md"
echo "     to implement the feature"
echo ""
echo "  Available slash commands after install:"
echo "    /generate-prp   — research codebase and generate a PRP"
echo "    /execute-prp    — implement a PRP end-to-end with validation"
echo "    /primer         — prime Claude with project context"
echo "    /fix-github-issue — fix a GitHub issue and create a PR"
echo "    /prep-parallel  — set up parallel git worktrees"
echo "    /execute-parallel — run parallel agent implementations"
echo ""
echo "  See usage.md for full workflow guidance."
echo ""
