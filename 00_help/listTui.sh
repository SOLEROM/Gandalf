#!/usr/bin/env bash
# eccTui.sh — Print Claude Code components (agents, skills, commands, rules) to stdout
#
# Usage:
#   eccTui.sh --local    Look in the current project directory
#   eccTui.sh --global   Look in ~/.claude
#   eccTui.sh            Show both (local first, then global)

# ── colours ───────────────────────────────────────────────────────────────────
BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
MAGENTA='\033[1;35m'
BLUE='\033[1;34m'
WHITE='\033[1;37m'
RESET='\033[0m'

# ── flags ─────────────────────────────────────────────────────────────────────
SHOW_LOCAL=false
SHOW_GLOBAL=false

for arg in "$@"; do
    case "$arg" in
        --local)  SHOW_LOCAL=true  ;;
        --global) SHOW_GLOBAL=true ;;
        -h|--help)
            echo "Usage: $(basename "$0") [--local] [--global]"
            echo "  --local   scan current project directory"
            echo "  --global  scan ~/.claude"
            echo "  (no flags) defaults to --global"
            exit 0
            ;;
        *) echo "Unknown flag: $arg  (use --local, --global, or --help)"; exit 1 ;;
    esac
done

# default: global only
if ! $SHOW_LOCAL && ! $SHOW_GLOBAL; then
    SHOW_GLOBAL=true
fi

# ── helpers ───────────────────────────────────────────────────────────────────
banner() {
    local title="$1" colour="$2"
    local width=72
    local line
    line=$(printf '─%.0s' $(seq 1 $width))
    echo
    echo -e "${colour}${BOLD}┌${line}┐${RESET}"
    printf "${colour}${BOLD}│  %-70s│${RESET}\n" "$title"
    echo -e "${colour}${BOLD}└${line}┘${RESET}"
}

section() {
    echo -e "\n${BOLD}${DIM}── $1 ──────────────────────────────────────────────────────${RESET}"
}

scope_header() {
    local label="$1"
    echo
    echo -e "${WHITE}${BOLD}╔══════════════════════════════════════════════════════════════════════════╗${RESET}"
    printf "${WHITE}${BOLD}║  %-72s║${RESET}\n" "$label"
    echo -e "${WHITE}${BOLD}╚══════════════════════════════════════════════════════════════════════════╝${RESET}"
}

# Extract a YAML frontmatter field from a file
# Usage: yaml_field <file> <field>
yaml_field() {
    local file="$1" field="$2"
    awk -v f="$field" '
        /^---/ { if (NR > 1) exit }
        $0 ~ "^" f ":" {
            sub("^" f ":[ \t]*", "")
            gsub(/^[">|'\''[:space:]]+|['\''[:space:]]+$/, "")
            print; exit
        }
    ' "$file"
}

# ── printers ──────────────────────────────────────────────────────────────────

# Agents from AGENTS.md table  (local layout)
print_agents_from_table() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo -e "  ${DIM}AGENTS.md not found — skipped${RESET}"
        return
    fi
    local count=0
    local in_table=0
    while IFS= read -r line; do
        if [[ "$line" == *"| Agent | Purpose | When to Use |"* ]]; then
            in_table=1
            printf "  ${BOLD}%-32s %-30s %s${RESET}\n" "AGENT" "PURPOSE" "WHEN TO USE"
            echo -e "  ${DIM}$(printf '─%.0s' $(seq 1 70))${RESET}"
            continue
        fi
        if (( in_table )) && [[ "$line" == \|* ]]; then
            [[ "$line" =~ ^\|[[:space:]|-]+\|$ ]] && continue
            IFS='|' read -ra parts <<< "$line"
            local agent purpose when
            agent=$(echo "${parts[1]:-}" | xargs)
            purpose=$(echo "${parts[2]:-}" | xargs)
            when=$(echo "${parts[3]:-}" | xargs)
            [[ -z "$agent" || "$agent" == "Agent" ]] && continue
            printf "  ${CYAN}%-32s${RESET} %-30s ${DIM}%s${RESET}\n" "$agent" "$purpose" "$when"
            (( count++ ))
        fi
    done < "$file"
    echo -e "\n  ${DIM}Total: $count agents${RESET}"
}

# Agents from individual .md files  (global layout: ~/.claude/agents/)
print_agents_from_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        echo -e "  ${DIM}agents/ not found — skipped${RESET}"
        return
    fi
    local count=0
    printf "  ${BOLD}%-32s %s${RESET}\n" "AGENT" "DESCRIPTION"
    echo -e "  ${DIM}$(printf '─%.0s' $(seq 1 70))${RESET}"
    while IFS= read -r file; do
        [[ -f "$file" ]] || continue
        local name desc
        name=$(basename "$file" .md)
        desc=$(yaml_field "$file" "description")
        [[ -z "$desc" ]] && desc=$(yaml_field "$file" "name")
        [[ -z "$desc" ]] && desc="${name//-/ }"
        echo -e "  ${CYAN}${name}${RESET}"
        echo -e "    ${DIM}${desc}${RESET}"
        (( count++ ))
    done < <(find "$dir" -maxdepth 1 -name '*.md' | sort)
    echo -e "\n  ${DIM}Total: $count agents${RESET}"
}

