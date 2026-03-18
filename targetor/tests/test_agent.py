"""
test_agent.py — Integration tests for agent.py. Spawns real subprocess.
Uses AgentHarness for wire-level protocol communication.
"""
import sys
import os
import time
import threading
import tempfile

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import pytest
import queue as _queue
import protocol as P


class AgentHarness:
    """
    Sends requests to agent subprocess and collects responses by ID.
    Thread-safe; background reader routes messages into per-request queues.
    """

    def __init__(self, proc):
        self.proc = proc
        self._queues = {}
        self._lock = threading.Lock()
        self._reader = threading.Thread(target=self._read_loop, daemon=True)
        self._reader.start()

    def _read_loop(self):
        try:
            for line in self.proc.stdout:
                try:
                    msg = P.decode(line)
                except ValueError:
                    continue
                req_id = msg.get("id")
                with self._lock:
                    q = self._queues.get(req_id)
                if q is not None:
                    q.put(msg)
        finally:
            import queue
            with self._lock:
                for q in self._queues.values():
                    q.put(None)

    def send(self, cmd, payload, req_id=None):
        import queue
        req_id = req_id or P.new_id()
        q = queue.Queue()
        with self._lock:
            self._queues[req_id] = q
        msg = P.make_request(cmd, payload, req_id=req_id)
        self.proc.stdin.write(P.encode(msg))
        self.proc.stdin.flush()
        return req_id, q

    def collect(self, q, timeout=10, until_done=False):
        """Collect messages from queue. If until_done, collect until STATUS_DONE."""
        msgs = []
        deadline = time.time() + timeout
        while True:
            remaining = deadline - time.time()
            if remaining <= 0:
                raise TimeoutError(f"Timed out waiting for response (got {msgs})")
            try:
                msg = q.get(timeout=min(remaining, 0.5))
            except _queue.Empty:
                continue  # retry until deadline
            if msg is None:
                break
            msgs.append(msg)
            if not until_done:
                break
            if msg["status"] in (P.STATUS_DONE, P.STATUS_ERROR, P.STATUS_OK):
                break
        return msgs


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture
def harness(agent_proc):
    return AgentHarness(agent_proc)


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

def test_ping(harness):
    _, q = harness.send(P.CMD_PING, {})
    msgs = harness.collect(q)
    assert len(msgs) == 1
    assert msgs[0]["status"] == P.STATUS_OK
    assert msgs[0]["payload"]["pong"] is True


def test_exec_echo(harness):
    _, q = harness.send(P.CMD_EXEC, {"command": "echo hello"})
    msgs = harness.collect(q)
    assert msgs[0]["status"] == P.STATUS_OK
    stdout = P.decode_content(
        msgs[0]["payload"]["stdout"],
        msgs[0]["payload"].get("stdout_encoding", "utf-8"),
    )
    assert b"hello" in stdout


def test_exec_returncode_nonzero(harness):
    _, q = harness.send(P.CMD_EXEC, {"command": "exit 42", "stream": False})
    msgs = harness.collect(q)
    assert msgs[0]["status"] == P.STATUS_OK
    assert msgs[0]["payload"]["returncode"] == 42


def test_exec_stderr(harness):
    _, q = harness.send(P.CMD_EXEC, {"command": "echo err >&2", "stream": True})
    msgs = harness.collect(q, until_done=True)
    stream_msgs = [m for m in msgs if m["status"] == P.STATUS_STREAMING]
    stderr_msgs = [m for m in stream_msgs if m["payload"].get("stream") == "stderr"]
    assert len(stderr_msgs) >= 1
    combined = b"".join(
        P.decode_content(m["payload"]["content"], m["payload"].get("encoding", "utf-8"))
        for m in stderr_msgs
    )
    assert b"err" in combined


def test_exec_streaming(harness):
    _, q = harness.send(P.CMD_EXEC, {"command": "echo hello", "stream": True})
    msgs = harness.collect(q, until_done=True)
    statuses = [m["status"] for m in msgs]
    assert P.STATUS_STREAMING in statuses
    assert msgs[-1]["status"] == P.STATUS_DONE


def test_exec_buffered(harness):
    _, q = harness.send(P.CMD_EXEC, {"command": "echo buffered", "stream": False})
    msgs = harness.collect(q)
    assert len(msgs) == 1
    p = msgs[0]["payload"]
    assert "stdout" in p
    assert "stderr" in p
    assert "returncode" in p


def test_exec_timeout(harness):
    _, q = harness.send(P.CMD_EXEC, {"command": "sleep 10", "stream": False, "timeout": 1})
    msgs = harness.collect(q, timeout=10)
    assert msgs[0]["status"] == P.STATUS_ERROR
    assert msgs[0]["payload"]["code"] == P.ERR_TIMEOUT


def test_exec_cwd(harness):
    _, q = harness.send(P.CMD_EXEC, {"command": "pwd", "cwd": "/tmp"})
    msgs = harness.collect(q)
    stdout = P.decode_content(
        msgs[0]["payload"]["stdout"],
        msgs[0]["payload"].get("stdout_encoding", "utf-8"),
    )
    assert b"/tmp" in stdout


def test_exec_missing_command(harness):
    _, q = harness.send(P.CMD_EXEC, {})  # no 'command' key
    msgs = harness.collect(q)
    assert msgs[0]["status"] == P.STATUS_ERROR
    assert msgs[0]["payload"]["code"] == P.ERR_INVALID_PAYLOAD


