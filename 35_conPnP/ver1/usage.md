# Usage Guide — Context Engineering Toolkit

Organized by when you reach for each tool during a development session.

---

## Before Writing Code

### /primer — Orient Claude to your project

**When**: Start of any session, or when Claude seems confused about project structure.

```
/primer
```

Claude reads CLAUDE.md, README.md, and key source files, then explains back the project structure, purpose, and conventions. Takes 30 seconds, saves hours.

**Anti-pattern**: Skipping this and wondering why Claude keeps using the wrong patterns.

---

### /generate-prp — Create an implementation blueprint

**When**: You have a feature idea and want Claude to research, plan, and document it before touching any code.

```
/generate-prp INITIAL.md
```

**What to put in INITIAL.md first**:
- FEATURE: specific description of what to build
- EXAMPLES: reference files in your `examples/` folder
- DOCUMENTATION: paste URLs to relevant API docs
- OTHER CONSIDERATIONS: gotchas Claude commonly misses

**What Claude does**:
1. Reads INITIAL.md
2. Searches the codebase for similar patterns
3. Fetches external documentation URLs
4. Writes `PRPs/{feature-name}.md` — a comprehensive blueprint

**Output**: A PRP file scored 1-10 on confidence. Below 7 means you should add more context to INITIAL.md.

**Anti-pattern**: Writing a vague INITIAL.md. "Build a web scraper" → bad. "Build an async scraper using BeautifulSoup that extracts product data, handles 429 rate limits, stores to Postgres with a retry queue" → good.

---

## Writing Code

### /execute-prp — Implement a feature end-to-end

**When**: You have a PRP and want Claude to implement it.

```
/execute-prp PRPs/my-feature.md
```

**What Claude does**:
1. Reads the entire PRP
2. ULTRATHINK — builds a comprehensive plan
3. Implements all tasks in order
4. Runs each validation command
5. Fixes failures and re-runs
6. Reports completion with checklist

**The key**: Claude runs your actual validation commands (tests, linting, type-checking) and iterates until they pass. This is what makes it reliable.

**Anti-pattern**: Running `/execute-prp` on a thin PRP with no validation commands. Claude will implement something, but without runnable checks it can't self-correct.

---

### validation-gates agent — Run tests until they pass

**When**: After implementing a feature, or when tests are failing and you want Claude to iterate.

```
use the validation-gates agent to test the changes in src/payment.py
— it should test happy path, invalid input, and network timeout cases
```

**What Claude does**:
1. Identifies which tests to run
2. Runs lint + typecheck + tests
3. For each failure: reads error, identifies root cause, fixes, re-runs
4. Repeats until all pass
5. Reports final status

**Anti-pattern**: Not specifying what was changed. Be explicit: "validate the changes in X, specifically test Y and Z scenarios."

---

### documentation-manager agent — Keep docs in sync

**When**: After any code changes that affect the public interface, setup steps, or architecture.

```
use the documentation-manager agent to update docs —
I changed the auth module in src/auth/ to use JWT instead of sessions
```

**What Claude does**:
- Checks README, API.md, ARCHITECTURE.md for affected sections
- Updates installation steps if dependencies changed
- Adds migration notes for breaking changes
- Cross-references all related docs

**Anti-pattern**: Running this without telling it what changed. It needs to know where to look.

---

## GitHub Workflow

### /fix-github-issue — Fix an issue end-to-end

**When**: You have a GitHub issue number and want Claude to read it, fix it, test it, and open a PR.

```
/fix-github-issue 42
```

**What Claude does**:
1. `gh issue view 42` — reads the issue
2. Searches codebase for relevant files
3. Implements the fix
4. Runs tests and linting
5. Creates a descriptive commit
6. Pushes and opens a PR

**Requires**: `gh` CLI installed and authenticated.

---

## Parallel Development

### /prep-parallel + /execute-parallel — Build N versions simultaneously

**When**: You want to try multiple implementation approaches and pick the best one.

**Step 1**: Set up worktrees
```
/prep-parallel auth-refactor 3
```
Creates `trees/auth-refactor-1/`, `trees/auth-refactor-2/`, `trees/auth-refactor-3/`

**Step 2**: Run parallel agents
```
/execute-parallel auth-refactor PRPs/auth-refactor.md 3
```
3 Claude agents independently implement the feature. Each writes a `RESULTS.md` summarizing their changes.

**Step 3**: Review and pick the best implementation.

**When this pays off**: Complex features where the first approach might not be optimal. Expensive in API cost, but cheap compared to going back and rewriting.

---

## Quick Reference

| Situation | Tool |
|-----------|------|
| Starting a new session | `/primer` |
| Have a feature idea | Fill INITIAL.md → `/generate-prp` |
| Have a PRP ready | `/execute-prp PRPs/feature.md` |
| Tests failing | `validation-gates` agent |
| Docs out of date | `documentation-manager` agent |
| GitHub issue to fix | `/fix-github-issue #N` |
| Want multiple approaches | `/prep-parallel` + `/execute-parallel` |

---

## The Full Workflow

```
1. /primer                        — orient Claude to the project
2. Fill INITIAL.md                — describe the feature
3. /generate-prp INITIAL.md       — research + blueprint
4. Review PRPs/feature.md         — check confidence score, add context if <7
5. /execute-prp PRPs/feature.md   — implement
6. validation-gates agent         — validate and iterate
7. documentation-manager agent    — sync docs
8. /fix-github-issue or manual PR — ship it
```
