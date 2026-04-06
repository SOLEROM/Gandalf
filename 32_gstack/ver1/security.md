# gstack — Security Review

Review of all executable scripts and code with security-relevant behavior.

---

## Shell scripts

### `skills/browse/bin/find-browse`

**Purpose:** Locates the compiled browse binary — checks the dist/ directory, then falls back to git-root and home-directory paths.

**Review:**
- No network calls
- No data recording or disk writes
- Paths constructed from `$0` (script location) and `git rev-parse --show-toplevel` — no user input accepted
- No external URL acceptance
- No auto-download behavior

**Verdict: CLEAN**

---

### `skills/browse/bin/remote-slug`

**Purpose:** Outputs `owner-repo` slug from the current git remote URL. Used to derive project-specific paths under `~/.gstack/projects/`.

**Review:**
- No network calls (reads git config only, via `git remote get-url origin`)
- No data recording or disk writes
- `sed` expression extracts owner/repo from a hardcoded pattern — no user-controlled regex
- No external URL acceptance
- No auto-download behavior

**Verdict: CLEAN**

---

## TypeScript source — browser binary (`skills/browse/src/`)

The browser binary is compiled from TypeScript and runs as a local daemon. The following behaviors are present by design — they are not vulnerabilities, but are documented here for informed use.

### Network calls

- **Outbound:** All outbound network requests are initiated by **Chromium**, not by gstack's own code. Chromium loads whatever URL the user or Claude specifies via `$B goto`. gstack does not make autonomous outbound HTTP calls.
- **Inbound:** The server binds to `localhost` only (not `0.0.0.0`). Not reachable from the network.
- **Bearer token:** Every session generates a random UUID token. All HTTP requests require `Authorization: Bearer <token>`. Token is stored in `.gstack/browse.json` (mode 0o600, owner-read only).

### Autonomous process spawning

- The CLI spawns the Bun server process on first use (`Bun.spawn`), then connects via localhost HTTP. This is the daemon model — it is intentional and documented in ARCHITECTURE.md.
- The server spawns Chromium via Playwright. Chromium exits when the server shuts down.
- Neither the CLI nor the server spawns any other processes.

### Local data recording

- `.gstack/browse.json` — server state (PID, port, token, version). Written on startup, deleted on shutdown. Mode 0o600.
- `.gstack/browse-console.log` — browser console messages. Append-only, 1-second async flush.
- `.gstack/browse-network.log` — network request metadata (URL, status, timing). **Does not record request/response bodies.**
- `.gstack/browse-dialog.log` — dialog events (type, message, action taken). **No cookie values recorded.**
- `~/.gstack/` — retro history and eval results (written by `retro` and eval scripts). Project-keyed subdirectories.

All disk writes are local to the machine. No data leaves the machine except via Chromium page loads (which are user-directed).

### Cookie handling

- Cookie values are decrypted in-process (PBKDF2 + AES-128-CBC) and loaded into the Playwright browser context. They are **never written to disk in plaintext**.
- The `cookies` command outputs cookie metadata (domain, name, expiry) only — values are truncated.
- macOS Keychain access requires explicit user approval (system dialog on first import per browser).
- The Chromium cookie database is opened read-only (copied to a temp file to avoid lock conflicts).

**Verdict: NO ISSUES — all behaviors are intentional, user-directed, and bounded to localhost.**

---

## Auto-download behavior

- `bun add playwright` (install step) downloads Playwright JS code. No auto-download occurs at runtime.
- Playwright's Chromium (~170MB) downloads to `~/.cache/ms-playwright/` on first server start — user-triggered, not autonomous.
- No `npx -y`, `pip install`, or equivalent runtime package fetches anywhere in the codebase.

---

## Quick-disable reference

| Behavior | How to disable |
|----------|----------------|
| Chromium daemon auto-start | Do not load the `browse` skill |
| Disk logging (console/network/dialog) | No config option — delete `.gstack/*.log` files after each session |
| Cookie import (macOS Keychain) | Do not run `setup-browser-cookies` or `$B cookie-import-browser` |
| Retro history persistence | Do not load the `retro` skill; delete `~/.gstack/<project>/retro/` manually |

---

## Clean list

All files reviewed, all passed:

- `skills/browse/bin/find-browse`
- `skills/browse/bin/remote-slug`
- `skills/browse/src/cli.ts`
- `skills/browse/src/server.ts`
- `skills/browse/src/browser-manager.ts`
- `skills/browse/src/snapshot.ts`
- `skills/browse/src/read-commands.ts`
- `skills/browse/src/write-commands.ts`
- `skills/browse/src/meta-commands.ts`
- `skills/browse/src/cookie-import-browser.ts`
- `skills/browse/src/cookie-picker-routes.ts`
- `skills/browse/src/cookie-picker-ui.ts`
- `skills/browse/src/buffers.ts`
