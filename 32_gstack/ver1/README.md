# gstack — Claude Code Skill Pack

**gstack** gives Claude Code a persistent headless browser and a set of opinionated workflow skills. Works with any software project regardless of language or framework.

---

## Directory structure

```
skills/
  browse/                — Headless browser skill + compiled binary
    bin/                 — Shell shims (find-browse, remote-slug)
    dist/                — Compiled binary (browse, find-browse)
    src/                 — TypeScript source (cli, server, browser-manager, snapshot, commands)
  plan-ceo-review/       — CEO/founder-mode plan review skill
  plan-eng-review/       — Eng-manager-mode plan review skill
  qa/                    — Systematic web QA testing skill
    references/          — Issue taxonomy and QA report template
    templates/           — Report format templates
  retro/                 — Weekly engineering retrospective skill
  review/                — Pre-landing PR review skill
    checklist.md         — Review checklist
    greptile-triage.md   — Greptile-assisted triage guide
  setup-browser-cookies/ — One-time cookie import from real browser
  ship/                  — Ship workflow skill (merge, test, PR)
README.md
usage.md
install.md
security.md
CURATION.md
```

---

## Skills

| Skill | Workflow phase | One-line role |
|-------|---------------|---------------|
| `browse` | Test / QA | Persistent headless Chromium — navigate, interact, snapshot, screenshot, assert |
| `plan-ceo-review` | Plan / Design | CEO-mode plan review — challenge premises, expand or cut scope, apply prime directives |
| `plan-eng-review` | Plan / Design | Eng-manager-mode plan review — architecture, data flow, edge cases, test coverage |
| `qa` | Test | Systematic QA of a web app — diff-aware, full, quick, and regression modes |
| `retro` | Session / Meta | Weekly retrospective — commit history, work patterns, per-person breakdown |
| `review` | Review | Pre-landing PR review — SQL safety, LLM trust boundaries, structural issues |
| `ship` | Release | Ship workflow — merge main, test, bump version, update changelog, push, open PR |
| `setup-browser-cookies` | Setup | Import real-browser cookies into the headless session for authenticated testing |

---

## Hooks

No hooks are included. gstack installs as a pure skill pack.

## Agents

No agent definitions. gstack provides skills, not subagents.

## Commands

No slash commands. Skills are invoked by description or with `/skill-name`.

## Rules

No rules files. gstack carries no CLAUDE.md additions.

## MCP servers

No MCP servers. The browser is a compiled CLI binary — zero MCP overhead.

---

## Notes

- `browse` requires a one-time build (Bun + Playwright Chromium). See `install.md`.
- `setup-browser-cookies` only works on macOS (Keychain-based cookie decryption).
- All skills include an update-check snippet that detects available upgrades.
