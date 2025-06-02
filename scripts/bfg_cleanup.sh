#!/usr/bin/env bash
set -euo pipefail

REPO_PATH="${1:-$HOME/Desktop/Baroboys}"
WORKDIR="/tmp/bfg-cleanup"
ORIG_LIST="/tmp/deletable-blobs.txt"
BFG_VERSION="1.14.0"
BFG_JAR="${WORKDIR}/bfg-${BFG_VERSION}.jar"
BFG_URL="https://repo1.maven.org/maven2/com/madgag/bfg/${BFG_VERSION}/bfg-${BFG_VERSION}.jar"
LOGDIR="${WORKDIR}/logs"

mkdir -p "$LOGDIR"

echo "🧹 Starting BFG cleanup in $WORKDIR..."

# Validate deletable list
if [[ ! -f "$ORIG_LIST" || ! -s "$ORIG_LIST" ]]; then
  echo "❌ Error: $ORIG_LIST missing or empty."
  exit 1
fi

# Clone or reuse repo mirror
if [[ -d "$WORKDIR/baroboys-bfg-clean.git" ]]; then
  echo "♻️  Reusing existing mirror at $WORKDIR/baroboys-bfg-clean.git"
else
  echo "📥 Cloning bare mirror → $WORKDIR/baroboys-bfg-clean.git"
  git clone --mirror "$REPO_PATH" "$WORKDIR/baroboys-bfg-clean.git" &> /dev/null
fi

# Download BFG if needed
if [[ ! -f "$BFG_JAR" ]]; then
  echo "⬇️ Downloading BFG v$BFG_VERSION..."
  curl -sSL "$BFG_URL" -o "$BFG_JAR"
fi

# Build unique filename list
echo "🔎 Building basename list from $ORIG_LIST..."
mapfile -t FILENAMES < <(xargs -n1 basename < "$ORIG_LIST" | sort -u)

TOTAL=${#FILENAMES[@]}
echo "📂 Found $TOTAL unique basenames to delete:"
printf "     • %s\n" "${FILENAMES[@]:0:10}"
[[ $TOTAL -gt 10 ]] && echo "     ... and $((TOTAL - 10)) more"

cd "$WORKDIR/baroboys-bfg-clean.git"

SUCCESS=0
FAIL=0
CURRENT=0

echo -e "\n🌀 Starting BFG cleanup loop..."
for FILENAME in "${FILENAMES[@]}"; do
  ((CURRENT++))
  SAFE_NAME="${FILENAME//[^a-zA-Z0-9]/_}"
  LOG_PATH="$LOGDIR/${SAFE_NAME}.log"

  if [[ -f "$LOG_PATH" ]]; then
    echo "[$CURRENT/$TOTAL] ⏭️  Skipping (already processed): $FILENAME"
    continue
  fi

  echo "[$CURRENT/$TOTAL] 🔸 Attempting: $FILENAME"
  java -jar "$BFG_JAR" --delete-files "$FILENAME" > "$LOG_PATH" 2>&1 || true

  if git rev-list --all | xargs -n1 -I{} git ls-tree -r --name-only {} | grep -Fxq "$FILENAME"; then
    echo "   ⚠️  Still present: $FILENAME"
    ((FAIL++)) || true
  else
    echo "   ✅ Removed: $FILENAME"
    ((SUCCESS++)) || true
  fi
done

echo -e "\n🧼 Final GC..."
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo -e "\n✅ Cleanup finished!"
echo "   ✔️ Success: $SUCCESS"
echo "   ❌ Failed:  $FAIL"
echo "📁 Repo at: $WORKDIR/baroboys-bfg-clean.git"
echo "🔍 Inspect:  ./scripts/print_git_info.sh $WORKDIR/baroboys-bfg-clean.git"

exit 0
