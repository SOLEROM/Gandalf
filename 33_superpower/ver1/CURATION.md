# Curation Log — Superpowers v5.0.7 → General-Purpose Dev Toolkit

## Source

Plugin: superpowers@claude-plugins-official v5.0.7
Extracted from: `~/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.7/`

---

## Agents

**Kept (1):** `code-reviewer` — general-purpose senior code reviewer subagent, dispatched by requesting-code-review and subagent-driven-development

**Removed (0):** none

---

## Commands

**Kept (3):** `brainstorm`, `write-plan`, `execute-plan`

**Note:** All three are deprecated aliases pointing to their corresponding skills. They are kept for backward compatibility with users who have muscle memory for slash commands, but the skills are the primary interface.

---

## Skills

**Kept (14):**

| Skill | Reason kept |
|-------|------------|
| `brainstorming` | Core design-phase workflow — universal, not project-specific |
| `dispatching-parallel-agents` | Coordination pattern applicable to any codebase |
| `executing-plans` | Alternative to subagent-driven-development for non-subagent environments |
| `finishing-a-development-branch` | Branch completion workflow — universal |
| `receiving-code-review` | Code review reception — universal |
| `requesting-code-review` | Code review dispatch — universal |
| `subagent-driven-development` | Recommended plan execution strategy — universal |
| `systematic-debugging` | Four-phase debugging methodology — universal |
| `test-driven-development` | Red-green-refactor discipline — universal |
| `using-git-worktrees` | Isolated workspace setup — universal git workflow |
| `using-superpowers` | Session/meta: teaches skill discovery and invocation — required for all other skills to work |
| `verification-before-completion` | Evidence-before-claims gate — universal |
| `writing-plans` | Implementation plan authoring — universal |
| `writing-skills` | TDD-based skill creation — universal meta-tooling |

**Removed (0):** none

---

## Hooks

**Kept:**
- `hooks.json` — Claude Code hook configuration for SessionStart event
- `session-start` — bash script that injects using-superpowers skill content at session start

**Removed:**
- `hooks-cursor.json` — Cursor IDE-specific hook format; not applicable to Claude Code CLI
- `run-hook.cmd` — Windows batch script wrapper; not applicable on POSIX systems (macOS/Linux Claude Code users)

---

## Rules

No standalone rules files exist in the source plugin at v5.0.7. The upstream `CLAUDE.md` in the repository root is contributor guidelines for the Superpowers plugin project itself (how to develop and contribute to the plugin), not user coding rules to be loaded by Claude. It was not copied.

If you want project-level coding rules, create your own `CLAUDE.md` in your project root.

---

## MCP Servers

**Removed:** `fakechat` — a test/demo HTTP server that simulates chat messages for development and testing of the plugin itself. It is not a development tool for users and has no value outside of plugin development.

---

## Other Excluded Files

- `docs/plans/*` — upstream design documents for the Superpowers plugin project's own development; not user tools
- `tests/subagent-driven-dev/*` — upstream test fixtures used during plugin development; not user tools
- Platform install documentation (`opencode-install.md`, `codex-install.md`, `cursor-install.md`) — installation guides for platforms other than Claude Code CLI; not relevant for this extract
- `skills/using-superpowers/references/*` — tool mapping documents for non-Claude Code platforms: `copilot-tools.md` (GitHub Copilot CLI tool equivalents), `gemini-tools.md` (Gemini CLI tool equivalents), `codex-tools.md` (Codex tool equivalents). These are not needed for Claude Code CLI users. Note: the `using-superpowers` SKILL.md itself references these files for non-CC platform users, but the references are conditional and do not break Claude Code operation when the files are absent.

---

## Counts

| Item | Before (source) | After (this extract) |
|------|----------------|---------------------|
| Skills | 14 | 14 |
| Agents | 1 | 1 |
| Commands | 3 | 3 |
| Hook configs | 2 (`hooks.json`, `hooks-cursor.json`) | 1 (`hooks.json`) |
| Hook scripts | 2 (`session-start`, `run-hook.cmd`) | 1 (`session-start`) |
| MCP demo servers | 1 (`fakechat`) | 0 |
