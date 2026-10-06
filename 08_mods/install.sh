#!/usr/bin/env bash
# Installs every mod in this folder into Claude Code on the current host.
#
# This folder is a local plugin marketplace ("gandalf-mods"). Every subfolder that has
# .claude-plugin/plugin.json is a mod; .claude-plugin/marketplace.json is regenerated
# from them on each run, so adding a mod = dropping a folder here and re-running.
#
# The mods are copied to ~/.claude/mods/gandalf-mods and installed from there, so this
# folder can be moved or deleted afterwards. After editing a mod, re-run this to push it.
#
# Usage: ./install.sh            install all mods (safe to re-run)
#        ./install.sh <mod>...   only these mods
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARKET=gandalf-mods
ONLY=()
for a in "$@"; do
  case "$a" in
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) ONLY+=("$a") ;;
  esac
done

command -v claude >/dev/null || { echo "claude CLI not found" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }

# 1. Regenerate the marketplace manifest from the mod folders.
mkdir -p "$ROOT/.claude-plugin"
plugins='[]'
for manifest in "$ROOT"/*/.claude-plugin/plugin.json; do
  [ -f "$manifest" ] || continue
  dir="$(basename "$(dirname "$(dirname "$manifest")")")"
  plugins="$(jq --arg src "./$dir" --slurpfile p "$manifest" \
    '. + [{name: $p[0].name, description: ($p[0].description // ""), version: ($p[0].version // "0.0.0"), source: $src}]' \
    <<<"$plugins")"
done
jq -n --arg name "$MARKET" --argjson plugins "$plugins" \
  '{name: $name, description: "Personal Claude Code mods", owner: {name: "vladSolov"}, plugins: $plugins}' \
  > "$ROOT/.claude-plugin/marketplace.json"
claude plugin validate "$ROOT" >/dev/null

# 2. Copy the mods to a host-owned location, so nothing points back at this folder.
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/mods/$MARKET"
mkdir -p "$DEST"
rsync -a --delete --exclude .git --exclude node_modules --exclude install.sh "$ROOT/" "$DEST/"

# 3. Register (or refresh) the marketplace from that copy.
registered="$(claude plugin marketplace list --json | jq -r --arg n "$MARKET" '.[] | select(.name == $n) | .path // ""')"
if [ -n "$registered" ] && [ "$registered" != "$DEST" ]; then
  claude plugin marketplace remove "$MARKET" # registered from another path (e.g. an older install): re-point it
  registered=""
fi
if [ -n "$registered" ]; then
  claude plugin marketplace update "$MARKET"
else
  claude plugin marketplace add "$DEST"
fi

# 4. Install or update each mod.
installed="$(claude plugin list --json | jq -r '.[].id')"
for name in $(jq -r '.plugins[].name' "$ROOT/.claude-plugin/marketplace.json"); do
  if [ ${#ONLY[@]} -gt 0 ] && [[ ! " ${ONLY[*]} " == *" $name "* ]]; then continue; fi
  id="$name@$MARKET"
  if grep -qx "$id" <<<"$installed"; then
    claude plugin update "$id"
  else
    claude plugin install "$id"
  fi
done

echo "Done. Restart Claude Code to load the mods."
