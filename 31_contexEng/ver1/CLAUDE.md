# CLAUDE.md

This file provides guidance to Claude Code when working in this repository.
Customize this file for your project's specific conventions and constraints.

## Core Development Philosophy

### KISS (Keep It Simple, Stupid)
Choose straightforward solutions over complex ones whenever possible.

### YAGNI (You Aren't Gonna Need It)
Implement features only when they are needed, not when you anticipate they might be useful.

### Design Principles
- **Single Responsibility**: Each function, class, and module should have one clear purpose.
- **Fail Fast**: Check for potential errors early and raise exceptions immediately.
- **Open/Closed**: Open for extension, closed for modification.

## Project Awareness & Context
- **Always read `PLANNING.md`** at the start of a new conversation (if it exists) to understand architecture, goals, style, and constraints.
- **Check `TASK.md`** before starting a new task (if it exists). If the task isn't listed, add it.
- **Use consistent naming conventions, file structure, and architecture patterns** as described in PLANNING.md.

## Code Structure & Modularity
- **Never create a file longer than 500 lines of code.** Refactor by splitting into modules.
- **Functions should be under 50 lines** with a single, clear responsibility.
- **Organize code into clearly separated modules**, grouped by feature or responsibility.

## Testing & Reliability
- **Always create unit tests for new features** (functions, classes, routes, etc).
- **After updating any logic**, check whether existing unit tests need to be updated.
- **Tests should include at least:**
  - 1 test for expected (happy path) use
  - 1 edge case
  - 1 failure case

## Task Completion
- **Mark completed tasks in `TASK.md`** immediately after finishing them.
- Add new sub-tasks or TODOs discovered during development to `TASK.md` under "Discovered During Work".

## Style & Conventions
- **[Set your primary language here]**
- Follow the language's standard style guide
- Use type hints / type annotations where available
- Write docstrings for every public function

## Documentation & Explainability
- **Update `README.md`** when new features are added, dependencies change, or setup steps are modified.
- **Comment non-obvious code** — add an inline `# Reason:` comment explaining the why, not just the what.

## AI Behavior Rules
- **Never assume missing context. Ask questions if uncertain.**
- **Never hallucinate libraries or functions** — only use known, verified packages.
- **Always confirm file paths and module names** exist before referencing them.
- **Never delete or overwrite existing code** unless explicitly instructed.

## Search Commands
- Use `rg` (ripgrep) instead of `grep` for searching the codebase.
- Use `rg --files -g "*.ext"` instead of `find . -name "*.ext"`.

---
_Customize this file for your project. Remove sections that don't apply, add sections specific to your stack._
