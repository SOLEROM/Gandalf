#!/usr/bin/env bash
# ECC Toolkit — Unattended Skill Test Runner
# Usage: bash test/test.sh [skill-filter...] [--help] [-d]
# Env:   VERBOSE=1  — print full Claude output on failure
#        TIMEOUT=N  — per-skill timeout in seconds (default 120)

set -euo pipefail

# ── Color helpers ────────────────────────────────────────────────────────────
green()  { printf '\033[0;32m%s\033[0m' "$*"; }
red()    { printf '\033[0;31m%s\033[0m' "$*"; }
yellow() { printf '\033[0;33m%s\033[0m' "$*"; }
bold()   { printf '\033[1m%s\033[0m\n' "$*"; }
dim()    { printf '\033[2m%s\033[0m' "$*"; }

# ── Config ───────────────────────────────────────────────────────────────────
TIMEOUT=${TIMEOUT:-120}
VERBOSE=${VERBOSE:-0}
REPORT="$(pwd)/testReport.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DEBUG=0

# ── Non-interactive preamble (prepended to every prompt) ────────────────────
read -r -d '' NI_PREAMBLE << 'PREAMBLE' || true
IMPORTANT: You are running in non-interactive automated test mode.
- Do NOT call AskUserQuestion under any circumstances.
- Make all decisions autonomously without asking for confirmation.
- When a skill offers mode options, choose SMALL CHANGE / quick mode automatically.
- Produce the output as if the user had already answered all questions.
- Keep your response concise and focused on demonstrating the skill's core output.

PREAMBLE

# ── Skill definitions ────────────────────────────────────────────────────────
# Format: SKILLS[name]="description|prompt|validation_regex"
declare -A SKILLS
declare -a SKILL_ORDER   # preserve insertion order for --help

_add_skill() {
  local name="$1" desc="$2" prompt="$3" regex="$4"
  SKILLS["$name"]="$desc|$prompt|$regex"
  SKILL_ORDER+=("$name")
}

_add_skill "tdd" \
  "tdd-workflow — Write tests before implementing" \
  "I'm about to implement sendNotification(userId, message) in notifications.ts. Apply the TDD workflow: write the test file first with describe/it blocks, then scaffold the minimal implementation. Show failing tests first, then the implementation." \
  "describe|it\(|expect|test|beforeEach|coverage|implement"

_add_skill "api-design" \
  "api-design — Design REST endpoints for a resource" \
  "Design two REST endpoints: POST /api/v1/users/:id/notifications (send) and GET /api/v1/users/:id/notifications (list with pagination). Review them against REST API design best practices and show the response envelopes." \
  "201|pagination|cursor|envelope|status.code|error.schema|resource|endpoint"

_add_skill "coding-standards" \
  "coding-standards — Review code for naming and type conventions" \
  "Review this function stub against coding standards: 'export async function sendNotification(userId, message) { }'. What type annotations, return types, and naming fixes are needed?" \
  "string|Promise|return type|annotation|camelCase|async|type|convention"

_add_skill "backend" \
  "backend-patterns — Choose async delivery architecture" \
  "Should sendNotification be synchronous in the request handler or use a background queue? Recommend the best backend pattern for a small Node.js API and show a code example." \
  "queue|event|emit|async|pattern|trade.off|synchronous|background|EventEmitter|BullMQ"

_add_skill "frontend" \
  "frontend-patterns — Plan a NotificationBell React component" \
  "I need a NotificationBell React component that fetches unread count on mount, shows a badge, and marks all as read on click. What React patterns should I use? Show the custom hook and component structure." \
  "useState|useEffect|hook|component|optimistic|badge|props|React|fetch"

_add_skill "e2e" \
  "e2e-testing — Write Playwright tests for a notification flow" \
  "Write Playwright E2E tests for: (1) user sees notification badge, (2) user clicks bell and list appears, (3) user clicks mark-all-read and badge clears. Use data-testid selectors." \
  "test\.|expect|page\.|locator|beforeEach|Playwright|data-testid|await"

