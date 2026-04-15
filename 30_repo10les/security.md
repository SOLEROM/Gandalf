# Security Review

Review of all executable scripts in this toolkit.

## Scripts Reviewed

| Script | Network Calls | Process Spawning | Local Recording | URL Acceptance | Auto-download |
|--------|--------------|------------------|-----------------|----------------|---------------|
| `code-review/scripts/analyze-metrics.py` | None | None | None | None | None |
| `code-review/scripts/compare-complexity.py` | None | None | None | None | None |
| `refactor/scripts/analyze-complexity.py` | None | None | None | None | None |
| `refactor/scripts/detect-smells.py` | None | None | None | None | None |
| `doc-generator/generate-docs.py` | None | None | None | None | None |
| `install.sh` | None | None | None | None | None |
| `test/test.sh` | None | `claude --print` subprocess | `testReport.log` (local, overwritten per run) | None | None |

## Clean / No Issues

All scripts passed review:

- **`analyze-metrics.py`** — reads one local file path from `sys.argv[1]`, prints metrics to stdout. Pure stdlib (`re`, `sys`).
- **`compare-complexity.py`** — reads two local file paths from `sys.argv`, prints comparison to stdout. Pure stdlib (`re`, `sys`).
- **`analyze-complexity.py`** — reads local files or a directory. CLI via `argparse`. Pure stdlib (`re`, `os`, `sys`, `argparse`, `math`, `json`, `dataclasses`).
- **`detect-smells.py`** — reads local files or a directory. CLI via `argparse`. Pure stdlib (`re`, `os`, `sys`, `argparse`, `dataclasses`, `enum`, `collections`).
- **`generate-docs.py`** — parses a local Python file using `ast.parse()`. Pure stdlib (`ast`, `sys`).
- **`install.sh`** — copies skill directories to `~/.claude/skills/`. No network access. Creates `~/.claude/skills/` if missing. Uses only `cp`, `find`, `chmod`.
- **`test/test.sh`** — spawns `claude --print` subprocesses to run skills. Writes `testReport.log` to the current directory (truncated fresh on each run). Creates and cleans up a temp directory via `mktemp -d` and an EXIT trap.

## Notable Behaviors

### `test/test.sh` — subprocess spawning
The test runner spawns `claude --print --dangerously-skip-permissions` for each skill. This is intentional and expected: it is the standard non-interactive invocation pattern for Claude Code. The flag disables the permissions confirmation prompt; it does not grant Claude any additional system access beyond what it would normally have.

### `test/test.sh` — local file write
Writes `./testReport.log` in whatever directory `test.sh` is run from. File is truncated and rewritten on every run. Contains skill names, test prompts, Claude output, and pass/fail status. No credentials or sensitive data are included in the prompts by design.

## Quick Disable Reference

| Behavior | How to disable |
|----------|---------------|
| `test.sh` writing testReport.log | Edit `REPORT_FILE` variable at top of `test/test.sh` to `/dev/null` |
| `test.sh` spawning claude subprocesses | Remove individual `run_skill` calls or set `SKIP_<SKILL>=1` (not yet implemented; pass skill names as positional args to run only specific ones) |
