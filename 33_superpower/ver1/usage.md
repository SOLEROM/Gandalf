# Usage Guide — Superpowers Dev Toolkit v5.0.7

Best-practice workflow guide organized by development phase. Each section covers the relevant tools: when to use them, exact invocations, notable behaviors, and anti-patterns to avoid.

---

## Phase 1 — Session Start: using-superpowers

### When to use
Automatically — the `session-start` hook injects the skill content into every new Claude Code session. You do not invoke this manually.

### What it does
At session start, the hook reads `skills/using-superpowers/SKILL.md` and injects the full content into the context wrapped in `<EXTREMELY_IMPORTANT>` tags. This teaches Claude to:
- Check for applicable skills before any response or action
- Use the `Skill` tool to invoke skills (never read skill files directly)
- Give process skills (brainstorming, debugging) priority over implementation skills

### Notable behaviors
- Fires on `startup`, `clear`, and `compact` events — so a `/clear` also re-injects the context
- If `~/.config/superpowers/skills` exists (legacy location), Claude will warn you to migrate to `~/.claude/skills`
- Subagents dispatched to do specific tasks skip the using-superpowers preamble to avoid noise

### Anti-patterns
- Do not invoke `using-superpowers` manually in normal operation; the hook handles it
- Do not delete the hook entry from `settings.json` — without it, Claude will not reliably check for skills

---

## Phase 2 — Before Coding: brainstorming → writing-plans → using-git-worktrees

### brainstorming

**When to use:** Before any creative work — creating features, building components, modifying behavior. This is a hard gate: no code before a design is approved.

**Invocation:**
```
Use the brainstorming skill to design [feature]
```
or trigger it via `/brainstorm` (deprecated alias).

**Process (in order):**
1. Explore project context (files, docs, recent commits)
2. Offer visual companion if visual questions are expected (its own message, nothing else)
3. Ask clarifying questions — one at a time
4. Propose 2–3 approaches with trade-offs and a recommendation
5. Present design sections, get approval after each
6. Write spec to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` and commit
7. Self-review spec (placeholders, contradictions, ambiguity)
8. Ask user to review the spec before proceeding
9. Invoke `writing-plans` — this is the only skill brainstorming hands off to

**Notable behaviors:**
- The hard gate (`<HARD-GATE>`) blocks all implementation until the user approves the design — no exceptions for "simple" projects
- If the scope covers multiple independent subsystems, brainstorming flags this and helps decompose before designing any single piece
- Spec is saved and committed before moving on

**Anti-patterns:**
- Skipping brainstorming for "simple" changes — the skill explicitly forbids this
- Asking multiple clarifying questions at once
- Invoking any skill other than `writing-plans` after the design is approved
- Starting implementation before the user reviews the written spec

---

### writing-plans

**When to use:** After brainstorming approves a design, or whenever you have a spec and need a detailed implementation plan.

**Invocation:**
```
Use the writing-plans skill to create an implementation plan for [spec/feature]
```
or `/write-plan` (deprecated alias).

**Process:**
1. Map out all files to be created or modified and their responsibilities
2. Write bite-sized tasks — each step is one action (2–5 minutes): write test → run to verify fail → write minimal code → run to verify pass → commit
3. Every step includes the actual code or command; no placeholders ("TBD", "implement later") are allowed
4. Save plan to `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
5. Self-review the plan against the spec (coverage, placeholder scan, type consistency)
6. Offer execution choice: Subagent-Driven (recommended) or Inline Execution

**Notable behaviors:**
- Plans must start with a standard header including goal, architecture summary, and tech stack
- The self-review runs against the spec to catch gaps before execution begins
- After saving, writing-plans hands off to either `subagent-driven-development` or `executing-plans`

**Anti-patterns:**
- Writing steps that say what to do without showing how (code blocks required)
- Including "Similar to Task N" references — repeat the code, the engineer may read tasks out of order
- Leaving types or method names inconsistent between tasks

---

### using-git-worktrees

**When to use:** Before executing any implementation plan, or when starting feature work that needs isolation from the current workspace.

**Invocation:**
```
Use the using-git-worktrees skill to set up a worktree for [feature/branch-name]
```

**Process:**
1. Check for existing worktree directory in priority order: `.worktrees/` → `worktrees/` → CLAUDE.md preference → ask user
2. Verify the chosen directory is in `.gitignore` (for project-local directories) — if not, add it and commit before proceeding
3. Create worktree: `git worktree add <path> -b <branch-name>`
4. Auto-detect and run project setup (npm install, pip install, cargo build, go mod download)
5. Run tests to verify a clean baseline
6. Report the worktree path and test results

