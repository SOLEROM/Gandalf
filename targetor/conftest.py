"""
conftest.py — pytest configuration: sys.path fix + shared fixtures.
"""
import sys
import os
from subprocess import Popen, PIPE

import pytest

# Ensure project root is on sys.path so protocol/transport/client are importable
sys.path.insert(0, os.path.dirname(__file__))

AGENT_PATH = os.path.join(os.path.dirname(__file__), "agent.py")


@pytest.fixture
def agent_proc():
    """Raw agent subprocess — used by test_agent.py for wire-level protocol tests."""
    proc = Popen(
        [sys.executable, "-u", AGENT_PATH],
        stdin=PIPE,
        stdout=PIPE,
        stderr=PIPE,
    )
    yield proc
    try:
        proc.stdin.close()
    except Exception:
        pass
    proc.terminate()
    try:
        proc.wait(timeout=2)
    except Exception:
        proc.kill()


@pytest.fixture
def mock_transport():
    """MockSSHTransport pointing at local agent.py — same Popen API as real SSH."""
    from transport import MockSSHTransport
    return MockSSHTransport(agent_path=AGENT_PATH)


@pytest.fixture
def conn(mock_transport):
    """AgentConnection via MockSSHTransport — used by test_client.py."""
    from client import AgentConnection
    c = AgentConnection(mock_transport)
    yield c
    c.close()
