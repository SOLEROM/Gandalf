#!/usr/bin/env bash

set -euo pipefail

################################################################################
# FUNCTIONS
################################################################################

fresh_install() {
    echo "Performing fresh install..."

    ## mkdirs
    mkdir -p ~/.claude/skills ~/.claude/agents ~/.claude/help ~/.claude/commands

    ## set settings
    ./01_claude.settings/setSettings.sh

    ## install plugins #########################################################

    ## claudeusage
    (
        cd /tmp || exit 1
        rm -rf claudeusage-mcp
        git clone https://github.com/OrelliusAI/claudeusage-mcp.git
        cd claudeusage-mcp || exit 1
        npm install && npm run build
    )
    claude mcp add claudeusage -- node $(pwd)/dist/index.js

    echo "Finished fresh install"
    update_skills
    install_agents
}

################################################################################

update_skills() {
    echo "Updating skills..."

    ## help
    mkdir -p ~/.claude/help ~/.claude/commands
    cp -ar 00_help/* ~/.claude/help/ || true
    cp -ar 06_cmds/* ~/.claude/commands/ || true

    ## mdTree
    mkdir -p ~/.claude/skills/mdTree
    cp 11_mySubsSkills/skill_mdRefactor/SKILL.md ~/.claude/skills/mdTree/
    echo "...skill_mdRefactor deployed"

    ## skill_gangPatterns
    mkdir -p ~/.claude/skills/gofPatterns
    cp -ar 11_mySubsSkills/skill_gangPatterns/* ~/.claude/skills/gofPatterns/
    echo "...skill_gangPatterns deployed"

    ## webTui
    mkdir -p ~/.claude/agents/webTui
    cp 11_mySubsSkills/skill_ccpan/WEBTUI_SKILL.md ~/.claude/agents/webTui/claude.md
    cp -ar 11_mySubsSkills/skill_ccpan/scripts/* ~/.claude/agents/webTui/
    echo "...skill_webTui deployed"

    ## agentTeam
    mkdir -p ~/.claude/skills/agentTeam
    cp -ar 21_agentTeam/* ~/.claude/skills/agentTeam/
    echo "...skill_agentTeam deployed"

    echo "Finished updating skills"
}

install_agents() {
    echo "Installing agents..."

    ## ateam
    cd ./21_agentTeam && ./install.sh

    echo "Finished installing agents"
}

# ## 30 ecc
# ./30_ecc/install.sh --mcp


# ## 33 superpower
# ./33_superpower/ver1/install.sh
# ## 34 TenLesonRepo
# ./34_cldTenLesRepo/ver1/install.sh

################################################################################
# FLAGS
################################################################################

# Early-exit help pass (before any state changes)
for arg in "$@"; do
  case "$arg" in
    --help|-h)
      echo "Usage: bash deploy.sh [options]"
      echo ""
      echo "Options:"
      echo "  --install    Fresh install (clone MCP plugin, copy settings, skills, agents)"
      echo "  --update     Update skills only (no MCP or settings changes)"
      echo "  --help, -h   Show this help"
      echo ""
      echo "No options: show interactive menu"
      exit 0
      ;;
  esac
done

# Unattended mode: parse action flags
HAS_FLAGS=false
DO_INSTALL=false
DO_UPDATE=false

for arg in "$@"; do
  case "$arg" in
    --install) DO_INSTALL=true; HAS_FLAGS=true ;;
    --update)  DO_UPDATE=true;  HAS_FLAGS=true ;;
  esac
done

if [[ "$HAS_FLAGS" == "true" ]]; then
    [[ "$DO_INSTALL" == "true" ]] && fresh_install
    [[ "$DO_UPDATE"  == "true" ]] && update_skills
    exit 0
fi

################################################################################
# MENU (no flags given)
################################################################################

echo "What do you want to do?"
echo "1) Install"
echo "2) Update"
echo "3) Exit"

read -rp "Enter your choice: " choice

case "$choice" in
    1)
        echo "Installing..."
        fresh_install
        ;;
    2)
        echo "Updating..."
        update_skills
        ;;
    3)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid choice, exiting."
        exit 1
        ;;
esac
