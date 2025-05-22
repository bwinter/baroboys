#!/bin/bash
set -eux

cd "$HOME/baroboys"

SAVE_PATHS=(
  "VRising/Data/Saves/v4/TestWorld-1"
)

for path in "${SAVE_PATHS[@]}"; do
  if [ -d "$path" ]; then
    git add "$path"
  fi
done

# Sanity check before commit
if git status --porcelain | grep .; then
  git commit -m "Auto-save before shutdown $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
  git push origin main
else
  echo "No changes to commit."
fi
