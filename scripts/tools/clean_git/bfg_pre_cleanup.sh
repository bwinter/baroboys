#!/usr/bin/env bash
set -euxo pipefail

########################################
# BFG Pre-Cleanup Script
# 1️⃣ Ensures clean, fresh bare mirror
# 2️⃣ Scans Git history for unwanted blobs
# 3️⃣ Saves deletable list for BFG step
########################################

### CONFIG ###
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
REPO_PATH="$(cd "$SCRIPT_DIR/../../.." && pwd)"
REPO_NAME="$(basename "$REPO_PATH")"
WORKDIR="/tmp/bfg-cleanup"
MIRROR_REPO="$WORKDIR/${REPO_NAME}-bfg-clean.git"
DELETABLE_LIST="/tmp/deletable-blobs.txt"

### Helpers ###
step() {
  printf "\n🔹 %s\n" "$1"
}

### Checks ###
command -v git >/dev/null || { echo "❌ 'git' not found in PATH."; exit 1; }

step "🗂️ Starting BFG pre-cleanup scan..."
echo "📁 Working repo: $REPO_PATH"
echo "📁 Bare mirror:  $MIRROR_REPO"

### 1️⃣ Create fresh bare mirror ###
step "1️⃣ Creating fresh bare mirror"
rm -rf "$MIRROR_REPO"
git clone --bare "$REPO_PATH" "$MIRROR_REPO"

### 2️⃣ Scan Git history ###
step "2️⃣ Scanning Git history for matching blobs"
cd "$MIRROR_REPO"

ALL_PATHS=$(git rev-list --objects --all | awk '{print $2}' | sort -u)
MATCHED_PATHS=$(echo "$ALL_PATHS" | grep -E '\.ogg$|AutoSave_.*\.save\.gz$|\.dll$|\.xml$|\.config$|\.ini$|\.cfg$|\.json$|\.version$' || true)

if [[ -z "$MATCHED_PATHS" ]]; then
  echo "✅ Repo appears clean — no blobs to purge."
  : > "$DELETABLE_LIST"
  exit 0
fi

echo "$MATCHED_PATHS" > "$DELETABLE_LIST"

### 3️⃣ Report ###
COUNT=$(echo "$MATCHED_PATHS" | wc -l | tr -d ' ')
echo "📄 Found $COUNT matching file paths."
echo "📝 Sample:"
echo "$MATCHED_PATHS" | head -n 10
[[ "$COUNT" -gt 10 ]] && echo "     ... and $((COUNT - 10)) more"

echo "✅ Deletable list written to: $DELETABLE_LIST"
echo "🟢 Pre-cleanup complete. Run bfg_cleanup.sh next."
