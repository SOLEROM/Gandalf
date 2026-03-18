"""
client.py — Local client proxy and CLI for Targetor.
"""
import sys
import os
import threading
import argparse

# Ensure protocol and transport are importable when run directly
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import protocol as P
from transport import Transport, SSHTransport, MockSSHTransport

try:
    from queue import Queue, Empty
except ImportError:
    from Queue import Queue, Empty  # Python 2 fallback (shouldn't be needed)


class AgentError(Exception):
    """Raised when the agent returns an error response."""
    def __init__(self, code, message):
        self.code = code
        self.message = message
        super().__init__(f"[{code}] {message}")


class AgentConnection:
    """
    Manages a bidirectional connection to a remote agent via a Transport.
    Thread-safe; a background reader thread routes responses by request ID.
    """

    def __init__(self, transport: Transport):
        self._proc = transport.connect()
        self._queues = {}   # req_id -> Queue
        self._lock = threading.Lock()
        self._closed = False
        self._reader = threading.Thread(target=self._reader_loop, daemon=True)
        self._reader.start()

    def _reader_loop(self):
        try:
            for line in self._proc.stdout:
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
            # EOF — inject sentinel into all pending queues
            with self._lock:
                queues = list(self._queues.values())
            for q in queues:
                q.put(None)

    def _send(self, msg):
        data = P.encode(msg)
        self._proc.stdin.write(data)
        self._proc.stdin.flush()

    def _request(self, cmd, payload):
        """Register queue BEFORE writing to pipe, then send."""
        req_id = P.new_id()
        q = Queue()
        with self._lock:
            self._queues[req_id] = q
        msg = P.make_request(cmd, payload, req_id=req_id)
        self._send(msg)
        return req_id, q

    def _deregister(self, req_id):
        with self._lock:
            self._queues.pop(req_id, None)

    def call(self, cmd, payload, timeout=30):
        """Send a request and wait for a single ok/error response."""
        req_id, q = self._request(cmd, payload)
        try:
            msg = q.get(timeout=timeout)
            if msg is None:
                raise ConnectionError("Agent disconnected")
            if msg["status"] == P.STATUS_ERROR:
                raise AgentError(
                    msg["payload"]["code"],
                    msg["payload"]["message"],
                )
            return msg
        finally:
            self._deregister(req_id)

    def call_streaming(self, cmd, payload, timeout=30):
        """
        Send a request and yield streaming/done messages until done.
        Yields each message dict. Raises AgentError if error received.
        """
        req_id, q = self._request(cmd, payload)
        try:
            while True:
                msg = q.get(timeout=timeout)
                if msg is None:
                    raise ConnectionError("Agent disconnected")
                if msg["status"] == P.STATUS_ERROR:
                    raise AgentError(
                        msg["payload"]["code"],
                        msg["payload"]["message"],
                    )
                yield msg
                if msg["status"] == P.STATUS_DONE:
                    break
        finally:
            self._deregister(req_id)

    # ------------------------------------------------------------------
    # High-level API
    # ------------------------------------------------------------------

    def ping(self):
        return self.call(P.CMD_PING, {})["payload"]

    def exec_cmd(self, command, stream=False, cwd=None, timeout=None):
        """
        Execute a shell command on the remote agent.
        If stream=False: returns (returncode, stdout_bytes, stderr_bytes).
        If stream=True: yields message dicts (streaming/done).
        """
        payload = {"command": command, "stream": stream}
        if cwd:
            payload["cwd"] = cwd
        if timeout is not None:
            payload["timeout"] = timeout

        if stream:
            return self.call_streaming(P.CMD_EXEC, payload)
        else:
            msg = self.call(P.CMD_EXEC, payload)
            p = msg["payload"]
            stdout = P.decode_content(p["stdout"], p.get("stdout_encoding", "utf-8"))
            stderr = P.decode_content(p["stderr"], p.get("stderr_encoding", "utf-8"))
            return p["returncode"], stdout, stderr

    def read_file(self, path, max_bytes=None):
        """Read a file from the remote agent. Returns bytes."""
        payload = {"path": path}
        if max_bytes is not None:
            payload["max_bytes"] = max_bytes
        msg = self.call(P.CMD_READ_FILE, payload)
        p = msg["payload"]
        return P.decode_content(p["content"], p.get("encoding", "utf-8"))

    def write_file(self, path, data: bytes, mode="w", makedirs=False):
        """Write bytes to a file on the remote agent."""
        content, encoding = P.encode_content(data)
        payload = {
            "path": path,
            "content": content,
            "encoding": encoding,
            "mode": mode,
            "makedirs": makedirs,
        }
        return self.call(P.CMD_WRITE_FILE, payload)["payload"]

    def list_dir(self, path="."):
        """List directory contents. Returns list of entry dicts."""
        msg = self.call(P.CMD_LIST_DIR, {"path": path})
        return msg["payload"]["entries"]

    def env_info(self):
        """Get environment info from the remote agent."""
        return self.call(P.CMD_ENV_INFO, {})["payload"]

    def close(self):
        if not self._closed:
            self._closed = True
            try:
                self._proc.stdin.close()
            except Exception:
                pass
            try:
                self._proc.terminate()
                self._proc.wait(timeout=3)
            except Exception:
                pass

    def __enter__(self):
        return self

    def __exit__(self, *args):
        self.close()


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def build_parser():
    parser = argparse.ArgumentParser(
        prog="targetor",
        description="Targetor — remote execution client",
    )

    # Global flags
    parser.add_argument("--host", default=None, help="Remote host")
    parser.add_argument("--user", default=None, help="SSH user")
    parser.add_argument("--port", type=int, default=22, help="SSH port")
    parser.add_argument("--key", default=None, help="SSH private key path")
    parser.add_argument("--agent-path", default="~/agent.py",
                        help="Path to agent.py on remote (or local with --local)")
    parser.add_argument("--local", action="store_true",
                        help="Use local MockSSHTransport instead of real SSH")
    parser.add_argument("--timeout", type=float, default=30,
                        help="Request timeout in seconds")

    sub = parser.add_subparsers(dest="command", metavar="COMMAND")
    sub.required = True

    # ping
    sub.add_parser("ping", help="Ping the remote agent")

    # exec
    p_exec = sub.add_parser("exec", help="Execute a shell command")
    p_exec.add_argument("cmd", help="Shell command to execute")
    p_exec.add_argument("--stream", action="store_true", help="Stream output")
    p_exec.add_argument("--cwd", default=None, help="Working directory")
    p_exec.add_argument("--timeout", dest="exec_timeout", type=float, default=None,
                        help="Command timeout in seconds")

    # read
    p_read = sub.add_parser("read", help="Read a remote file")
    p_read.add_argument("path", help="Remote file path")

    # write
    p_write = sub.add_parser("write", help="Write a remote file")
    p_write.add_argument("path", help="Remote file path")
    p_write.add_argument("content", nargs="?", default=None,
                         help="Content to write (reads stdin if omitted)")
    p_write.add_argument("--append", action="store_true", help="Append instead of overwrite")

    # ls
    p_ls = sub.add_parser("ls", help="List a remote directory")
    p_ls.add_argument("path", nargs="?", default=".", help="Remote directory path")

    # env
    sub.add_parser("env", help="Get remote environment info")

    return parser


