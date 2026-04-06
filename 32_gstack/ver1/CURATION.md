# gstack — Curation Log

Applied: 2026-04-06  
Task specification: `lib2tools.md`  
Source: `/data/proj/agents/gandalf/32_gstack/ver1`  

---

## Summary

| Category | Before | Kept | Removed |
|----------|--------|------|---------|
| Skills | 8 | 8 | 0 |
| Agents | 0 | 0 | 0 |
| Commands | 0 | 0 | 0 |
| Rules | 0 | 0 | 0 |
| Hooks | 0 | 0 | 0 |
| MCP configs | 0 | 0 | 0 |

**Result: No files removed. All 8 skills are language-agnostic and general-purpose.**

---

## Skills — kept (8/8)

| Skill | Phase | Reason kept |
|-------|-------|-------------|
| `browse` | Test / QA | Language-agnostic headless browser — works for any web-facing project |
| `plan-ceo-review` | Plan | Methodology-based plan review — applies to any project scope |
| `plan-eng-review` | Plan | Architecture and engineering review — applies to any codebase |
| `qa` | Test | Web QA methodology — language-independent, framework-independent |
| `retro` | Meta / Session | Git-based retrospective — applies to any repo |
| `review` | Review | PR review methodology — SQL safety, LLM trust boundaries, structural issues apply universally |
| `ship` | Release | Release workflow — merge, test, version bump, changelog, PR — applies to any project |
| `setup-browser-cookies` | Setup | Browser cookie import utility — supports `browse`, language-independent |

---

## Skills — removed (0/8)

None. No skill in this collection is named for or tied to a specific language, framework, or runtime. All skills address workflow phases (planning, review, testing, release, retrospective) that apply to any software project.

---

## Other assets

### Agents
No `agents/` directory exists in this source. Nothing to curate.

### Commands
No `commands/` directory exists in this source. Nothing to curate.

### Rules
No `rules/` directory exists in this source. Nothing to curate.

### Hooks
No `hooks/` directory or `hooks.json` exists in this source. Nothing to curate.

### MCP configs
No `mcp-configs/` or `mcp-servers.json` exists in this source. Nothing to curate.

---

## Supporting files

All skills live under `skills/`. Non-skill files at root are documentation only.

| File/Directory | Status | Reason |
|----------------|--------|--------|
| `skills/browse/src/` | Kept | Runtime source — server.ts is spawned by the CLI binary at runtime |
| `skills/browse/bin/` | Kept | Shell shims used by SKILL.md boot sequences |
| `skills/browse/dist/` | Kept | Compiled binary — required at runtime |

---

## Documentation added

| File | Description |
|------|-------------|
| `README.md` | Overview: directory structure, skills table, notes |
| `usage.md` | Best-practice usage guide by workflow phase |
| `install.md` | Step-by-step installation into Claude Code |
| `security.md` | Security review of all executable scripts and code |
| `CURATION.md` | This file |
