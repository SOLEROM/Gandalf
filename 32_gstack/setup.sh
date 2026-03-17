#!/usr/bin/env bash
# Link gstack skills into a target project (flat + prefixed)
# Usage: ./setup.sh /path/to/project

set -e

if [ $# -ne 1 ]; then
  echo "Usage: $0 <target-project-path>"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GSTACK_DIR="$SCRIPT_DIR/gstack"
TARGET_PROJECT="$(cd "$1" && pwd)"

SKILLS_DIR="$TARGET_PROJECT/.claude/skills"
BROWSE_BIN="$GSTACK_DIR/browse/dist/browse"

echo "== gstack setup =="
echo "Repo:   $GSTACK_DIR"
echo "Target: $TARGET_PROJECT"

# --- sanity checks ---
if [ ! -d "$GSTACK_DIR" ]; then
  echo "ERROR: gstack directory not found"
  exit 1
fi

if [ ! -x "$BROWSE_BIN" ]; then
  echo "ERROR: browse binary missing"
  echo "Run first: ./install.sh"
  exit 1
fi

mkdir -p "$SKILLS_DIR"

linked=()

# --- link each skill ---
for dir in "$GSTACK_DIR"/*/; do
  # Only directories with SKILL.md are valid skills
  [ -f "$dir/SKILL.md" ] || continue

  name="$(basename "$dir")"
  link_name="gstack-$name"
  link_path="$SKILLS_DIR/$link_name"

  # handle existing
  if [ -L "$link_path" ]; then
    rm "$link_path"
  elif [ -e "$link_path" ]; then
    echo "Skipping $link_name (exists and not a symlink)"
    continue
  fi

  ln -s "$dir" "$link_path"
  linked+=("$link_name")
  echo "Linked $link_name -> $dir"
done

echo ""

if [ ${#linked[@]} -eq 0 ]; then
  echo "WARNING: no skills found (no SKILL.md files)"
else
  echo "Done. Available skills:"
  for s in "${linked[@]}"; do
    echo "  $s"
  done
fi