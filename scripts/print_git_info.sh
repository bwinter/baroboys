#!/usr/bin/env bash
set -euo pipefail

# Ensure required commands exist
command -v git >/dev/null || { echo "❌ 'git' not found"; exit 1; }

REPO_PATH="$HOME/Desktop/Baroboys"
WORKDIR="/tmp/bfg-cleanup"
DELETABLE_LIST="/tmp/deletable-blobs.txt"

echo "🔍 Running Git history scan for Barotrauma and V Rising blob types..."
echo "📁 Target repo: $WORKDIR/baroboys-bfg-clean.git"

# Clone or reuse repo mirror
if [[ -d "$WORKDIR/baroboys-bfg-clean.git" ]]; then
  echo "♻️  Reusing existing mirror at $WORKDIR/baroboys-bfg-clean.git"
else
  echo "📥 Cloning bare → $WORKDIR/baroboys-bfg-clean.git"
  git clone --bare "$REPO_PATH" "$WORKDIR/baroboys-bfg-clean.git" &> /dev/null
fi

cd "$WORKDIR/baroboys-bfg-clean.git"

# Get all blob paths in history (deduplicated)
ALL_PATHS=$(git rev-list --objects --all | awk '{print $2}' | sort -u)

# Match only Barotrauma and V Rising file types
MATCHED_PATHS=$(echo "$ALL_PATHS" | grep -E '\.ogg$|AutoSave_.*\.save\.gz$' || true)

# Handle empty case
if [[ -z "$MATCHED_PATHS" ]]; then
  echo "⚠️  No matching blobs found (.ogg or AutoSave_*.save.gz)"
  : > "$DELETABLE_LIST"
  exit 0
fi

# Save to file
echo "$MATCHED_PATHS" > "$DELETABLE_LIST"

# Report
COUNT=$(printf "%d" "$(echo "$MATCHED_PATHS" | wc -l)")
echo "📄 Wrote $(printf "%5d" "$COUNT") matching file paths to: $DELETABLE_LIST"
echo "📝 Sample entries:"
echo "$MATCHED_PATHS" | head -n 10
[[ "$COUNT" -gt 10 ]] && echo "     ... and $((COUNT - 10)) more"

echo "🟢 Script complete. Terminal will stay open."
