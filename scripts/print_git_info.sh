#!/bin/bash
set -euo pipefail

# Usage: ./print_git_info.sh [path/to/repo]
# Defaults to current directory if none provided.

REPO_PATH="${1:-$PWD}"
echo "🔍 Analyzing Git repo at: $REPO_PATH"
echo

cd "$REPO_PATH"

# -------------------------
# 1. Top 10 Largest Blobs
# -------------------------
echo "📦 Largest blobs (top 10):"
git rev-list --objects --all \
  | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize)' \
  | awk '$1=="blob" { print $2, $3 }' \
  | sort -k2 -n -r \
  | head -n 10 \
  | while read -r SHA SIZE; do
      FILE=$(git rev-list --objects --all | grep "^$SHA " | cut -d' ' -f2- | head -n 1)
      printf "  %8s  %s\n" "$(numfmt --to=iec "$SIZE")" "$FILE"
    done \
  || echo "  (no blob objects found)"
echo

# --------------------------------------------
# 2. File Extensions by Total Blob Count
# --------------------------------------------
echo "📁 File types by blob count (top 10):"
git rev-list --objects --all \
  | git cat-file --batch-check='%(objecttype) %(objectname)' \
  | awk '$1=="blob" { print $2 }' \
  | while read -r SHA; do
      git rev-list --objects --all \
        | grep "^$SHA " | cut -d' ' -f2- \
        | awk -F. 'NF>1 { print tolower($NF) }'
    done \
  | sort | uniq -c | sort -k1 -n -r \
  | head -n 10 \
  | awk '{ printf "  %4d .%s\n", $1, $2 }' \
  || echo "  (no file extensions detected)"
echo

# -----------------------------------------------------
# 3. Historical .save and .ogg Matches (deduplicated)
# -----------------------------------------------------
echo "🎯 Looking for historical *.save and *.ogg entries:"
HITS=$(git rev-list --all \
  | xargs -n1 git ls-tree -r --name-only 2>/dev/null \
  | grep -E '\.save$|\.ogg$' || true)

if [[ -n "$HITS" ]]; then
  echo "$HITS" \
    | sort | uniq -c | sort -k1 -n -r \
    | awk '{ printf "  %4d %s\n", $1, $2 }' \
    | head -n 15
  TOTAL_MATCHES=$(echo "$HITS" | sort | uniq | wc -l)
  if [[ "$TOTAL_MATCHES" -gt 15 ]]; then
    echo "  ... and $((TOTAL_MATCHES - 15)) more paths"
  fi
else
  echo "  ❌ No matching .save or .ogg files found in history."
fi
echo

# -----------------
# 4. Repo Summary
# -----------------
REPO_SIZE=$(du -sh .git | cut -f1)
OBJ_COUNT=$(git count-objects -vH | grep '^count:' | awk '{print $2}')
echo "📊 Summary:"
echo "- Repo size on disk: $REPO_SIZE"
echo "- Total loose + packed objects: $OBJ_COUNT"
