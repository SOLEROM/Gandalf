# Usage Guide — ECC ver1 General-Purpose Toolkit

Best practices and when to reach for each tool.
Organized by development workflow phase, not alphabetically.

---

## How This Toolkit Is Structured

There are four types of assets, each used differently:

| Type | How to invoke | Purpose |
|---|---|---|
| **Agents** | `Agent tool` with the agent's file as the subagent prompt | Delegated, focused tasks with their own model/tools |
| **Commands** | `/command-name` in the CLI | Slash commands that trigger workflows |
| **Rules** | Referenced automatically via `rules/common/` | Guardrails applied throughout every session |
| **Skills** | Loaded on demand when the pattern is relevant | Deep how-to reference for specific techniques |

---

## Workflow Phase 1 — Before You Write Code

### When you have a new task or feature

**Use `/plan` first.**
Invokes the `planner` agent (Opus model). It breaks the task into phases, identifies dependencies, flags risks, and waits for your confirmation before touching any code.

```
/plan add Stripe subscription billing with per-seat pricing
```

The plan output includes: requirements, architecture changes, phased implementation steps (with exact file paths), testing strategy, risks, and success criteria. Do not skip this for anything non-trivial.

**When the scope is architectural** (new service, major refactor, cross-cutting change), use the `architect` agent directly before planning:

```
Agent: architect.md
→ "Evaluate our current auth module and recommend whether to extend it or replace it"
```

The architect uses read-only tools and the Opus model — it produces ADRs and design tradeoffs, not code.

**For multi-model planning** across a complex codebase:

```
/ccg:plan <task>
```

Runs a parallel Codex + Gemini analysis, then synthesizes a unified implementation plan saved to `.claude/plan/`.

---

### When you need to understand a library or API

**Use `/docs`** — it resolves the current docs via Context7 MCP and returns answers with code examples, without polluting your main context.

```
/docs stripe create subscription with trial period
```

Or invoke the `docs-lookup` agent directly for a longer back-and-forth:
```
Agent: docs-lookup.md
→ "How does Supabase RLS work with service role keys?"
```

Security note: both the command and agent treat fetched docs as untrusted content and resist prompt injection from documentation sources.

---

### When you need a side question answered without losing state

```
/aside what's the difference between JWT and opaque tokens?
```

Freezes current task state, answers the question, then automatically returns to where you were. Does NOT modify any files during the aside.

---

## Workflow Phase 2 — Writing Code

### Test-first discipline

**Always start with `/tdd`**, not with implementation.

```
/tdd add a rate-limited webhook endpoint that validates HMAC signatures
```

This invokes the `tdd-guide` agent, which:
1. Scaffolds the interface
2. Writes failing tests (RED)
3. Implements minimal code to make them pass (GREEN)
4. Refactors
5. Verifies ≥80% coverage

The 80% coverage floor is enforced by `rules/common/testing.md`. The tdd-guide agent will block completion if coverage is below threshold.

**Edge cases the tdd-guide always checks:**
- Null / undefined inputs
- Empty arrays and strings
- Invalid types
- Boundary values
- Error paths and thrown exceptions
- Race conditions
- Special characters

**Anti-patterns to avoid** (the agent flags these):
- Testing implementation details instead of behavior
- Tests that depend on other tests
- Mocking things you own
- Unmocked external dependencies (database, network, clock)

---

### Model routing — picking the right model for the task

```
/model-route <description of task> [--budget low|med|high]
```

General guidance from `rules/common/performance.md`:

| Model | Use when |
|---|---|
| **Haiku** | Deterministic/mechanical tasks — formatting, renaming, simple transforms. ~3x cheaper. |
| **Sonnet** | Default for all coding tasks |
| **Opus** | Architecture decisions, deep code review, complex multi-step planning |

Use `/model-route` when you're unsure — it returns a model recommendation with confidence score and rationale.

---

### Build failures during development

```
/build-fix
```

Language-agnostic flow: detects your build system, parses errors, groups them by file, and fixes them one at a time with a re-run after each fix. Never attempts a bulk fix that breaks more than it resolves.

---

## Workflow Phase 3 — Before You Commit

This is where the review and verification layer kicks in. Run these in order.

### Step 1 — Quality gate

```
/quality-gate [path] [--fix] [--strict]
```

Runs the full ECC quality pipeline: detect language → formatters → lint → type checks → produce remediation list. Use `--fix` to auto-remediate where possible.

### Step 2 — Code review

```
/code-review
```

Reviews all uncommitted changes. Output is organized by severity:
- **CRITICAL** — security vulnerabilities, data loss risk
- **HIGH** — correctness bugs, unhandled errors
- **MEDIUM** — maintainability, style violations
- **LOW** — suggestions

The underlying `code-reviewer` agent has >80% confidence threshold — it only flags issues it's sure about.

### Step 3 — Security review

Run the `security-reviewer` agent for **any** of these:
- Code that handles user input
- Authentication or authorization logic
- API endpoints
- File uploads
- Payment flows
- Webhook handlers

