#!/usr/bin/env bash

set -euo pipefail

SETTINGS_FILE="$HOME/.claude/settings.json"

################################################################################
# PRECHECKS
################################################################################

if ! command -v jq >/dev/null 2>&1; then
    echo "[ERROR] jq is required. Install with: sudo apt install jq"
    exit 1
fi

mkdir -p "$HOME/.claude"

# Create empty JSON if not exists
if [ ! -f "$SETTINGS_FILE" ]; then
    echo "{}" > "$SETTINGS_FILE"
fi

################################################################################
# UPDATE LOGIC (idempotent)
################################################################################

TMP_FILE="$(mktemp)"

jq '
    # ensure env exists
    if has("env") then . else . + {env: {}} end

    # ensure flag exists
    | if .env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS then
        .
      else
        .env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"
      end

    # ensure statusLine exists
    | if has("statusLine") then
        .
      else
        . + {
            statusLine: {
                type: "command",
                command: "bash ~/.claude/usage-statusline.sh"
            }
        }
      end
' "$SETTINGS_FILE" > "$TMP_FILE"

mv "$TMP_FILE" "$SETTINGS_FILE"

echo "[OK] settings.json updated safely"