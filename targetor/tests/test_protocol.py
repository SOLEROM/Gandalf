"""
test_protocol.py — Unit tests for protocol.py. No subprocess required.
"""
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import pytest
import protocol as P


def test_encode_decode_roundtrip():
    msg = P.make_request(P.CMD_PING, {"foo": "bar"})
    encoded = P.encode(msg)
    decoded = P.decode(encoded)
    assert decoded == msg


def test_decode_bytes_input():
    msg = {"id": "1", "cmd": "ping", "payload": {}}
    data = P.encode(msg)
    assert isinstance(data, bytes)
    result = P.decode(data)
    assert result == msg


def test_decode_str_input():
    msg = {"id": "1", "cmd": "ping", "payload": {}}
    data = P.encode(msg).decode("utf-8")
    result = P.decode(data)
    assert result == msg


def test_decode_empty_raises():
    with pytest.raises(ValueError):
        P.decode("")


def test_decode_empty_bytes_raises():
    with pytest.raises(ValueError):
        P.decode(b"")


def test_decode_whitespace_raises():
    with pytest.raises(ValueError):
        P.decode("   \n")


def test_decode_invalid_json_raises():
    with pytest.raises(ValueError):
        P.decode("not valid json {{{")


def test_make_request_structure():
    req = P.make_request(P.CMD_EXEC, {"command": "ls"})
    assert "id" in req
    assert req["cmd"] == P.CMD_EXEC
    assert req["payload"] == {"command": "ls"}


def test_make_request_unique_ids():
    r1 = P.make_request(P.CMD_PING, {})
    r2 = P.make_request(P.CMD_PING, {})
    assert r1["id"] != r2["id"]


def test_make_request_custom_id():
    req = P.make_request(P.CMD_PING, {}, req_id="custom-123")
    assert req["id"] == "custom-123"


def test_make_ok_structure():
    msg = P.make_ok("req-1", {"pong": True})
    assert msg["id"] == "req-1"
    assert msg["status"] == P.STATUS_OK
    assert msg["payload"] == {"pong": True}


def test_make_error_structure():
    msg = P.make_error("req-1", P.ERR_TIMEOUT, "timed out")
    assert msg["id"] == "req-1"
    assert msg["status"] == P.STATUS_ERROR
    assert msg["payload"]["code"] == P.ERR_TIMEOUT
    assert msg["payload"]["message"] == "timed out"


def test_encode_content_utf8():
    raw = b"hello world"
    text, enc = P.encode_content(raw)
    assert enc == "utf-8"
    assert text == "hello world"


def test_encode_content_binary_base64():
    raw = bytes(range(256))  # contains non-UTF-8 bytes
    text, enc = P.encode_content(raw)
    assert enc == "base64"
    # text should be valid ASCII (base64)
    assert all(c in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
               for c in text)


def test_decode_content_roundtrip_utf8():
    raw = b"Hello, \xc3\xa9l\xc3\xa8ve!"  # valid UTF-8
    text, enc = P.encode_content(raw)
    assert enc == "utf-8"
    recovered = P.decode_content(text, enc)
    assert recovered == raw


def test_decode_content_roundtrip_base64():
    raw = bytes([0x00, 0xFF, 0xFE, 0x80, 0x01, 0x7F])
    text, enc = P.encode_content(raw)
    assert enc == "base64"
    recovered = P.decode_content(text, enc)
    assert recovered == raw


def test_encode_produces_newline_terminated():
    data = P.encode({"id": "1", "status": "ok", "payload": {}})
    assert data.endswith(b"\n")


def test_constants_defined():
    assert P.STATUS_OK == "ok"
    assert P.STATUS_ERROR == "error"
    assert P.STATUS_STREAMING == "streaming"
    assert P.STATUS_DONE == "done"
    assert P.CMD_PING == "ping"
    assert P.CMD_EXEC == "exec"
    assert P.CMD_READ_FILE == "read_file"
    assert P.CMD_WRITE_FILE == "write_file"
    assert P.CMD_LIST_DIR == "list_dir"
    assert P.CMD_ENV_INFO == "env_info"
