#!/usr/bin/env bash
set -euo pipefail

# Ensure required commands exist
command -v git >/dev/null || { echo "❌ 'git' not found"; exit 1; }

REPO_PATH="${1:-.}"
DELETABLE_LIST="/tmp/deletable-blobs.txt"

echo "🔍 Running Git history scan for Barotrauma and V Rising blob types..."
echo "📁 Target repo: $REPO_PATH"

cd "$REPO_PATH"

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
COUNT=$(echo "$MATCHED_PATHS" | wc -l)
echo "📄 Wrote $(printf "%5d" "$COUNT") matching file paths to: $DELETABLE_LIST"
echo "📝 Sample entries:"
echo "$MATCHED_PATHS" | head -n 10
[[ "$COUNT" -gt 10 ]] && echo "     ... and $((COUNT - 10)) more"
