#!/usr/bin/env bash
# test/test.sh — Superpowers Dev Toolkit unattended test runner
#
# Exercises each installed skill by prompting Claude and validating
# that the response matches an expected pattern.
#
# Usage:
#   bash test.sh                    # run all skills
#   bash test.sh brainstorming tdd  # run only named skills (substring match)
#   bash test.sh --help             # list all skills
#   bash test.sh -d brainstorming   # debug mode for one skill

set -euo pipefail

# ---------------------------------------------------------------------------
# Color helpers
# ---------------------------------------------------------------------------
red()    { printf '\033[0;31m%s\033[0m\n' "$*"; }
green()  { printf '\033[0;32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[0;33m%s\033[0m\n' "$*"; }
bold()   { printf '\033[1m%s\033[0m\n' "$*"; }
dim()    { printf '\033[2m%s\033[0m\n' "$*"; }

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
TIMEOUT=${TIMEOUT:-120}
VERBOSE=${VERBOSE:-0}
DEBUG=0
FILTER=()

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
SKILLS_DIR="${HOME}/.claude/skills"
REPORT="${SCRIPT_DIR}/testReport.log"

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      bold "Superpowers Dev Toolkit — Test Runner"
      echo ""
      echo "Usage: bash test.sh [options] [skill-filter...]"
      echo ""
      echo "Options:"
      echo "  --help, -h       Show this help and list all skills"
      echo "  --debug, -d      Debug mode: print full Claude output for each skill"
      echo ""
      echo "Skill filter: pass one or more substrings; only matching skills run."
      echo ""
      bold "Available skills (number  name  description):"
      echo "  1  brainstorming              Design-phase: idea → spec workflow"
      echo "  2  writing-plans              Planning: implementation plan authoring"
      echo "  3  test-driven-development    Red-green-refactor discipline"
      echo "  4  systematic-debugging       Four-phase root-cause debugging"
      echo "  5  verification-before-completion  Evidence-before-claims gate"
      echo "  6  requesting-code-review     Dispatch code-reviewer subagent"
      echo "  7  receiving-code-review      Evaluate and respond to review feedback"
      echo "  8  dispatching-parallel-agents  Parallel independent task dispatch"
      echo "  9  finishing-a-development-branch  Merge/PR/discard workflow"
      echo " 10  using-git-worktrees        Isolated workspace setup"
      echo ""
      exit 0
      ;;
    --debug|-d)
      DEBUG=1
      shift
      ;;
    -*)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
    *)
      FILTER+=("$1")
      shift
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Skills array: name | description | prompt | validation_regex
# ---------------------------------------------------------------------------
# Format: skills[N]="name|description|prompt|regex"
# Populated below as parallel arrays for compatibility.

SKILL_NAMES=()
SKILL_DESCS=()
SKILL_PROMPTS=()
SKILL_PATTERNS=()

add_skill() {
  SKILL_NAMES+=("$1")
  SKILL_DESCS+=("$2")
  SKILL_PROMPTS+=("$3")
  SKILL_PATTERNS+=("$4")
}

add_skill \
  "brainstorming" \
  "Design-phase: idea → spec workflow" \
  "Use the brainstorming skill to help design a CSV export feature for a REST API. Create a brief spec." \
  "spec|design|requirement|brainstorm"

add_skill \
  "writing-plans" \
  "Planning: implementation plan authoring" \
  "Use the writing-plans skill to create an implementation plan for adding a /export endpoint that returns CSV." \
  "plan|task|step|implement"

add_skill \
  "test-driven-development" \
  "Red-green-refactor discipline" \
  "Use the test-driven-development skill to implement a CSV serializer function. Show the RED-GREEN-REFACTOR cycle." \
  "test|red|green|refactor|fail"

add_skill \
  "systematic-debugging" \
  "Four-phase root-cause debugging" \
  "Use the systematic-debugging skill. The symptom: CSV output has garbled UTF-8 characters. Walk through root cause investigation." \
  "root.cause|hypothesis|investigation|diagnosis"

add_skill \
  "verification-before-completion" \
  "Evidence-before-claims gate" \
  "Use the verification-before-completion skill. Claim: 'The CSV serializer handles all edge cases.' Verify this claim." \
  "verif|evidence|test|confirm"

add_skill \
  "requesting-code-review" \
  "Dispatch code-reviewer subagent" \
  "Use the requesting-code-review skill to request a review of changes that add a /export CSV endpoint." \
  "review|code.review|feedback"

add_skill \
  "receiving-code-review" \
  "Evaluate and respond to review feedback" \
  "Use the receiving-code-review skill. The reviewer says: 'You should stream the CSV instead of buffering it in memory.' Evaluate this feedback." \
  "stream|buffer|evaluat|technical"

