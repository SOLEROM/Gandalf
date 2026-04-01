#!/usr/bin/env bash
# Display a Claude Code session in a nice readable format
# Usage: bash less.sh <session-uuid>
#        bash less.sh <session-uuid> --plain   (no colors, for piping)
#        bash less.sh <session-uuid> | less -R  (scroll with colors)

SESSION_ID="${1:-}"
PLAIN="${2:-}"

# If stdout is a terminal and not --plain, auto-pipe through less
if [[ -t 1 && "$PLAIN" != "--plain" ]]; then
    "$0" "$SESSION_ID" --pager-mode | less -R
    exit $?
fi
# Internal re-invocation marker
[[ "$PLAIN" == "--pager-mode" ]] && PLAIN=""

if [[ -z "$SESSION_ID" ]]; then
    echo "Usage: $0 <session-uuid> [--plain]"
    echo "Run list.sh to find session UUIDs."
    exit 1
fi

# Find the session file
SESSION_FILE=$(find "$HOME/.claude/projects" -name "${SESSION_ID}.jsonl" 2>/dev/null | head -1)

if [[ -z "$SESSION_FILE" ]]; then
    echo "Session not found: $SESSION_ID"
    exit 1
fi

python3 - "$SESSION_FILE" "$PLAIN" <<'PYEOF'
import sys, json, textwrap, re

session_file = sys.argv[1]
plain = sys.argv[2] == "--plain" if len(sys.argv) > 2 else False

# ── ANSI colors ──────────────────────────────────────────────────────────────
RESET   = "" if plain else "\033[0m"
BOLD    = "" if plain else "\033[1m"
DIM     = "" if plain else "\033[2m"
ITALIC  = "" if plain else "\033[3m"

# Foreground colors
WHITE   = "" if plain else "\033[97m"
GRAY    = "" if plain else "\033[90m"
RED     = "" if plain else "\033[91m"
GREEN   = "" if plain else "\033[92m"
YELLOW  = "" if plain else "\033[93m"
BLUE    = "" if plain else "\033[94m"
MAGENTA = "" if plain else "\033[95m"
CYAN    = "" if plain else "\033[96m"

# Background colors (subtle)
BG_DARK   = "" if plain else "\033[48;5;235m"
BG_USER   = "" if plain else "\033[48;5;17m"
BG_ASST   = "" if plain else "\033[48;5;22m"
BG_TOOL   = "" if plain else "\033[48;5;52m"
BG_RESULT = "" if plain else "\033[48;5;233m"

cols = 100  # wrap width

def hr(char="─", color=GRAY):
    return f"{color}{char * cols}{RESET}"

def wrap(text, indent=2, width=cols-4):
    lines = text.split("\n")
    out = []
    for line in lines:
        if len(line) <= width:
            out.append(" " * indent + line)
        else:
            wrapped = textwrap.wrap(line, width=width)
            for w in wrapped:
                out.append(" " * indent + w)
    return "\n".join(out)

def fmt_json(obj, indent=2):
    raw = json.dumps(obj, indent=2)
    lines = raw.split("\n")
    # syntax highlight keys vs values
    out = []
    for line in lines:
        line = " " * indent + line
        # key: "something":
        line = re.sub(r'"([^"]+)"(\s*:)', f'{CYAN}"\\1"{RESET}\\2', line)
        # string values
        line = re.sub(r':\s*"([^"]*)"', f': {YELLOW}"\\1"{RESET}', line)
        # numbers / bools
        line = re.sub(r':\s*(true|false|null|\d+\.?\d*)', f': {MAGENTA}\\1{RESET}', line)
        out.append(line)
    return "\n".join(out)

def truncate(text, maxlen=400):
    if len(text) <= maxlen:
        return text
    return text[:maxlen] + f"\n{DIM}  … ({len(text)-maxlen} more chars){RESET}"

# ── Parse session ─────────────────────────────────────────────────────────────
messages = []
meta = {}

with open(session_file) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
            t = obj.get("type", "")
            if t in ("user", "assistant"):
                messages.append(obj)
            elif t == "last-prompt":
                meta["last_prompt"] = obj.get("lastPrompt", "")
            elif t == "system" and obj.get("subtype") == "stop_hook_summary":
                meta["stop_reason"] = obj.get("stopReason", "")
        except Exception:
            pass

# Get metadata from first user message
first_user = next((m for m in messages if m.get("type") == "user"), {})
session_id   = first_user.get("sessionId", "?")
cwd          = first_user.get("cwd", "?")
version      = first_user.get("version", "?")
started_at   = first_user.get("timestamp", "?")[:19].replace("T", " ")
git_branch   = first_user.get("gitBranch", "")

# Count turns
user_turns = sum(1 for m in messages if m.get("type") == "user"
                 and isinstance(m.get("message", {}).get("content"), str))
asst_turns = sum(1 for m in messages if m.get("type") == "assistant")

# ── Header ────────────────────────────────────────────────────────────────────
print()
print(hr("═", CYAN + BOLD))
print(f"{BOLD}{CYAN}  Claude Code Session Viewer{RESET}")
print(hr("═", CYAN + BOLD))
print(f"  {BOLD}Session ID :{RESET} {YELLOW}{session_id}{RESET}")
print(f"  {BOLD}Directory  :{RESET} {WHITE}{cwd}{RESET}")
if git_branch:
    print(f"  {BOLD}Git Branch :{RESET} {GREEN}{git_branch}{RESET}")