_add_skill "ai-regression" \
  "ai-regression-testing — Regression strategy for AI-written code" \
  "The sendNotification function was written by Claude. Design a regression testing strategy that guards against AI blind spots, including cross-model review and sandbox testing." \
  "regression|blind.spot|cross.model|sandbox|boundary|AI|pass@|strategy|mock"

_add_skill "eval-harness" \
  "eval-harness — Create a pass@k eval for sendNotification" \
  "Create a minimal eval harness for sendNotification that measures pass@3 reliability across three inputs: valid user, missing userId, and empty message. Show the eval cases table and result schema." \
  "pass@|eval|case|schema|reliability|criteria|model|result|score"

_add_skill "mcp" \
  "mcp-server-patterns — Scaffold a send_notification MCP tool" \
  "Show me how to create a minimal MCP server tool called send_notification that takes userId and message as string parameters using the Node.js MCP SDK with Zod validation and stdio transport." \
  "McpServer|tool|z\.string|stdio|transport|sdk|mcp|server|zod|Zod"

_add_skill "iterative-retrieval" \
  "iterative-retrieval — Progressive context retrieval for a subagent" \
  "I want to spawn a subagent to write integration tests for the notifications module. How should I use iterative retrieval to give it just enough context across retrieval phases without overwhelming it?" \
  "phase|retrieval|context|budget|broad|narrow|subagent|token|progressive"

_add_skill "verification" \
  "verification-loop — Run pre-PR verification phases" \
  "Run the full verification loop on a feature branch before opening a PR. Show Build, Types, Lint, Tests, Security, and Diff phases with PASS/FAIL status and a final READY/NOT READY verdict." \
  "PASS|FAIL|Build|Types|Lint|Tests|Security|Diff|READY|NOT READY|VERIFICATION"

_add_skill "compact" \
  "strategic-compact — Decide when to compact context" \
  "I've finished implementing and testing the notifications feature. Should I compact context before writing the CHANGELOG and opening the PR? Show what survives compaction and suggest the compact message." \
  "compact|phase|transition|survives|CLAUDE\.md|git|implementation|recommend"

_add_skill "stocktake" \
  "skill-stocktake — Audit installed skills for quality" \
  "Audit the skills in this toolkit directory for quality. List each skill found, evaluate whether it has a clear trigger, actionable content, and no overlapping scope. Produce a quality score per skill." \
  "score|audit|skill|quality|trigger|checklist|stocktake|scan|overlap"

_add_skill "continuous-learning" \
  "continuous-learning — Extract reusable patterns from a session" \
  "Extract reusable patterns from this session for the continuous learning skill. We learned: optimistic UI updates for notifications, pass@k eval design, and that AI regression testing needs cross-model review. Format each as name/context/solution." \
  "pattern|context|solution|extract|learning|reusable|destination|skill"

# ── Help ─────────────────────────────────────────────────────────────────────
show_help() {
  bold "ECC Toolkit — Skill Test Runner"
  echo
  echo "Usage:  bash test/test.sh [skill-filter...] [options]"
  echo "        Runs all skills by default. Pass one or more skill keys to filter."
  echo
  bold "Testable Skills:"
  local i=1
  for name in "${SKILL_ORDER[@]}"; do
    IFS='|' read -r desc _ _ <<< "${SKILLS[$name]}"
    printf "  %2d. %-20s %s\n" "$i" "$name" "$desc"
    ((i++))
  done
  echo
  bold "Options:"
  echo "  --help, -h     Show this help"
  echo "  -d, --debug    Print workdir, command, and prompt before each run"
  echo
  bold "Environment:"
  echo "  VERBOSE=1      Print full Claude output on failure (default: 0)"
  echo "  TIMEOUT=N      Per-skill timeout in seconds (default: 120)"
  echo
  bold "Examples:"
  echo "  bash test/test.sh                  # run all skills"
  echo "  bash test/test.sh tdd api-design   # run only these two"
  echo "  VERBOSE=1 bash test/test.sh        # verbose failure output"
  echo "  TIMEOUT=180 bash test/test.sh      # longer timeout"
  echo "  bash test/test.sh -d tdd           # debug mode for tdd"
}

