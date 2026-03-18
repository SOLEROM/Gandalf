# Targetor — Project Scope & Continuity Notes


## What this project is

A lightweight remote execution system so a locally-running Claude CLI (with internet) can operate on a remote embedded Linux device (offline, reachable over a direct network link) as if it were its local environment.

- Transport: SSH stdin/stdout — provides auth, encryption, no internet needed on target
- Protocol: newline-delimited JSON (one JSON object per line, UTF-8)
- Designed so the transport layer can later be swapped to TCP/ZeroMQ without touching agent or client logic

---

## File map

```
/data/sync/agents/targetor/
├── protocol.py       # Shared message format — constants, encode/decode, content encoding
├── agent.py          # Remote agent — runs on target, Python 3.6+, zero deps
├── transport.py      # Transport ABC + SSHTransport + MockSSHTransport
├── client.py         # AgentConnection class + CLI (argparse subcommands)
├── conftest.py       # pytest sys.path fix + shared fixtures
├── agent.md          # Instructions for Claude Code on how to use this infra for remote work
├── scope.md          # This file
├── README.md         # User-facing docs
├── plan.md           # Original implementation plan (reference)
└── tests/
    ├── test_protocol.py   # 17 unit tests — no subprocess
    ├── test_agent.py      # 21 integration tests — spawns agent subprocess
    └── test_client.py     # 14 tests — uses MockSSHTransport (no real SSH)
```

---

## Architecture

### protocol.py
- Constants: `STATUS_OK/ERROR/STREAMING/DONE`, `CMD_PING/EXEC/READ_FILE/WRITE_FILE/LIST_DIR/ENV_INFO`
- Error codes: `ERR_INVALID_PAYLOAD`, `ERR_EXEC_FAILED`, `ERR_TIMEOUT`, `ERR_FILE_NOT_FOUND`, `ERR_PERMISSION_DENIED`, `ERR_IO_ERROR`, `ERR_UNKNOWN_CMD`, `ERR_INTERNAL`
- `encode(msg)` → newline-terminated UTF-8 JSON bytes
- `decode(line)` → dict; raises `ValueError` on empty or invalid JSON; accepts bytes or str
- `encode_content(raw_bytes)` → `(text, encoding)` — tries UTF-8, falls back to base64
- `decode_content(text, encoding)` → bytes

### agent.py
- Must run with `python3 -u agent.py` (unbuffered stdout)
- `stdout_lock = threading.Lock()` — all writes go through `safe_write()`
- Main loop: `for line in sys.stdin` — exits cleanly on SSH disconnect (EOF)
- Each request dispatched in a daemon `threading.Thread`
- All subprocesses use `stdin=DEVNULL` to prevent stdout protocol corruption
- **exec handler**: uses `start_new_session=True` + `os.killpg()` on timeout — critical for killing shell + its children (e.g. `sleep 10` spawned by a shell with `shell=True`)
- Streaming exec: uses `select.select()` on stdout/stderr fds in a loop; removes fd on empty read
- Handlers: `ping`, `exec`, `read_file`, `write_file`, `list_dir`, `env_info`

### transport.py
- `Transport` ABC with single `connect() → Popen` method
- `SSHTransport(host, user, port, key, agent_path, python_cmd)` — real SSH
- `MockSSHTransport(agent_path, python_cmd)` — runs agent.py locally, identical Popen interface
- Both deployed to the same directory; `MockSSHTransport` defaults `agent_path` to sibling `agent.py`

### client.py
- `AgentConnection(transport, logger=None)` — calls `transport.connect()` internally
- Background reader thread routes responses by `msg["id"]` into per-request `Queue`s
- **Critical ordering**: register queue BEFORE writing to pipe (prevents race with fast responses)
- `call(cmd, payload, timeout)` → single ok/error response; raises `AgentError` on error status
- `call_streaming(cmd, payload, timeout)` → iterator of streaming/done messages
- High-level API: `ping()`, `exec_cmd()`, `read_file()`, `write_file()`, `list_dir()`, `env_info()`
- `exec_cmd(stream=False)` returns `(returncode, stdout_bytes, stderr_bytes)`
- `exec_cmd(stream=True)` returns iterator of message dicts
- `AgentError(code, message)` — raised by `call()` and `call_streaming()` on error responses
- Context manager: `with AgentConnection(transport) as conn:`
- `Logger(path)` — thread-safe timestamped file logger; records `[INFO]` session events, `[SEND]` raw JSON requests, `[RECV]` raw JSON responses; appends across runs
- CLI via argparse: subcommands `ping`, `exec`, `read`, `write`, `ls`, `env`
- CLI flag `--local` → uses MockSSHTransport; otherwise requires `--host`
- CLI flag `--log [PATH]` → enables session logging; auto-names file as `targetor_YYYYMMDDTHHmmSS.log` if no path given

