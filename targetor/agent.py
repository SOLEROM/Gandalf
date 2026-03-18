#!/usr/bin/env python3
"""
agent.py — Remote agent for Targetor. Python 3.6+. No external deps.
Run with: python3 -u agent.py
Communicates via stdin/stdout using newline-delimited JSON protocol.
"""
import os
import sys
import signal
import threading
import subprocess
import select
import platform
import socket

# Both files deployed together; import protocol from same directory
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import protocol as P

stdout_lock = threading.Lock()


def safe_write(msg):
    data = P.encode(msg)
    with stdout_lock:
        sys.stdout.buffer.write(data)
        sys.stdout.buffer.flush()


# ---------------------------------------------------------------------------
# Handlers
# ---------------------------------------------------------------------------

def handle_ping(req_id, payload):
    safe_write(P.make_ok(req_id, {"pong": True}))


def handle_exec(req_id, payload):
    command = payload.get("command")
    if not command:
        safe_write(P.make_error(req_id, P.ERR_INVALID_PAYLOAD, "Missing 'command' field"))
        return

    stream = payload.get("stream", False)
    cwd = payload.get("cwd") or None
    timeout = payload.get("timeout") or None
    env_extra = payload.get("env") or {}

    env = os.environ.copy()
    env.update(env_extra)

    try:
        proc = subprocess.Popen(
            command,
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            stdin=subprocess.DEVNULL,
            cwd=cwd,
            env=env,
            start_new_session=True,
        )
    except Exception as e:
        safe_write(P.make_error(req_id, P.ERR_EXEC_FAILED, str(e)))
        return

    if stream:
        fds = {
            proc.stdout.fileno(): ("stdout", proc.stdout),
            proc.stderr.fileno(): ("stderr", proc.stderr),
        }
        while fds:
            try:
                readable, _, _ = select.select(list(fds.keys()), [], [], 1.0)
            except ValueError:
                break
            for fd in readable:
                stream_name, _ = fds[fd]
                try:
                    chunk = os.read(fd, 4096)
                except OSError:
                    chunk = b""
                if chunk:
                    text, encoding = P.encode_content(chunk)
                    safe_write(P.make_response(req_id, P.STATUS_STREAMING, {
                        "stream": stream_name,
                        "content": text,
                        "encoding": encoding,
                    }))
                else:
                    del fds[fd]
        returncode = proc.wait()
        safe_write(P.make_response(req_id, P.STATUS_DONE, {"returncode": returncode}))
    else:
        try:
            stdout, stderr = proc.communicate(timeout=timeout)
        except subprocess.TimeoutExpired:
            try:
                os.killpg(proc.pid, signal.SIGKILL)
            except OSError:
                proc.kill()
            proc.communicate()
            safe_write(P.make_error(req_id, P.ERR_TIMEOUT,
                                    f"Command timed out after {timeout}s"))
            return
        stdout_text, stdout_enc = P.encode_content(stdout)
        stderr_text, stderr_enc = P.encode_content(stderr)
        safe_write(P.make_ok(req_id, {
            "stdout": stdout_text,
            "stdout_encoding": stdout_enc,
            "stderr": stderr_text,
            "stderr_encoding": stderr_enc,
            "returncode": proc.returncode,
        }))


def handle_read_file(req_id, payload):
    path = payload.get("path")
    if not path:
        safe_write(P.make_error(req_id, P.ERR_INVALID_PAYLOAD, "Missing 'path' field"))
        return

    max_bytes = payload.get("max_bytes")

    try:
        size = os.path.getsize(path)
        if max_bytes is not None and size > max_bytes:
            safe_write(P.make_error(req_id, P.ERR_IO_ERROR,
                                    f"File size {size} exceeds max_bytes {max_bytes}"))
            return
        with open(path, "rb") as f:
            raw = f.read(max_bytes) if max_bytes else f.read()
    except FileNotFoundError:
        safe_write(P.make_error(req_id, P.ERR_FILE_NOT_FOUND, f"File not found: {path}"))
        return
    except PermissionError:
        safe_write(P.make_error(req_id, P.ERR_PERMISSION_DENIED,
                                f"Permission denied: {path}"))
        return
    except OSError as e:
        safe_write(P.make_error(req_id, P.ERR_IO_ERROR, str(e)))
        return

    content, encoding = P.encode_content(raw)
    safe_write(P.make_ok(req_id, {
        "content": content,
        "encoding": encoding,
        "size": len(raw),
    }))


