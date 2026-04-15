#!/usr/bin/env bash
# eccTui.sh — Print Claude Code components (agents, skills, commands, rules) to stdout
#
# Usage:
#   eccTui.sh              Scan ~/.claude  (terminal output)
#   eccTui.sh --local      Scan current project directory
#   eccTui.sh --global     Scan ~/.claude
#   eccTui.sh --md         Markdown output  (combine with --local / --global)

# ── colours (terminal mode only) ─────────────────────────────────────────────
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
OUTPUT_MODE="term"

for arg in "$@"; do
    case "$arg" in
        --local)  SHOW_LOCAL=true  ;;
        --global) SHOW_GLOBAL=true ;;
        --md)     OUTPUT_MODE="md" ;;
        -h|--help)
            echo "Usage: $(basename "$0") [--local] [--global] [--md]"
            echo "  --local   scan current project directory"
            echo "  --global  scan ~/.claude"
            echo "  --md      output as markdown instead of terminal colours"
            echo "  (no scope flag) defaults to --global"
            exit 0
            ;;
        *) echo "Unknown flag: $arg  (use --local, --global, --md, or --help)"; exit 1 ;;
    esac
done

if ! $SHOW_LOCAL && ! $SHOW_GLOBAL; then
    SHOW_GLOBAL=true
fi

# ── mode-aware output helpers ─────────────────────────────────────────────────

out_scope_header() {   # $1 = label  $2 = path
    if [[ $OUTPUT_MODE == md ]]; then
        echo "# $1"
        echo
        echo "> $2"
        echo
    else
        echo
        echo -e "${WHITE}${BOLD}╔══════════════════════════════════════════════════════════════════════════╗${RESET}"
        printf "${WHITE}${BOLD}║  %-72s║${RESET}\n" "$1  ($2)"
        echo -e "${WHITE}${BOLD}╚══════════════════════════════════════════════════════════════════════════╝${RESET}"
    fi
}

out_section_header() {  # $1 = title  $2 = colour (term only)
    if [[ $OUTPUT_MODE == md ]]; then
        echo "## $1"
        echo
    else
        local line
        line=$(printf '─%.0s' $(seq 1 72))
        echo
        echo -e "${2}${BOLD}┌${line}┐${RESET}"
        printf "${2}${BOLD}│  %-70s│${RESET}\n" "$1"
        echo -e "${2}${BOLD}└${line}┘${RESET}"
    fi
}

out_subsection() {      # $1 = label
    if [[ $OUTPUT_MODE == md ]]; then
        echo "### $1"
        echo
    else
        echo -e "\n${BOLD}${DIM}── $1 ──────────────────────────────────────────────────────${RESET}"
    fi
}

out_not_found() {       # $1 = what was missing
    if [[ $OUTPUT_MODE == md ]]; then
        echo "_$1 not found — skipped_"
        echo
    else
        echo -e "  ${DIM}$1 not found — skipped${RESET}"
    fi
}

out_total() {           # $1 = count  $2 = label
    if [[ $OUTPUT_MODE == md ]]; then
        echo
        echo "_Total: $1 $2_"
        echo
    else
        echo -e "\n  ${DIM}Total: $1 $2${RESET}"
    fi
}

# ── shared utility ────────────────────────────────────────────────────────────

