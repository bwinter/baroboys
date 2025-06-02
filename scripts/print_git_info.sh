#!/bin/bash
set -euo pipefail

REPO_PATH="${1:-$PWD}"
cd "$REPO_PATH"

echo "🔍 Analyzing Git repo at: $REPO_PATH"
echo

# ---- Largest blobs ----
echo "📦 Largest blobs (top 10):"
BLOBS=$(git rev-list --objects --all | \
  git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize)' | \
  awk '$1 == "blob" { print $2, $3 }' | \
  sort -k2 -n -r)

JOINED=$(git rev-list --objects --all)
COUNT=0
echo "$BLOBS" | while read -r SHA SIZE; do
  FILE=$(echo "$JOINED" | grep "$SHA" | cut -d' ' -f2-)
  [[ -n "$FILE" ]] && echo "  $(numfmt --to=iec $SIZE)  $FILE"
  COUNT=$((COUNT+1))
  [[ $COUNT -ge 10 ]] && break
done
echo

# ---- File types by blob size ----
echo "📁 File types by blob size (top 10):"
git rev-list --objects --all | \
  git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize)' | \
  awk '$1 == "blob" { print $2, $3 }' | \
  join -j1 - <(git rev-list --objects --all | sort) | \
  awk -F. '{ if (NF>1) print $NF }' | \
  sort | uniq -c | sort -k1 -n -r | head -n 10 | \
  awk '{ printf "  %4d .%s\n", $1, $2 }' || echo "  (no extensions found)"
echo

# ---- Historical .save and .ogg files ----
echo "🎯 Looking for historical *.save and *.ogg entries:"
MATCHES=$(git rev-list --all | xargs git grep -I --name-only -e '.save' -e '.ogg' 2>/dev/null || true)

if [[ -n "$MATCHES" ]]; then
  SORTED=$(echo "$MATCHES" | sort | uniq -c | sort -k1 -n -r)
  TOP_MATCHES=$(echo "$SORTED" | head -n 15)
  TOTAL_MATCHES=$(echo "$SORTED" | wc -l)

  echo "$TOP_MATCHES" | awk '{ printf "  %4d %s\n", $1, $2 }'
  if [[ "$TOTAL_MATCHES" -gt 15 ]]; then
    echo "  ... and $((TOTAL_MATCHES - 15)) more."
  fi
else
  echo "  ❌ No matching .save or .ogg files found in history."
fi
echo

# ---- Summary ----
REPO_SIZE=$(du -sh .git | cut -f1)
OBJ_COUNT=$(git count-objects -vH | grep 'count:' | awk '{print $2}')
echo "📊 Summary:"
echo "- Repo size on disk: $REPO_SIZE"
echo "- Total objects: $OBJ_COUNT"
