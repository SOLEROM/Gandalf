# Security Review

Reviewed: 2026-04-06
Scope: All assets in this working set — agents, commands, skills (scripts), rules, mcp-configs.

**Overall verdict: No malicious code found.** Active security mitigations are present throughout. Four items require informed consent before enabling.

---

## Know Before You Install

### Flag 1 — Autonomous background Claude processes
**File:** `skills/continuous-learning-v2/agents/observer-loop.sh`
**Severity:** Yellow — opt-in, but significant autonomy change

If `observer.enabled` is set to `true` in `skills/continuous-learning-v2/config.json`, a background Claude Haiku process spawns every 5 minutes while you work:

```bash
claude --model haiku --max-turns 10 --print --allowedTools "Read,Write" < prompt_file
```

It analyzes your tool usage patterns and writes "instinct" files to `~/.claude/homunculus/` without you explicitly asking. Guards are present (cooldown, re-entrancy lock, session guardian, idle detection) but the process runs autonomously.

**Default state:** Disabled (`observer.enabled: false`). Safe as long as you don't enable it.

**Rule:** Do not enable on machines where secrets, credentials, or confidential source code live in your working directories.

---

### Flag 2 — All tool I/O is recorded locally
**File:** `skills/continuous-learning-v2/hooks/observe.sh`
**Severity:** Yellow — active when hooks are installed

When the ECC plugin hooks are active, every Claude tool call is captured — including file contents read, bash outputs, file writes — and written to:

```
~/.claude/homunculus/projects/<hash>/observations.jsonl
```

A secret scrubber runs on each event (regex matching `api_key`, `token`, `password`, `authorization`, etc.) but it is best-effort, not a guarantee. Each event is truncated at 5000 characters. If the observer (Flag 1) is enabled, this stored content is fed to automated Haiku sessions.

**Mitigations present:** Secret regex scrubbing, 5000-char truncation, 30-day archive rotation, self-loop prevention (`ECC_SKIP_OBSERVE=1` on automated sessions).

**Rule:** Periodically audit `~/.claude/homunculus/` to understand what has accumulated. If working with highly sensitive data, disable the observe hook by adding `~/.claude/homunculus/disabled` (empty file).

---

### Flag 3 — Instinct import accepts arbitrary URLs
**File:** `skills/continuous-learning-v2/scripts/instinct-cli.py`
**Severity:** Yellow — social engineering vector

The `/instinct-import` command accepts a URL:

```
/instinct-import https://example.com/instincts.yaml
```

Instinct files are behavioral instructions that modify how Claude acts going forward. A crafted instinct file could suppress security warnings, inject code patterns, or alter review behavior — without being obviously malicious.

Filesystem path traversal protections are solid (blocks `..`, leading `.`, system directories, non-alphanumeric IDs). The risk is in *content*, not file paths.

**Rule:** Never import instincts from a URL you did not personally author. Treat instinct files like linter config — read them before applying.

---

### Flag 4 — MCP servers auto-download on first use
**File:** `mcp-configs/mcp-servers.json`
**Severity:** Informational — supply chain consideration

Every MCP server uses `npx -y` which downloads and executes the npm package without prompting:

```json
"command": "npx",
"args": ["-y", "@modelcontextprotocol/server-github"]
```

All packages listed are from established organizations (`@modelcontextprotocol`, `@upstash`, `@playwright`, etc.) but they run with your full user permissions.

**Rule:** Verify package names carefully before adding (typosquatting risk). For production or sensitive environments, pin versions explicitly: `@modelcontextprotocol/server-github@1.2.3`.

---

## Clean — No Issues Found

| Asset | Finding |
|---|---|
| All 10 agents | No network calls, no exfiltration, read-only tools where appropriate |
| All 53 commands | Markdown instruction files — no executable code |
| All 9 common rules | Markdown files — no executable code |
| `strategic-compact/suggest-compact.sh` | Writes a counter to `/tmp`, outputs warnings to stderr only |
| `continuous-learning/evaluate-session.sh` | Reads local transcript, emits stderr signal — no network, no writes |
| `skill-stocktake/scan.sh` | Local filesystem scan, JSON output to stdout only |
| `skill-stocktake/save-results.sh` | Local JSON merge with atomic temp-file write — no network |
| `session-guardian.sh` | Reads system idle time (macOS: `ioreg`, Linux: `xprintidle`) — no writes, no network |
| `instinct-cli.py` path/ID validation | Path traversal guards solid: blocks `..`, leading `.`, system dirs, enforces `^[A-Za-z0-9][A-Za-z0-9._-]*$` |
| `detect-project.sh` | Strips credentials from git remote URLs before hashing — does not log raw URLs |

---

## Quick Disable Reference

| Concern | How to disable |
|---|---|
| Observer background process | Keep `observer.enabled: false` in `continuous-learning-v2/config.json` (default) |
| Observation logging (observe hook) | `touch ~/.claude/homunculus/disabled` |
| Specific ECC hooks | Set `ECC_DISABLED_HOOKS="post:observe,pre:observe"` in environment |
| All non-essential hooks | Set `ECC_HOOK_PROFILE=minimal` in environment |
| Full continuous-learning-v2 | Do not install `skills/continuous-learning-v2/` — skip it in the install steps |