# Skills from a skills/ directory
print_skills() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        echo -e "  ${DIM}skills/ not found — skipped${RESET}"
        return
    fi
    local count=0
    local tmp
    tmp=$(mktemp)

    while IFS= read -r skill_path; do
        [[ -d "$skill_path" ]] || continue
        local name description category
        name=$(basename "$skill_path")
        description=""

        local skill_file="$skill_path/SKILL.md"
        if [[ -f "$skill_file" ]]; then
            description=$(yaml_field "$skill_file" "description")
            if [[ -z "$description" ]]; then
                description=$(grep -m1 '^# ' "$skill_file" | sed 's/^# //')
            fi
        fi
        [[ -z "$description" ]] && description="${name//-/ }"

        local nl="${name,,}"
        if   [[ "$nl" == *python* || "$nl" == *django* ]];                     then category="Python"
        elif [[ "$nl" == go-* || "$nl" == *golang* ]];                         then category="Go"
        elif [[ "$nl" == *frontend* || "$nl" == *react* || "$nl" == *next* ]]; then category="Frontend"
        elif [[ "$nl" == *backend* || "$nl" == *api* ]];                       then category="Backend"
        elif [[ "$nl" == *security* ]];                                        then category="Security"
        elif [[ "$nl" == *test* || "$nl" == *tdd* ]];                          then category="Testing"
        elif [[ "$nl" == *docker* || "$nl" == *deploy* ]];                     then category="DevOps"
        elif [[ "$nl" == *swift* || "$nl" == *ios* ]];                         then category="iOS"
        elif [[ "$nl" == *java* || "$nl" == *spring* ]];                       then category="Java"
        elif [[ "$nl" == *rust* ]];                                            then category="Rust"
        elif [[ "$nl" == *android* || "$nl" == *kotlin* ]];                    then category="Android"
        else category="General"
        fi

        printf '%s\t%s\t%s\n' "$category" "$name" "$description" >> "$tmp"
        (( count++ ))
    done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d | sort)

    local prev_cat=""
    while IFS=$'\t' read -r cat name desc; do
        if [[ "$cat" != "$prev_cat" ]]; then
            section "$cat"
            prev_cat="$cat"
        fi
        echo -e "  ${GREEN}${name}${RESET}"
        echo -e "    ${DIM}${desc}${RESET}"
    done < <(sort "$tmp")
    rm -f "$tmp"

    echo -e "\n  ${DIM}Total: $count skills${RESET}"
}

# Commands from a commands/ directory
print_commands() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        echo -e "  ${DIM}commands/ not found — skipped${RESET}"
        return
    fi
    local count=0
    printf "  ${BOLD}%-30s %s${RESET}\n" "COMMAND" "DESCRIPTION"
    echo -e "  ${DIM}$(printf '─%.0s' $(seq 1 70))${RESET}"
    while IFS= read -r file; do
        [[ -f "$file" ]] || continue
        local cmd description
        cmd=$(basename "$file" .md)
        description=$(yaml_field "$file" "description")
        if [[ -z "$description" ]]; then
            description=$(grep -m1 '^# ' "$file" | sed 's/^# //')
        fi
        [[ -z "$description" ]] && description="${cmd//-/ }"
        echo -e "  ${YELLOW}/${cmd}${RESET}"
        echo -e "    ${DIM}${description}${RESET}"
        (( count++ ))
    done < <(find "$dir" -maxdepth 1 -name '*.md' | sort)
    echo -e "\n  ${DIM}Total: $count commands${RESET}"
}

# Rules from a rules/ directory
print_rules() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        echo -e "  ${DIM}rules/ not found — skipped${RESET}"
        return
    fi
    local count=0
    while IFS= read -r lang_dir; do
        [[ -d "$lang_dir" ]] || continue
        local lang
        lang=$(basename "$lang_dir")
        section "${lang^}"
        while IFS= read -r file; do
            [[ -f "$file" ]] || continue
            printf "  ${MAGENTA}%s${RESET}\n" "$(basename "$file" .md)"
            (( count++ ))
        done < <(find "$lang_dir" -maxdepth 1 -name '*.md' | sort)
    done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d | sort)
    echo -e "\n  ${DIM}Total: $count rules${RESET}"
}

# ── scope runner ──────────────────────────────────────────────────────────────
print_scope() {
    local root="$1" label="$2"

    scope_header "$label  ($root)"

    # --- Agents ---
    banner "AGENTS" "$CYAN"
    if [[ -f "$root/AGENTS.md" ]]; then
        print_agents_from_table "$root/AGENTS.md"
    elif [[ -d "$root/agents" ]]; then
        print_agents_from_dir "$root/agents"
    else
        echo -e "  ${DIM}No agents found${RESET}"
    fi

    # --- Skills ---
    banner "SKILLS" "$GREEN"
    print_skills "$root/skills"

    # --- Commands ---
    banner "COMMANDS" "$YELLOW"
    print_commands "$root/commands"

    # --- Rules ---
    banner "RULES" "$MAGENTA"
    print_rules "$root/rules"
}

# ── main ──────────────────────────────────────────────────────────────────────
echo -e "${BOLD}${BLUE}"
echo "  ██████╗██╗      █████╗ ██╗   ██╗██████╗ ███████╗"
echo "  ██╔════╝██║     ██╔══██╗██║   ██║██╔══██╗██╔════╝"
echo "  ██║     ██║     ███████║██║   ██║██║  ██║█████╗"
echo "  ██║     ██║     ██╔══██║██║   ██║██║  ██║██╔══╝"
echo "  ╚██████╗███████╗██║  ██║╚██████╔╝██████╔╝███████╗"
echo "   ╚═════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝  Claude TUI"
echo -e "${RESET}"

if $SHOW_LOCAL; then
    # Prefer git root so the script works from any subdirectory
    if git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
        local_root="$git_root"
    else
        local_root="$(pwd)"
    fi
    print_scope "$local_root" "LOCAL"
fi

if $SHOW_GLOBAL; then
    print_scope "$HOME/.claude" "GLOBAL  (~/.claude)"
fi

echo