yaml_field() {          # $1=file  $2=field
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

skill_category() {      # $1 = skill name (lowercase)
    local nl="$1"
    if   [[ "$nl" == *python*  || "$nl" == *django*  ]]; then echo "Python"
    elif [[ "$nl" == go-*      || "$nl" == *golang*  ]]; then echo "Go"
    elif [[ "$nl" == *frontend* || "$nl" == *react* || "$nl" == *next* ]]; then echo "Frontend"
    elif [[ "$nl" == *backend* || "$nl" == *api*     ]]; then echo "Backend"
    elif [[ "$nl" == *security*                      ]]; then echo "Security"
    elif [[ "$nl" == *test*    || "$nl" == *tdd*     ]]; then echo "Testing"
    elif [[ "$nl" == *docker*  || "$nl" == *deploy*  ]]; then echo "DevOps"
    elif [[ "$nl" == *swift*   || "$nl" == *ios*     ]]; then echo "iOS"
    elif [[ "$nl" == *java*    || "$nl" == *spring*  ]]; then echo "Java"
    elif [[ "$nl" == *rust*                          ]]; then echo "Rust"
    elif [[ "$nl" == *android* || "$nl" == *kotlin*  ]]; then echo "Android"
    else echo "General"
    fi
}

# ── agents ────────────────────────────────────────────────────────────────────

print_agents_from_table() {     # $1 = AGENTS.md path
    local file="$1"
    if [[ ! -f "$file" ]]; then
        out_not_found "AGENTS.md"
        return
    fi

    if [[ $OUTPUT_MODE == md ]]; then
        local count=0 in_table=0
        while IFS= read -r line; do
            if [[ "$line" == *"| Agent | Purpose | When to Use |"* ]]; then
                in_table=1
                echo "| Agent | Purpose | When to Use |"
                echo "|-------|---------|-------------|"
                continue
            fi
            if (( in_table )) && [[ "$line" == \|* ]]; then
                [[ "$line" =~ ^\|[[:space:]|-]+\|$ ]] && continue
                IFS='|' read -ra p <<< "$line"
                local agent purpose when
                agent=$(echo "${p[1]:-}" | xargs)
                purpose=$(echo "${p[2]:-}" | xargs)
                when=$(echo "${p[3]:-}" | xargs)
                [[ -z "$agent" || "$agent" == "Agent" ]] && continue
                echo "| **$agent** | $purpose | $when |"
                (( count++ ))
            fi
        done < "$file"
        out_total "$count" "agents"
    else
        local count=0 in_table=0
        while IFS= read -r line; do
            if [[ "$line" == *"| Agent | Purpose | When to Use |"* ]]; then
                in_table=1
                printf "  ${BOLD}%-32s %-30s %s${RESET}\n" "AGENT" "PURPOSE" "WHEN TO USE"
                echo -e "  ${DIM}$(printf '─%.0s' $(seq 1 70))${RESET}"
                continue
            fi
            if (( in_table )) && [[ "$line" == \|* ]]; then
                [[ "$line" =~ ^\|[[:space:]|-]+\|$ ]] && continue
                IFS='|' read -ra p <<< "$line"
                local agent purpose when
                agent=$(echo "${p[1]:-}" | xargs)
                purpose=$(echo "${p[2]:-}" | xargs)
                when=$(echo "${p[3]:-}" | xargs)
                [[ -z "$agent" || "$agent" == "Agent" ]] && continue
                printf "  ${CYAN}%-32s${RESET} %-30s ${DIM}%s${RESET}\n" "$agent" "$purpose" "$when"
                (( count++ ))
            fi
        done < "$file"
        out_total "$count" "agents"
    fi
}

print_agents_from_dir() {       # $1 = agents/ dir
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        out_not_found "agents/"
        return
    fi

    local count=0
    if [[ $OUTPUT_MODE == md ]]; then
        echo "| Agent | Description |"
        echo "|-------|-------------|"
        while IFS= read -r file; do
            [[ -f "$file" ]] || continue
            local name desc
            name=$(basename "$file" .md)
            desc=$(yaml_field "$file" "description")
            [[ -z "$desc" ]] && desc=$(yaml_field "$file" "name")
            [[ -z "$desc" ]] && desc="${name//-/ }"
            echo "| **$name** | $desc |"
            (( count++ ))
        done < <(find "$dir" -maxdepth 1 -name '*.md' | sort)
    else
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
    fi
    out_total "$count" "agents"
}

# ── skills ────────────────────────────────────────────────────────────────────

print_skills() {                # $1 = skills/ dir
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        out_not_found "skills/"
        return
    fi

    local count=0
    local tmp
    tmp=$(mktemp)

    while IFS= read -r skill_path; do
        [[ -d "$skill_path" ]] || continue
        local name description
        name=$(basename "$skill_path")
        description=""
        local skill_file="$skill_path/SKILL.md"
        if [[ -f "$skill_file" ]]; then
            description=$(yaml_field "$skill_file" "description")
            [[ -z "$description" ]] && description=$(grep -m1 '^# ' "$skill_file" | sed 's/^# //')
        fi
        [[ -z "$description" ]] && description="${name//-/ }"
        local category
        category=$(skill_category "${name,,}")
        printf '%s\t%s\t%s\n' "$category" "$name" "$description" >> "$tmp"
        (( count++ ))
    done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d | sort)

    local prev_cat=""
    while IFS=$'\t' read -r cat name desc; do
        if [[ "$cat" != "$prev_cat" ]]; then
            out_subsection "$cat"
            prev_cat="$cat"
            if [[ $OUTPUT_MODE == md ]]; then
                : # subsection heading already printed
            fi
        fi
        if [[ $OUTPUT_MODE == md ]]; then
            echo "- **${name}** — ${desc}"
        else
            echo -e "  ${GREEN}${name}${RESET}"
            echo -e "    ${DIM}${desc}${RESET}"
        fi
    done < <(sort "$tmp")
    rm -f "$tmp"

    out_total "$count" "skills"
}

