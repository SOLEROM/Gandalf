#!/usr/bin/env bash
# List all Claude Code sessions available for restore
# Usage: bash list.sh          → all sessions
#        bash list.sh .        → only sessions for current directory
#        bash list.sh <filter> → sessions matching a name filter

PROJECTS_DIR="$HOME/.claude/projects"
ARG="${1:-}"

# Resolve filter: "." means match current pwd
if [[ "$ARG" == "." ]]; then
    # Convert pwd to the project slug format (slashes → dashes, leading slash → leading dash)
    FILTER=$(echo "$PWD" | sed 's|/|-|g')
else
    FILTER="$ARG"
fi

echo "Claude Code sessions in: $PROJECTS_DIR"
[[ "$ARG" == "." ]] && echo "Filtering for: $PWD"
echo "----------------------------------------"

for proj_dir in "$PROJECTS_DIR"/*/; do
    proj=$(basename "$proj_dir")
    [[ -n "$FILTER" && "$proj" != *"$FILTER"* ]] && continue

    sessions=("$proj_dir"*.jsonl)
    [[ ! -e "${sessions[0]}" ]] && continue

    # Convert dir name back to path (leading dashes = slashes)
    path=$(echo "$proj" | sed 's|^-|/|; s|-|/|g')

    echo ""
    echo "Project: $path"
    for f in "${sessions[@]}"; do
        uuid=$(basename "$f" .jsonl)
        modified=$(stat -c "%y" "$f" | cut -d. -f1)
        size=$(stat -c "%s" "$f")
        echo "  $uuid  [$modified]  $(( size / 1024 ))KB"
    done
done

echo ""
echo "To restore: claude --resume <session-uuid>"