add_skill \
  "dispatching-parallel-agents" \
  "Parallel independent task dispatch" \
  "Use the dispatching-parallel-agents skill to dispatch two parallel tasks: (1) update unit tests for CSV export, (2) update API docs." \
  "parallel|agent|concurrent|dispatch"

add_skill \
  "finishing-a-development-branch" \
  "Merge/PR/discard workflow" \
  "Use the finishing-a-development-branch skill on the current branch. Show the merge/PR/discard options." \
  "merge|PR|pull.request|branch|finish"

add_skill \
  "using-git-worktrees" \
  "Isolated workspace setup" \
  "Use the using-git-worktrees skill to set up a worktree for a new feature branch called feature/csv-export." \
  "worktree|branch|git|isolat"

# ---------------------------------------------------------------------------
# Non-interactive preamble — prepended to every prompt
# ---------------------------------------------------------------------------
NON_INTERACTIVE_PREAMBLE="IMPORTANT: You are running in non-interactive automated test mode.
- Do NOT call AskUserQuestion under any circumstances.
- Make all decisions autonomously without asking for confirmation.
- When a skill offers mode options, choose SMALL CHANGE / quick mode automatically.
- Produce the output as if the user had already answered all questions.

"

# ---------------------------------------------------------------------------
# Skill check / auto-install hint
# ---------------------------------------------------------------------------
check_skills_installed() {
  local sentinel="${SKILLS_DIR}/brainstorming/SKILL.md"
  if [[ ! -f "$sentinel" ]]; then
    yellow "WARNING: Skills not found at ${SKILLS_DIR}/brainstorming/SKILL.md"
    yellow "         Install skills first. See ${TOOLKIT_DIR}/install.md"
    yellow "         (No automatic install script is included in ver1 — install manually.)"
    echo ""
    # Don't exit — the test can still run; Claude will just not find skills
  fi
}

# ---------------------------------------------------------------------------
# Temp git repo setup
# ---------------------------------------------------------------------------
TMPDIR_BASE=""

setup_temp_repo() {
  TMPDIR_BASE="$(mktemp -d)"
  local repo="${TMPDIR_BASE}/testrepo"
  mkdir -p "${repo}/src"

  cd "$repo"
  git init -q
  git config user.email "test@superpowers.test"
  git config user.name "Superpowers Test Runner"

  # README.md
  cat > README.md <<'EOREADME'
# Test Repo — Superpowers Dev Toolkit

A minimal Python REST API for testing superpowers skills.
EOREADME

  # VERSION
  echo "1.0.0" > VERSION

  # CHANGELOG.md
  cat > CHANGELOG.md <<'EOCHLOG'
# Changelog

## [1.0.0] - 2026-01-01
- Initial release
EOCHLOG

  # src/main.py — small Python REST API skeleton
  cat > src/main.py <<'EOMAIN'
"""
Minimal Python REST API skeleton.
Endpoints:
  GET  /users        — list users
  GET  /users/<id>   — get user by id
  POST /users        — create user
"""

from http.server import BaseHTTPRequestHandler, HTTPServer
import json

USERS = [
    {"id": 1, "name": "Alice Smith", "email": "alice@example.com"},
    {"id": 2, "name": "Zoé Dupont", "email": "zoe@example.com"},
    {"id": 3, "name": "Carlos García", "email": "carlos@example.com"},
]


class APIHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):  # suppress default logging
        pass

    def send_json(self, status, data):
        body = json.dumps(data).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/users":
            self.send_json(200, USERS)
        elif self.path.startswith("/users/"):
            try:
                uid = int(self.path.split("/")[-1])
                user = next((u for u in USERS if u["id"] == uid), None)
                if user:
                    self.send_json(200, user)
                else:
                    self.send_json(404, {"error": "not found"})
            except ValueError:
                self.send_json(400, {"error": "invalid id"})
        else:
            self.send_json(404, {"error": "not found"})


def run(host="127.0.0.1", port=8000):
    server = HTTPServer((host, port), APIHandler)
    print(f"Serving on http://{host}:{port}")
    server.serve_forever()


if __name__ == "__main__":
    run()
EOMAIN

  # Initial commit
  git add README.md VERSION CHANGELOG.md src/main.py
  git commit -q -m "feat: initial project structure"

  # Feature branch commit
  git checkout -q -b feature/add-user-endpoints
  cat >> src/main.py <<'EOFEAT'


# TODO: add POST /users endpoint
EOFEAT
  git add src/main.py
  git commit -q -m "feat: add user endpoints (WIP)"
  git checkout -q main

  echo "$repo"
}

