#!/usr/bin/env bash
# test.sh — Unattended test runner for dev-toolkit skills
# Usage: bash test/test.sh [skill1 skill2 ...]
#        VERBOSE=1 bash test/test.sh
#        TIMEOUT=180 bash test/test.sh
set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'
green()  { echo -e "${GREEN}$*${RESET}"; }
red()    { echo -e "${RED}$*${RESET}"; }
yellow() { echo -e "${YELLOW}$*${RESET}"; }
bold()   { echo -e "${BOLD}$*${RESET}"; }
dim()    { echo -e "${DIM}$*${RESET}"; }

# ── Config ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPORT_FILE="${TOOLKIT_DIR}/testReport.log"
VERBOSE="${VERBOSE:-0}"
TIMEOUT="${TIMEOUT:-120}"
DEBUG=0
FILTER=()

# ── Help ──────────────────────────────────────────────────────────────────────
usage() {
    bold "dev-toolkit test runner"
    echo
    echo "Usage: bash test/test.sh [OPTIONS] [skill...]"
    echo
    echo "Skills:"
    echo "  [1] claude-md                   — Create/audit CLAUDE.md for AI agent onboarding"
    echo "  [2] code-review-specialist      — Security, performance, quality code review"
    echo "  [3] code-refactor               — Fowler-methodology refactoring workflow"
    echo "  [4] api-documentation-generator — Generate API docs from source code"
    echo
    echo "Options:"
    echo "  -h, --help     Show this help"
    echo "  -d, --debug    Print workdir, command, and full prompt before each run"
    echo
    echo "Environment:"
    echo "  VERBOSE=1      Print full Claude output on failure"
    echo "  TIMEOUT=N      Per-skill timeout in seconds (default: 120)"
    echo
    echo "Examples:"
    echo "  bash test/test.sh"
    echo "  bash test/test.sh code-review refactor"
    echo "  VERBOSE=1 TIMEOUT=180 bash test/test.sh"
}

# ── Arg parsing ───────────────────────────────────────────────────────────────
for arg in "$@"; do
    case "${arg}" in
        -h|--help) usage; exit 0 ;;
        -d|--debug) DEBUG=1 ;;
        *) FILTER+=("${arg}") ;;
    esac
done