**Notable behaviors:**
- If both `.worktrees/` and `worktrees/` exist, `.worktrees/` wins
- `.gitignore` verification is mandatory for project-local directories — worktree contents must not be tracked
- If baseline tests fail, the skill reports failures and asks whether to proceed rather than silently continuing

**Anti-patterns:**
- Creating a worktree without verifying it is git-ignored
- Skipping the baseline test run
- Assuming the directory location without checking CLAUDE.md first
- Proceeding with failing baseline tests without explicit user permission

---

## Phase 3 — Implementation

### executing-plans

**When to use:** When you have a written implementation plan and want to execute it inline in the current session with review checkpoints.

**Invocation:**
```
Use the executing-plans skill to implement the plan at [path/to/plan.md]
```
or `/execute-plan` (deprecated alias).

**Process:**
1. Read and critically review the plan — raise concerns before starting
2. Create a TodoWrite with all tasks
3. Execute each task step-by-step exactly as written; mark tasks in_progress then completed
4. Stop and ask if blocked (missing dependency, unclear instruction, repeated test failure)
5. After all tasks, invoke `finishing-a-development-branch`

**Notable behaviors:**
- Recommends using `subagent-driven-development` instead when subagents are available — quality is significantly higher
- Never starts implementation on main/master without explicit user consent
- "Stop and ask, don't guess" is the explicit policy for blockers

**Anti-patterns:**
- Skipping verifications specified in the plan
- Guessing past blockers instead of stopping
- Modifying plan steps instead of following them

---

### test-driven-development

**When to use:** When implementing any feature or bugfix, before writing implementation code. No exceptions without human partner permission.

**Invocation:**
```
Use the test-driven-development skill to implement [feature/bugfix]
```

**The Iron Law:** No production code without a failing test first. If you wrote code before the test, delete it and start over.

**Red-Green-Refactor cycle:**
1. **RED** — Write one minimal test showing expected behavior; run it and confirm it fails for the right reason
2. **GREEN** — Write the simplest code that makes the test pass; run and confirm pass
3. **REFACTOR** — Clean up (remove duplication, improve names); keep tests green

**Notable behaviors:**
- Watching the test fail is mandatory — a test that passes immediately is not a real test
- "Minimal code" means exactly enough to pass, no more (YAGNI enforced)
- The skill includes an extensive rationalization table covering every common excuse for skipping TDD

**Anti-patterns:**
- Writing code first "as reference" and then tests — the skill explicitly requires deleting that code
- Tests that only test mock behavior rather than real code
- Adding extra features during the GREEN phase
- Saying "tests after achieve the same purpose" — they do not

---

### subagent-driven-development

**When to use:** Executing an implementation plan with independent tasks in the current session, when subagents are available.

**Invocation:**
```
Use the subagent-driven-development skill to execute the plan at [path/to/plan.md]
```

**Process (per task):**
1. Read the full plan once, extract all task text, create TodoWrite
2. Dispatch implementer subagent with full task text and scene-setting context
3. Answer any questions the implementer raises before letting it proceed
4. Dispatch spec compliance reviewer — verifies code matches what was specified
5. Dispatch code quality reviewer — verifies the implementation is well-built
6. Fix any issues found and re-review until both reviewers approve
7. Mark task complete; move to next task
8. After all tasks, dispatch a final code reviewer, then invoke `finishing-a-development-branch`

**Model selection:** Use the least powerful model that can handle each role. Mechanical implementation tasks (isolated functions, clear spec, 1–2 files) → cheap model. Integration and judgment → standard model. Architecture and review → most capable model.

**Notable behaviors:**
- Implementer subagents report one of four statuses: `DONE`, `DONE_WITH_CONCERNS`, `NEEDS_CONTEXT`, `BLOCKED` — each has a specific handling protocol
- Spec compliance review runs before code quality review — wrong order is a red flag
- Subagents never inherit your session history; you construct exactly the context they need

**Anti-patterns:**
- Dispatching multiple implementation subagents in parallel (they conflict)
- Making a subagent read the plan file — provide the full task text directly
- Moving to the next task before both reviews pass
- Letting implementer self-review substitute for the two-stage review

---

### dispatching-parallel-agents

**When to use:** When facing 2+ independent tasks or failures that can be worked on concurrently without shared state or sequential dependencies.

**Invocation:**
```
Use the dispatching-parallel-agents skill to investigate [failure-A] and [failure-B] simultaneously
```