cleanup_temp_repo() {
  if [[ -n "${TMPDIR_BASE:-}" && -d "${TMPDIR_BASE}" ]]; then
    rm -rf "${TMPDIR_BASE}"
  fi
}

# ---------------------------------------------------------------------------
# Filter helper
# ---------------------------------------------------------------------------
skill_matches_filter() {
  local name="$1"
  if [[ ${#FILTER[@]} -eq 0 ]]; then
    return 0  # no filter → match all
  fi
  for f in "${FILTER[@]}"; do
    if [[ "$name" == *"$f"* ]]; then
      return 0
    fi
  done
  return 1
}

# ---------------------------------------------------------------------------
# Run a single skill test
# ---------------------------------------------------------------------------
run_skill_test() {
  local name="$1"
  local desc="$2"
  local prompt="$3"
  local pattern="$4"
  local repo_dir="$5"

  local full_prompt="${NON_INTERACTIVE_PREAMBLE}${prompt}"
  local output=""
  local exit_code=0
  local status="PASS"

  printf "  %-45s " "${name}"

  output=$(
    cd "$repo_dir" && \
    timeout "$TIMEOUT" claude --print --dangerously-skip-permissions "$full_prompt" 2>&1
  ) || exit_code=$?

  if [[ $exit_code -eq 124 ]]; then
    status="TIMEOUT"
  elif [[ $exit_code -ne 0 ]] && [[ -z "$output" ]]; then
    status="ERROR"
  else
    # Check pattern (case-insensitive extended regex)
    if ! echo "$output" | grep -qiE "$pattern"; then
      status="FAIL"
    fi
  fi

  case "$status" in
    PASS)    green "PASS" ;;
    FAIL)    red   "FAIL  (pattern not matched: ${pattern})" ;;
    TIMEOUT) yellow "TIMEOUT (${TIMEOUT}s)" ;;
    ERROR)   red   "ERROR (exit ${exit_code})" ;;
  esac

  # Write to report
  {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "SKILL:   ${name}"
    echo "DESC:    ${desc}"
    echo "STATUS:  ${status}"
    echo "PATTERN: ${pattern}"
    echo "EXIT:    ${exit_code}"
    echo ""
    echo "--- OUTPUT ---"
    echo "$output"
    echo ""
  } >> "$REPORT"

  if [[ "$DEBUG" -eq 1 ]]; then
    echo ""
    dim "--- DEBUG OUTPUT for ${name} ---"
    echo "$output"
    echo ""
  fi

  [[ "$status" == "PASS" ]]
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  bold "Superpowers Dev Toolkit v5.0.7 — Test Runner"
  dim  "$(date)"
  echo ""

  check_skills_installed

  # Set up temp repo
  local repo_dir
  repo_dir="$(setup_temp_repo)"
  trap cleanup_temp_repo EXIT

  dim "Temp repo: ${repo_dir}"
  dim "Report:    ${REPORT}"
  echo ""

  # Initialize report
  {
    echo "Superpowers Dev Toolkit — Test Report"
    echo "Generated: $(date)"
    echo "Timeout:   ${TIMEOUT}s"
    echo "Repo:      ${repo_dir}"
    echo ""
  } > "$REPORT"

  local total=0
  local passed=0
  local failed=0
  local skipped=0

  bold "Running skill tests:"
  echo ""

  for i in "${!SKILL_NAMES[@]}"; do
    local name="${SKILL_NAMES[$i]}"
    local desc="${SKILL_DESCS[$i]}"
    local prompt="${SKILL_PROMPTS[$i]}"
    local pattern="${SKILL_PATTERNS[$i]}"

    if ! skill_matches_filter "$name"; then
      skipped=$((skipped + 1))
      continue
    fi

    total=$((total + 1))
    if run_skill_test "$name" "$desc" "$prompt" "$pattern" "$repo_dir"; then
      passed=$((passed + 1))
    else
      failed=$((failed + 1))
    fi
  done

  echo ""
  bold "Summary"
  echo "  Total:   ${total}"
  green "  Passed:  ${passed}"
  if [[ $failed -gt 0 ]]; then
    red "  Failed:  ${failed}"
  else
    echo "  Failed:  ${failed}"
  fi
  if [[ $skipped -gt 0 ]]; then
    dim "  Skipped: ${skipped}"
  fi
  echo ""

  # Write summary to report
  {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "SUMMARY"
    echo "Total:   ${total}"
    echo "Passed:  ${passed}"
    echo "Failed:  ${failed}"
    echo "Skipped: ${skipped}"
    echo "Generated: $(date)"
  } >> "$REPORT"

  echo "Report written to ./testReport.log"

  if [[ $failed -gt 0 ]]; then
    exit 1
  fi
  exit 0
}

main "$@"