def handle_write_file(req_id, payload):
    path = payload.get("path")
    if path is None:
        safe_write(P.make_error(req_id, P.ERR_INVALID_PAYLOAD, "Missing 'path' field"))
        return

    content = payload.get("content", "")
    encoding = payload.get("encoding", "utf-8")
    mode = payload.get("mode", "w")
    makedirs = payload.get("makedirs", False)

    try:
        raw = P.decode_content(content, encoding)
    except Exception as e:
        safe_write(P.make_error(req_id, P.ERR_INVALID_PAYLOAD,
                                f"Failed to decode content: {e}"))
        return

    if makedirs:
        parent = os.path.dirname(os.path.abspath(path))
        try:
            os.makedirs(parent, exist_ok=True)
        except OSError as e:
            safe_write(P.make_error(req_id, P.ERR_IO_ERROR,
                                    f"makedirs failed: {e}"))
            return

    open_mode = "ab" if mode == "a" else "wb"
    try:
        with open(path, open_mode) as f:
            f.write(raw)
    except PermissionError:
        safe_write(P.make_error(req_id, P.ERR_PERMISSION_DENIED,
                                f"Permission denied: {path}"))
        return
    except OSError as e:
        safe_write(P.make_error(req_id, P.ERR_IO_ERROR, str(e)))
        return

    safe_write(P.make_ok(req_id, {"bytes_written": len(raw)}))


def handle_list_dir(req_id, payload):
    path = payload.get("path", ".")

    try:
        entries = []
        with os.scandir(path) as it:
            for entry in it:
                try:
                    stat = entry.stat(follow_symlinks=False)
                    if entry.is_symlink():
                        entry_type = "symlink"
                    elif entry.is_dir(follow_symlinks=False):
                        entry_type = "dir"
                    elif entry.is_file(follow_symlinks=False):
                        entry_type = "file"
                    else:
                        entry_type = "other"

                    info = {
                        "name": entry.name,
                        "path": entry.path,
                        "type": entry_type,
                        "size": stat.st_size,
                        "mtime": stat.st_mtime,
                        "mode": stat.st_mode,
                    }
                    if entry_type == "symlink":
                        try:
                            info["target"] = os.readlink(entry.path)
                        except OSError:
                            info["target"] = None
                    entries.append(info)
                except OSError:
                    pass
    except FileNotFoundError:
        safe_write(P.make_error(req_id, P.ERR_FILE_NOT_FOUND,
                                f"Directory not found: {path}"))
        return
    except PermissionError:
        safe_write(P.make_error(req_id, P.ERR_PERMISSION_DENIED,
                                f"Permission denied: {path}"))
        return
    except OSError as e:
        safe_write(P.make_error(req_id, P.ERR_IO_ERROR, str(e)))
        return

    safe_write(P.make_ok(req_id, {"entries": entries}))


def handle_env_info(req_id, payload):
    safe_write(P.make_ok(req_id, {
        "python_version": sys.version,
        "platform": platform.platform(),
        "hostname": socket.gethostname(),
        "cwd": os.getcwd(),
        "pid": os.getpid(),
    }))


# ---------------------------------------------------------------------------
# Dispatcher
# ---------------------------------------------------------------------------

HANDLERS = {
    P.CMD_PING: handle_ping,
    P.CMD_EXEC: handle_exec,
    P.CMD_READ_FILE: handle_read_file,
    P.CMD_WRITE_FILE: handle_write_file,
    P.CMD_LIST_DIR: handle_list_dir,
    P.CMD_ENV_INFO: handle_env_info,
}


def dispatch(msg):
    handler = HANDLERS.get(msg.get("cmd"))
    if not handler:
        safe_write(P.make_error(
            msg.get("id", "unknown"),
            P.ERR_UNKNOWN_CMD,
            f"Unknown command: {msg.get('cmd')!r}",
        ))
        return
    try:
        handler(msg.get("id", "unknown"), msg.get("payload", {}))
    except Exception as e:
        safe_write(P.make_error(msg.get("id", "unknown"), P.ERR_INTERNAL, str(e)))


def main():
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            msg = P.decode(line)
        except ValueError:
            # Malformed JSON — log to stderr, keep running
            sys.stderr.write(f"[agent] malformed JSON ignored: {line[:80]!r}\n")
            sys.stderr.flush()
            continue

        t = threading.Thread(target=dispatch, args=(msg,), daemon=True)
        t.start()


if __name__ == "__main__":
    main()
