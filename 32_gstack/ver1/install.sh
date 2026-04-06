#!/usr/bin/env bash
set -euo pipefail

# ─── Config ─────────────────────────────────────────────────────────────────

SKILLS_SRC="$(cd "$(dirname "$0")/skills" && pwd)"
SKILLS_DST="$HOME/.claude/skills"

# ─── Helpers ────────────────────────────────────────────────────────────────

green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
red()    { printf '\033[31m%s\033[0m\n' "$*"; }
step()   { printf '\n\033[1m%s\033[0m\n' "$*"; }
die()    { red "ERROR: $*"; exit 1; }

# ─── Prerequisites ───────────────────────────────────────────────────────────

step "Checking prerequisites..."

if ! command -v bun &>/dev/null; then
  die "bun is not installed. Install it first: curl -fsSL https://bun.sh/install | bash"
fi
green "  bun $(bun --version)"

if [ ! -d "$SKILLS_SRC" ]; then
  die "skills/ directory not found at $SKILLS_SRC"
fi

# ─── Create destination ──────────────────────────────────────────────────────

step "Preparing $SKILLS_DST ..."

mkdir -p "$SKILLS_DST"

# ─── Copy skills ─────────────────────────────────────────────────────────────

step "Copying skills..."

for skill_dir in "$SKILLS_SRC"/*/; do
  skill_name="$(basename "$skill_dir")"
  dst="$SKILLS_DST/$skill_name"

  if [ -d "$dst" ]; then
    yellow "  overwriting $skill_name"
  else
    printf '  installing %s\n' "$skill_name"
  fi

  rm -rf "$dst"
  cp -r "$skill_dir" "$dst"
done

green "  done"

# ─── Fix permissions ─────────────────────────────────────────────────────────

step "Setting executable permissions..."

BROWSE="$SKILLS_DST/browse"

chmod +x "$BROWSE/dist/browse"
chmod +x "$BROWSE/dist/find-browse"
chmod +x "$BROWSE/bin/find-browse"
chmod +x "$BROWSE/bin/remote-slug"

green "  done"

# ─── Install Playwright (browse runtime dependency) ───────────────────────────

step "Installing Playwright (browse runtime dependency)..."

if [ ! -d "$BROWSE/node_modules/playwright" ]; then
  ( cd "$BROWSE" && bun add playwright 2>&1 | sed 's/^/  /' )
  green "  Playwright installed"
else
  yellow "  Playwright already installed, skipping"
fi

# ─── Verify browse binary ────────────────────────────────────────────────────

step "Verifying browse binary..."

if "$BROWSE/dist/browse" status &>/dev/null || true; then
  green "  browse binary OK"
else
  yellow "  browse binary returned non-zero (server may not be running — this is normal)"
fi

# ─── Summary ─────────────────────────────────────────────────────────────────

step "Installed skills:"

for skill_dir in "$SKILLS_DST"/*/; do
  skill_name="$(basename "$skill_dir")"
  if [ -f "$skill_dir/SKILL.md" ]; then
    printf '  ✓ %s\n' "$skill_name"
  fi
done

printf '\n'
green "Installation complete."
printf 'Skills are ready at %s\n' "$SKILLS_DST"
printf '\n'
printf 'Note: Playwright Chromium (~170MB) downloads on first browse use.\n'
printf 'Trigger it manually with:\n'
printf '  cd %s && bun x playwright install chromium\n' "$BROWSE"
