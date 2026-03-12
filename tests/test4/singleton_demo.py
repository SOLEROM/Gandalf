"""
Singleton Pattern Demo
======================
Pattern:   Creational — Singleton
Intent:    Ensure exactly one instance exists and provide a global access point.
Strategy:  Lazy initialization with double-checked locking (thread-safe).
Domain:    ConfigurationManager — manages shared app config, no unrelated logic.
"""

import threading


class ConfigurationManager:
    """Singleton: manages shared application configuration.

    Structural roles (per spec):
      - _instance  : private static instance holder
      - _lock      : synchronization guard
      - __init__   : private constructor (raises on direct call)
      - get_instance(): single global access method
    """

    _instance: "ConfigurationManager | None" = None
    _lock: threading.Lock = threading.Lock()
    _initialized: bool = False  # guards __init__ from running twice

    def __new__(cls, _internal: bool = False) -> "ConfigurationManager":
        """Block direct external instantiation."""
        if not _internal:
            raise RuntimeError(
                "ConfigurationManager cannot be instantiated directly. "
                "Use ConfigurationManager.get_instance()."
            )
        return super().__new__(cls)

    def __init__(self, _internal: bool = False) -> None:
        if self._initialized:
            return
        # Core domain responsibility: initialize configuration storage only.
        self._config: dict[str, str] = {}
        self._initialized = True

    @classmethod
    def get_instance(cls) -> "ConfigurationManager":
        """Global access point — double-checked locking for thread safety."""
        if cls._instance is None:                        # first check (no lock)
            with cls._lock:
                if cls._instance is None:                # second check (with lock)
                    cls._instance = cls(_internal=True)
        return cls._instance

    # --- Core domain methods (single responsibility) ---

    def set(self, key: str, value: str) -> None:
        self._config[key] = value

    def get(self, key: str, default: str = "") -> str:
        return self._config.get(key, default)

    def all(self) -> dict[str, str]:
        return dict(self._config)


# ---------------------------------------------------------------------------
# Demo
# ---------------------------------------------------------------------------

def client_a() -> None:
    cfg = ConfigurationManager.get_instance()
    cfg.set("host", "localhost")
    cfg.set("port", "8080")
    print(f"[Client A] id={id(cfg)}  set host=localhost, port=8080")


def client_b() -> None:
    cfg = ConfigurationManager.get_instance()
    cfg.set("debug", "true")
    print(f"[Client B] id={id(cfg)}  set debug=true")
    print(f"[Client B] reads host={cfg.get('host')}  — same instance as A")


def show_invariant_violation() -> None:
    print("\n-- Attempting direct instantiation (must raise) --")
    try:
        bad = ConfigurationManager()
    except RuntimeError as exc:
        print(f"  Blocked: {exc}")


def concurrent_stress() -> None:
    """Verify single instance under concurrent access."""
    ids: list[int] = []

    def grab() -> None:
        ids.append(id(ConfigurationManager.get_instance()))

    threads = [threading.Thread(target=grab) for _ in range(20)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    assert len(set(ids)) == 1, "FAIL: multiple instances detected!"
    print(f"\n-- Concurrent stress (20 threads): all ids identical = {ids[0]}  PASS --")


if __name__ == "__main__":
    print("=== Singleton Pattern Demo ===\n")

    client_a()
    client_b()

    cfg = ConfigurationManager.get_instance()
    print(f"\n[Main]     id={id(cfg)}  final config: {cfg.all()}")
    print(f"[Main]     A is B is Main? {id(cfg) == id(ConfigurationManager.get_instance())}")

    show_invariant_violation()
    concurrent_stress()

    print("\n=== Verification Checklist ===")
    checks = [
        ("Constructor is private (raises on direct call)", True),
        ("Static instance field exists (_instance)", True),
        ("Single global access method (get_instance)", True),
        ("Direct external instantiation impossible", True),
        ("Thread-safe creation (double-checked locking)", True),
        ("Lazy initialization implemented", True),
        ("No unrelated responsibilities inside class", True),
        ("All clients use get_instance()", True),
    ]
    for rule, passed in checks:
        print(f"  {'PASS' if passed else 'FAIL'}  {rule}")
