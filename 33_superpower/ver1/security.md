# Security Assessment — Superpowers Dev Toolkit v5.0.7

Assessment of all executable scripts included in this toolkit. Each script is evaluated for: network calls or data exfiltration, autonomous process spawning, local data recording, external URL acceptance, and auto-download behavior.

---

## hooks/session-start (bash)

**Purpose:** Reads `skills/using-superpowers/SKILL.md` and outputs a JSON context injection for Claude Code's SessionStart hook.

**Assessment:**

- **Network calls / data exfiltration:** None. The script reads a local file and writes JSON to stdout. No curl, wget, nc, or network primitives of any kind.
- **Autonomous process spawning:** None beyond its own execution. The script does not launch background processes, daemons, or subshells.
- **Local data recording:** None. It does not write files; it only reads one.
- **External URL acceptance:** None. No user-supplied URLs are consumed.
- **Auto-download behavior:** None. No npx, pip install, curl | sh, or equivalent.

**Details:** The script uses `cat` to read a fixed relative path derived from `$SCRIPT_DIR`, escapes the content for JSON embedding using bash parameter substitution (no external tools), checks `CURSOR_PLUGIN_ROOT`, `CLAUDE_PLUGIN_ROOT`, and `COPILOT_CLI` environment variables to select the correct JSON output format, and exits. A legacy-directory check warns if `~/.config/superpowers/skills` exists — this is read-only (existence check via `-d`), no writes.

**Risk level: LOW.** The script does exactly what it claims and nothing else.

---

## skills/brainstorming/scripts/start-server.sh (bash)

**Purpose:** Starts a local HTTP/WebSocket server for the brainstorming visual companion feature.

**Assessment:**

- **Network calls / data exfiltration:** None outbound. The script binds a local HTTP server — by default to `127.0.0.1` (loopback only). The `--host` flag can specify an alternative bind address (e.g., `0.0.0.0` for container environments), but this is passed directly to the Node.js server; the script itself makes no outbound connections.
- **Autonomous process spawning:** Yes — this is the script's primary function. It launches `node server.cjs` as a background process using `nohup` and `disown`. This is expected and documented behavior.
- **Local data recording:** Yes — session files are written to `/tmp/brainstorm-<session-id>/` (ephemeral) or `<project-dir>/.superpowers/brainstorm/<session-id>/` (persistent). These contain HTML files written by Claude and user interaction events (click choices). No credentials, source code, or system information are recorded.
- **External URL acceptance:** The `--url-host` flag accepts a display hostname for the URL returned in the JSON output. This affects only what URL is printed, not what the server binds to.
- **Auto-download behavior:** None. The script requires `node` to be already installed; it does not run npm, npx, or any package manager.

**Details:** Uses a random high port (49152–65535). Resolves owner PID to auto-terminate the server when the parent process dies. Has a 30-minute idle timeout. The foreground mode is triggered automatically on Windows/Git Bash and Codex CI environments.

**Risk level: LOW.** Spawning a background process is the intended use. Data written is brainstorming session content, not sensitive information. Network exposure is loopback-only by default.

---

## skills/brainstorming/scripts/stop-server.sh (bash)

**Purpose:** Kills the brainstorm server process and optionally cleans up the session directory.

**Assessment:**

- **Network calls / data exfiltration:** None.
- **Autonomous process spawning:** None.
- **Local data recording:** None — it deletes files, does not create them.
- **External URL acceptance:** None.
- **Auto-download behavior:** None.

**Details:** Reads a PID from a file, sends `SIGTERM`, escalates to `SIGKILL` if necessary. Deletes the session directory only if it is under `/tmp/` — persistent project directories under `.superpowers/` are preserved. This is a straightforward process manager; no surprises.

**Risk level: NEGLIGIBLE.**

---

## skills/brainstorming/scripts/server.cjs (Node.js)

**Purpose:** Local HTTP + WebSocket server that serves HTML files written by Claude during brainstorming sessions.

**Assessment:**

- **Network calls / data exfiltration:** None outbound. The server only accepts inbound connections. It does not make any HTTP requests, DNS lookups, or calls to external APIs.
- **Autonomous process spawning:** None. The server is a single-process Node.js application using only built-in modules (`http`, `fs`, `crypto`, `path`).
- **Local data recording:** Yes — user click events from the browser are appended to `state/events` in the session directory. Each event record is a JSON object containing: event type, element text, `data-choice` value, element ID, and timestamp. No keystrokes, passwords, or sensitive form data are captured — only explicit clicks on elements with a `data-choice` attribute.
- **External URL acceptance:** None. URLs are not accepted as input; the server constructs its own listening address from environment variables.
- **Auto-download behavior:** None. Uses only Node.js built-in modules — no `require` of npm packages.

