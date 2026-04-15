#!/usr/bin/env bash
# eccTui.sh — Print Claude Code components (agents, skills, commands, rules) to stdout
#
# Usage:
#   eccTui.sh              Scan ~/.claude  (terminal output)
#   eccTui.sh --local      Scan current project directory
#   eccTui.sh --global     Scan ~/.claude
#   eccTui.sh --md         Markdown output  (combine with --local / --global)

# zsh compatibility: suppress NOMATCH errors when globs have no results,
# and enable SH_WORD_SPLIT so unquoted $var behaves like bash word splitting.
if [[ -n "${ZSH_VERSION:-}" ]]; then
    setopt NO_NOMATCH SH_WORD_SPLIT 2>/dev/null || true
fi

# ── portable helpers ─────────────────────────────────────────────────────────

# Repeat a character N times without glob-prone $(seq) expansion
repeat_char() {   # $1=char  $2=count
    local s="" i=0
    while (( i++ < $2 )); do s+="$1"; done
    printf '%s' "$s"
}

# find wrappers that skip hidden directories (name starts with '.') unless --hidden is set.
# Uses -prune so the root dir itself is never excluded, even if its path contains a dot segment.
find_files() {    # $1=dir  $2=name-pattern  [extra find args passed before expression]
    local dir="$1" pattern="$2"; shift 2
    if [[ "$SEARCH_HIDDEN" == true ]]; then
        find "$dir" "$@" -name "$pattern"
    else
        find "$dir" "$@" \( -name '.*' -prune \) -o \( -name "$pattern" -print \)
    fi
}

find_dirs() {     # $1=dir  [extra find args passed before expression]
    local dir="$1"; shift
    if [[ "$SEARCH_HIDDEN" == true ]]; then
        find "$dir" "$@" -type d
    else
        find "$dir" "$@" \( -name '.*' -prune \) -o \( -type d -print \)
    fi
}

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
SEARCH_HIDDEN=false

