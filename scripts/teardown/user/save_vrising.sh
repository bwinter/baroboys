#!/bin/bash
set -eux

cd "$HOME/baroboys"

SAVE_DIR="VRising/Data/Saves/v4/TestWorld-1"

# Tell players and trigger autosave
mcrcon -H 127.0.0.1 -P 25575 -p Donalds \
  "announce Server is saving and shutting down..." \
  "shutdown 15 Auto-save before shutdown"

# Wait for shutdown to complete
if ! timeout 180 bash -c 'while pgrep -u bwinter_sc81 -f VRisingServer.exe >/dev/null; do sleep 1; done'; then
  echo "⚠️ VRisingServer.exe did not exit in time. Logging debug info..."
  ps -fu bwinter_sc81 | tee /tmp/vrising_stuck.log
fi

# Identify the most recent autosave file
latest=$(
  find "$SAVE_DIR" -type f -name 'AutoSave_*.save.gz' \
    -printf '%f\n' |
    sed -E 's/^AutoSave_([0-9]+)\.save\.gz$/\1/' |
    grep -E '^[0-9]+$' |
    sort -n | tail -n1
)
latest_file="$SAVE_DIR/AutoSave_${latest}.save.gz"

# Add only the latest autosave to git
git add "$latest_file"
git commit -m "Auto-save before shutdown $(date -u +'%Y-%m-%d %H:%M:%S UTC')" || echo "Nothing to commit"

# Temporarily stash everything else (untracked or modified)
git stash push --include-untracked --quiet || echo "Nothing to stash"

# Pull latest from origin
git pull --rebase

# Push the committed autosave
git push origin main

# Restore stashed changes
git stash pop --quiet || echo "No stash to pop"
