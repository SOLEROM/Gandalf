# Dev Toolkit — End-to-End Test Scenario

## Context

You are working on a Python/TypeScript monorepo called **Taskflow** — a lightweight task management API.

- **Branch**: `feature/bulk-operations` (2 commits ahead of `main`)
- **Changed files**: `src/tasks/processor.py` (new bulk processing logic, 180 lines), `src/api/routes.py` (3 new endpoints)
- **Tests**: 12 passing, 0 failing
- **Known issues**: `processor.py` has some duplication and a 60-line method `process_bulk_tasks()`. No CLAUDE.md exists yet.

---

## Skill 1: `claude-md` — Create project onboarding file

**Purpose:** Generate a CLAUDE.md that orients Claude Code in any new session without noise.

**Prompt:**
```
/claude-md create
```

**What Claude does:**
- Scans for existing CLAUDE.md files (finds none)
- Reads README.md, package.json or pyproject.toml for stack details
- Identifies project structure, dev commands, and non-obvious conventions
- Drafts a CLAUDE.md under 100 lines with Tech Stack, Development Commands, and Critical Conventions sections
- Presents draft for review before writing

**Expected output shape:**
```markdown
# Taskflow

Brief description.

## Tech Stack
- Python 3.11, FastAPI
- TypeScript, ...
- PostgreSQL / ...

## Development Commands
- Install: `...`
- Test: `...`
- Build: `...`

## Critical Conventions
- [Non-obvious convention 1]
- [Non-obvious convention 2]
```

---

## Skill 2: `code-review-specialist` — Review the new processor

**Purpose:** Catch security, performance, and quality issues before merge.

**Prompt:**
```
/code-review-specialist
Review src/tasks/processor.py — it's new code on a feature branch. Focus on security and code quality.
```

**What Claude does:**
- Reads the file
- Checks for injection risks, data exposure, auth issues (security)
- Analyzes Big O complexity of key methods (performance)
- Checks SOLID, naming, function length, test coverage (quality/maintainability)
- Outputs structured report with severity ratings

**Expected output shape:**
```markdown
## Summary
- Overall quality: X/5
- N findings

## Critical Issues (if any)
...

## Findings by Category

### Security
...

### Performance
...

### Quality
...

### Maintainability
...
```

---

## Skill 3: `code-refactor` — Refactor the long method

**Purpose:** Break down `process_bulk_tasks()` incrementally while keeping tests green.

**Prompt:**
```
/code-refactor
Refactor process_bulk_tasks() in src/tasks/processor.py. It's 60 lines with duplicated validation and mixed responsibilities.
```

**What Claude does:**
- Phase 1: Reads the file, summarizes structure, asks approval
- Phase 2: Checks for existing tests
- Phase 3: Identifies smells (Long Method, Duplicate Code)
- Phase 4: Proposes plan (Extract Method × 3, Remove Duplication)
- Phase 5: Implements one step at a time, runs tests after each
- Phase 6: Presents before/after metrics

**Expected output shape:**
```markdown
## Phase 1: Analysis
[Code structure summary]
[Identified problems]

## Phase 3: Code Smells Found
| Smell | Severity | Location |
|-------|----------|----------|
| Long Method | High | process_bulk_tasks():1-60 |
| Duplicate Code | Medium | lines 12-18, 34-40 |

## Phase 4: Refactoring Plan
Phase A: Extract validate_task() from lines 12-18
Phase B: Extract apply_bulk_operation() ...
Phase C: ...

## Phase 6: Results
Before: CC=18, MI=42
After:  CC=7,  MI=71
```

---

## Skill 4: `api-documentation-generator` — Document the new endpoints

**Purpose:** Generate API docs for the three new routes in `src/api/routes.py`.

**Prompt:**
```
/api-documentation-generator
Generate API documentation for the new endpoints in src/api/routes.py
```

**What Claude does:**
- Reads the routes file
- Identifies each endpoint (method, path, parameters, response shape)
- Generates per-endpoint docs with parameter tables, response schemas, and cURL/JS/Python examples
- Outputs OpenAPI-compatible structure

**Expected output shape:**
```markdown
## POST /api/v1/tasks/bulk

### Description
Process multiple tasks in a single request.

### Parameters
| Name | Type | Required | Description |
|------|------|----------|-------------|
| task_ids | array | Yes | List of task IDs |
| operation | string | Yes | Operation to apply |

### Response
**200 Success**
...

### Examples
**cURL**
...
```

---

## Running the Demo

### Install
```bash
bash install.sh
```

### Start a Claude Code session
```bash
claude
```

### Skill trigger reference

| Skill | Trigger phrase |
|-------|---------------|
| `claude-md` | `/claude-md create` |
| `code-review-specialist` | `/code-review-specialist` |
| `code-refactor` | `/code-refactor` |
| `api-documentation-generator` | `/api-documentation-generator` |

### Run unattended tests
```bash
bash test/test.sh                      # all skills
bash test/test.sh code-review refactor # specific skills only
VERBOSE=1 bash test/test.sh            # full Claude output on failure
TIMEOUT=180 bash test/test.sh          # longer timeout per skill
```
