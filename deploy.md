#!/bin/bash
mkdir -p ~/.claude/skills/ ~/.claude/agents

## mdTree
mkdir -p ~/.claude/skills/mdTree
cp 11_mySubsSkills/skill_mdRefactor/SKILL.md ~/.claude/skills/mdTree/
echo "...skill_mdRefactor deployed" 

## webTui
mkdir -p ~/.claude/agents/webTui
cp 11_mySubsSkills/skill_ccpan/WEBTUI_SKILL.md ~/.claude/agents/webTui/claude.md
cp -ar 11_mySubsSkills/skill_ccpan/scripts ~/.claude/agents/webTui/
echo "...skill_webTui deployed"