should_run() {
    local name="$1"
    [[ ${#FILTER[@]} -eq 0 ]] && return 0
    for f in "${FILTER[@]}"; do
        [[ "${name}" == *"${f}"* ]] && return 0
    done
    return 1
}

# ── Auto-install ──────────────────────────────────────────────────────────────
SKILLS_DIR="${HOME}/.claude/skills"
if [[ ! -f "${SKILLS_DIR}/claude-md/SKILL.md" ]]; then
    echo "Skills not installed — running install.sh first..."
    bash "${TOOLKIT_DIR}/install.sh"
fi

# ── Temp repo setup ───────────────────────────────────────────────────────────
WORKDIR="$(mktemp -d)"
trap 'rm -rf "${WORKDIR}"' EXIT

setup_repo() {
    cd "${WORKDIR}"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"

    # Initial commit
    cat > README.md <<'EOF'
# Taskflow

Lightweight task management API built with Python/FastAPI.

## Tech Stack
- Python 3.11, FastAPI, PostgreSQL

## Development Commands
- Install: `pip install -e .[dev]`
- Test: `pytest`
- Build: `docker build .`
EOF

    echo "1.0.0" > VERSION
    cat > CHANGELOG.md <<'EOF'
# Changelog

## [Unreleased]
- Add bulk task operations

## [1.0.0]
- Initial release
EOF

    mkdir -p src/tasks src/api
    cat > src/tasks/processor.py <<'EOF'
"""Task processing module."""

def process_bulk_tasks(task_ids, operation, user_id, config, notify):
    """Process multiple tasks in bulk."""
    results = []
    errors = []

    # validate inputs
    if not task_ids:
        raise ValueError("task_ids cannot be empty")
    if not operation:
        raise ValueError("operation cannot be empty")
    if not user_id:
        raise ValueError("user_id cannot be empty")

    for task_id in task_ids:
        try:
            # validate task
            if not isinstance(task_id, str):
                errors.append({"task_id": task_id, "error": "invalid id type"})
                continue
            if len(task_id) != 36:
                errors.append({"task_id": task_id, "error": "invalid id length"})
                continue

            if operation == "complete":
                result = {"task_id": task_id, "status": "completed"}
            elif operation == "archive":
                result = {"task_id": task_id, "status": "archived"}
            elif operation == "delete":
                result = {"task_id": task_id, "status": "deleted"}
            else:
                errors.append({"task_id": task_id, "error": "unknown operation"})
                continue

            results.append(result)

        except Exception as e:
            errors.append({"task_id": task_id, "error": str(e)})

    # validate outputs
    if not results and errors:
        raise RuntimeError("all tasks failed")

    return {"results": results, "errors": errors, "total": len(task_ids)}


def get_task(task_id: str) -> dict:
    """Get a single task by ID."""
    return {"task_id": task_id, "status": "pending"}


def create_task(title: str, description: str = "") -> dict:
    """Create a new task."""
    return {"title": title, "description": description, "status": "pending"}
EOF

    cat > src/api/routes.py <<'EOF'
"""API route definitions."""


def get_tasks(user_id: str, status: str = None, limit: int = 50) -> list:
    """
    List all tasks for a user.

    Returns paginated list of tasks filtered by optional status.
    """
    return []


def post_tasks(title: str, description: str, user_id: str, priority: str = "normal") -> dict:
    """
    Create a new task.

    Creates a task and returns the created object with generated ID.
    """
    return {}


def post_bulk_operations(task_ids: list, operation: str, user_id: str) -> dict:
    """
    Apply an operation to multiple tasks.

    Supported operations: complete, archive, delete.
    Returns results and errors per task.
    """
    return {}
EOF

    git add -A
    git commit -q -m "initial commit: task management API"

    # Feature branch commit
    cat >> src/tasks/processor.py <<'EOF'


def validate_bulk_input(task_ids, operation):
    """Validate inputs for bulk operations."""
    if not task_ids:
        raise ValueError("task_ids cannot be empty")
    if operation not in ("complete", "archive", "delete"):
        raise ValueError(f"unknown operation: {operation}")
EOF

    git add -A
    git commit -q -m "feat: add input validation helper for bulk ops"

    cd - > /dev/null
}

setup_repo

# ── Report file ───────────────────────────────────────────────────────────────
> "${REPORT_FILE}"
{
    echo "================================================================"
    echo "DEV-TOOLKIT TEST REPORT"
    echo "Run: $(date)"
    echo "================================================================"
    echo
} >> "${REPORT_FILE}"

# ── Non-interactive preamble ──────────────────────────────────────────────────
PREAMBLE="IMPORTANT: You are running in non-interactive automated test mode.
- Do NOT call AskUserQuestion under any circumstances.
- Make all decisions autonomously without asking for confirmation.
- When a skill offers mode options, choose SMALL CHANGE / quick mode automatically.
- Produce the output as if the user had already answered all questions."

# ── Test runner ───────────────────────────────────────────────────────────────
PASS=0; FAIL=0; SKIP=0
declare -A RESULTS

run_skill() {
    local step="$1"
    local total="$2"
    local name="$3"
    local prompt="$4"
    local pattern="$5"
    local platform_only="${6:-any}"

    # Platform check
    if [[ "${platform_only}" == "macos" && "$(uname)" != "Darwin" ]]; then
        printf "[%d/%d] %-40s " "${step}" "${total}" "${name}"
        yellow "SKIP (macOS only)"
        RESULTS["${name}"]="SKIP"
        ((SKIP++))
        {
            echo "----------------------------------------------------------------"
            echo "SKILL: ${name}"
            echo "STATUS: SKIP (macOS only)"
            echo
        } >> "${REPORT_FILE}"
        return
    fi

    if ! should_run "${name}"; then
        RESULTS["${name}"]="SKIP"
        ((SKIP++))
        return
    fi

    local full_prompt="${PREAMBLE}

${prompt}"

    if [[ "${DEBUG}" -eq 1 ]]; then
        dim "  workdir: ${WORKDIR}"
        dim "  command: claude --print --dangerously-skip-permissions"
        dim "  prompt:  ${full_prompt:0:200}..."
        echo
    fi

    printf "[%d/%d] %-40s " "${step}" "${total}" "${name}"

    local output
    local exit_code=0
    output=$(cd "${WORKDIR}" && \
        timeout "${TIMEOUT}" claude --print --dangerously-skip-permissions \
            "${full_prompt}" 2>&1) || exit_code=$?

    if [[ ${exit_code} -eq 124 ]]; then
        red "FAIL (timeout after ${TIMEOUT}s)"
        RESULTS["${name}"]="FAIL"
        ((FAIL++))
        {
            echo "----------------------------------------------------------------"
            echo "SKILL: ${name}"
            echo "STATUS: FAIL (timeout)"
            echo
        } >> "${REPORT_FILE}"
        return
    fi

    if echo "${output}" | grep -qiE "${pattern}"; then
        green "PASS"
        RESULTS["${name}"]="PASS"
        ((PASS++))
        {
            echo "----------------------------------------------------------------"
            echo "SKILL: ${name}"
            echo "STATUS: PASS"
            echo
            echo "OUTPUT:"
            echo "${output}"
            echo
        } >> "${REPORT_FILE}"
    else
        red "FAIL"
        RESULTS["${name}"]="FAIL"
        ((FAIL++))
        {
            echo "----------------------------------------------------------------"
            echo "SKILL: ${name}"
            echo "STATUS: FAIL"
            echo "EXPECTED PATTERN: ${pattern}"
            echo
            echo "OUTPUT:"
            echo "${output}"
            echo
        } >> "${REPORT_FILE}"
        if [[ "${VERBOSE}" -eq 1 ]]; then
            echo
            dim "--- Full Claude output ---"
            echo "${output}"
            dim "--- End output ---"
            echo
        fi
    fi
}

TOTAL=4

run_skill 1 "${TOTAL}" "claude-md" \
    "Use the claude-md skill. Run: /claude-md audit
Audit the current project and describe what a CLAUDE.md should contain for this repo. Do not create the file." \
    "CLAUDE\.md|tech stack|development command|convention|golden rule|under 300|concise"

run_skill 2 "${TOTAL}" "code-review-specialist" \
    "Use the code-review-specialist skill. Run: /code-review-specialist
Review the file src/tasks/processor.py for security, performance, and code quality issues." \
    "security|performance|quality|maintainability|SOLID|severity|critical|high|medium|finding|issue"

run_skill 3 "${TOTAL}" "code-refactor" \
    "Use the code-refactor skill. Run: /code-refactor
Analyze src/tasks/processor.py and identify code smells. Do a Phase 1 and Phase 3 analysis only — do not implement any changes." \
    "refactor|smell|long method|duplicate|phase|extract|complexity|maintainab"

run_skill 4 "${TOTAL}" "api-documentation-generator" \
    "Use the api-documentation-generator skill. Run: /api-documentation-generator
Generate API documentation for the endpoints defined in src/api/routes.py" \
    "endpoint|parameter|response|GET\|POST\|api|documentation|description|returns"

# ── Summary ───────────────────────────────────────────────────────────────────
echo
bold "SUMMARY"
echo "  PASS: ${PASS}   FAIL: ${FAIL}   SKIP: ${SKIP}"
echo

for name in "claude-md" "code-review-specialist" "code-refactor" "api-documentation-generator"; do
    status="${RESULTS[${name}]:-SKIP}"
    case "${status}" in
        PASS) printf "  %-42s " "${name}"; green "PASS" ;;
        FAIL) printf "  %-42s " "${name}"; red "FAIL" ;;
        SKIP) printf "  %-42s " "${name}"; yellow "SKIP" ;;
    esac
done

{
    echo
    echo "================================================================"
    echo "SUMMARY"
    echo "  PASS: ${PASS}   FAIL: ${FAIL}   SKIP: ${SKIP}"
    for name in "claude-md" "code-review-specialist" "code-refactor" "api-documentation-generator"; do
        status="${RESULTS[${name}]:-SKIP}"
        printf "  %-42s %s\n" "${name}" "${status}"
    done
    echo "================================================================"
} >> "${REPORT_FILE}"

echo
echo "Report written to ${REPORT_FILE}"

[[ "${FAIL}" -eq 0 ]]