def main():
    parser = build_parser()
    args = parser.parse_args()

    # Build transport
    if args.local:
        agent_path = args.agent_path if args.agent_path != "~/agent.py" else None
        transport = MockSSHTransport(agent_path=agent_path)
    else:
        if not args.host:
            parser.error("--host is required unless --local is set")
        transport = SSHTransport(
            host=args.host,
            user=args.user,
            port=args.port,
            key=args.key,
            agent_path=args.agent_path,
        )

    with AgentConnection(transport) as conn:
        if args.command == "ping":
            import time
            t0 = time.time()
            result = conn.ping()
            elapsed = (time.time() - t0) * 1000
            print(f"pong={result['pong']}  latency={elapsed:.1f}ms")

        elif args.command == "exec":
            if args.stream:
                for msg in conn.exec_cmd(args.cmd, stream=True, cwd=args.cwd,
                                          timeout=args.exec_timeout):
                    p = msg["payload"]
                    if msg["status"] == P.STATUS_STREAMING:
                        chunk = P.decode_content(p["content"], p.get("encoding", "utf-8"))
                        stream_name = p.get("stream", "stdout")
                        out = sys.stdout if stream_name == "stdout" else sys.stderr
                        out.buffer.write(chunk)
                        out.buffer.flush()
                    elif msg["status"] == P.STATUS_DONE:
                        rc = p.get("returncode", 0)
                        if rc != 0:
                            sys.exit(rc)
            else:
                rc, stdout, stderr = conn.exec_cmd(args.cmd, stream=False,
                                                    cwd=args.cwd,
                                                    timeout=args.exec_timeout)
                sys.stdout.buffer.write(stdout)
                if stderr:
                    sys.stderr.buffer.write(stderr)
                if rc != 0:
                    sys.exit(rc)

        elif args.command == "read":
            data = conn.read_file(args.path)
            sys.stdout.buffer.write(data)

        elif args.command == "write":
            if args.content is not None:
                data = args.content.encode("utf-8")
            else:
                data = sys.stdin.buffer.read()
            mode = "a" if args.append else "w"
            result = conn.write_file(args.path, data, mode=mode)
            print(f"Written {result['bytes_written']} bytes to {args.path}")

        elif args.command == "ls":
            entries = conn.list_dir(args.path)
            for e in sorted(entries, key=lambda x: (x["type"] != "dir", x["name"])):
                type_char = {"dir": "d", "file": "f", "symlink": "l", "other": "?"}.get(
                    e["type"], "?"
                )
                size_str = str(e["size"]).rjust(8)
                target = f" -> {e['target']}" if e.get("target") else ""
                print(f"{type_char} {size_str}  {e['name']}{target}")

        elif args.command == "env":
            info = conn.env_info()
            for k, v in info.items():
                print(f"{k}: {v}")


if __name__ == "__main__":
    main()
