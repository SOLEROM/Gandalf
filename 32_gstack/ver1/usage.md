# gstack — Usage Guide

Best practices for using each skill, organized by dev workflow phase.

---

## Before coding — Plan review

### `/plan-ceo-review`

**When:** You have a written plan (spec, task.md, issue description) and want a high-level challenge before committing to implementation.

**Invocation:** Load the skill, then paste or reference the plan.

**Three modes — choose one before the review starts:**
- `SCOPE EXPANSION` — push ambition up; find the 10x version
- `HOLD SCOPE` — accept current scope; make it bulletproof
- `SCOPE REDUCTION` — cut to the minimum viable version

**Notable behaviors:**
- Runs a full system audit (git log, TODOS.md, CLAUDE.md) before reviewing
- Forces you to choose a mode and commits to it — won't silently drift
- Produces a TODOS.md entry for everything deferred
- Always produces ASCII diagrams for non-trivial data flows

**Anti-patterns:**
- Don't load this mid-implementation; it's a pre-work tool
- Don't skip mode selection — without it the review has no consistent posture
- Don't use for trivial one-file changes; overhead is not worth it

---

### `/plan-eng-review`

**When:** You need an engineering-level review — architecture, data flow, error handling, test coverage — rather than a strategic/CEO perspective.

**Invocation:** Load the skill and describe or paste the plan.

**Notable behaviors:**
- Walks through the plan interactively with opinionated recommendations
- Maps every error path explicitly — no "handle errors gracefully" generalities
- Produces diagrams for every non-trivial data flow
- Checks against existing code to avoid rebuilding what already exists

**Anti-patterns:**
- Don't use without a written plan; verbal descriptions produce shallow reviews
- Don't skip the pre-review system audit section

---

## Writing code — no dedicated skill

gstack doesn't include a coding assistant skill. Use Claude's native capabilities.

---

## Before commit — Review

### `/review`

**When:** Before landing a PR — after you're satisfied with the implementation but before merging.

**Invocation:** Load the skill; it analyzes `git diff main` automatically.

**What it checks:**
- SQL injection and query safety
- LLM trust boundary violations (unsanitized input passed to prompts)
- Conditional side effects (mutations inside if-blocks without rollback)
- Other structural issues (hardcoded secrets, missing error paths)

**Notable behaviors:**
- Reads `review/checklist.md` for project-specific checks
- Can trigger Greptile-assisted triage via `review/greptile-triage.md`
- Produces a TODOS list for issues that don't block the PR

**Anti-patterns:**
- Don't use as a substitute for writing tests; review catches structural issues, not logic bugs
- Don't skip if the diff touches auth, payments, or LLM input paths

---

## Release — Ship

### `/ship`

**When:** You're ready to merge a branch, cut a release, and open a PR.

**Invocation:** Load the skill and confirm the target branch.

**Workflow:**
1. Merge main into current branch
2. Run tests
3. Review diff summary
4. Bump VERSION file
5. Update CHANGELOG
6. Commit, push, open PR

**Notable behaviors:**
- Stops and asks before each destructive step (push, PR creation)
- Checks for test failures before bumping version
- Creates a structured PR description

**Anti-patterns:**
- Don't use on a branch with uncommitted changes
- Don't skip the test run step

---

## Testing — QA

### `/browse`

**When:** You need to verify a page, test a user flow, or gather visual evidence for a bug report.

**Invocation:** Load the skill, then use `$B` commands in Bash tool calls.

**Core commands:**
```bash
$B goto <url>           # navigate
$B snapshot -i          # see all interactive elements with @refs
$B click @e3            # click by ref
$B fill @e4 "value"     # fill input
$B snapshot -D          # diff: what changed after the action?
$B is visible ".class"  # assert element state
$B screenshot /tmp/s.png
$B console              # check JS errors
$B network              # check failed requests
```

**Setup check (always run first):**
```bash
_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
B=""
[ -n "$_ROOT" ] && [ -x "$_ROOT/.claude/skills/gstack/browse/dist/browse" ] && B="$_ROOT/.claude/skills/gstack/browse/dist/browse"
[ -z "$B" ] && B=~/.claude/skills/gstack/browse/dist/browse
if [ -x "$B" ]; then echo "READY: $B"; else echo "NEEDS_SETUP"; fi
```

**Notable behaviors:**
- First call starts Chromium (~3s). Every subsequent call: ~100ms.
- State persists between calls: cookies, tabs, login sessions.
- Auto-shuts down after 30 minutes idle. Restarts automatically on next call.
- Each git repo gets its own isolated Chromium instance (state in `.gstack/`).

**Anti-patterns:**
- Don't run `snapshot` after every command — only when you need refs or a diff
- Don't use `js` for assertions you can do with `is visible`/`is enabled`
- Don't forget to re-run `snapshot` after navigation (refs become stale)

---

### `/qa`

**When:** Asked to "QA this", "find bugs", "dogfood the feature", or run a systematic review of a web app.

**Invocation:** Load the skill; it auto-detects mode based on context.

**Four modes:**
- `diff-aware` (default on feature branches) — analyzes git diff, tests affected pages
- `full` — systematic exploration of all routes
- `quick` — 30-second smoke test
- `regression` — compare current state against a baseline

**Output:** Structured report with health score, categorized issues, screenshots, and repro steps.

**Anti-patterns:**
- Don't use without `browse` set up and working
- Don't run `full` mode on large apps without a time budget

---

### `/setup-browser-cookies`

**When:** You need to QA an authenticated page and your headless browser has no session.

**Invocation:** Load the skill; it opens an interactive cookie picker in your real browser.

**Supported browsers:** Comet, Chrome, Arc, Brave, Edge (macOS only).

**Anti-patterns:**
- Don't run on Linux — cookie decryption only works on macOS (Keychain)
- Run this once per session, not before every `goto`

---

## Retrospective — Retro

### `/retro`

**When:** End of week, or when you want an engineering quality snapshot.

**Invocation:** Load the skill; it reads git history automatically.

**Output:**
- Commit history breakdown
- Work pattern analysis (day/time distribution, focus areas)
- Per-contributor breakdown with praise and growth areas
- Trend comparison against previous retros (if history exists)

**Anti-patterns:**
- Don't run on a repo with <1 week of commits — output will be thin
- Don't use as a performance review tool; it's an engineering health signal

---

## Quick-reference: situation → tool

| Situation | Tool |
|-----------|------|
| Have a plan, need a strategic challenge | `/plan-ceo-review` |
| Have a plan, need architecture + edge case review | `/plan-eng-review` |
| About to land a PR | `/review` |
| Ready to cut a release | `/ship` |
| Need to verify a page loads / a flow works | `/browse` |
| Need systematic QA of a feature or app | `/qa` |
| Need to test behind a login | `/setup-browser-cookies` then `/browse` |
| End of week engineering review | `/retro` |
