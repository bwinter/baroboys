#!/bin/bash
set -euxo pipefail

cd "$HOME/baroboys"

WORLD_DIR="VRising/Data/Saves/v4/TestWorld-1"
LOG_DIR="VRising/logs"
SAVE_PATHS=("$WORLD_DIR" "$LOG_DIR")

# Ensure Git is on a branch
if ! git symbolic-ref -q HEAD >/dev/null; then
  echo "❌ Git is in a detached HEAD state. Skipping auto-save."
  exit 0
fi

# Stage relevant changes
for path in "${SAVE_PATHS[@]}"; do
  if [ -d "$path" ]; then
    git add "$path"
  fi
done

# Commit if there are changes
if git diff --cached --quiet; then
  echo "✅ No save-related changes to commit."
else
  COMMIT_MSG="🧃 VRising auto-save for world 'TestWorld-1' @ $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
  git commit -m "$COMMIT_MSG"
  git push origin "$(git rev-parse --abbrev-ref HEAD)"
fi