def test_read_file_utf8(harness, tmp_path):
    f = tmp_path / "test.txt"
    f.write_text("hello world\n", encoding="utf-8")
    _, q = harness.send(P.CMD_READ_FILE, {"path": str(f)})
    msgs = harness.collect(q)
    assert msgs[0]["status"] == P.STATUS_OK
    p = msgs[0]["payload"]
    content = P.decode_content(p["content"], p.get("encoding", "utf-8"))
    assert content == b"hello world\n"


def test_read_file_binary(harness, tmp_path):
    raw = bytes(range(256))
    f = tmp_path / "binary.bin"
    f.write_bytes(raw)
    _, q = harness.send(P.CMD_READ_FILE, {"path": str(f)})
    msgs = harness.collect(q)
    assert msgs[0]["status"] == P.STATUS_OK
    p = msgs[0]["payload"]
    assert p["encoding"] == "base64"
    recovered = P.decode_content(p["content"], p["encoding"])
    assert recovered == raw


def test_read_file_not_found(harness):
    _, q = harness.send(P.CMD_READ_FILE, {"path": "/nonexistent/path/file.txt"})
    msgs = harness.collect(q)
    assert msgs[0]["status"] == P.STATUS_ERROR
    assert msgs[0]["payload"]["code"] == P.ERR_FILE_NOT_FOUND


def test_write_file_create(harness, tmp_path):
    dest = str(tmp_path / "output.txt")
    content, encoding = P.encode_content(b"written by agent\n")
    _, q = harness.send(P.CMD_WRITE_FILE, {
        "path": dest,
        "content": content,
        "encoding": encoding,
    })
    msgs = harness.collect(q)
    assert msgs[0]["status"] == P.STATUS_OK
    assert open(dest, "rb").read() == b"written by agent\n"


def test_write_file_append(harness, tmp_path):
    dest = str(tmp_path / "append.txt")
    with open(dest, "wb") as fh:
        fh.write(b"line1\n")
    content, encoding = P.encode_content(b"line2\n")
    _, q = harness.send(P.CMD_WRITE_FILE, {
        "path": dest,
        "content": content,
        "encoding": encoding,
        "mode": "a",
    })
    msgs = harness.collect(q)
    assert msgs[0]["status"] == P.STATUS_OK
    assert open(dest, "rb").read() == b"line1\nline2\n"


def test_write_file_makedirs(harness, tmp_path):
    dest = str(tmp_path / "a" / "b" / "c" / "file.txt")
    content, encoding = P.encode_content(b"nested\n")
    _, q = harness.send(P.CMD_WRITE_FILE, {
        "path": dest,
        "content": content,
        "encoding": encoding,
        "makedirs": True,
    })
    msgs = harness.collect(q)
    assert msgs[0]["status"] == P.STATUS_OK
    assert open(dest, "rb").read() == b"nested\n"


def test_list_dir(harness, tmp_path):
    (tmp_path / "file.txt").write_text("hi")
    (tmp_path / "subdir").mkdir()
    _, q = harness.send(P.CMD_LIST_DIR, {"path": str(tmp_path)})
    msgs = harness.collect(q)
    assert msgs[0]["status"] == P.STATUS_OK
    entries = msgs[0]["payload"]["entries"]
    assert len(entries) >= 2
    for e in entries:
        assert "name" in e
        assert "type" in e
        assert "size" in e
        assert "mtime" in e


def test_list_dir_not_found(harness):
    _, q = harness.send(P.CMD_LIST_DIR, {"path": "/nonexistent/dir/path"})
    msgs = harness.collect(q)
    assert msgs[0]["status"] == P.STATUS_ERROR
    assert msgs[0]["payload"]["code"] == P.ERR_FILE_NOT_FOUND


def test_env_info(harness):
    _, q = harness.send(P.CMD_ENV_INFO, {})
    msgs = harness.collect(q)
    assert msgs[0]["status"] == P.STATUS_OK
    p = msgs[0]["payload"]
    for key in ("hostname", "python_version", "platform", "cwd", "pid"):
        assert key in p


def test_unknown_command(harness):
    _, q = harness.send("totally_unknown_cmd", {})
    msgs = harness.collect(q)
    assert msgs[0]["status"] == P.STATUS_ERROR
    assert msgs[0]["payload"]["code"] == P.ERR_UNKNOWN_CMD


def test_malformed_json_agent_continues(agent_proc, harness):
    # Send garbage line
    agent_proc.stdin.write(b"this is not json at all\n")
    agent_proc.stdin.flush()
    time.sleep(0.1)
    # Agent should still respond to a valid ping
    _, q = harness.send(P.CMD_PING, {})
    msgs = harness.collect(q)
    assert msgs[0]["status"] == P.STATUS_OK
    assert msgs[0]["payload"]["pong"] is True


def test_concurrent_requests(harness):
    import queue as qmod
    _, q1 = harness.send(P.CMD_EXEC, {"command": "echo req1"})
    _, q2 = harness.send(P.CMD_EXEC, {"command": "echo req2"})

    msgs1 = harness.collect(q1, timeout=10)
    msgs2 = harness.collect(q2, timeout=10)

    assert msgs1[0]["status"] == P.STATUS_OK
    assert msgs2[0]["status"] == P.STATUS_OK

    stdout1 = P.decode_content(
        msgs1[0]["payload"]["stdout"],
        msgs1[0]["payload"].get("stdout_encoding", "utf-8"),
    )
    stdout2 = P.decode_content(
        msgs2[0]["payload"]["stdout"],
        msgs2[0]["payload"].get("stdout_encoding", "utf-8"),
    )
    assert b"req1" in stdout1
    assert b"req2" in stdout2
