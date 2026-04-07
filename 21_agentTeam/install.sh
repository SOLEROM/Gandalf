#!/usr/bin/env bash
set -euo pipefail

# Install script for agent-team Claude Code skill
# See README.md for details

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

# ── 1. Install tmux ──────────────────────────────────────────────────────────
if command -v tmux &>/dev/null; then
    echo "[ok] tmux already installed ($(tmux -V))"
else
    echo "[..] Installing tmux..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y tmux
    elif command -v brew &>/dev/null; then
        brew install tmux
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y tmux
    elif command -v yum &>/dev/null; then
        sudo yum install -y tmux
    else
        echo "[!!] Could not detect package manager. Install tmux manually and re-run."
        exit 1
    fi
    echo "[ok] tmux installed"
fi

# ── 2. Copy skill ────────────────────────────────────────────────────────────
SKILLS_DIR="${CLAUDE_DIR}/skills"
mkdir -p "${SKILLS_DIR}"

if [[ ! -d "${SCRIPT_DIR}/agent-team" ]]; then
    echo "[!!] agent-team directory not found at ${SCRIPT_DIR}/agent-team"
    exit 1
fi

cp -r "${SCRIPT_DIR}/agent-team" "${SKILLS_DIR}/"
echo "[ok] Skill copied to ${SKILLS_DIR}/agent-team"

# ── 3. Enable experimental agent teams in settings.json ─────────────────────
mkdir -p "${CLAUDE_DIR}"

if [[ ! -f "${SETTINGS_FILE}" ]]; then
    # Create minimal settings file
    cat > "${SETTINGS_FILE}" <<'EOF'
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
EOF
    echo "[ok] Created ${SETTINGS_FILE} with agent teams enabled"
else
    # Check if already enabled
    if grep -q "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" "${SETTINGS_FILE}"; then
        echo "[ok] CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS already present in settings.json"
    else
        # Use python3 to merge the key safely if available
        if command -v python3 &>/dev/null; then
            python3 - "${SETTINGS_FILE}" <<'PYEOF'
import json, sys

path = sys.argv[1]
with open(path) as f:
    cfg = json.load(f)

cfg.setdefault("env", {})["CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS"] = "1"

with open(path, "w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")

print(f"[ok] Patched {path}")
PYEOF
        else
            echo ""
            echo "[!!] python3 not found — add the following to ${SETTINGS_FILE} manually:"
            echo '      "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" }'
        fi
    fi
fi

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo "Installation complete. Usage:"
echo "  /agent-team <plan-path> [num-agents]"
echo ""
echo "Example:"
echo "  /agent-team ./plans/my-project.md 3"
