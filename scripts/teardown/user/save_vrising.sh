#!/bin/bash
set -eux

cd "$HOME/baroboys"

SAVE_DIR="VRising/Data/Saves/v4/TestWorld-1"

# Tell players and trigger autosave
mcrcon -H 127.0.0.1 -P 25575 -p Donalds \
  "announce Server is saving and shutting down..." \
  "shutdown 15 Auto-save before shutdown"

# Wait to ensure shutdown message is handled
sleep 60

# Find the most recent save by numeric suffix
latest=$(
  find "$SAVE_DIR" -type f -name 'AutoSave_*.save.gz' \
    -printf '%f\n' |                       # Extract just the filenames
    sed -E 's/^AutoSave_([0-9]+)\.save\.gz$/\1/' |
    grep -E '^[0-9]+$' |                   # Sanity: ensure numeric suffix
    sort -n | tail -n1
)
latest_file="$SAVE_DIR/AutoSave_${latest}.save.gz"


# Remove all other tracked AutoSaves from Git
for tracked in $(git ls-files "$SAVE_DIR/AutoSave_*.save.gz"); do
  [[ "$tracked" != "$latest_file" ]] && git rm --cached "$tracked"
done

# Stage only the latest save
git add "$latest_file"

# Commit if anything changed
if git status --porcelain | grep .; then
  git commit -m "Auto-save before shutdown $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
  git push origin main
else
  echo "No changes to commit."
fi
