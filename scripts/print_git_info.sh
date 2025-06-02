#!/bin/bash
set -euo pipefail

echo "📦 GIT REPO DIAGNOSTICS REPORT"
echo "🕒 Timestamp: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
echo "📍 Working directory: $(pwd)"
echo "--------------------------------------------------"

# Ensure we're inside a git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "❌ Not a Git repository."
  exit 1
fi

# 1. Total .git directory size
echo "📦 .git directory size:"
du -sh .git

# 2. Top-level file/folder sizes in working tree
echo
echo "📁 Working tree top 10 largest folders/files:"
du -sh -- * .[^.]* 2>/dev/null | sort -hr | head -n 10

# 3. Shallow clone benchmark (optional signal)
echo
echo "⚡ Commit count (full history depth):"
git rev-list --count HEAD

# 4. Largest historical objects (blobs)
echo
echo "🔍 Top 10 largest objects in repo history:"
git rev-list --all --objects \
  | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' \
  | awk '$1 == "blob" {print $2, $3, $4}' \
  | sort -k2 -n -r \
  | head -n 10 \
  | awk '{printf "📄 %s — %s bytes — %s\n", $1, $2, $3}'

# 5. Largest packfile (if present)
echo
PACK_FILE=$(find .git/objects/pack/ -name '*.pack' | head -n 1 || true)
if [[ -n "$PACK_FILE" ]]; then
  echo "🧱 Largest packfile: $(basename "$PACK_FILE")"
  du -h "$PACK_FILE"
fi

echo
echo "✅ Git diagnostic report complete."