**Process:**
1. Identify independent problem domains (group failures by what subsystem is broken)
2. For each domain, write a focused agent prompt: specific scope, clear goal, explicit constraints, expected output format
3. Dispatch all agents simultaneously using the Task tool
4. Review returned summaries, check for conflicts, run full test suite, integrate changes

**Notable behaviors:**
- Each agent receives precisely crafted context — never your session history
- "Focused" means one test file or one subsystem, not "fix all tests"
- After agents return: review summaries, check for editing conflicts, run full suite, spot-check for systematic errors

**Anti-patterns:**
- Using this when failures are related (fixing one might fix others — investigate together first)
- Writing vague prompts ("fix the race condition") without specifying where
- Skipping constraints in agent prompts — agents may refactor things they shouldn't
- Skipping the post-integration full test run

---

## Phase 4 — Debugging: systematic-debugging

**When to use:** For any technical issue — test failures, production bugs, unexpected behavior, performance problems, build failures. Especially when under time pressure.

**Invocation:**
```
Use the systematic-debugging skill. The symptom: [description]
```

**The Iron Law:** No fixes without root cause investigation first.

**Four phases (complete each before proceeding):**
1. **Root Cause Investigation** — read error messages carefully, reproduce consistently, check recent changes, add diagnostic instrumentation at component boundaries, trace data flow backward
2. **Pattern Analysis** — find working examples, compare against references completely (not skimmed), identify every difference
3. **Hypothesis and Testing** — form one specific hypothesis, test with the smallest possible change, one variable at a time
4. **Implementation** — create a failing test first, implement single fix at root cause (not symptom), verify

**Notable behaviors:**
- After 3+ failed fixes, the skill requires stopping and questioning the architecture rather than attempting fix #4
- "Add diagnostic instrumentation first, then analyze evidence" is the prescribed approach for multi-component systems
- The skill includes a list of signals from your human partner that indicate you are rationalizing rather than investigating

**Anti-patterns:**
- "Quick fix for now, investigate later"
- Proposing multiple fixes at once
- Fixing symptoms instead of root cause
- Attempting fix #4 without an architectural discussion

---

## Phase 5 — Quality Gates: verification-before-completion

**When to use:** Before claiming any work is complete, fixed, or passing. Before committing, creating PRs, or moving to the next task.

**Invocation:**
```
Use the verification-before-completion skill. Claim: "[what you want to claim]". Verify it.
```

**The Gate Function:**
1. Identify the command that proves the claim
2. Run it — fresh and complete, not a cached result
3. Read the full output and check exit code
4. Verify the output confirms the claim
5. Only then make the claim, with the evidence

**Notable behaviors:**
- Trusting agent success reports without independent verification is a specific red flag
- "Should", "probably", "seems to" in your own wording are red flags
- Expressions of satisfaction ("Great!", "Done!", "Perfect!") before verification are forbidden
- Regression test verification requires the full red-green cycle: write test → pass → revert fix → must fail → restore → pass

**Anti-patterns:**
- Running partial checks ("linter passed" ≠ "build succeeds")
- Relying on a previous run's output
- Trusting subagent reports without checking the VCS diff

---

## Phase 6 — Review: requesting-code-review + code-reviewer, receiving-code-review

### requesting-code-review

**When to use:** After completing each task in subagent-driven development, after major features, before merging to main.

**Invocation:**
```
Use the requesting-code-review skill to review the work from [base-SHA] to [head-SHA]
```

**Process:**
1. Get git SHAs: `BASE_SHA=$(git rev-parse HEAD~1)` and `HEAD_SHA=$(git rev-parse HEAD)`
2. Dispatch `superpowers:code-reviewer` subagent via the Task tool with the template from `requesting-code-review/code-reviewer.md`
3. Act on feedback: fix Critical immediately, fix Important before proceeding, note Minor for later

**Notable behaviors:**
- The reviewer gets precisely crafted context — not your session history
- "Review early, review often" — after each task in subagent-driven development, after each batch of 3 tasks in executing-plans
- Push back on reviewer feedback if it is technically wrong (with reasoning)

---

### code-reviewer agent

The `code-reviewer` agent (`agents/code-reviewer.md`) is a Senior Code Reviewer subagent. It performs:
- Plan alignment analysis (comparing implementation to original spec)
- Code quality assessment (error handling, type safety, naming, test coverage)
- Architecture and design review (SOLID principles, separation of concerns)
- Documentation and standards check
- Issue categorization: Critical (must fix) / Important (should fix) / Minor (nice to have)

It is dispatched by `requesting-code-review` and `subagent-driven-development`. Do not invoke it directly in normal workflows.

---

