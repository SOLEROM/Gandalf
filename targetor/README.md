# Targetor — Remote Execution System for Embedded Linux

## Overview

Targetor lets a locally-running Claude CLI (with internet access) operate on a remote embedded Linux device (offline, reachable over a direct network link) as if it were its local environment.

```
┌────────────────────────────┐          SSH stdin/stdout          ┌─────────────────────────┐
│  Local machine             │  ─────────────────────────────►   │  Embedded Linux target  │
│  (internet access)         │                                    │  (no internet needed)   │
│                            │  ◄─────────────────────────────   │                         │
│  client.py                 │      newline-delimited JSON        │  agent.py               │
│  ├─ AgentConnection        │                                    │  ├─ stdin reader loop   │
│  ├─ SSHTransport           │                                    │  ├─ thread dispatcher   │
│  └─ protocol.py            │                                    │  └─ protocol.py         │
└────────────────────────────┘                                    └─────────────────────────┘
```

Transport uses SSH stdin/stdout for auth, encryption, and framing — no internet required on the target. The transport layer can later be swapped for TCP/ZeroMQ without touching the agent or client logic.

---

## Prerequisites

**Local machine:**
- Python 3.7+
- `ssh` client in PATH
- `pytest` for running tests (`pip install pytest`)

**Remote target:**
- Python 3.6+
- SSH server (`sshd`) running
- No external Python packages needed

---

## Deployment

Copy both files to the target (they must be in the same directory):

```bash
scp agent.py protocol.py user@target:~/
```

No installation, no pip, no virtual environment needed on the target.

---

## SSH Usage

```bash
# Basic command execution
python client.py --host target --user user exec "uname -a"

# Stream output in real time
python client.py --host target --user user exec "journalctl -f" --stream

# Read a file
python client.py --host target --user user read /etc/os-release

# Write a file
python client.py --host target --user user write /tmp/test.txt "hello"

# List a directory
python client.py --host target --user user ls /var/log

# Environment info
python client.py --host target --user user env

# Ping with latency
python client.py --host target --user user ping
```

Custom SSH options:

```bash
python client.py --host 192.168.1.100 --user pi --port 2222 --key ~/.ssh/id_ed25519 exec "ls -la"
```

---

## Local Testing

Use `--local` to run the agent as a local subprocess (no SSH required):

```bash
python client.py --local ping
python client.py --local exec "echo hello world"
python client.py --local exec "ls -la /tmp" --stream
python client.py --local read /etc/hostname
python client.py --local write /tmp/targetor_test.txt "hello"
python client.py --local ls /tmp
python client.py --local env
```

---

## Session Logging

Add `--log` to any command to record a timestamped log of the full session:

```bash
# Auto-named file (e.g. targetor_20260318T142545.log)
python client.py --local --log exec "uname -a"

# Explicit path
python client.py --host target --user user --log /tmp/session.log exec "journalctl -n 100"
```

The log file appends across runs. Each line is:
```
[<ISO-timestamp>] [<LEVEL>] <message>
```

| Level  | Content |
|--------|---------|
| `INFO` | Session start/end marker and the full CLI invocation |
| `SEND` | Raw JSON request sent to the agent |
| `RECV` | Raw JSON response from the agent (full payload including stdout/stderr) |

Example:
```
[2026-03-18T14:25:45.672] [INFO] === session start ===
[2026-03-18T14:25:45.672] [INFO] invocation: client.py --local --log exec uname -a
[2026-03-18T14:25:45.672] [SEND] {"id": "2a58a...", "cmd": "exec", "payload": {"command": "uname -a", "stream": false}}
[2026-03-18T14:25:45.696] [RECV] {"id": "2a58a...", "status": "ok", "payload": {"stdout": "Linux ...", "returncode": 0}}
[2026-03-18T14:25:45.698] [INFO] === session end ===
```

---

## Running Tests

```bash
cd /data/sync/agents/targetor
python -m pytest tests/ -v
```

