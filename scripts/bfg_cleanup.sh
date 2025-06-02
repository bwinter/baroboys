#!/bin/bash
set -euo pipefail

# Usage: ./bfg_cleanup.sh [path/to/repo]
REPO_PATH="${1:-$HOME/Desktop/Baroboys}"
WORKDIR="/tmp/bfg-cleanup"
ORIG_LIST="/tmp/deletable-blobs.txt"
BFG_VERSION="1.14.0"
BFG_URL="https://repo1.maven.org/maven2/com/madgag/bfg/$BFG_VERSION/bfg-$BFG_VERSION.jar"
BFG_JAR="$WORKDIR/bfg-$BFG_VERSION.jar"

echo "🧹 Starting resilient BFG history cleanup..."

# 1. Validate blob list
if [[ ! -f "$ORIG_LIST" ]] || [[ ! -s "$ORIG_LIST" ]]; then
  echo "❌ Error: $ORIG_LIST missing or empty."
  echo "🧠 Run ./scripts/print_git_info.sh $REPO_PATH first."
  exit 1
fi

# 2. Prepare workspace
echo "♻️  Cleaning workspace at $WORKDIR ..."
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"

# 3. Clone mirror
echo "📥 Cloning bare mirror of '$REPO_PATH' → $WORKDIR/baroboys-bfg-clean.git"
git clone --mirror "$REPO_PATH" "$WORKDIR/baroboys-bfg-clean.git" &> /dev/null

# 4. Download BFG if needed
if [[ ! -f "$BFG_JAR" ]]; then
  echo "⬇️ Downloading BFG v$BFG_VERSION..."
  curl -sSL "$BFG_URL" -o "$BFG_JAR"
fi

# 5. Build unique filename list
echo "🔎 Reducing $ORIG_LIST → filenames only…"
FILENAMES=($(cat "$ORIG_LIST" | xargs -n1 basename | sort -u))

echo "📂 Found ${#FILENAMES[@]} unique filenames to attempt deletion:"
printf "     • %s\n" "${FILENAMES[@]:0:10}"
if [[ ${#FILENAMES[@]} -gt 10 ]]; then echo "     ... and $((${#FILENAMES[@]} - 10)) more"; fi

# 6. Per-file loop
echo -e "\n🌀 Starting per-file BFG cleanup loop..."

cd "$WORKDIR/baroboys-bfg-clean.git"
SUCCESS_COUNT=0
FAILURE_COUNT=0

for FILENAME in "${FILENAMES[@]}"; do
  echo "🔸 Attempting BFG cleanup for: $FILENAME"

  # Run BFG on this one file
  java -jar "$BFG_JAR" --delete-files "$FILENAME" &> "$WORKDIR/bfg-tmp.log" || true

  # Post-clean HEAD presence check
  STILL_PRESENT=$(git log -p --all -- "$FILENAME" | grep -q "$FILENAME" && echo "yes" || echo "no")

  if [[ "$STILL_PRESENT" == "no" ]]; then
    echo "   ✅ Removed from history: $FILENAME"
    ((SUCCESS_COUNT++))
  else
    echo "   ⚠️  Still present in HEAD/history: $FILENAME"
    ((FAILURE_COUNT++))
  fi
done

# 7. Reflog + GC
echo -e "\n🧼 Expiring reflogs and performing aggressive GC in the mirror…"
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# 8. Summary
echo -e "\n✅ History cleanup complete!"
echo "   ✔️ Successes: $SUCCESS_COUNT"
echo "   ❌ Failures:  $FAILURE_COUNT"
echo
echo "📁 Cleaned bare repo: $WORKDIR/baroboys-bfg-clean.git"
echo "🔍 To inspect the cleaned repo, run:"
echo "    ./scripts/print_git_info.sh $WORKDIR/baroboys-bfg-clean.git"
echo
echo "🚩 To overwrite your origin, run:"
echo "    cd $WORKDIR/baroboys-bfg-clean.git"
echo "    git remote set-url origin <your-remote-url>"
echo "    git push --force"
