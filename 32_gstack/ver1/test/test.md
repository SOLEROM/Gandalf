# gstack Skills Demo Scenario

## Context

You are a developer building a **user onboarding flow** feature for a SaaS web app.
The stack is irrelevant — gstack skills are language-agnostic.

You have:
- A written feature plan (pasted inline below)
- Code changes on a branch `feature/onboarding-flow`
- A staging deployment at `https://example.com` (used as stand-in for staging URL)
- A week of commit history in the repo

Work through the steps below in order. Each step shows exactly what to type to Claude Code.

---

## The Feature Plan (reference for plan review steps)

> **Feature: User Onboarding Flow**
>
> Goal: After signup, walk new users through 3 steps: (1) set display name, (2) connect one
> integration, (3) invite a teammate. Progress is saved per step. Users can skip and return.
> On completion, show a confetti animation and redirect to dashboard.
>
> Implementation:
> - New `OnboardingController` with 3 action methods
> - `onboarding_progress` column on `users` table (jsonb)
> - Three view partials rendered in sequence
> - JS for confetti via cdn.jsdelivr.net/npm/canvas-confetti
>
> Out of scope: email reminders, analytics events, mobile layout

---

## Step 1 — Engineering Plan Review

**Skill:** `plan-eng-review`
**Purpose:** Lock down architecture, data flow, edge cases, test coverage before writing code.

**What to type to Claude:**
```
Use the plan-eng-review skill to review this plan:

[paste the feature plan above]
```

**Or more naturally:**
```
eng review this plan before I start: [paste plan]
```

**What Claude does:**
- Runs a system audit (git log, TODOS.md, CLAUDE.md) first
- Challenges architecture: is `jsonb` column the right model? What if a user deletes mid-flow?
- Maps every error path: what happens if the CDN for confetti is down?
- Asks: how is partial completion tested? What is the rollback path?
- Produces ASCII data flow diagram
- Lists implementation-time ambiguities with suggested resolutions

**Expected output shape:**
```
## System Audit
[recent commits, open TODOs, relevant files]

## Architecture Review
- Concern: jsonb on users is a smell if progress becomes queryable later...
- Diagram: [onboarding state machine]

## Error/Rescue Map
- cdn.jsdelivr.net fails → confetti silently skipped? Or retry? Document this.
- Step 2 network error mid-save → progress lost → handle with optimistic local state

## Edge Cases
- User navigates back in browser mid-flow
- Two tabs open simultaneously
- Invited teammate is already a member

## Test Coverage
- Happy path (all 3 steps)
- Skip all → return later → complete
- Each step in isolation

## Questions for you before implementation
1. ...
```

---

## Step 2 — CEO Plan Review (scope challenge)

**Skill:** `plan-ceo-review`
**Purpose:** Challenge premises, find the better/bigger/leaner version before committing.

**What to type to Claude:**
```
Use the plan-ceo-review skill on this plan. I want SCOPE EXPANSION mode.

[paste the feature plan above]
```

**Or:**
```
ceo review this plan, expansion mode: [paste plan]
```

**What Claude does:**
- Runs system audit
- Challenges: "Is onboarding the right problem? Could a smarter default state eliminate the need?"
- 10x check: "What if onboarding also imported data from the connected integration on step 2?"
- Delight opportunities: progress persistence across devices, teammate invite pre-fills their name
- Temporal interrogation: "At hour 3, you'll need to decide: server-side or client-side confetti trigger?"
- Presents 3 mode options and commits to EXPANSION

**Expected output shape:**
```
## System Audit
[...]

## Step 0: Nuclear Scope Challenge

### 0A. Premise Challenge
Is onboarding truly the bottleneck? What does the drop-off data say about where users leave?

### 0C. Dream State
CURRENT: users land on empty dashboard, confused
THIS PLAN: 3-step wizard
12-MONTH IDEAL: personalized onboarding that pre-populates based on signup source

### 0D. 10x Check
10x version: after step 2 (connect integration), immediately show a live preview of what
their data would look like in the app. Turn onboarding into a value demonstration.

### Delight Opportunities
1. Step completion animations beyond confetti — each step has its own micro-celebration
2. "Resume where you left off" email if user abandons mid-flow
3. Invite step pre-fills teammate name from integration contacts

[continues...]
```

---

## Step 3 — Browse: Test the Staging Deployment

**Skill:** `browse`
**Purpose:** Verify the feature works in a real browser before shipping.

