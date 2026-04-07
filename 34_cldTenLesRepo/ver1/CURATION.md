# Curation Log

Applied the lib2tools.md rules: keep only language-agnostic skills that support any software development workflow phase.

## Summary

| Category | Before | After | Removed |
|----------|--------|-------|---------|
| Skills   | 6      | 4     | 2       |

---

## Skills

### Kept

| Skill | Reason |
|-------|--------|
| `claude-md` | Language-agnostic. Supports meta/session phase. Works for any project stack. |
| `code-review` | Language-agnostic. Security, performance, SOLID review applies to any codebase. |
| `refactor` | Language-agnostic. Fowler's methodology applies to any language. |
| `doc-generator` | Language-agnostic. API documentation generation applies to any project. |

### Removed

| Skill | Reason |
|-------|--------|
| `blog-draft` | Content creation (blog posts). Not a software development workflow skill. Not related to code, planning, review, testing, refactoring, or documentation of software. |
| `brand-voice` | Marketing/communications skill. Encodes a specific brand identity (mission, values, vocabulary). Not applicable across arbitrary software projects. |

---

## Rule Applied

> **Skills — delete if:** A presentation or slide template with no workflow function; or not applicable across arbitrary software projects.

Both removed skills fail the core test: *"Useful across any software development process — planning, design, architecture, code review, testing, refactoring, documentation."* They serve content creation and marketing, not development.
