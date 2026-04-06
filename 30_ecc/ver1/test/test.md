# ECC Toolkit — End-to-End Test Scenario

A realistic development scenario that exercises every skill in the toolkit from planning through shipping.

---

## Context

You are the only backend engineer on a small team building **Taskr**, a lightweight project-management API. The main branch is stable. You have just checked out a feature branch called `feat/user-notifications` and written the first stub of a notifications module. Your staging URL is `http://localhost:3000`.

**Repo state:**
```
main (stable, tagged v1.0.0)
└── feat/user-notifications
    ├── src/
    │   ├── users.ts        (existing, tested)
    │   └── notifications.ts (new, stub only — no tests yet)
    ├── tests/
    │   └── users.test.ts
    ├── README.md
    ├── CHANGELOG.md
    └── VERSION            → 1.0.0
```

`notifications.ts` currently just exports an empty `sendNotification()` function with no implementation.

---

## Skills Exercised (in dependency order)

---

### 1. tdd-workflow — Write tests before implementing

**Purpose:** Enforce TDD: write failing tests, then implement, then verify coverage.

**Prompt:**
```
I'm about to implement sendNotification(userId, message) in notifications.ts.
Apply the TDD workflow: write the test file first, show me what tests to write,
then scaffold the minimal implementation that makes them pass.
```

**What Claude does:**
- Identifies the function signature and its contracts (success path, invalid user, empty message)
- Writes a `notifications.test.ts` with describe/it blocks before any implementation
- Shows the tests failing (placeholder)
- Writes the minimal `sendNotification` body to make them pass
- Estimates coverage and confirms ≥80% threshold

**Expected output shape:**
```
## Tests (notifications.test.ts)

describe('sendNotification', () => {
  it('sends a notification to a valid user', ...)
  it('throws when userId is missing', ...)
  it('throws when message is empty', ...)
})

## Implementation (notifications.ts)

export async function sendNotification(userId: string, message: string) { ... }

## Coverage estimate: ~85%
```

---

### 2. api-design — Design the notification endpoints

**Purpose:** Apply REST API conventions before wiring routes.

**Prompt:**
```
I need to add two endpoints for notifications:
- POST /api/v1/users/:id/notifications  (send)
- GET  /api/v1/users/:id/notifications  (list, with pagination)
Review them against REST API design best practices and suggest any corrections.
```

**What Claude does:**
- Checks URL structure (resource nesting, plural nouns, versioning)
- Recommends correct status codes (201 vs 200, 422 vs 400)
- Shows pagination envelope format (cursor-based or page/limit)
- Suggests error response schema

**Expected output shape:**
```
## Endpoint Review

POST /api/v1/users/:id/notifications
  Status: 201 Created
  Body: { data: { id, userId, message, createdAt } }

GET /api/v1/users/:id/notifications?limit=20&cursor=...
  Status: 200 OK
  Body: { data: [...], pagination: { nextCursor, hasMore } }

## Error Schema
{ error: { code, message, details? } }
```

---

### 3. coding-standards — Review the stub for conventions

**Purpose:** Catch naming, typing, and formatting issues before the PR.

**Prompt:**
```
Review notifications.ts against coding standards.
The file exports sendNotification(userId, message) with no types and no JSDoc.
What needs to change?
```

**What Claude does:**
- Flags missing TypeScript types on parameters and return value
- Recommends explicit `async`/`Promise<void>` annotation
- Notes naming conventions (camelCase, descriptive parameter names)
- Suggests import ordering if applicable

**Expected output shape:**
```
## Issues Found

1. Parameters lack type annotations — add `userId: string, message: string`
2. Return type missing — should be `Promise<void>`
3. No error handling for network failure

## Corrected Signature
export async function sendNotification(userId: string, message: string): Promise<void>
```

---

### 4. backend-patterns — Choose the right architecture pattern

**Purpose:** Pick an appropriate backend pattern for async notification delivery.

**Prompt:**
```
Should notifications be sent synchronously in the request handler
or via a background queue? What backend pattern fits best for a small Node.js API?
```

**What Claude does:**
- Compares synchronous vs queue-based patterns
- Recommends event-driven / message queue approach for reliability
- Notes trade-offs (complexity vs resilience)
- Shows a simple in-process event emitter as a starting point

**Expected output shape:**
```
## Recommendation: Event-Driven (queue-based)

For resilience, use a background job queue (BullMQ / simple EventEmitter for small scale).

## Pattern

emitter.emit('notification', { userId, message })
emitter.on('notification', async ({ userId, message }) => { await deliver(userId, message) })

## Trade-offs
- Sync: simpler, but request blocks and fails if delivery fails
- Queue: more resilient, decoupled, but adds dependency
```

---

### 5. frontend-patterns — Plan the notification UI component

**Purpose:** Apply React patterns before writing the frontend.

**Prompt:**
```
I need a NotificationBell component that fetches unread count on mount,
shows a badge, and marks all as read on click.
What React patterns should I use?
```

**What Claude does:**
- Recommends custom hook (`useNotifications`) to separate data from UI
- Suggests optimistic update for "mark all read"
- Notes error boundary placement
- Warns against prop drilling for notification state

