#!/bin/bash
set -eux

cd "$HOME/baroboys"

git add ./Barotrauma/Data ./Barotrauma/Multiplayer ./Barotrauma/serversettings.xml ./Barotrauma/config_player.xml
git commit -m "Auto-save before shutdown $(date -u +'%Y-%m-%d %H:%M:%S UTC')" || echo "Nothing to commit"

# Stash local state, pull, and push
git stash push --include-untracked --quiet || echo "Nothing to stash"
git pull --rebase
git push origin main
git stash pop --quiet || echo "No stash to pop"
