#!/bin/bash
set -euo pipefail

# Usage: ./print_git_info.sh [path/to/repo]
# Defaults to current directory if none provided.

REPO_PATH="${1:-$PWD}"
cd "$REPO_PATH"

echo "🔍 Analyzing Git repo at: $REPO_PATH"
echo

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
# 3. Historical *.save and *.ogg Matches (deduplicated)
# -----------------------------------------------------
echo "🎯 Looking for historical *.save and *.ogg entries:"
HIST_MATCHES=$(git rev-list --all \
  | xargs -n1 git ls-tree -r --name-only 2>/dev/null \
  | grep -E '\.save$|\.ogg$' | sort -u || true)

if [[ -n "$HIST_MATCHES" ]]; then
  echo "$HIST_MATCHES" \
    | xargs -n1 basename \
    | sort | uniq -c | sort -k1 -n -r \
    | head -n 15 \
    | awk '{ printf "  %4d %s\n", $1, $2 }'
  TOTAL=$(echo "$HIST_MATCHES" | wc -l)
  if [[ "$TOTAL" -gt 15 ]]; then
    echo "  ... and $((TOTAL - 15)) more paths"
  fi
else
  echo "  ❌ No matching .save or .ogg files found in history."
fi
echo

# --------------------------------------------------------
# 4. Files in history matching *.ogg or *.save, but not HEAD
# --------------------------------------------------------
echo "🧨 Matching files not in HEAD (safe to delete):"
HEAD_MATCHES=$(git ls-tree -r HEAD --name-only | grep -E '\.save$|\.ogg$' | sort -u || true)

comm -23 \
  <(printf "%s\n" $HIST_MATCHES) \
  <(printf "%s\n" $HEAD_MATCHES) > /tmp/deletable-blobs.txt

if [[ -s /tmp/deletable-blobs.txt ]]; then
  head -n 15 /tmp/deletable-blobs.txt | awk '{ print "  " $0 }'
  COUNT=$(wc -l < /tmp/deletable-blobs.txt)
  if [[ "$COUNT" -gt 15 ]]; then
    echo "  ... and $((COUNT - 15)) more paths"
  fi
else
  echo "  ✅ No deletable matching files found (HEAD still contains them all)"
fi
echo "💾 Saved list to /tmp/deletable-blobs.txt"
echo

# -----------------
# 5. Repo Summary
# -----------------
REPO_SIZE=$(du -sh .git | cut -f1)
OBJ_COUNT=$(git count-objects -vH | grep '^count:' | awk '{print $2}')
echo "📊 Summary:"
echo "- Repo size on disk: $REPO_SIZE"
echo "- Total loose + packed objects: $OBJ_COUNT"
