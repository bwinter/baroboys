#!/bin/bash
set -euo pipefail

# Usage: ./bfg_cleanup.sh [path/to/repo]
# Defaults to ~/Desktop/Baroboys if none provided.

echo "🧹 Starting BFG history cleanup..."

# ---- Config ----
REPO_SOURCE="${1:-$HOME/Desktop/Baroboys}"
TARGET_DIR="/tmp/bfg-cleanup"
CLONE_NAME="baroboys-bfg-clean.git"
CLEANED_REPO="$TARGET_DIR/$CLONE_NAME"
BFG_VERSION="1.14.0"
BFG_URL="https://repo1.maven.org/maven2/com/madgag/bfg/$BFG_VERSION/bfg-$BFG_VERSION.jar"
BFG_JAR="$TARGET_DIR/bfg-$BFG_VERSION.jar"
PATTERNS_TO_DELETE="*.save,*.ogg"
REPORT_FILE="bfg-report.log"

# ---- Convert to absolute path so `git clone --mirror` sees it ----
REPO_ABS="$(cd "$REPO_SOURCE" && pwd)"

# ---- Clean any existing workspace ----
if [[ -d "$TARGET_DIR" ]]; then
  echo "♻️  Cleaning previous workspace at $TARGET_DIR..."
  rm -rf "$TARGET_DIR"
fi
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

# ---- Clone bare mirror from the absolute path ----
echo "📥 Cloning bare mirror of repo ($REPO_ABS) ..."
git clone --mirror "$REPO_ABS" "$CLONE_NAME"
cd "$CLONE_NAME"

# ---- Download BFG if it isn’t already there ----
if [[ ! -f "$BFG_JAR" ]]; then
  echo "⬇️ Downloading BFG v$BFG_VERSION..."
  curl -sSL "$BFG_URL" -o "$BFG_JAR"
fi

# ---- Run BFG to delete all *.save and *.ogg blobs from history ----
echo "🚀 Running BFG cleanup (removing patterns: $PATTERNS_TO_DELETE)..."
java -jar "$BFG_JAR" --delete-files "$PATTERNS_TO_DELETE"

# ---- Print BFG report ----
if [[ -f "$REPORT_FILE" ]]; then
  MATCHED_COUNT=$(grep -c '^file ' "$REPORT_FILE" || true)
  echo
  echo "📝 Deleted blob entries: $MATCHED_COUNT"
  echo "🗒️ Top 10 deleted paths:"
  grep -E '^file ' "$REPORT_FILE" \
    | sort -k3 -n -r \
    | head -n 10 \
    | awk '{ printf "  %s\n", $3 }'
else
  echo
  echo "⚠️  No BFG report found. Something went wrong."
  exit 1
fi

# ---- Cleanup Git objects (expire reflogs + GC) ----
echo
echo "🧼 Expiring reflogs and performing aggressive GC..."
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo
echo "✅ History rewrite complete!"
echo "📁 Cleaned repo is at:"
echo "    $CLEANED_REPO"
echo
echo "📝 To inspect or push your cleaned repo, run:"
echo "    cd $CLEANED_REPO"
echo "    git remote set-url origin <your-remote-url>"
echo "    git push --force"