# ── commands ──────────────────────────────────────────────────────────────────

print_commands() {              # $1 = commands/ dir
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        out_not_found "commands/"
        return
    fi

    local count=0
    if [[ $OUTPUT_MODE == md ]]; then
        echo "| Command | Description |"
        echo "|---------|-------------|"
        while IFS= read -r file; do
            [[ -f "$file" ]] || continue
            local cmd description
            cmd=$(basename "$file" .md)
            description=$(yaml_field "$file" "description")
            [[ -z "$description" ]] && description=$(grep -m1 '^# ' "$file" | sed 's/^# //')
            [[ -z "$description" ]] && description="${cmd//-/ }"
            echo "| \`/$cmd\` | $description |"
            (( count++ ))
        done < <(find "$dir" -maxdepth 1 -name '*.md' | sort)
    else
        printf "  ${BOLD}%-30s %s${RESET}\n" "COMMAND" "DESCRIPTION"
        echo -e "  ${DIM}$(printf '─%.0s' $(seq 1 70))${RESET}"
        while IFS= read -r file; do
            [[ -f "$file" ]] || continue
            local cmd description
            cmd=$(basename "$file" .md)
            description=$(yaml_field "$file" "description")
            [[ -z "$description" ]] && description=$(grep -m1 '^# ' "$file" | sed 's/^# //')
            [[ -z "$description" ]] && description="${cmd//-/ }"
            echo -e "  ${YELLOW}/${cmd}${RESET}"
            echo -e "    ${DIM}${description}${RESET}"
            (( count++ ))
        done < <(find "$dir" -maxdepth 1 -name '*.md' | sort)
    fi
    out_total "$count" "commands"
}

# ── rules ─────────────────────────────────────────────────────────────────────

print_rules() {                 # $1 = rules/ dir
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        out_not_found "rules/"
        return
    fi

    local count=0
    while IFS= read -r lang_dir; do
        [[ -d "$lang_dir" ]] || continue
        local lang
        lang=$(basename "$lang_dir")
        out_subsection "${lang^}"
        while IFS= read -r file; do
            [[ -f "$file" ]] || continue
            local rulename
            rulename=$(basename "$file" .md)
            if [[ $OUTPUT_MODE == md ]]; then
                echo "- $rulename"
            else
                printf "  ${MAGENTA}%s${RESET}\n" "$rulename"
            fi
            (( count++ ))
        done < <(find "$lang_dir" -maxdepth 1 -name '*.md' | sort)
        [[ $OUTPUT_MODE == md ]] && echo
    done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d | sort)
    out_total "$count" "rules"
}

# ── scope runner ──────────────────────────────────────────────────────────────

print_scope() {
    local root="$1" label="$2"

    out_scope_header "$label" "$root"

    out_section_header "AGENTS" "$CYAN"
    if [[ -f "$root/AGENTS.md" ]]; then
        print_agents_from_table "$root/AGENTS.md"
    elif [[ -d "$root/agents" ]]; then
        print_agents_from_dir "$root/agents"
    else
        out_not_found "agents"
    fi

    out_section_header "SKILLS" "$GREEN"
    print_skills "$root/skills"

    out_section_header "COMMANDS" "$YELLOW"
    print_commands "$root/commands"

    out_section_header "RULES" "$MAGENTA"
    print_rules "$root/rules"
}

# ── main ──────────────────────────────────────────────────────────────────────

if [[ $OUTPUT_MODE == term ]]; then
    echo -e "${BOLD}${BLUE}"
    echo "  ██████╗██╗      █████╗ ██╗   ██╗██████╗ ███████╗"
    echo "  ██╔════╝██║     ██╔══██╗██║   ██║██╔══██╗██╔════╝"
    echo "  ██║     ██║     ███████║██║   ██║██║  ██║█████╗"
    echo "  ██║     ██║     ██╔══██║██║   ██║██║  ██║██╔══╝"
    echo "  ╚██████╗███████╗██║  ██║╚██████╔╝██████╔╝███████╗"
    echo "   ╚═════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝  Claude TUI"
    echo -e "${RESET}"
else
    echo "# Claude Code Components"
    echo
    echo "_Generated by eccTui.sh on $(date '+%Y-%m-%d %H:%M')_"
    echo
fi

if $SHOW_LOCAL; then
    if git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
        local_root="$git_root"
    else
        local_root="$(pwd)"
    fi
    print_scope "$local_root" "LOCAL"
fi

if $SHOW_GLOBAL; then
    print_scope "$HOME/.claude" "GLOBAL (~/.claude)"
fi

[[ $OUTPUT_MODE == term ]] && echo
