# End-to-End Scenario — Superpowers Dev Toolkit v5.0.7

A single narrative exercises all 14 skills in realistic order. The developer is adding a "user export to CSV" feature to a Python REST API.

## Context

- **Feature:** User export to CSV endpoint
- **Branch:** `feature/csv-export`
- **App:** Python REST API at `http://localhost:8000`
- **Staging:** `https://staging.example.com`
- **Starting state:** No plan, no spec, no existing CSV code

---

## Skill 1 — brainstorming

**Purpose:** Turn a vague idea into an approved design spec before any code is written.

**Developer prompt:**
> "Help me design the CSV export feature. Users should be able to download all their account data as a CSV file."

**What Claude does:**
- Explores project structure (looks at existing endpoints, models, test patterns)
- Offers visual companion if the design will involve layout questions
- Asks clarifying questions one at a time: which fields to export? authentication required? streaming or buffered? size limits?
- Proposes 2–3 approaches (streaming with chunked transfer encoding / buffered with response size cap / async job + polling)
- Recommends streaming with a size cap as the pragmatic choice
- Presents design sections and gets approval after each
- Writes spec to `docs/superpowers/specs/2026-04-06-csv-export-design.md`
- Runs spec self-review: checks for placeholders, contradictions, scope creep
- Asks developer to review and approve the written spec
- Invokes `writing-plans` skill

**Expected output shape:**
- `docs/superpowers/specs/2026-04-06-csv-export-design.md` committed
- Claude announces it is invoking `writing-plans`

---

## Skill 2 — writing-plans

**Purpose:** Convert the approved spec into a bite-sized implementation plan ready for execution.

**Developer prompt:**
> "Use the writing-plans skill to create an implementation plan for this spec."

**What Claude does:**
- Announces "I'm using the writing-plans skill to create the implementation plan"
- Maps file structure: `src/export/csv_serializer.py`, `src/export/endpoint.py`, `tests/export/test_csv_serializer.py`, `tests/export/test_endpoint.py`
- Writes tasks with 2–5 minute steps: write failing test → run to verify fail → write minimal code → run to verify pass → commit
- Includes exact pytest commands with expected output per step
- Saves to `docs/superpowers/plans/2026-04-06-csv-export.md`
- Self-reviews: checks spec coverage, scans for placeholders ("TBD" etc.), checks type consistency
- Offers execution choice: Subagent-Driven (recommended) or Inline Execution

**Expected output shape:**
- `docs/superpowers/plans/2026-04-06-csv-export.md` committed
- Plan header with goal, architecture, tech stack
- Each task has Files section (Create/Modify/Test), and checkbox steps with code

---

## Skill 3 — using-git-worktrees

**Purpose:** Create an isolated workspace for the feature branch before touching any code.

**Developer prompt:**
> "Use the using-git-worktrees skill to set up a worktree for this feature branch."

**What Claude does:**
- Announces "I'm using the using-git-worktrees skill to set up an isolated workspace"
- Checks for `.worktrees/` directory (priority 1), then `worktrees/`, then CLAUDE.md preference
- If directory found but not in `.gitignore`: adds it, commits the change
- Creates: `git worktree add .worktrees/csv-export -b feature/csv-export`
- Runs `pip install -r requirements.txt` (detects Python project from `requirements.txt`)
- Runs `pytest` to verify clean baseline
- Reports: "Worktree ready at `/project/.worktrees/csv-export`. Tests passing (47 tests, 0 failures). Ready to implement csv-export"

**Expected output shape:**
- `.worktrees/csv-export` directory exists and is in `.gitignore`
- Baseline test results reported
- Claude is now working from the worktree

---

## Skill 4 — executing-plans

**Purpose:** Execute the implementation plan inline in the current session with review checkpoints.

**Developer prompt:**
> "Use the executing-plans skill to execute the plan in docs/superpowers/plans/2026-04-06-csv-export.md"

**What Claude does:**
- Announces "I'm using the executing-plans skill to implement this plan"
- Reads the plan and reviews it critically — raises any questions before starting
- Creates TodoWrite with all tasks
- Executes each task step exactly: writes the failing test first, runs pytest to confirm it fails, writes minimal code, runs pytest to confirm it passes, commits
- Marks tasks in_progress then completed as it goes
- Stops and asks if it hits a blocker (e.g., a missing dependency or ambiguous instruction)
- After all tasks, announces it is invoking `finishing-a-development-branch`

**Expected output shape:**
- Each task committed with appropriate message
- All pytest runs produce the expected output (FAIL then PASS)
- TodoWrite reflects completion state

---

## Skill 5 — test-driven-development

**Purpose:** Implement the CSV serializer following strict red-green-refactor discipline.

**Developer prompt:**
> "Use the test-driven-development skill to implement the CSV serializer function. Show the RED-GREEN-REFACTOR cycle."

