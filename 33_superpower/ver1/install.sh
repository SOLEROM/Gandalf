#!/usr/bin/env bash
# install.sh — Superpowers Dev Toolkit installer
# Installs agents, commands, skills, and hooks into ~/.claude/
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"

# ── colors ────────────────────────────────────────────────────────────────────
red()    { printf '\033[0;31m%s\033[0m\n' "$*"; }
green()  { printf '\033[0;32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[0;33m%s\033[0m\n' "$*"; }
bold()   { printf '\033[1m%s\033[0m\n' "$*"; }
step()   { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
ok()     { green "    ✓ $*"; }
warn()   { yellow "    ! $*"; }

# ── pre-flight ────────────────────────────────────────────────────────────────
bold "Superpowers Dev Toolkit — Installer"
echo "Source : $SCRIPT_DIR"
echo "Target : $CLAUDE_DIR"

if [ ! -d "$CLAUDE_DIR" ]; then
  warn "~/.claude/ does not exist. Creating it now."
  mkdir -p "$CLAUDE_DIR"
fi

# ── 1. Agents ─────────────────────────────────────────────────────────────────
step "1/4  Agents"
mkdir -p "$CLAUDE_DIR/agents"
cp "$SCRIPT_DIR/agents/"*.md "$CLAUDE_DIR/agents/"
ok "$(ls "$SCRIPT_DIR/agents/"*.md | wc -l | tr -d ' ') agent(s) → ~/.claude/agents/"

# ── 2. Commands ───────────────────────────────────────────────────────────────
step "2/4  Commands"
mkdir -p "$CLAUDE_DIR/commands"
cp "$SCRIPT_DIR/commands/"*.md "$CLAUDE_DIR/commands/"
ok "$(ls "$SCRIPT_DIR/commands/"*.md | wc -l | tr -d ' ') command(s) → ~/.claude/commands/"

# ── 3. Skills ─────────────────────────────────────────────────────────────────
step "3/4  Skills"
mkdir -p "$CLAUDE_DIR/skills"
SKILL_COUNT=0
for dir in "$SCRIPT_DIR/skills/"/*/; do
  cp -r "$dir" "$CLAUDE_DIR/skills/"
  SKILL_COUNT=$((SKILL_COUNT + 1))
done
# Make shell scripts executable
chmod +x "$CLAUDE_DIR/skills/brainstorming/scripts/"*.sh 2>/dev/null || true
chmod +x "$CLAUDE_DIR/skills/systematic-debugging/find-polluter.sh" 2>/dev/null || true
ok "$SKILL_COUNT skill(s) → ~/.claude/skills/"

# ── 4. Hooks ──────────────────────────────────────────────────────────────────
step "4/4  Hooks"
mkdir -p "$CLAUDE_DIR/hooks"
cp "$SCRIPT_DIR/hooks/session-start" "$CLAUDE_DIR/hooks/session-start"
chmod +x "$CLAUDE_DIR/hooks/session-start"
ok "session-start → ~/.claude/hooks/"

HOOK_CMD="$CLAUDE_DIR/hooks/session-start"

# Build the hook JSON fragment (single SessionStart entry)
HOOK_FRAGMENT=$(cat <<JSON
{
  "SessionStart": [
    {
      "matcher": "startup|clear|compact",
      "hooks": [
        {
          "type": "command",
          "command": "$HOOK_CMD",
          "async": false
        }
      ]
    }
  ]
}
JSON
)

# Ensure settings.json exists
if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
  ok "Created ~/.claude/settings.json"
fi

# Merge hook entry — prefer python3, fall back to jq, else print manual steps
if command -v python3 &>/dev/null; then
  python3 - "$SETTINGS" "$HOOK_CMD" <<'PYEOF'
import sys, json

settings_path = sys.argv[1]
hook_cmd      = sys.argv[2]

with open(settings_path) as f:
    settings = json.load(f)

entry = {
    "matcher": "startup|clear|compact",
    "hooks": [{"type": "command", "command": hook_cmd, "async": False}]
}

hooks = settings.setdefault("hooks", {})
ss    = hooks.setdefault("SessionStart", [])

# Replace any existing entry with same command; otherwise append
replaced = False
for i, h in enumerate(ss):
    cmds = [x.get("command") for x in h.get("hooks", [])]
    if hook_cmd in cmds:
        ss[i] = entry
        replaced = True
        break
if not replaced:
    ss.append(entry)

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")
PYEOF
  ok "SessionStart hook merged into ~/.claude/settings.json (python3)"

elif command -v jq &>/dev/null; then
  MERGED=$(jq --argjson frag "$HOOK_FRAGMENT" \
    '.hooks.SessionStart = ($frag.SessionStart)' "$SETTINGS")
  echo "$MERGED" > "$SETTINGS"
  ok "SessionStart hook merged into ~/.claude/settings.json (jq)"
  warn "jq merge replaced any existing SessionStart entries — check settings.json if you had other hooks."

else
  warn "Neither python3 nor jq found. Add the hook manually to ~/.claude/settings.json:"
  echo ""
  echo '  "hooks": {'
  echo '    "SessionStart": ['
  echo '      {'
  echo '        "matcher": "startup|clear|compact",'
  echo '        "hooks": [{"type": "command", "command": "'"$HOOK_CMD"'", "async": false}]'
  echo '      }'
  echo '    ]'
  echo '  }'
  echo ""
fi

# ── summary ───────────────────────────────────────────────────────────────────
printf '\n'
bold "Done."
echo ""
printf "  %-12s %s\n" "agents:"   "$(ls "$CLAUDE_DIR/agents/"*.md   2>/dev/null | wc -l | tr -d ' ') file(s) in ~/.claude/agents/"
printf "  %-12s %s\n" "commands:" "$(ls "$CLAUDE_DIR/commands/"*.md  2>/dev/null | wc -l | tr -d ' ') file(s) in ~/.claude/commands/"
printf "  %-12s %s\n" "skills:"   "$(ls -d "$CLAUDE_DIR/skills/"*/  2>/dev/null | wc -l | tr -d ' ') dir(s)  in ~/.claude/skills/"
printf "  %-12s %s\n" "hooks:"    "session-start in ~/.claude/hooks/"
echo ""
echo "Verify: bash $SCRIPT_DIR/test/test.sh"
