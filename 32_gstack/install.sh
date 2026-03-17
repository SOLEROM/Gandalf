#!/usr/bin/env bash
# gstack host installation (run once per machine)
## deps: curl -fsSL https://bun.com/install | bash
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
GSTACK_DIR="$ROOT/gstack"
BROWSE_BIN="$GSTACK_DIR/browse/dist/browse"

echo "== gstack install (host) =="

cd "$GSTACK_DIR"

# 1. deps
if [ ! -d "node_modules" ]; then
  echo "[1/4] Installing dependencies..."
  bun install
else
  echo "[1/4] Dependencies already installed"
fi

# 2. build browse
NEEDS_BUILD=0
if [ ! -x "$BROWSE_BIN" ]; then
  NEEDS_BUILD=1
elif find "$GSTACK_DIR/browse/src" -type f -newer "$BROWSE_BIN" | grep -q .; then
  NEEDS_BUILD=1
elif [ "$GSTACK_DIR/package.json" -nt "$BROWSE_BIN" ]; then
  NEEDS_BUILD=1
elif [ -f "$GSTACK_DIR/bun.lock" ] && [ "$GSTACK_DIR/bun.lock" -nt "$BROWSE_BIN" ]; then
  NEEDS_BUILD=1
fi

if [ "$NEEDS_BUILD" -eq 1 ]; then
  echo "[2/4] Building browse binary..."
  bun run build
else
  echo "[2/4] Browse binary up to date"
fi

if [ ! -x "$BROWSE_BIN" ]; then
  echo "ERROR: browse binary missing at $BROWSE_BIN"
  exit 1
fi

# 3. playwright
echo "[3/4] Ensuring Playwright Chromium..."
bunx playwright install chromium >/dev/null 2>&1 || true

# verify
if ! bun --eval 'import { chromium } from "playwright"; const b = await chromium.launch(); await b.close();'; then
  echo "ERROR: Playwright Chromium failed to launch"
  exit 1
fi

# 4. global dir
echo "[4/4] Creating global state..."
mkdir -p "$HOME/.gstack/projects"

echo ""
echo "Install complete."
echo "Browse binary:"
echo "  $BROWSE_BIN"