All tests use `MockSSHTransport` — no real SSH connection needed.

---

## CLI Reference

```
python client.py [GLOBAL FLAGS] COMMAND [OPTIONS]

Global flags:
  --host HOST          Remote hostname or IP
  --user USER          SSH username
  --port PORT          SSH port (default: 22)
  --key PATH           SSH private key path
  --agent-path PATH    Path to agent.py on target (default: ~/agent.py)
  --local              Use local MockSSHTransport (no SSH)
  --timeout N          Request timeout in seconds (default: 30)
  --log [PATH]         Write timestamped session log to PATH
                       (auto-names file as targetor_YYYYMMDDTHHmmSS.log if PATH omitted)

Commands:
  ping                           Ping the agent, show latency
  exec CMD [--stream] [--cwd PATH] [--timeout N]
                                 Execute a shell command
  read PATH                      Read a remote file to stdout
  write PATH [CONTENT] [--append]
                                 Write content to a remote file
  ls [PATH]                      List a directory (default: .)
  env                            Show remote environment info
```

---

## Protocol Reference

All messages are newline-delimited JSON (one JSON object per line), encoded as UTF-8.

### Request format
```json
{"id": "<uuid>", "cmd": "<command>", "payload": {...}}
```

### Response format
```json
{"id": "<uuid>", "status": "<status>", "payload": {...}}
```

### Status codes
| Status      | Meaning                              |
|-------------|--------------------------------------|
| `ok`        | Success; payload contains result     |
| `error`     | Failure; payload has `code`+`message`|
| `streaming` | Partial output chunk                 |
| `done`      | Stream complete; payload has rc      |

### Commands
| Command      | Payload fields                                        |
|--------------|-------------------------------------------------------|
| `ping`       | *(none)*                                              |
| `exec`       | `command`, `stream?`, `cwd?`, `timeout?`, `env?`      |
| `read_file`  | `path`, `max_bytes?`                                  |
| `write_file` | `path`, `content`, `encoding?`, `mode?`, `makedirs?`  |
| `list_dir`   | `path?`                                               |
| `env_info`   | *(none)*                                              |

### Error codes
`INVALID_PAYLOAD`, `EXEC_FAILED`, `TIMEOUT`, `FILE_NOT_FOUND`, `PERMISSION_DENIED`, `IO_ERROR`, `UNKNOWN_COMMAND`, `INTERNAL`

### Content encoding
Binary files are base64-encoded for transport. UTF-8 text is sent as-is. The `encoding` field in read/write payloads indicates which format is in use.

---

## Architecture Notes

- **`protocol.py`** — Shared message format. Imported by both agent and client. Zero dependencies.
- **`agent.py`** — Single-file remote agent. Python 3.6+, zero deps. Runs with `python3 -u agent.py`. Each request is dispatched in a daemon thread; `stdout_lock` ensures writes don't interleave.
- **`transport.py`** — `Transport` ABC with `SSHTransport` (real) and `MockSSHTransport` (tests/local). Both return a `Popen` with identical stdin/stdout interface.
- **`client.py`** — `AgentConnection` wraps a transport. Background reader thread routes responses by request ID into per-request queues, enabling concurrent requests and streaming.

---

## Known Limitations

- `exec` with `stream=True` uses `select()` — works on Linux/macOS, not on Windows.
- No authentication beyond what SSH provides.
- No request cancellation (in-flight requests run to completion).
- `env_info` intentionally omits full environment variables for security.

---

## Future Extensions

- **TCP/ZeroMQ transport** — implement a new `Transport` subclass; no changes to agent or client logic.
- **File watching** — add `CMD_WATCH_FILE` with streaming status messages.
- **Multiplexed channels** — extend protocol to support named channels.
- **Compression** — add optional zlib/lz4 for large file transfers.
- **Request cancellation** — add `CMD_CANCEL` that signals the running subprocess.