# ── Parse args ───────────────────────────────────────────────────────────────
FILTERS=()
for arg in "$@"; do
  case "$arg" in
    --help|-h) show_help; exit 0 ;;
    -d|--debug) DEBUG=1 ;;
    *) FILTERS+=("$arg") ;;
  esac
done

# ── Platform detection ───────────────────────────────────────────────────────
IS_MACOS=0
[[ "$(uname)" == "Darwin" ]] && IS_MACOS=1

# ── Auto-install check ───────────────────────────────────────────────────────
FIRST_SKILL="${SKILL_ORDER[0]}"
if [[ ! -f "$HOME/.claude/skills/$FIRST_SKILL/SKILL.md" ]]; then
  if [[ -f "$TOOLKIT_DIR/install.sh" ]]; then
    echo "$(yellow "Skills not found at ~/.claude/skills/. Running install.sh...")"
    bash "$TOOLKIT_DIR/install.sh"
  else
    echo "$(yellow "Warning: skills not installed and no install.sh found. Tests may fail.")"
    echo "$(dim "  Run: bash $TOOLKIT_DIR/install.md manually, then re-run tests.")"
  fi
fi

# ── Temp repo setup ──────────────────────────────────────────────────────────
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

(
  cd "$WORKDIR"
  git init -q
  git config user.email "test@ecc-toolkit.local"
  git config user.name "ECC Test Runner"

  # Initial commit — baseline
  echo "# Taskr API" > README.md
  echo "1.0.0" > VERSION
  cat > CHANGELOG.md << 'EOF'
# Changelog

## [1.0.0] - 2026-01-01
- Initial release
EOF
  mkdir -p src tests
  cat > src/users.ts << 'EOF'
export async function getUserById(id: string): Promise<{ id: string; name: string } | null> {
  if (!id) throw new Error("userId required")
  return { id, name: "Test User" }
}
EOF
  cat > tests/users.test.ts << 'EOF'
import { getUserById } from "../src/users"

describe("getUserById", () => {
  it("returns a user for valid id", async () => {
    const user = await getUserById("u1")
    expect(user).toEqual({ id: "u1", name: "Test User" })
  })
  it("throws for empty id", async () => {
    await expect(getUserById("")).rejects.toThrow("userId required")
  })
})
EOF
  git add -A
  git commit -q -m "Initial commit: users module with tests"

  # Feature branch commit — notifications stub
  git checkout -q -b feat/user-notifications
  cat > src/notifications.ts << 'EOF'
export async function sendNotification(userId, message) {
  // TODO: implement
}
EOF
  git add src/notifications.ts
  git commit -q -m "feat: add notifications stub (no tests yet)"
)

# ── Report init ───────────────────────────────────────────────────────────────
{
  echo "=========================================="
  echo "ECC Toolkit Test Report"
  echo "Run: $(date)"
  echo "Workdir: $WORKDIR"
  echo "=========================================="
  echo
} > "$REPORT"

# ── Counters ─────────────────────────────────────────────────────────────────
PASS=0
FAIL=0
SKIP=0
declare -a SUMMARY_LINES

