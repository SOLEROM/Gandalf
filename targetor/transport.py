"""
transport.py — Transport abstraction for Targetor.
Provides SSHTransport (real) and MockSSHTransport (testing/local).
"""
import os
import sys
from abc import ABC, abstractmethod
from subprocess import Popen, PIPE


def _default_agent_path():
    return os.path.join(os.path.dirname(os.path.abspath(__file__)), "agent.py")


class Transport(ABC):
    @abstractmethod
    def connect(self) -> Popen:
        """Return a running Popen with stdin/stdout pipes speaking the protocol."""


class SSHTransport(Transport):
    """Real SSH connection — used in production."""

    def __init__(self, host, user=None, port=22, key=None,
                 agent_path="~/agent.py", python_cmd="python3"):
        self.host = host
        self.user = user
        self.port = port
        self.key = key
        self.agent_path = agent_path
        self.python_cmd = python_cmd

    def connect(self) -> Popen:
        cmd = [
            "ssh", "-T",
            "-o", "BatchMode=yes",
            "-o", "ServerAliveInterval=10",
            "-o", "ServerAliveCountMax=3",
            "-o", "ConnectTimeout=10",
            "-p", str(self.port),
        ]
        if self.key:
            cmd += ["-i", self.key]
        target = f"{self.user}@{self.host}" if self.user else self.host
        cmd += [target, self.python_cmd, "-u", self.agent_path]
        return Popen(cmd, stdin=PIPE, stdout=PIPE, stderr=PIPE)


class MockSSHTransport(Transport):
    """
    Fakes SSH by running agent.py as a local subprocess.
    Uses identical Popen interface as SSHTransport — AgentConnection
    cannot tell the difference. Used for all tests and --local CLI flag.
    """

    def __init__(self, agent_path=None, python_cmd=None):
        self.agent_path = agent_path or _default_agent_path()
        self.python_cmd = python_cmd or sys.executable

    def connect(self) -> Popen:
        return Popen(
            [self.python_cmd, "-u", self.agent_path],
            stdin=PIPE,
            stdout=PIPE,
            stderr=PIPE,
        )