**What Claude does:**
- Writes one minimal failing test: `test_serialize_user_to_csv_row`
- Runs `pytest tests/export/test_csv_serializer.py::test_serialize_user_to_csv_row -v`
- Confirms test fails with "NameError: name 'serialize_user_to_csv_row' is not defined"
- Writes minimal implementation — just enough to pass the one test
- Runs pytest again, confirms PASS
- Refactors: extracts field list as a constant, removes duplication
- Runs tests again after refactor to confirm still green
- Moves to next failing test for next behavior (e.g., UTF-8 handling)

**Expected output shape:**
- Test written before any implementation code
- Explicit run output showing FAIL then PASS for each cycle
- Refactor step shown with tests re-run

---

## Skill 6 — systematic-debugging

**Purpose:** Find the root cause of a UTF-8 encoding bug before attempting any fix.

**Developer prompt:**
> "Use the systematic-debugging skill. The symptom: CSV output has garbled UTF-8 characters when user names contain accented characters (é, ñ, ü). Trace the root cause."

**What Claude does:**
- Phase 1 — Root Cause Investigation:
  - Reads the error carefully (where exactly does garbling appear — in the file, in the HTTP response header, or in the test assertion?)
  - Reproduces consistently: writes a test with `"Zoé"` as a user name, runs it, confirms garbled output
  - Checks recent changes: was encoding set explicitly anywhere?
  - Adds diagnostic instrumentation: logs raw bytes at serializer output, at response body, at HTTP headers
  - Runs once to gather evidence
- Phase 2 — Pattern Analysis: finds working example (JSON endpoint uses `json.dumps` with `ensure_ascii=False`); identifies difference (CSV writer does not set `encoding='utf-8'` on the StringIO)
- Phase 3 — Hypothesis: "The StringIO object defaults to the system locale encoding, not UTF-8"
- Phase 4 — Implementation: writes failing test reproducing the bug, applies single fix (`io.StringIO()` → explicit UTF-8 via `io.BytesIO` + `csv.writer` with encoding), verifies test passes

**Expected output shape:**
- Four distinct phases reported in sequence
- Hypothesis stated explicitly: "I think X is the root cause because Y"
- Single fix applied, not multiple simultaneous changes
- Failing test written before the fix

---

## Skill 7 — verification-before-completion

**Purpose:** Verify the CSV export feature is actually complete before claiming it is done.

**Developer prompt:**
> "Use the verification-before-completion skill. Claim: 'The CSV export feature is complete and all edge cases are handled.' Verify this claim."

**What Claude does:**
- Identifies the verification commands needed to support the claim
- Runs `pytest tests/export/ -v` — reads full output, counts failures (must be 0)
- Re-reads the original spec line by line, creates a checklist
- Checks each requirement: streaming ✓, authentication ✓, UTF-8 ✓, size cap ✓, field selection ✓
- Reports any gaps found (e.g., "Spec requires 429 rate-limit response; no test exists for this")
- Only after all checks pass makes the claim: "Tests pass (23/23). Spec requirements verified line by line. No gaps found."

**Expected output shape:**
- Explicit test run output shown
- Spec-to-implementation checklist
- Claim made only after evidence is presented, not before

---

## Skill 8 — requesting-code-review

**Purpose:** Dispatch the code-reviewer subagent to review the CSV export implementation.

**Developer prompt:**
> "Use the requesting-code-review skill to request a review of the CSV export implementation."

**What Claude does:**
- Gets git SHAs: `BASE_SHA=$(git rev-parse origin/main)`, `HEAD_SHA=$(git rev-parse HEAD)`
- Dispatches `superpowers:code-reviewer` subagent via Task tool with:
  - WHAT_WAS_IMPLEMENTED: "CSV export endpoint and serializer"
  - PLAN_OR_REQUIREMENTS: path to the plan file
  - BASE_SHA and HEAD_SHA
  - DESCRIPTION: "Added /export endpoint returning CSV of authenticated user's data"
- Reports back code reviewer findings categorized as Critical / Important / Minor
- Fixes Critical issues immediately before continuing

**Expected output shape:**
- Review feedback structured by severity
- Critical issues addressed before any further steps

---

## Skill 9 — receiving-code-review

**Purpose:** Evaluate the reviewer's suggestion to stream CSV instead of buffering it in memory, without performative agreement.

**Developer prompt:**
> "Use the receiving-code-review skill. The reviewer says we should stream the CSV output instead of buffering it all in memory. Evaluate this feedback."

**What Claude does:**
- Reads the complete feedback
- Restates the technical requirement: "Reviewer says to stream CSV rows directly to response rather than building full string in memory"
- Verifies against the codebase: checks current implementation, checks the spec (spec says streaming is preferred approach)
- Evaluates: streaming IS technically correct for large exports, consistent with spec
- Checks YAGNI: are there large user datasets in tests? Yes — the spec explicitly mentions it
- Acknowledges the issue: "Fixed. Changed response to StreamingHttpResponse with a generator that yields CSV rows" — no "Great point!", no "You're absolutely right!"
- Implements the change and tests it