**Expected output shape:**
```
## Pattern: Custom Hook + Optimistic Update

// useNotifications.ts
function useNotifications() {
  const [count, setCount] = useState(0)
  // fetch on mount, expose markAllRead()
}

// NotificationBell.tsx
function NotificationBell() {
  const { count, markAllRead } = useNotifications()
  // render badge, handle click
}
```

---

### 6. e2e-testing — Write Playwright tests for the notification flow

**Purpose:** Cover the critical user flow end-to-end.

**Prompt:**
```
Write Playwright E2E tests for:
1. User logs in and sees notification badge
2. User clicks bell, list appears
3. User clicks "Mark all read", badge disappears
```

**What Claude does:**
- Sets up `test.beforeEach` with login
- Uses `page.locator` with semantic selectors (data-testid)
- Asserts badge count, list visibility, badge removal
- Shows `expect.poll` for async state

**Expected output shape:**
```
import { test, expect } from '@playwright/test'

test.describe('Notifications', () => {
  test.beforeEach(async ({ page }) => { /* login */ })

  test('shows unread badge', async ({ page }) => { ... })
  test('opens notification list on click', async ({ page }) => { ... })
  test('clears badge after mark-all-read', async ({ page }) => { ... })
})
```

---

### 7. ai-regression-testing — Design a regression strategy for the AI-assisted code

**Purpose:** Prevent regressions introduced by AI-generated implementations.

**Prompt:**
```
The sendNotification function was written by Claude.
What regression testing strategy should I use to catch AI blind spots?
```

**What Claude does:**
- Identifies AI blind spots (same model writes and reviews → misses same class of errors)
- Recommends sandbox API testing (no real DB needed)
- Suggests cross-model review (have a different model review the code)
- Shows a minimal regression test checklist

**Expected output shape:**
```
## AI Regression Testing Strategy

1. Sandbox tests — test against a mock delivery service, not real infra
2. Cross-model review — use Claude Opus to review Claude Sonnet code
3. Boundary tests — empty message, very long message, invalid userId format
4. Regression suite — pin a baseline run, alert on any output change

## Blind Spots to Watch
- AI models consistently undertest their own output
- Shared failure modes across temperature/sampling runs
```

---

### 8. eval-harness — Create a formal eval for sendNotification reliability

**Purpose:** Set up eval-driven development so regressions are measurable.

**Prompt:**
```
Create a minimal eval harness for sendNotification.
I want to measure pass@3 reliability across three inputs:
valid user, missing userId, empty message.
```

**What Claude does:**
- Defines eval cases with expected outcomes (pass/fail criteria)
- Shows how to run `k` samples and compute pass@k
- Suggests a result schema to store in JSON
- Notes how to track regressions across model versions

**Expected output shape:**
```
## Eval Cases

| Input | Expected | Criteria |
|-------|----------|----------|
| valid userId + message | resolves | no throw, delivery called |
| missing userId | rejects | throws ValidationError |
| empty message | rejects | throws ValidationError |

## pass@k Formula
pass@k = 1 - C(n-c, k) / C(n, k)

## Result Schema
{ evalId, model, date, results: [{ case, passed, runs }], passAtK }
```

---

### 9. mcp-server-patterns — Scaffold a notification MCP tool

**Purpose:** Expose notification delivery as an MCP tool.

**Prompt:**
```
Show me how to create a minimal MCP server tool called send_notification
that takes userId and message as string parameters using the Node.js MCP SDK.
```

**What Claude does:**
- Shows the server setup with `@modelcontextprotocol/sdk`
- Defines the tool with Zod schema for input validation
- Shows stdio transport setup
- Notes error handling pattern

**Expected output shape:**
```typescript
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js"
import { z } from "zod"

const server = new McpServer({ name: "notifications", version: "1.0.0" })

server.tool("send_notification", {
  userId: z.string(),
  message: z.string()
}, async ({ userId, message }) => {
  await sendNotification(userId, message)
  return { content: [{ type: "text", text: "sent" }] }
})
```

---

### 10. iterative-retrieval — Retrieve context progressively for a subagent

**Purpose:** Solve the context problem when a subagent needs to understand the notifications module.

**Prompt:**
```
I want to spawn a subagent to write integration tests for the notifications module.
How should I use iterative retrieval to give it just enough context without overwhelming it?
```

**What Claude does:**
- Explains the start-broad-then-narrow approach
- Shows a retrieval sequence (file list → SKILL.md → relevant source files)
- Notes which context is load-bearing vs noise
- Recommends a context budget per phase

**Expected output shape:**
```
## Iterative Retrieval Plan

Phase 1 (10%): file tree — what exists?
Phase 2 (30%): notifications.ts, notifications.test.ts — current state
Phase 3 (60%): only the failing test cases + function signature

Stop retrieving when: subagent has function contract + one passing example.
Budget: ~2K tokens for integration test context.
```

---

### 11. verification-loop — Run verification before the PR

**Purpose:** Confirm build, types, lint, tests, and security all pass.

**Prompt:**
```
Run the full verification loop on my feature branch before I open the PR.
```

