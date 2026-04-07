# Usage Guide

Best-practice usage organized by development workflow phase.

---

## Before Coding — Project Setup

### `claude-md` — Create or audit CLAUDE.md

**When:** Starting a new project, onboarding a repo to Claude Code, or improving an existing CLAUDE.md.

**Invocation:**
```
/claude-md create
/claude-md update
/claude-md audit
/claude-md create src/api/CLAUDE.md   # directory-specific
```

**Notable behaviors:**
- `audit` mode reports without modifying the file
- Recommends `agent_docs/` folder for large projects (progressive disclosure)
- Enforces the Golden Rules: under 300 lines, no style rules, no code snippets

**Anti-patterns:**
- Don't run `update` when you actually want `audit` first — read the report before applying changes
- Don't include task-specific instructions; those belong in separate files referenced from CLAUDE.md

---

## Reviewing Code — Before Merging

### `code-review-specialist` — Comprehensive code review

**When:** Reviewing a PR, auditing a module, or assessing quality before a release.

**Invocation:**
```
/code-review-specialist
Review the file src/auth/login.py for security and quality issues.
```

**Notable behaviors:**
- Covers four dimensions: Security, Performance, Code Quality, Maintainability
- Uses Big O analysis for performance findings
- Checks SOLID principles, cyclomatic complexity, type safety

**Supporting scripts:**
```bash
python code-review/scripts/analyze-metrics.py src/auth/login.py
python code-review/scripts/compare-complexity.py before.py after.py
```

**Anti-patterns:**
- Don't use as a linter replacement — it finds structural and security issues, not formatting
- Don't run on a whole repo at once; scope it to the changed files

---

## Improving Existing Code — Refactoring

### `code-refactor` — Phased refactoring workflow

**When:** Reducing technical debt, cleaning up a long method, or improving a module before extending it.

**Invocation:**
```
/code-refactor
Refactor the processOrder function in src/orders/processor.py — it's 180 lines and has duplicate validation logic.
```

**Notable behaviors:**
- Six-phase workflow: Research → Test Coverage → Smell ID → Plan → Implementation → Review
- Pauses at each phase for approval before proceeding
- Requires passing tests before proceeding (or explicit user acknowledgment of risk)
- Commits after each atomic change

**Supporting scripts:**
```bash
python refactor/scripts/detect-smells.py src/orders/processor.py
python refactor/scripts/analyze-complexity.py src/orders/processor.py --verbose
python refactor/scripts/analyze-complexity.py before.py after.py   # compare mode
python refactor/scripts/detect-smells.py --dir src/orders/
```

**Anti-patterns:**
- Don't combine refactoring with feature work in the same session
- Don't skip the test coverage phase — the skill enforces this by design

---

## Generating Documentation

### `api-documentation-generator` — API docs from source

**When:** Creating or updating API documentation, generating OpenAPI specs, onboarding a new integration.

**Invocation:**
```
/api-documentation-generator
Generate API documentation for all endpoints in src/api/routes.py
```

**Notable behaviors:**
- Produces per-endpoint docs: description, parameters table, response schemas, cURL/JS/Python examples
- Extracts from Python source via AST (`generate-docs.py`) or by reading source directly
- Outputs OpenAPI-compatible structure

**Supporting script:**
```bash
python doc-generator/generate-docs.py src/api/routes.py
```

**Anti-patterns:**
- Script only handles `get_*` / `post_*` function naming convention; for other patterns, let Claude read the source directly
- Don't use for internal library docs — this is scoped to HTTP API endpoints

---

## Quick Reference

| Situation | Tool |
|-----------|------|
| Starting a new repo with Claude Code | `/claude-md create` |
| Existing CLAUDE.md feels noisy or stale | `/claude-md audit` then `/claude-md update` |
| PR ready for review | `/code-review-specialist` |
| Function > 50 lines or full of TODOs | `/code-refactor` |
| Need to measure complexity before/after | `refactor/scripts/analyze-complexity.py` |
| Hunting for code smells across a module | `refactor/scripts/detect-smells.py --dir src/` |
| Writing API docs for a new endpoint | `/api-documentation-generator` |
| Verifying all skills work after install | `bash test/test.sh` |