for arg in "$@"; do
    case "$arg" in
        --local)  SHOW_LOCAL=true  ;;
        --global) SHOW_GLOBAL=true ;;
        --md)     OUTPUT_MODE="md" ;;
        --hidden) SEARCH_HIDDEN=true ;;
        -h|--help)
            local_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
            global_root="$HOME/.claude"
            echo "Usage: $(basename "$0") [--local] [--global] [--md] [--hidden]"
            echo
            echo "  --local   scan current project directory"
            printf "            %-12s %s\n" "AGENTS.md:"  "$local_root/AGENTS.md"
            printf "            %-12s %s\n" "agents/:"    "$local_root/agents/"
            printf "            %-12s %s\n" "skills/:"    "$local_root/skills/"
            printf "            %-12s %s\n" "commands/:"  "$local_root/commands/"
            printf "            %-12s %s\n" "rules/:"     "$local_root/rules/"
            echo
            echo "  --global  scan ~/.claude and all installed plugins"
            printf "            %-12s %s\n" "agents/:"    "$global_root/agents/"
            printf "            %-12s %s\n" "skills/:"    "$global_root/skills/"
            printf "            %-12s %s\n" "commands/:"  "$global_root/commands/"
            printf "            %-12s %s\n" "rules/:"     "$global_root/rules/"
            printf "            %-12s %s\n" "plugins/:"   "$global_root/plugins/  (each subdir scanned)"
            echo
            echo "  --md      output as markdown instead of terminal colours"
            echo "  --hidden  include hidden directories (starting with .) in search"
            echo "            (default: hidden directories are skipped)"
            echo "  (no scope flag) defaults to --global"
            exit 0
            ;;
        *) echo "Unknown flag: $arg  (use --local, --global, --md, --hidden, or --help)"; exit 1 ;;
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
        line=$(repeat_char '─' 72)
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
            gsub(/^[">[:space:]]+|[[:space:]]+$/, "")
            if ($0 == "|" || $0 == ">") {
                # block scalar — capture first non-empty indented line
                while ((getline line) > 0) {
                    if (line !~ /^[ \t]/) break
                    gsub(/^[ \t]+/, "", line)
                    if (line != "") { print line; exit }
                }
            } else {
                gsub(/^['\'']+|['\'']+$/, "")
                print; exit
            }
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
                echo -e "  ${DIM}$(repeat_char '─' 70)${RESET}"
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
            # Skip files without YAML frontmatter (not agent definitions)
            head -1 "$file" 2>/dev/null | grep -q '^---' || continue
            local name desc
            name="${file#$dir/}"
            name="${name%.md}"
            desc=$(yaml_field "$file" "description")
            [[ -z "$desc" ]] && desc=$(yaml_field "$file" "name")
            [[ -z "$desc" ]] && desc="${name//-/ }"
            echo "| **$name** | $desc |"
            (( count++ ))
        done < <(find_files "$dir" '*.md' | sort)
    else
        printf "  ${BOLD}%-32s %s${RESET}\n" "AGENT" "DESCRIPTION"
        echo -e "  ${DIM}$(repeat_char '─' 70)${RESET}"
        while IFS= read -r file; do
            [[ -f "$file" ]] || continue
            head -1 "$file" 2>/dev/null | grep -q '^---' || continue
            local name desc
            name="${file#$dir/}"
            name="${name%.md}"
            desc=$(yaml_field "$file" "description")
            [[ -z "$desc" ]] && desc=$(yaml_field "$file" "name")
            [[ -z "$desc" ]] && desc="${name//-/ }"
            echo -e "  ${CYAN}${name}${RESET}"
            echo -e "    ${DIM}${desc}${RESET}"
            (( count++ ))
        done < <(find_files "$dir" '*.md' | sort)
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

    while IFS= read -r skill_file; do
        local skill_path name leaf description
        skill_path=$(dirname "$skill_file")
        name="${skill_path#$dir/}"   # relative path from skills/
        leaf=$(basename "$skill_path")
        description=$(yaml_field "$skill_file" "description")
        [[ -z "$description" ]] && description=$(awk 'BEGIN{n=0} /^---/{n++;next} n>=2 && /^# /{sub(/^# /,"");print;exit}' "$skill_file")
        [[ -z "$description" ]] && description="${leaf//-/ }"
        local category
        category=$(skill_category "${leaf,,}")
        printf '%s\t%s\t%s\n' "$category" "$name" "$description" >> "$tmp"
        (( count++ ))
    done < <(find_files "$dir" 'SKILL.md' | sort)

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
            cmd="${file#$dir/}"
            cmd="${cmd%.md}"
            description=$(yaml_field "$file" "description")
            [[ -z "$description" ]] && description=$(awk 'BEGIN{n=0} /^---/{n++;next} n>=2 && /^# /{sub(/^# /,"");print;exit}' "$file")
            [[ -z "$description" ]] && description="${cmd//-/ }"
            echo "| \`/$cmd\` | $description |"
            (( count++ ))
        done < <(find_files "$dir" '*.md' | sort)
    else
        printf "  ${BOLD}%-30s %s${RESET}\n" "COMMAND" "DESCRIPTION"
        echo -e "  ${DIM}$(repeat_char '─' 70)${RESET}"
        while IFS= read -r file; do
            [[ -f "$file" ]] || continue
            local cmd description
            cmd="${file#$dir/}"
            cmd="${cmd%.md}"
            description=$(yaml_field "$file" "description")
            [[ -z "$description" ]] && description=$(awk 'BEGIN{n=0} /^---/{n++;next} n>=2 && /^# /{sub(/^# /,"");print;exit}' "$file")
            [[ -z "$description" ]] && description="${cmd//-/ }"
            echo -e "  ${YELLOW}/${cmd}${RESET}"
            echo -e "    ${DIM}${description}${RESET}"
            (( count++ ))
        done < <(find_files "$dir" '*.md' | sort)
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
    local tmp
    tmp=$(mktemp)
    while IFS= read -r file; do
        local relpath group rulename
        relpath="${file#$dir/}"
        group=$(echo "$relpath" | cut -d'/' -f1)
        rulename="${relpath%.md}"
        printf '%s\t%s\n' "$group" "$rulename" >> "$tmp"
        (( count++ ))
    done < <(find "$dir" -name '*.md' | sort)

    local prev_group=""
    while IFS=$'\t' read -r group rulename; do
        if [[ "$group" != "$prev_group" ]]; then
            [[ $OUTPUT_MODE == md && -n "$prev_group" ]] && echo
            out_subsection "${group^}"
            prev_group="$group"
        fi
        if [[ $OUTPUT_MODE == md ]]; then
            echo "- $rulename"
        else
            printf "  ${MAGENTA}%s${RESET}\n" "$rulename"
        fi
    done < <(sort "$tmp")
    rm -f "$tmp"
    out_total "$count" "rules"
}

# ── plugin discovery ─────────────────────────────────────────────────────────

# Returns a list of "label\tpath" lines for every installed plugin that has
# at least one component directory (agents/ skills/ commands/ rules/).
discover_plugins() {
    local plugins_dir="$HOME/.claude/plugins"
    local seen=()

    # Helper: emit a plugin entry if the path has component dirs and is new
    emit_plugin() {
        local path="$1" label="$2"
        [[ -d "$path" ]] || return
        # Must contain at least one known component dir to be worth showing
        local has_components=false
        for d in agents skills commands rules; do
            if [[ -d "$path/$d" ]]; then has_components=true; break; fi
        done
        [[ "$has_components" == true ]] || return
        # Deduplicate by real path
        local real
        real=$(realpath "$path" 2>/dev/null || echo "$path")
        for s in "${seen[@]}"; do [[ "$s" == "$real" ]] && return; done
        seen+=("$real")
        printf '%s\t%s\n' "$label" "$path"
    }

    # 1. Parse installed_plugins.json for official install paths
    local json="$plugins_dir/installed_plugins.json"
    if [[ -f "$json" ]]; then
        while IFS= read -r install_path; do
            [[ -z "$install_path" ]] && continue
            # Skip paths inside any meta directory (cache, data, etc.)
            local skip=false
            for m in cache data; do
                if [[ "$install_path" == *"/$m/"* || "$install_path" == *"/$m" ]]; then
                    skip=true; break
                fi
            done
            [[ "$skip" == true ]] && continue
            # Strip version-like suffixes (numbers/semver) to get a clean name
            local clean_name
            clean_name=$(basename "$(dirname "$install_path")")
            emit_plugin "$install_path" "PLUGIN  $clean_name"
        done < <(grep '"installPath"' "$json" | sed 's/.*"installPath": *"\([^"]*\)".*/\1/' | sort -u)
    fi

    # 2. Scan direct subdirectories of ~/.claude/plugins/ (manually placed plugins)
    local -a meta_dirs=(cache data marketplaces)
    if [[ -d "$plugins_dir" ]]; then
        while IFS= read -r subdir; do
            [[ -d "$subdir" ]] || continue
            local dname
            dname=$(basename "$subdir")
            # Skip known meta directories
            local skip=false
            for m in "${meta_dirs[@]}"; do
                if [[ "$dname" == "$m" ]]; then skip=true; break; fi
            done
            [[ "$skip" == true ]] && continue
            emit_plugin "$subdir" "PLUGIN  $dname"
        done < <(find_dirs "$plugins_dir" -mindepth 1 -maxdepth 1 | sort)
    fi

    # 3. Scan one level inside ~/.claude/plugins/marketplaces/ (marketplace-installed plugins)
    local marketplaces_dir="$plugins_dir/marketplaces"
    if [[ -d "$marketplaces_dir" ]]; then
        while IFS= read -r subdir; do
            [[ -d "$subdir" ]] || continue
            local dname
            dname=$(basename "$subdir")
            # Skip meta directories (cache, data, etc.)
            local skip=false
            for m in "${meta_dirs[@]}"; do
                if [[ "$dname" == "$m" ]]; then skip=true; break; fi
            done
            [[ "$skip" == true ]] && continue
            emit_plugin "$subdir" "PLUGIN  $dname"
        done < <(find_dirs "$marketplaces_dir" -mindepth 1 -maxdepth 1 | sort)
    fi
}

# ── scope runner ──────────────────────────────────────────────────────────────

print_scope() {
    local root="$1" label="$2"

    out_scope_header "$label" "$root"

    out_section_header "AGENTS" "$CYAN"
    if [[ -d "$root/agents" ]]; then
        print_agents_from_dir "$root/agents"
    elif [[ -f "$root/AGENTS.md" ]]; then
        print_agents_from_table "$root/AGENTS.md"
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

    while IFS=$'\t' read -r label path; do
        print_scope "$path" "$label"
    done < <(discover_plugins)
fi

[[ $OUTPUT_MODE == term ]] && echo