### conftest.py
- `agent_proc` fixture → raw `Popen` of agent.py (for wire-level tests in test_agent.py)
- `mock_transport` fixture → `MockSSHTransport` pointing at local agent.py
- `conn` fixture → `AgentConnection(mock_transport)` (for test_client.py)

---

## Key design decisions & lessons learned

### Subprocess timeout with shell=True
**Problem**: `proc.kill()` after `TimeoutExpired` kills the shell but not its children (`sleep 10` etc.), which keep the pipes open → `proc.communicate()` hangs forever.

**Fix**: `start_new_session=True` in `Popen` puts the shell and all its children in a new process group. Then `os.killpg(proc.pid, signal.SIGKILL)` kills the entire group atomically. Fallback to `proc.kill()` if `os.killpg` fails.

### Queue polling in test harness
**Problem**: `AgentHarness.collect()` used `except Exception: raise TimeoutError` which triggered on every `queue.Empty`, failing immediately instead of retrying until the deadline.

**Fix**: Catch `queue.Empty` specifically and `continue` the loop; only raise `TimeoutError` when `deadline - time.time() <= 0`.

### Thread safety in AgentConnection
The reader thread and calling threads share `self._queues`. Protected by `self._lock`. Queue must be registered before writing to pipe — otherwise a very fast agent response could arrive before the queue exists and be lost.

### EOF handling
When the agent subprocess exits (SSH disconnect or `proc.stdin.close()`), the reader loop exits its `for line in proc.stdout` loop. A finally block injects `None` sentinels into all pending queues so blocked `call()` / `call_streaming()` unblock with a `ConnectionError`.

---

## Test strategy

- `test_protocol.py` — pure unit tests, no I/O
- `test_agent.py` — uses `AgentHarness` (custom helper, not `AgentConnection`) for wire-level tests; spawned from `agent_proc` fixture
- `test_client.py` — uses `AgentConnection` via `MockSSHTransport`; never touches real SSH
- All tests run with `python -m pytest tests/ -v` from `/data/sync/agents/targetor/`

---

## Deployment (to a real target)

```bash
# One-time: copy both files (they import each other)
scp agent.py protocol.py user@target:~/

# Verify
python client.py --host target --user user ping
```

---

## CLI quick reference

```bash
# Local (no SSH needed)
python client.py --local ping
python client.py --local exec "uname -a"
python client.py --local exec "journalctl -f" --stream
python client.py --local read /etc/os-release
python client.py --local write /tmp/test.txt "hello"
python client.py --local ls /var/log
python client.py --local env

# Remote via SSH
python client.py --host 192.168.1.100 --user pi exec "uname -a"
python client.py --host target --user user --key ~/.ssh/id_ed25519 read /etc/hostname

# Session logging
python client.py --local --log exec "uname -a"              # auto-named log file
python client.py --host target --user user --log /tmp/session.log exec "ls /var/log"
```

---

## What agent.md is for

`agent.md` is instructions for Claude Code telling it to route all commands and file operations through `client.py` when working on the remote device. It covers the tool mapping (Bash → exec, Read → read, Write → write, etc.), the edit workflow (read → local edit → write back), and behavioral rules (no local assumptions, use `--stream` for long output, chain with `&&`).

---

## Potential next steps (not started)

- TCP/ZeroMQ transport — implement new `Transport` subclass; no changes to agent or client
- File watching (`CMD_WATCH_FILE`) with streaming status messages
- Request cancellation (`CMD_CANCEL` that sends SIGINT to the running subprocess)
- Compression (zlib/lz4) for large file transfers
- Named channels / multiplexing
- `max_bytes` enforcement in `read_file` currently checks file size first but doesn't prevent race; could be improved
- `write_file` with `makedirs=True` could fail silently if the path is a file not a dir — could add a check
- Windows support for streaming exec (replace `select` with threads on stdout/stderr)
