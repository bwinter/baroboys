#!/bin/bash
set -eux

cd "$HOME/baroboys"

SAVE_DIR="Barotrauma/Multiplayer"

if pkill -0 DedicatedServer 2>/dev/null; then
    pkill DedicatedServer
else
    echo "DedicatedServer not running, nothing to kill"
fi

echo "🔃 Monitoring DedicatedServer status..."

if ! timeout 300 bash -c 'while ps -C DedicatedServer >/dev/null; do sleep 1; done'; then
  echo "⚠️ DedicatedServer did not exit in time."
else
  echo "✅ DedicatedServer exited cleanly."
fi

# === Commit saves ===
find "$SAVE_DIR" -type f \( -name '*.save' -o -name '*.xml' \) ! -name '*.bk*' -print0 \
  | xargs -0 git add
git commit -m "Auto-save before shutdown $(date -u +'%Y-%m-%d %H:%M:%S UTC')" || echo "Nothing to commit"

# Stash local state, pull, and push
git stash push --include-untracked --quiet || echo "Nothing to stash"
git pull --rebase
git push origin main
git stash pop --quiet || echo "No stash to pop"
