#!/bin/bash
set -eux

cd "$HOME/baroboys"

sudo rm -f "/etc/systemd/system/game-startup.service"
sudo sudo systemctl daemon-reload
sudo systemctl mask game-startup

pkill DedicatedServer

echo "🔃 Monitoring DedicatedServer status..."

if ! timeout 300 bash -c 'while ps -C DedicatedServer >/dev/null; do sleep 1; done'; then
  echo "⚠️ DedicatedServer did not exit in time."
else
  echo "✅ DedicatedServer exited cleanly."
fi

# === Commit latest autosave ===
git add ./Barotrauma/Multiplayer
git commit -m "Auto-save before shutdown $(date -u +'%Y-%m-%d %H:%M:%S UTC')" || echo "Nothing to commit"

# Stash local state, pull, and push
git stash push --include-untracked --quiet || echo "Nothing to stash"
git pull --rebase
git push origin main
git stash pop --quiet || echo "No stash to pop"