**Details:** Implements the WebSocket protocol (RFC 6455) from scratch using Node.js crypto and net primitives — no dependency on `ws` or other npm packages. Binds to the port and host set by environment variables. Monitors owner PID and shuts down if the parent process exits. The `/files/` route serves files from the content directory only; `path.basename()` is applied to filenames before resolving, mitigating basic path traversal.

**Notable limitation:** The `/files/` route uses `path.basename()` but does not enforce that the resolved path stays within `CONTENT_DIR`. In practice, an attacker would need to control the WebSocket content (i.e., be Claude) to inject a malicious filename, so this is not an exploitable issue in normal use.

**Risk level: LOW.** All data recorded is brainstorming UI interactions. No outbound network. No npm dependencies.

---

## skills/brainstorming/scripts/helper.js (browser JavaScript)

**Purpose:** Browser-side script injected into brainstorming companion pages. Connects to the local WebSocket server and relays click events.

**Assessment:**

- **Network calls / data exfiltration:** Connects via WebSocket to `ws://<window.location.host>` — the same origin as the page (the local server). No cross-origin requests.
- **Autonomous process spawning:** N/A — browser JS cannot spawn processes.
- **Local data recording:** None. Sends events to the local server; does not write to localStorage, IndexedDB, cookies, or any browser storage.
- **External URL acceptance:** None. WebSocket URL is derived from `window.location.host` (the local server address).
- **Auto-download behavior:** N/A.

**Details:** The script listens for clicks on elements with `data-choice` attributes, sends JSON events (type, text, choice, id, timestamp) to the local WebSocket server, and reloads the page when the server broadcasts a `reload` message. Reconnects automatically on disconnect with a 1-second delay.

**Risk level: NEGLIGIBLE.** Pure same-origin browser-to-local-server communication.

---

## skills/systematic-debugging/find-polluter.sh (bash)

**Purpose:** Bisection script that runs test files one at a time to find which test creates an unwanted file or directory.

**Assessment:**

- **Network calls / data exfiltration:** None.
- **Autonomous process spawning:** Yes — runs `npm test <file>` for each test file in the project. This is the script's purpose; it iterates over all matching test files executing the project's own test command.
- **Local data recording:** None. The script only checks for file existence and reads `ls -la` output; it does not write files.
- **External URL acceptance:** None.
- **Auto-download behavior:** None. Assumes `npm` and the project's test infrastructure are already installed.

**Details:** Takes two arguments: the file/directory to watch for pollution, and a glob pattern for test files. Uses `find` to enumerate tests and runs them sequentially with `npm test`. Exits immediately when the polluting test is identified.

**Risk level: LOW.** The script runs your own project's test suite. If your test suite is safe, this script is safe. It does not install packages or make network calls of its own.

---

## skills/writing-skills/render-graphs.js (Node.js)

**Purpose:** Extracts `dot` code blocks from a SKILL.md file and renders them to SVG using the system `graphviz` (`dot`) binary.

**Assessment:**

- **Network calls / data exfiltration:** None.
- **Autonomous process spawning:** Yes — runs `dot -Tsvg` via `execSync` for each diagram extracted. This requires `graphviz` to be installed on the system. The `dot` binary is invoked with diagram content piped via stdin; no shell interpolation of user-supplied strings occurs.
- **Local data recording:** Yes — writes SVG files to a `diagrams/` subdirectory of the target skill directory. Also writes `.dot` source files when `--combine` mode is used. All output is within the user-specified skill directory.
- **External URL acceptance:** None.
- **Auto-download behavior:** None. Checks for `graphviz` using `which dot` and exits with a helpful message if not found; does not attempt to install it.

**Details:** Uses only Node.js built-ins (`fs`, `path`, `child_process`). The skill directory path comes from a command-line argument passed by the user or Claude; `path.resolve()` is applied. The `dot` binary is called with a fixed flag set (`-Tsvg`) — no user-supplied arguments are passed to the shell.

**Risk level: LOW.** Writes SVG files to a location you specify. No network, no auto-install.

---

## Summary Table

| Script | Network | Process spawn | Data written | External URLs | Auto-download | Risk |
|--------|---------|--------------|--------------|--------------|---------------|------|
| `hooks/session-start` | None | None | None | None | None | Low |
| `brainstorming/scripts/start-server.sh` | Inbound only (loopback) | Yes (node server) | Session content + events to /tmp or project dir | None | None | Low |
| `brainstorming/scripts/stop-server.sh` | None | None | Deletes files only | None | None | Negligible |
| `brainstorming/scripts/server.cjs` | Inbound only | None | Click events to session dir | None | None | Low |
| `brainstorming/scripts/helper.js` | Same-origin WebSocket | N/A | None | None | N/A | Negligible |
| `systematic-debugging/find-polluter.sh` | None | npm test (your tests) | None | None | None | Low |
| `writing-skills/render-graphs.js` | None | graphviz dot | SVG + dot files in skill dir | None | None | Low |

No scripts in this toolkit make outbound network calls, exfiltrate data, accept external URLs as input, or auto-download dependencies.
