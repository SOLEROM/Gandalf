#!/usr/bin/env bash
# test.sh — unattended smoke test for gstack skills
# Runs each skill scenario from test.md using claude --print (non-interactive)
#
# Usage:
#   bash test/test.sh              # run all skills
#   bash test/test.sh browse qa    # run specific skills only
#   VERBOSE=1 bash test/test.sh    # show full claude output on failure

set -euo pipefail

# ─── Colors ──────────────────────────────────────────────────────────────────

green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
red()    { printf '\033[31m%s\033[0m\n' "$*"; }
bold()   { printf '\033[1m%s\033[0m\n' "$*"; }
dim()    { printf '\033[2m%s\033[0m\n' "$*"; }

# ─── Help ────────────────────────────────────────────────────────────────────

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  bold "Usage:"
  echo "  bash test/test.sh [skill...] [options]"
  echo ""
  bold "Available skills:"
  echo "  plan-eng-review       Architecture/edge-case plan review (Step 1)"
  echo "  plan-ceo-review       Scope challenge + expansion review (Step 2)"
  echo "  browse                Headless browser navigation (Step 3)"
  echo "  qa                    Diff-aware QA report with health score (Step 4)"
  if [[ "$(uname)" == "Darwin" ]]; then
  echo "  setup-browser-cookies Import real browser cookies into headless session (Step 5)"
  else
  echo "  setup-browser-cookies [macOS only — skipped on this platform] (Step 5)"
  fi
  echo "  review                Pre-landing PR review (Step 6)"
  echo "  ship                  Merge/test/version/changelog/PR workflow (Step 7)"
  echo "  retro                 Weekly engineering retrospective (Step 8)"
  echo ""
  bold "Options:"
  echo "  -d                    Debug mode — print the claude command before each run"
  echo "  VERBOSE=1             Show full claude output on failure"
  echo "  TIMEOUT=<secs>        Per-skill timeout in seconds (default: 120)"
  echo ""
  bold "Examples:"
  echo "  bash test/test.sh                      # run all skills"
  echo "  bash test/test.sh browse qa            # run specific skills"
  echo "  bash test/test.sh -d browse            # debug a stuck skill"
  echo "  VERBOSE=1 bash test/test.sh review     # verbose single skill"
  exit 0
fi

# ─── Config ──────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_SRC="$SCRIPT_DIR/skills"
SKILLS_DST="$HOME/.claude/skills"
VERBOSE="${VERBOSE:-0}"
TIMEOUT="${TIMEOUT:-120}"   # seconds per skill
DEBUG=0

# Parse flags and collect remaining args as skill filter
FILTER=()
for arg in "$@"; do
  if [[ "$arg" == "-d" || "$arg" == "--debug" ]]; then
    DEBUG=1
  else
    FILTER+=("$arg")
  fi
done

PASS=0
FAIL=0
SKIP=0
declare -a RESULTS=()

REPORT_FILE="./testReport.log"
# Start fresh each run
{
  echo "========================================"
  echo "  gstack skills test run"
  echo "  $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo "========================================"
  echo ""
} > "$REPORT_FILE"

log_report() {
  # log_report <skill> <status> <output>
  local skill="$1" status="$2" output="$3"
  {
    echo "----------------------------------------"
    printf '  %-28s %s\n' "$skill" "$status"
    echo "----------------------------------------"
    if [ -n "$output" ]; then
      echo "$output"
    fi
    echo ""
  } >> "$REPORT_FILE"
}

# ─── Feature plan (from test.md) ─────────────────────────────────────────────

read -r -d '' FEATURE_PLAN <<'EOF' || true
Feature: User Onboarding Flow

Goal: After signup, walk new users through 3 steps: (1) set display name,
(2) connect one integration, (3) invite a teammate. Progress is saved per step.
Users can skip and return. On completion, show a confetti animation and redirect
to dashboard.

Implementation:
- New OnboardingController with 3 action methods
- onboarding_progress column on users table (jsonb)
- Three view partials rendered in sequence
- JS for confetti via cdn.jsdelivr.net/npm/canvas-confetti

Out of scope: email reminders, analytics events, mobile layout
EOF