### receiving-code-review

**When to use:** When receiving code review feedback, before implementing suggestions — especially if feedback is unclear or technically questionable.

**Invocation:**
```
Use the receiving-code-review skill. The reviewer says: "[feedback]". Evaluate and respond.
```

**Response pattern:**
1. Read complete feedback without reacting
2. Restate requirements in own words, or ask for clarification
3. Verify claims against codebase reality
4. Evaluate: technically sound for this codebase?
5. Respond with technical acknowledgment or reasoned pushback
6. Implement one item at a time, test each

**Notable behaviors:**
- "You're absolutely right!" is explicitly forbidden — it is performative, not technical
- If any item is unclear, stop and clarify all items before implementing any of them
- External reviewer suggestions require checking: correct for this codebase? breaks existing functionality? conflicts with architectural decisions?
- YAGNI check: if a reviewer suggests implementing something that is not called anywhere, confirm removal rather than implementation

**Anti-patterns:**
- Implementing suggestions before verifying them against the codebase
- Implementing multiple items at once without testing each
- Agreeing performatively without technical evaluation
- Avoiding pushback when feedback is technically incorrect

---

## Phase 7 — Branch Completion: finishing-a-development-branch

**When to use:** Implementation is complete, all tests pass, and you need to decide how to integrate the work.

**Invocation:**
```
Use the finishing-a-development-branch skill to complete this work
```

**Process:**
1. Verify tests pass (if they fail, stop and fix before presenting any options)
2. Determine base branch
3. Present exactly 4 options:
   - Merge back to `<base-branch>` locally
   - Push and create a Pull Request
   - Keep the branch as-is (handle later)
   - Discard this work
4. Execute the chosen option
5. Clean up the worktree (for options 1 and 4; keep for options 2 and 3)

**Notable behaviors:**
- Option 4 (discard) requires typed "discard" confirmation — no accidental deletions
- Worktree cleanup happens only for merge and discard; PR and keep-as-is preserve the worktree
- PR body follows a standard template: Summary bullets + Test Plan checklist

**Anti-patterns:**
- Proceeding with failing tests
- Offering open-ended "what should I do?" instead of the structured 4 options
- Automatically cleaning up the worktree after creating a PR

---

## Phase 8 — Extending This System: writing-skills

**When to use:** Creating new skills, editing existing skills, or verifying skills work before deployment.

**Invocation:**
```
Use the writing-skills skill to create a new skill for [topic]
```

**Core concept:** Writing skills IS Test-Driven Development applied to process documentation. The same Iron Law applies — no skill without a failing test first.

**RED-GREEN-REFACTOR for skills:**
- **RED** — Run pressure scenarios with a subagent without the skill; document exact rationalizations and failures
- **GREEN** — Write minimal skill addressing those specific failures; verify agents now comply
- **REFACTOR** — Find new rationalizations, add explicit counters, re-test until bulletproof

**SKILL.md structure:** YAML frontmatter (name + description, max 1024 chars), Overview, When to Use, Core Pattern, Quick Reference, Implementation, Common Mistakes

**Description field rules:** Start with "Use when..." and describe triggering conditions only — never summarize the skill's workflow. A description that summarizes the workflow creates a shortcut Claude will take instead of reading the full skill.

**Notable behaviors:**
- Skills live in a flat namespace: `~/.claude/skills/<name>/SKILL.md`
- Token efficiency is critical for frequently-loaded skills — target under 200 words
- The `render-graphs.js` utility renders `dot` flowchart blocks to SVG for visualization

**Anti-patterns:**
- Deploying a skill without testing it with a subagent first
- Describing the skill's process in the description field
- Creating multiple skills in batch without testing each one

---

## Quick Reference

| Situation | Tool / Skill |
|-----------|-------------|
| Starting work on a new feature | `brainstorming` |
| Have a spec, need a plan | `writing-plans` |
| Need an isolated workspace | `using-git-worktrees` |
| Have a plan, executing inline | `executing-plans` |
| Have a plan, subagents available | `subagent-driven-development` |
| Implementing any feature or fix | `test-driven-development` |
| Multiple independent failures | `dispatching-parallel-agents` |
| Bug, test failure, unexpected behavior | `systematic-debugging` |
| About to claim something works | `verification-before-completion` |
| Finished a task or feature | `requesting-code-review` |
| Got review feedback | `receiving-code-review` |
| Implementation complete, tests passing | `finishing-a-development-branch` |
| Need to capture a reusable technique | `writing-skills` |
| AI doesn't seem to be checking skills | Check that the `session-start` hook is installed and executable |