# ── Runner ────────────────────────────────────────────────────────────────────
run_skill() {
  local name="$1"
  IFS='|' read -r desc prompt regex <<< "${SKILLS[$name]}"

  # Apply filter
  if [[ ${#FILTERS[@]} -gt 0 ]]; then
    local matched=0
    for f in "${FILTERS[@]}"; do
      [[ "$name" == *"$f"* ]] && matched=1 && break
    done
    [[ $matched -eq 0 ]] && return
  fi

  # Skip macOS-only skills on Linux
  if [[ $IS_MACOS -eq 0 ]] && [[ "$name" == "setup-browser-cookies" ]]; then
    printf "  %-22s %s" "$name" "$(yellow "[SKIP] macOS only")"
    SUMMARY_LINES+=("SKIP  $name — macOS only")
    ((SKIP++))
    return
  fi

  printf "  %-22s " "$name"

  local full_prompt="${NI_PREAMBLE}${prompt}"

  if [[ $DEBUG -eq 1 ]]; then
    echo
    dim "  workdir: $WORKDIR"
    dim "  command: claude --print --dangerously-skip-permissions"
    dim "  prompt:"
    echo "$full_prompt" | head -6 | while IFS= read -r line; do dim "    $line"; done
  fi

  local output
  local exit_code=0
  output=$(cd "$WORKDIR" && timeout "$TIMEOUT" claude --print --dangerously-skip-permissions "$full_prompt" 2>&1) || exit_code=$?

  local status
  if [[ $exit_code -eq 124 ]]; then
    status="TIMEOUT"
  elif echo "$output" | grep -qiE "$regex"; then
    status="PASS"
  else
    status="FAIL"
  fi

  case "$status" in
    PASS)
      printf "%s" "$(green "[PASS]")"
      ((PASS++))
      SUMMARY_LINES+=("PASS  $name")
      ;;
    FAIL)
      printf "%s" "$(red "[FAIL]")"
      ((FAIL++))
      SUMMARY_LINES+=("FAIL  $name")
      if [[ $VERBOSE -eq 1 ]]; then
        echo
        dim "  --- Claude output ---"
        echo "$output" | sed 's/^/  /'
        dim "  --- end output ---"
        echo
      fi
      ;;
    TIMEOUT)
      printf "%s" "$(yellow "[TIMEOUT after ${TIMEOUT}s]")"
      ((FAIL++))
      SUMMARY_LINES+=("FAIL  $name — timeout after ${TIMEOUT}s")
      ;;
  esac

  # Write to report
  {
    echo "------------------------------------------"
    echo "Skill: $name"
    echo "Desc:  $desc"
    echo "Status: $status"
    echo "--- Claude output ---"
    echo "$output"
    echo "--- end output ---"
    echo
  } >> "$REPORT"
}

# ── Main ──────────────────────────────────────────────────────────────────────
echo
bold "ECC Toolkit — Skill Test Runner"
echo "$(dim "Workdir: $WORKDIR")"
echo "$(dim "Timeout: ${TIMEOUT}s per skill | Verbose: $VERBOSE")"
echo

for name in "${SKILL_ORDER[@]}"; do
  run_skill "$name"
done

# ── Summary ───────────────────────────────────────────────────────────────────
echo
bold "Results:"
for line in "${SUMMARY_LINES[@]}"; do
  case "${line:0:4}" in
    PASS) echo "  $(green "✓") ${line#PASS  }" ;;
    FAIL) echo "  $(red   "✗") ${line#FAIL  }" ;;
    SKIP) echo "  $(yellow "-") ${line#SKIP  }" ;;
  esac
done

TOTAL=$((PASS + FAIL + SKIP))
echo
printf "%s  %s  %s  (total: %s)" \
  "$(green "${PASS} passed")" \
  "$(red "${FAIL} failed")" \
  "$(yellow "${SKIP} skipped")" \
  "$TOTAL"

{
  echo "=========================================="
  echo "SUMMARY"
  echo "=========================================="
  for line in "${SUMMARY_LINES[@]}"; do
    echo "$line"
  done
  echo
  echo "PASS: $PASS  FAIL: $FAIL  SKIP: $SKIP  TOTAL: $TOTAL"
  echo "Generated: $(date)"
} >> "$REPORT"

echo
echo "Report written to $REPORT"

[[ $FAIL -eq 0 ]]