```
Agent: security-reviewer.md
→ "Review the new /api/webhooks/stripe endpoint"
```

It runs OWASP Top 10 checks, scans for hardcoded secrets, checks for injection patterns, and reviews dependencies with `npm audit`.

**The 10 critical patterns it always looks for:**

| Pattern | Risk |
|---|---|
| Hardcoded secrets in source | Credential exposure |
| Shell commands with user input | Command injection |
| String-concatenated SQL | SQL injection |
| innerHTML mutation | XSS |
| `fetch(userProvidedUrl)` | SSRF |
| Plaintext password comparison | Auth bypass |
| Missing auth checks on routes | Unauthorized access |
| Balance checks without locks | Race condition / double-spend |
| Missing rate limiting | Abuse / DoS |
| Passwords in log statements | Credential leakage |

### Step 4 — Full verification

```
/verify [quick|full|pre-commit|pre-pr]
```

Runs in order: Build → TypeScript → Lint → Tests → console.log audit → git status. Returns a concise PASS/FAIL report per phase. Use `pre-pr` before opening a pull request.

Or invoke the `verification-loop` skill directly for a structured 6-phase QA pass — especially useful before releases.

---

## Workflow Phase 4 — After Merging / During Maintenance

### Remove dead code

```
/refactor-clean
```

Invokes the `refactor-cleaner` agent. It uses `knip`, `depcheck`, and `ts-prune` to find unused code, then categorizes removals:

- **SAFE** — clearly unused, no references
- **CAREFUL** — used in tests or dynamic requires
- **RISKY** — public API, might be external dependency

Always runs one category at a time with test verification between batches. Never run during active feature development — only on stable branches.

### Prune stale instincts

```
/prune [--max-age 30] [--dry-run]
```

Deletes pending instincts (learned patterns that were never promoted to global scope) older than the specified age. Run `--dry-run` first to see what would be removed.

---

## Workflow Phase 5 — Testing

### End-to-end tests

```
/e2e <test journey description>
```

Invokes the `e2e-runner` agent. It uses Agent Browser (preferred over raw Playwright) for semantic selectors and AI-optimized auto-waiting. Outputs screenshots, traces, and videos on failure.

**Flaky test handling:** Any test that fails intermittently is quarantined automatically using `test.fixme(true, 'reason')` rather than deleted. Use `--repeat-each=10` to surface flakiness before CI.

**From the `e2e-testing` skill — test organization:**
```
tests/e2e/
  auth/       login, logout, session expiry
  features/   core user journeys
  api/        API contract tests
```

**Playwright best practices enforced:**
- Semantic selectors: `data-testid` > CSS > XPath
- Wait for conditions, never `page.waitForTimeout()`
- Test isolation — no shared state between specs
- CI config: retries=2, trace on first retry, screenshot/video only on failure

### Test coverage analysis

```
/test-coverage
```

Auto-detects your test framework (jest/vitest/pytest/cargo/maven/go test), runs coverage, identifies under-covered files, and generates missing test stubs for the gaps.

Coverage floor from `rules/common/testing.md`: **80% minimum** across unit + integration + E2E.

---

## Multi-Agent Orchestration

### Sequential agent pipeline for a feature

```
/orchestrate feature <description>
```

Runs agents in order with handoff documents between each step:
```
planner → tdd-guide → code-reviewer → security-reviewer
```

Each agent receives the previous agent's findings as context. Use this for significant features where you want every phase covered automatically.

### Parallel multi-repo work

```
/devfleet
```

Spins up a multi-agent fleet via the DevFleet MCP server. Each agent gets an isolated git worktree. Use for tasks that span multiple services or repos simultaneously.

```
/multi-workflow <task>
```

6-phase workflow (Research → Ideation → Plan → Execute → Optimize → Review) with intelligent routing: Codex for backend, Gemini for frontend, Claude for orchestration.

### Monitoring an autonomous loop

```
/loop-start [pattern] [--mode safe|fast]
```

Patterns: `sequential`, `continuous-pr`, `rfc-dag`, `infinite`.

```
/loop-status [--watch]
```

Shows current phase, last checkpoint, failing checks, cost/time drift. The `loop-operator` agent monitors for stalls and escalates when:
- No progress across multiple checkpoints
- Same stack trace repeating
- Cost drift exceeds threshold
- Merge conflicts block progress

Always start with `--mode safe` (default). Only use `--mode fast` when the plan is fully validated and quality gates are trusted.

---

## Session & Context Management

### Save and restore work

```
/save-session
```

Captures: what you're building, what worked, what didn't, what hasn't been tried, key decisions, blockers, and next step. Saves to `~/.claude/session-data/`.

```
/resume-session [date|file]
```

Loads saved state and presents a structured briefing. It does **not** auto-resume work — you review and decide the next action.

```
/sessions list [--recent|--project|--all]
```

Manage multiple saved sessions with filtering, aliasing, and info display.

### Context budget

```
/context-budget [--verbose]
```

