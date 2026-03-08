#!/usr/bin/env bash
set -euxo pipefail

########################################
# BFG Cleanup Script
# 1️⃣ Validates local repo and deletable list
# 2️⃣ Confirms mirror freshness
# 3️⃣ Runs BFG history rewrite
########################################

### CONFIG ###
REPO_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
WORKDIR="/tmp/bfg-cleanup"
MIRROR_REPO="$WORKDIR/baroboys-bfg-clean.git"
ORIG_LIST="/tmp/deletable-blobs.txt"
LOGDIR="$WORKDIR/logs"
BFG_VERSION="1.14.0"
BFG_JAR="$WORKDIR/bfg-${BFG_VERSION}.jar"
BFG_URL="https://repo1.maven.org/maven2/com/madgag/bfg/${BFG_VERSION}/bfg-${BFG_VERSION}.jar"

### Helpers ###
step() {
  printf "\n🔹 %s\n" "$1"
}

### 1️⃣ Validate working tree ###
step "1️⃣ Validating working tree"
cd "$REPO_PATH"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "❌ Working tree is dirty! Please commit or stash changes before cleanup."
  exit 1
fi

LOCAL_HASH=$(git rev-parse main)
REMOTE_HASH=$(git rev-parse origin/main)

if [[ "$LOCAL_HASH" != "$REMOTE_HASH" ]]; then
  echo "⚠️ Local main is not in sync with origin/main."
  echo "   Consider 'git pull' before running BFG."
  read -rp "Continue anyway? [y/N]: " answer
  [[ "$answer" =~ ^[Yy]$ ]] || exit 1
fi

### 2️⃣ Validate deletable list ###
step "2️⃣ Validating deletable list"
if [[ ! -f "$ORIG_LIST" || ! -s "$ORIG_LIST" ]]; then
  echo "❌ Deletable list $ORIG_LIST missing or empty."
  exit 1
fi

MODIFIED=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$ORIG_LIST")
  echo "ℹ️  Using deletable list last modified: $MODIFIED"

### 3️⃣ Verify mirror freshness ###
step "3️⃣ Checking bare mirror freshness"
if [[ ! -d "$MIRROR_REPO" ]]; then
  echo "❌ Bare mirror missing. Run bfg_pre_cleanup.sh first."
  exit 1
fi

LATEST_HASH=$(git rev-parse main)
MIRROR_HASH=$(git -C "$MIRROR_REPO" rev-parse main)

if [[ "$LATEST_HASH" != "$MIRROR_HASH" ]]; then
  echo "⚠️  Local repo has new commits since mirror was cloned!"
  echo "   Run bfg_pre_cleanup.sh to refresh the mirror."
  exit 1
fi

### 4️⃣ Download BFG if needed ###
step "4️⃣ Preparing BFG JAR"
mkdir -p "$WORKDIR" "$LOGDIR"
if [[ ! -f "$BFG_JAR" ]]; then
  echo "⬇️ Downloading BFG v$BFG_VERSION..."
  curl -sSL "$BFG_URL" -o "$BFG_JAR"
fi

### 5️⃣ Build file list and run BFG ###
step "5️⃣ Running BFG cleanup loop"
mapfile -t FILENAMES < <(xargs -n1 basename < "$ORIG_LIST" | sort -u)
TOTAL=${#FILENAMES[@]}
echo "📂 Found $TOTAL unique basenames to delete."

printf "     • %s\n" "${FILENAMES[@]:0:10}"
[[ $TOTAL -gt 10 ]] && echo "     ... and $((TOTAL - 10)) more"

cd "$MIRROR_REPO"

CURRENT=0
for FILENAME in "${FILENAMES[@]}"; do
  ((CURRENT+=1))
  SAFE_NAME="${FILENAME//[^a-zA-Z0-9]/_}"
  LOG_PATH="$LOGDIR/${SAFE_NAME}.log"

  if [[ -f "$LOG_PATH" ]]; then
    echo "[$CURRENT/$TOTAL] ⏭️  Skipping (already processed): $FILENAME"
    continue
  fi

  echo "[$CURRENT/$TOTAL] 🔸 Deleting: $FILENAME"
  java -jar "$BFG_JAR" --delete-files "$FILENAME" > "$LOG_PATH" 2>&1 || true
done

step "6️⃣ Final aggressive GC"
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo "✅ BFG cleanup complete!"
echo "📁 Cleaned mirror: $MIRROR_REPO"
echo "🔍 Next: Run bfg_post_cleanup.sh"