**Setup check (always first):**
```
Run this to confirm browse is ready:

_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
B=""
[ -n "$_ROOT" ] && [ -x "$_ROOT/.claude/skills/browse/dist/browse" ] && B="$_ROOT/.claude/skills/browse/dist/browse"
[ -z "$B" ] && B=~/.claude/skills/browse/dist/browse
if [ -x "$B" ]; then echo "READY: $B"; else echo "NEEDS_SETUP"; fi
```

**What to type to Claude:**
```
Use the browse skill to test the onboarding flow on staging.
The URL is https://staging.myapp.com/onboarding
```

**Typical browse session Claude runs:**

```bash
# 1. Navigate and check the page loads
$B goto https://staging.myapp.com/onboarding
$B text                        # Does content load?
$B console                     # Any JS errors?
$B network                     # Any failed requests?

# 2. See all interactive elements
$B snapshot -i                 # Lists all buttons/inputs with @e refs

# 3. Fill step 1 — display name
$B fill @e1 "Demo User"
$B click @e2                   # "Continue" button
$B snapshot -D                 # Diff: did step 2 appear?

# 4. Screenshot for evidence
$B screenshot /tmp/onboarding-step2.png

# 5. Verify step progress is visible
$B is visible ".step-indicator"
$B text                        # Does it say "Step 2 of 3"?

# 6. Test skip behavior
$B click @e5                   # "Skip for now" link
$B snapshot -D                 # Diff: did it advance to step 3?

# 7. Complete flow and check redirect
$B click @e8                   # "Finish" button
$B is visible ".dashboard"     # Did we land on the dashboard?

# 8. Check confetti fired (no JS errors is the proxy)
$B console --errors            # Should be empty
```

**Expected output shape:**
```
READY: /home/user/.claude/skills/browse/dist/browse

[snapshot output]
  @e1 [textbox] "Display name"
  @e2 [button] "Continue"
  @e3 [button] "Skip for now"
  ...

[diff output after click]
  - @e1 [textbox] "Display name"
  + @e4 [combobox] "Choose integration"
  + @e5 [button] "Connect"
  ...
```

---

## Step 4 — QA: Systematic Quality Check

**Skill:** `qa`
**Purpose:** Structured multi-mode QA run — not just happy path.

**What to type to Claude:**
```
QA the onboarding flow on staging: https://staging.myapp.com/onboarding
```

**Or on a feature branch:**
```
Run qa on this branch's changes
```

**What Claude does (diff-aware mode, on a feature branch):**
- Reads `git diff main --stat` to identify changed files
- Maps changed files to affected pages/routes
- Tests each affected route
- Runs full interaction matrix: happy path, edge cases, error states
- Produces structured report with health score

**Expected output shape:**
```
## QA Report — onboarding-flow
Health Score: 8/10

### Changed routes detected
- /onboarding (new)
- /dashboard (redirect target)

### Test results
✓ Page loads < 2s
✓ Step 1: display name saves correctly
✓ Step 2: integration connect flow works
✗ Step 3: invite input accepts invalid emails (no validation)
✗ Back button mid-flow shows blank page (no back-nav handling)
⚠ Confetti fires on slow connections with 300ms delay (acceptable)

### Screenshots
[attached: step1.png, step2.png, step3-bug.png]

### Repro steps for issues
Issue 1: Invalid email accepted
  1. Go to /onboarding
  2. Complete steps 1–2
  3. Enter "notanemail" in invite field
  4. Click Send — accepted without error
```

---

## Step 5 — Browse: Import Cookies for Authenticated Testing

**Skill:** `setup-browser-cookies`
**Purpose:** Bring your real browser session into the headless browser for authenticated pages.

> **Note:** macOS only. Skip on Linux.

**What to type to Claude:**
```
Import my browser cookies so I can test the authenticated onboarding flow
```

**Or:**
```
Use setup-browser-cookies to import my Chrome session
```

**What Claude does:**
- Opens an interactive cookie picker in your real browser at `localhost:<port>/cookie-picker`
- Lists all domains with cookie counts
- You select the domains you need (e.g. `staging.myapp.com`)
- Imports selected cookies into the headless session
- Browse is now authenticated for the rest of the session

**After setup — authenticated browse commands:**
```bash
$B goto https://staging.myapp.com/dashboard    # logged-in page
$B is visible ".user-menu"                      # confirms session works
```

---

## Step 6 — Code Review Before Landing

**Skill:** `review`
**Purpose:** Pre-landing PR review — catches structural issues, not just logic bugs.

**What to type to Claude:**
```
Review my PR before I land it
```

**Or:**
```
Use the review skill on this branch
```