Analyzes context usage across agents, skills, MCPs, and rules. Returns optimization recommendations to reduce token overhead. Run this when you notice responses slowing down or costs climbing.

### Strategic compaction

From the `strategic-compact` skill — **never let auto-compact trigger mid-task**. Compact deliberately at phase boundaries:

- After research → before planning
- After planning → before implementation
- After debugging → before next feature
- After a failed approach → before trying a new one

What survives compaction: CLAUDE.md, TodoWrite task list, memory files, git state, files on disk.
What is lost: intermediate reasoning, previously-read file content, tool call history, verbal preferences stated during session.

Write key decisions to files or memory before compacting.

---

## Learning & Pattern Capture

### After solving something non-obvious

```
/learn
```

Extracts reusable patterns from the session — error resolutions, debugging techniques, workarounds, project-specific discoveries — and saves them as a skill file.

```
/learn-eval
```

More rigorous: runs a checklist (does this overlap existing skills? is it reusable? where should it live?) and returns a verdict: **Save / Improve / Absorb / Drop**.

### Viewing and managing instincts

```
/instinct-status
```

Shows all learned instincts grouped by domain, with confidence bars and observation counts (project + global merged).

```
/instinct-export [--domain <name>] [--min-confidence 0.8]
```

Export instincts to YAML for sharing or version control.

```
/promote [instinct-id]
```

Promote a project-scoped instinct to global scope once it's proven reliable.

---

## Documentation

### After changing behavior or APIs

```
/update-docs
```

Syncs docs with the codebase: regenerates script reference (from package.json), environment variable docs (from .env.example), contributing guide, runbook. Auto-generated sections are marked clearly.

```
/update-codemaps
```

Rebuilds the structural codebase map in `docs/CODEMAPS/` — INDEX.md, frontend.md, backend.md, database.md, integrations.md. Includes staleness detection.

Or use the `doc-updater` agent for both in one pass (runs on Haiku for cost efficiency):
```
Agent: doc-updater.md
→ "Update all docs after the auth module refactor"
```

---

## Skills Reference — When to Load Each

Skills are deep reference packs loaded when you need the methodology, not just a command.

| Skill | Load it when... |
|---|---|
| `tdd-workflow` | Starting a new feature with test-first requirements |
| `verification-loop` | Running a full QA pass before a release |
| `api-design` | Designing new REST endpoints or reviewing an existing API |
| `backend-patterns` | Implementing service layers, repositories, caching, retry logic, RBAC |
| `coding-standards` | Onboarding to a new project or reviewing conventions |
| `e2e-testing` | Setting up or debugging Playwright test suites |
| `eval-harness` | Defining eval-driven acceptance criteria before coding begins |
| `plankton-code-quality` | Setting up write-time formatting + linting enforcement via hooks |
| `iterative-retrieval` | Spawning subagents that need to discover their own context progressively |
| `strategic-compact` | Managing long sessions or multi-phase tasks near context limits |

---

## Common Rules — Always Active

These are not opt-in — they apply to every session via `rules/common/`.

| Rule | Key requirement |
|---|---|
| `testing.md` | 80% minimum coverage. Unit + Integration + E2E all required. |
| `coding-style.md` | **Immutability is CRITICAL.** Never mutate objects. Functions ≤50 lines. Files ≤800 lines. Nesting ≤4 levels. |
| `git-workflow.md` | Commit format: `<type>: <description>` (feat/fix/refactor/docs/test/chore/perf/ci) |
| `security.md` | Mandatory pre-commit: no secrets, SQL injection prevention, XSS prevention, auth verified, rate limiting. |
| `development-workflow.md` | Pipeline: Research & Reuse → Plan → TDD → Code Review → Commit. Never skip steps. |
| `patterns.md` | Repository pattern for data access. Consistent API response envelope (success, data, error, meta). |
| `performance.md` | Haiku for mechanical tasks. Sonnet for coding. Opus for architecture. Compact before context ceiling. |
| `agents.md` | Planner for complex features. Code-reviewer after every change. TDD-guide for bugs and features. Architect for design decisions. |

---

## Quick Reference — Tool by Situation

| Situation | Reach for |
|---|---|
| New feature, unclear scope | `/plan` → planner agent |
| New system or major refactor | architect agent first |
| "How does library X work?" | `/docs` or docs-lookup agent |
| Writing new code | `/tdd` |
| About to commit | `/quality-gate` → `/code-review` → security-reviewer → `/verify` |
| Auth / payments / input handling code | security-reviewer agent (mandatory) |
| Test suite is flaky | e2e-runner agent with `--repeat-each=10` |
| Coverage below 80% | `/test-coverage` |
| Dead code accumulating | `/refactor-clean` |
| Context window getting large | `/context-budget` → strategic-compact skill |
| Session needs to pause | `/save-session` |
| Picking up yesterday's work | `/resume-session` |
| Solved something non-obvious | `/learn` or `/learn-eval` |
| Parallel work across repos | `/devfleet` |
| Full feature pipeline, hands-off | `/orchestrate feature <description>` |
