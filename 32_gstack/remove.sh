#!/usr/bin/env bash
# Remove gstack from project

set -e

TARGET="${1:-.}"
TARGET="$(cd "$TARGET" && pwd)"

LINK="$TARGET/.claude/skills/gstack"

if [ -L "$LINK" ]; then
  rm "$LINK"
  echo "Removed $LINK"
else
  echo "Nothing to remove"
fi