print(f"  {BOLD}Started    :{RESET} {WHITE}{started_at}{RESET}")
print(f"  {BOLD}Version    :{RESET} {DIM}{version}{RESET}")
print(f"  {BOLD}Messages   :{RESET} {WHITE}{user_turns} user  /  {asst_turns} assistant{RESET}")
if meta.get("last_prompt"):
    print(f"  {BOLD}Last Prompt:{RESET} {DIM}{truncate(meta['last_prompt'], 120)}{RESET}")
print(hr("═", CYAN + BOLD))
print()

# ── Render messages ───────────────────────────────────────────────────────────
turn = 0

for msg in messages:
    mtype   = msg.get("type", "")
    content = msg.get("message", {}).get("content", "")
    ts      = msg.get("timestamp", "")[:19].replace("T", " ")

    # ── USER ──────────────────────────────────────────────────────────────────
    if mtype == "user":
        if isinstance(content, str):
            turn += 1
            print(f"{BG_USER}{BOLD}{BLUE}  ▶ USER  #{turn:<3}{RESET}{BG_USER}{DIM}  {ts}{RESET}")
            print(hr("─", BLUE + DIM))
            print(f"{WHITE}{wrap(content, indent=2)}{RESET}")
            print()

        elif isinstance(content, list):
            # tool results
            for item in content:
                if item.get("type") == "tool_result":
                    result_content = item.get("content", "")
                    is_error = item.get("is_error", False)
                    tool_id  = item.get("tool_use_id", "")[:12]
                    color    = RED if is_error else GRAY
                    label    = "ERROR" if is_error else "RESULT"
                    print(f"{BG_RESULT}{color}{BOLD}  ◀ TOOL {label}  {RESET}{BG_RESULT}{DIM}id:{tool_id}…  {ts}{RESET}")
                    print(hr("─", GRAY + DIM))
                    if isinstance(result_content, str):
                        print(f"{DIM}{wrap(truncate(result_content, 600), indent=2)}{RESET}")
                    elif isinstance(result_content, list):
                        for part in result_content:
                            if part.get("type") == "text":
                                print(f"{DIM}{wrap(truncate(part.get('text',''), 600), indent=2)}{RESET}")
                    print()

    # ── ASSISTANT ─────────────────────────────────────────────────────────────
    elif mtype == "assistant":
        if not isinstance(content, list):
            continue

        model     = msg.get("message", {}).get("model", "")
        usage     = msg.get("message", {}).get("usage", {})
        in_tok    = usage.get("input_tokens", 0)
        out_tok   = usage.get("output_tokens", 0)
        cache_r   = usage.get("cache_read_input_tokens", 0)
        cache_w   = usage.get("cache_creation_input_tokens", 0)

        has_text  = any(c.get("type") == "text" for c in content)
        has_tool  = any(c.get("type") == "tool_use" for c in content)

        label = "ASSISTANT"
        if has_tool and not has_text:
            label = "ASSISTANT  ⚙ tool call"
        elif has_tool:
            label = "ASSISTANT  ⚙ + text"

        tok_info = f"{DIM}in:{in_tok} out:{out_tok} cache-r:{cache_r} cache-w:{cache_w}{RESET}"
        print(f"{BG_ASST}{BOLD}{GREEN}  ● {label:<28}{RESET}{BG_ASST}{DIM}  {ts}{RESET}")
        if model:
            print(f"  {DIM}model: {model}   tokens: {tok_info}")
        print(hr("─", GREEN + DIM))

        for part in content:
            ptype = part.get("type", "")

            if ptype == "thinking":
                thought = part.get("thinking", "").strip()
                if thought:
                    print(f"  {MAGENTA}{ITALIC}┌─ thinking ───────────────────────────────────{RESET}")
                    print(f"{MAGENTA}{DIM}{wrap(truncate(thought, 500), indent=4)}{RESET}")
                    print(f"  {MAGENTA}{ITALIC}└──────────────────────────────────────────────{RESET}")
                    print()

            elif ptype == "text":
                text = part.get("text", "").strip()
                if text:
                    print(f"{WHITE}{wrap(text, indent=2)}{RESET}")
                    print()

            elif ptype == "tool_use":
                name  = part.get("name", "?")
                tid   = part.get("id", "")[:12]
                inp   = part.get("input", {})
                # special: show command clearly
                cmd   = inp.get("command", "")
                desc  = inp.get("description", "")
                print(f"  {YELLOW}{BOLD}⚙ TOOL: {name}{RESET}  {DIM}id:{tid}…{RESET}")
                if desc:
                    print(f"  {DIM}  desc: {desc}{RESET}")
                if cmd:
                    print(f"  {CYAN}  $ {cmd}{RESET}")
                elif inp:
                    # show other inputs compactly
                    small = {k: v for k, v in inp.items()
                             if k not in ("command",) and not isinstance(v, dict)}
                    if small:
                        print(f"  {CYAN}{wrap(json.dumps(small, indent=None), indent=4)}{RESET}")
                    big = {k: v for k, v in inp.items()
                           if isinstance(v, (dict, list))}
                    for k, v in big.items():
                        preview = json.dumps(v)[:200]
                        print(f"  {DIM}  {k}: {preview}{RESET}")
                print()

        print()

print(hr("═", CYAN + BOLD))
print(f"{BOLD}{CYAN}  End of session  {DIM}({len(messages)} total records){RESET}")
print(hr("═", CYAN + BOLD))
print()
PYEOF
