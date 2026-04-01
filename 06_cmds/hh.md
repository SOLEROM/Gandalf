---
description: Show all my custom commands
allowed-tools: Bash
disable-model-invocation: true
---

Run this command to list all my custom slash commands:
!find ~/.claude/commands .claude/commands -name "*.md" 2>/dev/null | sort

Then read each file found and extract its `description` from the frontmatter (if present), or use the filename as the description.

Output a formatted reference table like this:

╔══════════════════════════════════════════════════════════════╗
║                  MY CUSTOM COMMANDS                          ║
╠═══════════════════════╦══════════════════════════════════════╣
║ COMMAND               ║ WHAT IT DOES                         ║
╠═══════════════════════╬══════════════════════════════════════╣
║ /command-name         ║ description here                     ║
║ ...                   ║ ...                                  ║
╚═══════════════════════╩══════════════════════════════════════╝

Group them by: 🌍 Global (~/.claude/commands/) and 📁 Project (.claude/commands/)
At the bottom, add a tip: "Run /help anytime to see this menu."