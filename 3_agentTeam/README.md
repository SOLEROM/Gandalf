# Build with Agent Team

A Claude Code skill for building projects using [Agent Teams](https://www.anthropic.com/news/claude-opus-4-6) — Anthropic's multi-agent collaboration feature where multiple Claude instances work in parallel, communicate with each other, and coordinate autonomously. Give it a plan document describing what you want to build, and it spawns a team of specialized agents in tmux split panes to build it together.

Once set up, it's as simple as:

```bash
/build-with-agent-team [plan-path] [num-agents]
```

## Prerequisites

### 1. Install tmux

Agent teams use tmux for split-pane visualization so you can see all agents working simultaneously.


**Linux (Ubuntu/Debian):**
```bash
sudo apt update && sudo apt install tmux
```


### 2. Enable Agent Teams

Agent teams are experimental and disabled by default. Enable by adding to `~/.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

## Installation

Copy the skill to your personal skills directory:

```bash
cp -r agent-team ~/.claude/skills/
```

Or for project-level use:
```bash
cp -r agent-team .claude/skills/
```

## Create Your Plan

Write a markdown document describing what you want to build. This works for:

- **Greenfield projects**: A new app, API, or system from scratch
- **Brownfield features**: A new feature in an existing codebase

Your plan should be detailed enough that multiple agents could divide the work. Include:

- What you're building and why
- Tech stack and architecture
- Project structure
- Key components and how they interact
- Data models or API contracts
- Acceptance criteria

See `example*.md` for an example.

## Usage

```bash
/agent-team [plan-path] [num-agents]
```

**Parameters:**

| Parameter | Required | Description |
|-----------|----------|-------------|
| `plan-path` | Yes | Path to your plan markdown file |
| `num-agents` | No | Number of agents to spawn. If omitted, determined automatically based on the plan's complexity |

**Examples:**

```bash
# Let the skill determine team size
/agent-team ./plans/my-project.md

/agent-team ./plans/my-project.md 3

# Build a feature in existing codebase
/agent-team ./docs/new-auth-feature.md 2
```

The skill will:
1. Read your plan
2. Analyze it to determine agent roles (frontend, backend, database, etc.)
3. Spawn agents in tmux split panes
4. Coordinate collaboration between agents
5. Ensure agents communicate and challenge each other's work

