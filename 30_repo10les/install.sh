#!/usr/bin/env bash
# install.sh — Install dev-toolkit skills into Claude Code
set -euo pipefail

SKILLS_DIR="${HOME}/.claude/skills"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; RESET='\033[0m'
ok()   { echo -e "${GREEN}✔${RESET} $*"; }
warn() { echo -e "${YELLOW}⚠${RESET} $*"; }
fail() { echo -e "${RED}✗${RESET} $*"; }

echo "Installing dev-toolkit skills to ${SKILLS_DIR}..."
echo

# Create skills directory if needed
mkdir -p "${SKILLS_DIR}"

SKILLS=( claude-md code-review refactor doc-generator )

for skill in "${SKILLS[@]}"; do
    src="${SCRIPT_DIR}/${skill}"
    dst="${SKILLS_DIR}/${skill}"

    if [[ ! -d "${src}" ]]; then
        warn "Skipping ${skill} — source directory not found"
        continue
    fi

    if [[ -d "${dst}" ]]; then
        warn "${skill} already installed — overwriting"
    fi

    cp -r "${src}" "${dst}"

    # Make any shell scripts executable
    find "${dst}" -name "*.sh" -exec chmod +x {} \;

    # Verify SKILL.md is present
    if [[ -f "${dst}/SKILL.md" ]]; then
        ok "${skill}"
    else
        fail "${skill} — SKILL.md missing after copy"
    fi
done

echo
echo "Installation complete. Verify with:"
echo "  ls ~/.claude/skills/"
echo
echo "Run the test suite to confirm everything works:"
echo "  bash ${SCRIPT_DIR}/test/test.sh"
