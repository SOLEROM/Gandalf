# Dev Toolkit — General-Purpose Claude Code Skills

A curated set of language-agnostic Claude Code skills covering the core software development workflow: documentation, code review, refactoring, and AI project setup.

## Directory Structure

```
.
├── install.sh              — one-command installer
├── README.md               — this file
├── usage.md                — when and how to use each skill
├── install.md              — step-by-step installation guide
├── security.md             — security review of all scripts
├── CURATION.md             — what was kept, what was removed, and why
├── test/
│   ├── test.md             — human-readable scenario for manual testing
│   └── test.sh             — unattended test runner (validates all skills)
├── claude-md/              — create/audit CLAUDE.md files
├── code-review/            — security, performance, quality code review
├── refactor/               — Fowler-methodology refactoring workflow
└── doc-generator/          — API documentation from source code
```

## Skills

| Skill | Name in SKILL.md | Workflow Phase | Description |
|-------|-----------------|----------------|-------------|
| `claude-md` | `claude-md` | meta/session | Create, update, or audit CLAUDE.md files for optimal AI agent onboarding |
| `code-review` | `code-review-specialist` | review | Comprehensive review: security, performance, SOLID, maintainability |
| `refactor` | `code-refactor` | refactor | Phased refactoring using Martin Fowler's methodology with test safety |
| `doc-generator` | `api-documentation-generator` | docs | Generate OpenAPI specs and API docs from source code |

## Quick Start

```bash
# Install all skills
bash install.sh

# Verify installation
ls ~/.claude/skills/

# Run test suite
bash test/test.sh
```

## Included Scripts

Each skill ships supporting Python scripts (stdlib-only, no network access):

| Script | Purpose |
|--------|---------|
| `code-review/scripts/analyze-metrics.py` | Basic code metrics (functions, classes, complexity) |
| `code-review/scripts/compare-complexity.py` | Compare cyclomatic/cognitive complexity before/after |
| `refactor/scripts/analyze-complexity.py` | Full complexity analysis with per-function breakdown |
| `refactor/scripts/detect-smells.py` | Detect 14 code smell types from Fowler's catalog |
| `doc-generator/generate-docs.py` | Extract API docs from Python source via AST |