# Prepended to every prompt — suppresses AskUserQuestion blocking in --print mode
read -r -d '' NON_INTERACTIVE_PREAMBLE <<'EOF' || true
IMPORTANT: You are running in non-interactive automated test mode.
- Do NOT call AskUserQuestion under any circumstances.
- Make all decisions autonomously without asking for confirmation.
- When a skill offers mode options (e.g. SMALL CHANGE / BIG CHANGE / SCOPE REDUCTION), choose SMALL CHANGE automatically.
- Produce the output as if the user had already answered all questions.
EOF

# ─── Preflight checks ────────────────────────────────────────────────────────

bold "=== gstack skills smoke test ==="
echo ""

if ! command -v claude &>/dev/null; then
  red "ERROR: claude CLI not found. Install Claude Code first."
  exit 1
fi

# Install skills if not already installed
if [ ! -f "$SKILLS_DST/plan-eng-review/SKILL.md" ]; then
  bold "Installing skills..."
  bash "$SCRIPT_DIR/install.sh" 2>&1 | grep -E "(Installing|Copying|done|ERROR)" || true
  echo ""
fi

# Create isolated temp git repo for tests that read git state
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

(
  cd "$TMPDIR"
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"

  # Simulate a feature branch with some changes
  mkdir -p app/controllers
  printf '# App\n' > README.md
  printf '1.0.0\n' > VERSION
  printf '# Changelog\n\n## 1.0.0\n- Initial release\n' > CHANGELOG.md
  printf 'class OnboardingController\n  def show\n  end\nend\n' > app/controllers/onboarding_controller.rb
  git add .
  git commit -q -m "initial commit"

  # Add a change to simulate a feature branch diff
  printf 'class OnboardingController\n  def show\n  end\n  def complete\n    UserMailer.welcome(current_user).deliver_now\n    redirect_to dashboard_path\n  end\nend\n' > app/controllers/onboarding_controller.rb
  git add .
  git commit -q -m "add onboarding controller"
)

# ─── Helpers ─────────────────────────────────────────────────────────────────

should_run() {
  local skill="$1"
  if [ "${#FILTER[@]}" -eq 0 ]; then return 0; fi
  for f in "${FILTER[@]}"; do
    [[ "$f" == "$skill" ]] && return 0
  done
  return 1
}

run_skill() {
  local skill_name="$1"
  local prompt="$2"
  local check_pattern="$3"
  local workdir="${4:-$TMPDIR}"

  should_run "$skill_name" || return 0

  local full_prompt="$NON_INTERACTIVE_PREAMBLE

$prompt"

  printf '  %-28s ' "$skill_name"

  if [ "$DEBUG" = "1" ]; then
    printf '\n'
    dim "  [debug] workdir: $workdir"
    dim "  [debug] command: timeout $TIMEOUT claude --print --dangerously-skip-permissions <prompt>"
    dim "  [debug] prompt (preamble + skill prompt):"
    echo "$full_prompt" | sed 's/^/    /' | while IFS= read -r line; do dim "$line"; done
    printf '  %-28s ' "$skill_name"
  fi

  local output exit_code
  exit_code=0
  output=$(cd "$workdir" && timeout "$TIMEOUT" claude --print --dangerously-skip-permissions "$full_prompt" 2>&1) || exit_code=$?

  if [ $exit_code -eq 124 ]; then
    red "TIMEOUT (${TIMEOUT}s)"
    FAIL=$((FAIL + 1))
    RESULTS+=("FAIL  $skill_name (timeout after ${TIMEOUT}s)")
    log_report "$skill_name" "FAIL — timeout after ${TIMEOUT}s" ""
    return
  fi

  if [ $exit_code -ne 0 ]; then
    red "ERROR (exit $exit_code)"
    if [ "$VERBOSE" = "1" ]; then
      dim "--- output ---"
      echo "$output" | head -20
      dim "--- end ---"
    fi
    FAIL=$((FAIL + 1))
    RESULTS+=("FAIL  $skill_name (claude exit $exit_code)")
    log_report "$skill_name" "FAIL — claude exit $exit_code" "$output"
    return
  fi

  if echo "$output" | grep -qiE "$check_pattern"; then
    green "PASS"
    PASS=$((PASS + 1))
    RESULTS+=("PASS  $skill_name")
    log_report "$skill_name" "PASS" "$output"
  else
    red "FAIL (pattern not matched)"
    FAIL=$((FAIL + 1))
    RESULTS+=("FAIL  $skill_name (expected /$check_pattern/ in output)")
    log_report "$skill_name" "FAIL — pattern /$check_pattern/ not matched" "$output"
    if [ "$VERBOSE" = "1" ]; then
      dim "--- output (first 30 lines) ---"
      echo "$output" | head -30
      dim "--- end ---"
    else
      dim "  Re-run with VERBOSE=1 to see output"
    fi
  fi
}

