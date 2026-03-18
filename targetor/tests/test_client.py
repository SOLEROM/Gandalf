"""
test_client.py — Tests for AgentConnection using MockSSHTransport (no real SSH).
"""
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import pytest
import protocol as P
from client import AgentConnection, AgentError


def test_ping(conn):
    result = conn.ping()
    assert isinstance(result, dict)
    assert result.get("pong") is True


def test_exec_cmd_buffered(conn):
    rc, stdout, stderr = conn.exec_cmd("echo hi")
    assert rc == 0
    assert stdout == b"hi\n"
    assert stderr == b""


def test_exec_cmd_nonzero(conn):
    rc, stdout, stderr = conn.exec_cmd("exit 3")
    assert rc == 3


def test_exec_cmd_streaming(conn):
    msgs = list(conn.exec_cmd("echo streaming_test", stream=True))
    statuses = [m["status"] for m in msgs]
    assert P.STATUS_STREAMING in statuses
    assert msgs[-1]["status"] == P.STATUS_DONE


def test_read_write_roundtrip(conn, tmp_path):
    dest = str(tmp_path / "roundtrip.bin")
    data = bytes(range(256))
    conn.write_file(dest, data)
    recovered = conn.read_file(dest)
    assert recovered == data


def test_read_write_roundtrip_utf8(conn, tmp_path):
    dest = str(tmp_path / "text.txt")
    data = b"hello from client\n"
    conn.write_file(dest, data)
    recovered = conn.read_file(dest)
    assert recovered == data


def test_list_dir(conn, tmp_path):
    (tmp_path / "a.txt").write_text("a")
    (tmp_path / "b.txt").write_text("b")
    (tmp_path / "subdir").mkdir()
    entries = conn.list_dir(str(tmp_path))
    assert isinstance(entries, list)
    assert len(entries) >= 3
    for e in entries:
        assert "name" in e
        assert "type" in e
        assert "size" in e
        assert "mtime" in e


def test_env_info(conn):
    info = conn.env_info()
    for key in ("hostname", "python_version", "platform", "cwd", "pid"):
        assert key in info


def test_connection_error_on_unknown(conn):
    with pytest.raises(AgentError) as exc_info:
        conn.call("no_such_command", {})
    assert exc_info.value.code == P.ERR_UNKNOWN_CMD


def test_context_manager(mock_transport):
    with AgentConnection(mock_transport) as c:
        result = c.ping()
    assert result["pong"] is True
    # After exit, proc should be terminated (no exception raised)


def test_exec_stderr_capture(conn):
    rc, stdout, stderr = conn.exec_cmd("echo errout >&2")
    assert b"errout" in stderr


def test_write_file_append(conn, tmp_path):
    dest = str(tmp_path / "append.txt")
    conn.write_file(dest, b"line1\n", mode="w")
    conn.write_file(dest, b"line2\n", mode="a")
    recovered = conn.read_file(dest)
    assert recovered == b"line1\nline2\n"


def test_write_file_makedirs(conn, tmp_path):
    dest = str(tmp_path / "nested" / "deep" / "file.txt")
    conn.write_file(dest, b"deep content\n", makedirs=True)
    recovered = conn.read_file(dest)
    assert recovered == b"deep content\n"