**Expected output shape:**
- Technical evaluation shown (not emotional reaction)
- Verification against codebase before implementing
- Fix described factually: "Fixed. [what changed]"
- No performative agreement phrases

---

## Skill 10 — dispatching-parallel-agents

**Purpose:** Update tests and update API docs simultaneously without waiting for one to finish before starting the other.

**Developer prompt:**
> "Use the dispatching-parallel-agents skill. In parallel: (1) update the unit tests to cover the streaming implementation, (2) update the API docs for the /export endpoint."

**What Claude does:**
- Identifies these as independent domains: tests and docs do not share state, can be edited simultaneously
- Writes focused prompt for Agent 1: "Update tests/export/test_endpoint.py to add streaming tests. Do NOT change production code. Return: list of tests added."
- Writes focused prompt for Agent 2: "Update docs/api/endpoints.md to document the /export endpoint. Return: updated section."
- Dispatches both via Task tool concurrently
- When both return: reads summaries, checks for file conflicts (tests vs docs — no conflict), runs `pytest` to verify test changes, reviews doc update
- Integrates results

**Expected output shape:**
- Both agents dispatched simultaneously (not sequentially)
- Summaries from both agents reported
- Full test suite run after integration

---

## Skill 11 — finishing-a-development-branch

**Purpose:** Complete the `feature/csv-export` branch by choosing among merge, PR, keep, or discard.

**Developer prompt:**
> "Use the finishing-a-development-branch skill to finish the feature/csv-export branch."

**What Claude does:**
- Announces "I'm using the finishing-a-development-branch skill to complete this work"
- Runs `pytest` — if any failures, stops and reports them
- Determines base branch (`main`)
- Presents exactly 4 options:
  1. Merge back to `main` locally
  2. Push and create a Pull Request
  3. Keep the branch as-is (handle later)
  4. Discard this work
- Executes the chosen option (assume: option 2, Push and create PR)
- Runs `git push -u origin feature/csv-export`
- Creates PR with `gh pr create`: summary bullets + test plan checklist
- Removes worktree: `git worktree remove .worktrees/csv-export`

**Expected output shape:**
- Tests verified before options are presented
- Exactly 4 options (no more, no fewer)
- PR URL returned
- Worktree removed

---

## Skill 12 — writing-skills

**Purpose:** Capture the CSV export patterns as a reusable skill for future projects.

**Developer prompt:**
> "Use the writing-skills skill to write a new skill for CSV export patterns in Python REST APIs."

**What Claude does:**
- Assesses whether this pattern is reusable and non-obvious (yes: encoding pitfalls, streaming vs buffering decision, field selection)
- RED phase: runs a pressure scenario with a subagent WITHOUT the skill — documents what the subagent gets wrong (e.g., forgets UTF-8 encoding, buffers instead of streaming)
- GREEN phase: writes `skills/csv-export-patterns/SKILL.md` with:
  - Frontmatter: `name: csv-export-patterns`, `description: Use when implementing CSV export endpoints...`
  - Overview, When to Use, Core Pattern (streaming generator pattern), Quick Reference, Common Mistakes
  - Description starts with "Use when..." and describes triggering conditions only (not the skill's workflow)
- Tests the skill with the same subagent — confirms it now avoids the previous failures
- REFACTOR phase: finds any remaining loopholes (e.g., missing rate-limit guidance), adds them

**Expected output shape:**
- `skills/csv-export-patterns/SKILL.md` written and committed
- Description field does not summarize the skill's process
- Subagent compliance verified before declaring the skill done

---

## Running the Demo

### Install

Follow `install.md` to install agents, commands, skills, and hooks into `~/.claude/`.

### Start a session

Open Claude Code in your project directory. The `session-start` hook automatically injects `using-superpowers` context. You should see Claude acknowledge the superpowers skills are available.

### Skill invocation reference

| Skill | Invocation phrase |
|-------|------------------|
| brainstorming | "Use the brainstorming skill to design [feature]" |
| writing-plans | "Use the writing-plans skill to create an implementation plan for [spec]" |
| using-git-worktrees | "Use the using-git-worktrees skill to set up a worktree for [branch]" |
| executing-plans | "Use the executing-plans skill to execute the plan at [path]" |
| test-driven-development | "Use the test-driven-development skill to implement [feature]" |
| systematic-debugging | "Use the systematic-debugging skill. The symptom: [description]" |
| verification-before-completion | "Use the verification-before-completion skill. Claim: [claim]. Verify it." |
| requesting-code-review | "Use the requesting-code-review skill to review [what was done]" |
| receiving-code-review | "Use the receiving-code-review skill. The reviewer says: [feedback]" |
| dispatching-parallel-agents | "Use the dispatching-parallel-agents skill. In parallel: [task A] and [task B]" |
| finishing-a-development-branch | "Use the finishing-a-development-branch skill to complete this work" |
| writing-skills | "Use the writing-skills skill to write a new skill for [topic]" |