**What Claude does:**
- Runs (or simulates) build, type check, lint, test suite, security scan, diff review
- Reports each phase as PASS/FAIL
- Lists any issues to fix before opening PR
- Outputs the final READY/NOT READY verdict

**Expected output shape:**
```
VERIFICATION REPORT
==================

Build:     PASS
Types:     PASS (0 errors)
Lint:      PASS (0 warnings)
Tests:     PASS (12/12 passed, 87% coverage)
Security:  PASS (0 issues)
Diff:      3 files changed

Overall:   READY for PR
```

---

### 12. strategic-compact — Decide when to compact before the final push

**Purpose:** Preserve context integrity through the last phase of work.

**Prompt:**
```
I've finished implementing and testing the notifications feature.
Should I compact context before writing the CHANGELOG and opening the PR?
```

**What Claude does:**
- Evaluates the current phase transition (implementation → docs/PR)
- Recommends compacting since the implementation context is no longer needed
- Reminds what survives compaction (CLAUDE.md, git state, files on disk)
- Suggests the compact message to use

**Expected output shape:**
```
## Recommendation: Compact Now

Phase transition: implementation complete → PR/docs
Implementation context is no longer load-bearing.

What survives:
- CLAUDE.md instructions
- All committed/staged files
- Git history

Suggested: /compact Focus on writing CHANGELOG and PR description for feat/user-notifications
```

---

### 13. skill-stocktake — Audit the toolkit skills for quality

**Purpose:** Ensure all skills in this toolkit meet quality standards.

**Prompt:**
```
/skill-stocktake
Run a full stocktake audit of the installed ECC skills.
```

**What Claude does:**
- Scans `~/.claude/skills/` for all installed skills
- Evaluates each against a quality checklist (clear trigger, actionable content, no overlap)
- Reports a quality score per skill
- Highlights any skills needing improvement

**Expected output shape:**
```
## Skill Stocktake — Full Run

Skills scanned: 18
| Skill | Score | Issues |
|-------|-------|--------|
| tdd-workflow | 9/10 | — |
| verification-loop | 8/10 | — |
| ...

Recommendations:
- project-guidelines-example: update to reflect current stack
```

---

### 14. continuous-learning — Extract reusable patterns from this session

**Purpose:** Capture what was learned so it's available in future sessions.

**Prompt:**
```
Extract reusable patterns from this session for the continuous learning skill.
We learned: optimistic UI updates for notifications, pass@k eval design,
and that AI regression testing needs cross-model review.
```

**What Claude does:**
- Identifies patterns worth saving (general enough to apply to future projects)
- Writes concise pattern descriptions (name, context, solution, trade-offs)
- Suggests which patterns belong in skills vs commands vs memory

**Expected output shape:**
```
## Extracted Patterns

### 1. Optimistic UI for State Mutations
Context: User action with async side effect (mark-as-read)
Pattern: Update local state immediately, revert on error
Destination: frontend-patterns skill

### 2. Cross-Model AI Code Review
Context: AI-generated code review
Pattern: Use different model to review AI output
Destination: ai-regression-testing skill

### 3. pass@k Eval Design
Context: Measuring AI reliability
Pattern: Run k samples, compute pass@k score
Destination: eval-harness skill
```

---

## Running the Demo

### Prerequisites

```bash
# 1. Install the toolkit
export ECC_DIR="/data/proj/agents/gandalf/30_ecc/ver1"
bash "$ECC_DIR/install.sh"   # or follow install.md manually

# 2. Verify skills are installed
ls ~/.claude/skills/

# 3. Start a Claude Code session in any project
claude
```

### Skill Trigger Reference

| Skill | Trigger phrase |
|-------|---------------|
| tdd-workflow | "write tests first", "TDD", "test before implement" |
| api-design | "design endpoints", "REST API", "API contract" |
| coding-standards | "code review", "naming convention", "type annotation" |
| backend-patterns | "backend architecture", "async pattern", "Node.js service" |
| frontend-patterns | "React component", "custom hook", "state management" |
| e2e-testing | "Playwright", "E2E test", "end-to-end" |
| ai-regression-testing | "AI regression", "blind spot", "cross-model" |
| eval-harness | "eval harness", "pass@k", "EDD" |
| mcp-server-patterns | "MCP server", "MCP tool", "model context protocol" |
| iterative-retrieval | "subagent context", "iterative retrieval", "context budget" |
| verification-loop | "verify", "verification", "pre-PR check" |
| strategic-compact | "compact", "context limit", "when to /compact" |
| skill-stocktake | "/skill-stocktake", "audit skills" |
| continuous-learning | "extract patterns", "what did we learn" |

### Running the Automated Tests

```bash
bash test/test.sh              # run all skills
bash test/test.sh tdd api      # run only tdd-workflow and api-design
VERBOSE=1 bash test/test.sh    # show full Claude output on failure
TIMEOUT=180 bash test/test.sh  # longer timeout per skill
bash test/test.sh --help       # list all testable skills
bash test/test.sh -d tdd       # debug mode: print prompt before running
```

Test results are written to `./testReport.log`.