skip_skill() {
  local skill_name="$1"
  local reason="$2"
  should_run "$skill_name" || return 0
  printf '  %-28s ' "$skill_name"
  yellow "SKIP ($reason)"
  SKIP=$((SKIP + 1))
  RESULTS+=("SKIP  $skill_name ($reason)")
  log_report "$skill_name" "SKIP — $reason" ""
}

# ─── Skill Tests ─────────────────────────────────────────────────────────────

bold "Running skill tests..."
echo ""

# Step 1 — plan-eng-review
run_skill "plan-eng-review" \
  "Use the plan-eng-review skill to review this plan. Choose SMALL CHANGE mode if asked.

$FEATURE_PLAN" \
  "architecture|scope|edge case|test|review"

# Step 2 — plan-ceo-review
run_skill "plan-ceo-review" \
  "Use the plan-ceo-review skill on this plan in SCOPE EXPANSION mode.

$FEATURE_PLAN" \
  "scope|challenge|10x|dream|expansion|delight|premise"

# Step 3 — browse (basic navigation)
run_skill "browse" \
  "Use the browse skill to test https://example.com — navigate to the page,
take a text snapshot, and report what you see." \
  "example\.com|snapshot|text|heading|navigate|goto|READY" \
  "$TMPDIR"

# Step 4 — qa (diff-aware on feature branch)
run_skill "qa" \
  "Run qa on this branch's changes. Use quick mode. The staging URL is https://example.com." \
  "QA|health|score|test|route|changed|smoke|quick" \
  "$TMPDIR"

# Step 5 — setup-browser-cookies (macOS only)
if [[ "$(uname)" == "Darwin" ]]; then
  run_skill "setup-browser-cookies" \
    "Use the setup-browser-cookies skill to show me what domains are available for cookie import." \
    "cookie|domain|picker|import|browser|localhost"
else
  skip_skill "setup-browser-cookies" "macOS only"
fi

# Step 6 — review (PR review)
run_skill "review" \
  "Use the review skill on this branch's changes before I land it." \
  "review|SQL|diff|side effect|struct|approved|TODOS|concern|safety" \
  "$TMPDIR"

# Step 7 — ship (dry run — describe steps only, no push)
run_skill "ship" \
  "Use the ship skill. List the steps you would take to ship this branch but do NOT
push or create a PR — describe the workflow and stop before executing any git push." \
  "merge|test|VERSION|CHANGELOG|bump|branch|PR|ship|push" \
  "$TMPDIR"

# Step 8 — retro
run_skill "retro" \
  "Use the retro skill to run the weekly retrospective for this repo." \
  "retro|commit|contributor|week|pattern|praise|velocity|engineering"

# ─── Summary ─────────────────────────────────────────────────────────────────

echo ""
bold "=== Results ==="
echo ""

for r in "${RESULTS[@]}"; do
  case "$r" in
    PASS*) green "  $r" ;;
    FAIL*) red   "  $r" ;;
    SKIP*) yellow "  $r" ;;
  esac
done

echo ""
printf 'Total: %d passed, %d failed, %d skipped\n' "$PASS" "$FAIL" "$SKIP"
echo ""

# Write summary to report
{
  echo "========================================"
  echo "  SUMMARY"
  echo "========================================"
  for r in "${RESULTS[@]}"; do
    echo "  $r"
  done
  echo ""
  printf '  Total: %d passed, %d failed, %d skipped\n' "$PASS" "$FAIL" "$SKIP"
  echo ""
  echo "  Report: $REPORT_FILE"
  echo "========================================"
} >> "$REPORT_FILE"

dim "Report written to $REPORT_FILE"
echo ""

if [ "$FAIL" -gt 0 ]; then
  red "Some skills failed. Re-run with VERBOSE=1 for output details."
  exit 1
fi

green "All skills passed."
