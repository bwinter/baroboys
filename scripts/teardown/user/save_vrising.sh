#!/bin/bash
set -eux

cd "$HOME/baroboys"

SAVE_DIR="VRising/Data/Saves/v4/TestWorld-1"

# Notify and schedule shutdown (announce, then delay, then shutdown)
if ! mcrcon -H 127.0.0.1 -P 25575 -p Donalds -w 2 \
  "announce Server will shut down in 1 minute! Get to a safe place." \
  "shutdown 1 Server will shut down in ~{t}m! Get to a safe place."; then
  echo "⚠️ mcrcon failed to send shutdown commands"
fi

# Wait for shutdown to complete (VRisingServer.exe should exit)
if ! timeout 180 bash -c '
  while pidof -x VRisingServer.exe >/dev/null; do sleep 1; done
'; then
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
