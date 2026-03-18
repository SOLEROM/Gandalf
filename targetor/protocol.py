"""
protocol.py — Shared message format for Targetor remote execution system.
Imported by both agent.py and client.py. No external dependencies.
"""
import json
import uuid
import base64

# Status codes
STATUS_OK = "ok"
STATUS_ERROR = "error"
STATUS_STREAMING = "streaming"
STATUS_DONE = "done"

# Command names
CMD_PING = "ping"
CMD_EXEC = "exec"
CMD_READ_FILE = "read_file"
CMD_WRITE_FILE = "write_file"
CMD_LIST_DIR = "list_dir"
CMD_ENV_INFO = "env_info"

# Error codes
ERR_INVALID_PAYLOAD = "INVALID_PAYLOAD"
ERR_EXEC_FAILED = "EXEC_FAILED"
ERR_TIMEOUT = "TIMEOUT"
ERR_FILE_NOT_FOUND = "FILE_NOT_FOUND"
ERR_PERMISSION_DENIED = "PERMISSION_DENIED"
ERR_IO_ERROR = "IO_ERROR"
ERR_UNKNOWN_CMD = "UNKNOWN_COMMAND"
ERR_INTERNAL = "INTERNAL"


def new_id():
    return str(uuid.uuid4())


def make_request(cmd, payload, req_id=None):
    return {
        "id": req_id or new_id(),
        "cmd": cmd,
        "payload": payload,
    }


def make_response(req_id, status, payload):
    return {
        "id": req_id,
        "status": status,
        "payload": payload,
    }


def make_ok(req_id, payload):
    return make_response(req_id, STATUS_OK, payload)


def make_error(req_id, code, message):
    return make_response(req_id, STATUS_ERROR, {"code": code, "message": message})


def encode(msg):
    """Serialize a message dict to newline-terminated UTF-8 JSON bytes."""
    return (json.dumps(msg, separators=(",", ":")) + "\n").encode("utf-8")


def decode(line):
    """Deserialize a line (bytes or str) to a dict. Raises ValueError on empty or invalid JSON."""
    if isinstance(line, bytes):
        line = line.decode("utf-8")
    line = line.strip()
    if not line:
        raise ValueError("Empty line")
    try:
        return json.loads(line)
    except json.JSONDecodeError as e:
        raise ValueError(f"Invalid JSON: {e}") from e


def encode_content(raw_bytes):
    """
    Encode bytes for transport. Returns (text_str, encoding_str).
    Tries UTF-8 first; falls back to base64.
    """
    try:
        return raw_bytes.decode("utf-8"), "utf-8"
    except UnicodeDecodeError:
        return base64.b64encode(raw_bytes).decode("ascii"), "base64"


def decode_content(text_str, encoding_str):
    """Decode transported content back to bytes."""
    if encoding_str == "base64":
        return base64.b64decode(text_str)
    else:
        return text_str.encode("utf-8")