**What Claude does:**
- Runs `git diff main --stat` to see the full diff
- Checks SQL safety: any raw string interpolation in queries?
- Checks LLM trust boundaries: any user input passed unsanitized to prompts?
- Checks conditional side effects: mutations inside if-blocks without rollback?
- Reads `review/checklist.md` for project-specific checks
- Produces TODOS for non-blocking issues

**Expected output shape:**
```
## PR Review — feature/onboarding-flow

### SQL Safety ✓
No raw query interpolation found.

### LLM Trust Boundaries — N/A
No LLM calls in this diff.

### Conditional Side Effects ⚠
OnboardingController#complete — sends welcome email before DB commit.
If commit fails, email is already sent. Move email send to after_commit callback.

### Structural Issues ✓
No issues.

### TODOS (non-blocking)
- [ ] Add index on users.onboarding_progress for the dashboard query
- [ ] Confetti CDN fallback not handled — document in BROWSER.md

### Verdict: APPROVED WITH TODOS
```

---

## Step 7 — Ship It

**Skill:** `ship`
**Purpose:** Merge, test, version bump, changelog, push, PR — the full release workflow.

**What to type to Claude:**
```
Ship this branch
```

**What Claude does:**
1. Merges main into current branch
2. Runs the test suite
3. Shows diff summary for final confirmation
4. Bumps VERSION
5. Updates CHANGELOG
6. Commits, pushes
7. Opens PR with structured description

**Expected output shape:**
```
Merging main into feature/onboarding-flow... done
Running tests... 142 passed, 0 failed
Diff: +847 -12 lines across 9 files

Ready to ship. Confirm:
  Version: 1.4.0 → 1.5.0
  Branch: feature/onboarding-flow → main
  PR title: "Add user onboarding flow"

Proceed? [y/n]
```

---

## Step 8 — Weekly Retrospective

**Skill:** `retro`
**Purpose:** End-of-week engineering health check.

**What to type to Claude:**
```
Run the weekly retro
```

**Or:**
```
Use the retro skill
```

**What Claude does:**
- Reads `git log --since="7 days ago"` for the full team
- Analyzes commit patterns (day/time, focus areas, PR velocity)
- Per-contributor breakdown with praise and growth areas
- Compares against previous retro if history exists in `~/.gstack/<project>/retro/`

**Expected output shape:**
```
## Engineering Retro — Week of Apr 7, 2026

### Commits this week: 34 across 3 contributors

### Work pattern
- Most active: Tuesday–Thursday
- Slowest: Monday (planning overhead?)
- Focus areas: onboarding (60%), bug fixes (25%), infra (15%)

### Per-contributor
@vlad — 18 commits
  Praise: Shipped onboarding flow end-to-end with QA evidence and security review
  Growth area: 3 commits with "fix" in message same day — consider smaller PRs

@alex — 12 commits
  Praise: Fast review turnaround, good checklist coverage
  Growth area: Large commits late Friday increase review risk

### Trend vs last week
Commit volume: +12% ↑
Test coverage: stable
PR cycle time: 2.1 days (was 2.8) ↓ improving

### Top shipped: user onboarding flow
```

---

## Running the Demo

### 1. Install gstack first

```bash
cd /path/to/gstack/ver1
bash install.sh
```

### 2. Start a Claude Code session in your project

```bash
cd /your/project
claude
```

### 3. Run each step in order

Paste the prompts from each step above. Claude will detect and load the appropriate skill automatically based on the description.

### 4. Browse commands

For steps that use `$B`, Claude runs them via the Bash tool. You can also run them manually:

```bash
B=~/.claude/skills/browse/dist/browse
$B goto https://example.com
$B text
$B snapshot -i
$B stop
```

### Skill names for explicit invocation

| Skill | Trigger phrase | Explicit invocation |
|-------|---------------|---------------------|
| browse | "test this URL", "check the page", "take a screenshot" | `use the browse skill` |
| plan-ceo-review | "ceo review", "challenge this plan", "expand scope" | `use plan-ceo-review` |
| plan-eng-review | "eng review", "architecture review", "review this plan" | `use plan-eng-review` |
| qa | "qa this", "find bugs", "test the site" | `use the qa skill` |
| retro | "weekly retro", "run retro" | `use the retro skill` |
| review | "review my PR", "review before landing" | `use the review skill` |
| setup-browser-cookies | "import my cookies", "set up browser auth" | `use setup-browser-cookies` |
| ship | "ship this", "create the PR" | `use the ship skill` |
