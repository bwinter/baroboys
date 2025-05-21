#!/bin/bash
set -eux

cd "$HOME/baroboys"

# Sanity: Check for changes
if git status --porcelain | grep .; then
  git add ./Barotrauma/Data ./Barotrauma/Multiplayer ./Barotrauma/serversettings.xml ./Barotrauma/config_player.xml
  git commit -m "Auto-save before shutdown $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
  git push origin main
else
  echo "No changes to commit."
fi
