#!/bin/bash
set -euo pipefail

echo "🧹 Starting BFG history cleanup..."

# Config
REPO_SOURCE="${1:-$HOME/Desktop/Baroboys}"  # Default if not passed
TARGET_DIR="/tmp/bfg-cleanup"
CLONE_NAME="baroboys-bfg-clean.git"
CLEANED_REPO="$TARGET_DIR/$CLONE_NAME"
BFG_VERSION="1.14.0"
BFG_URL="https://repo1.maven.org/maven2/com/madgag/bfg/$BFG_VERSION/bfg-$BFG_VERSION.jar"
BFG_JAR="$TARGET_DIR/bfg-$BFG_VERSION.jar"
REPORT_FILE="bfg-report.log"
PATTERNS_TO_DELETE="*.save,*.ogg"

# Clean up old runs
if [[ -d "$TARGET_DIR" ]]; then
  echo "♻️  Cleaning previous workspace at $TARGET_DIR..."
  rm -rf "$TARGET_DIR"
fi
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

# Clone bare repo
echo "📥 Cloning bare mirror of repo..."
git clone --mirror "$REPO_SOURCE" "$CLONE_NAME"
cd "$CLONE_NAME"

# Download BFG
echo "⬇️ Downloading BFG v$BFG_VERSION..."
curl -sSL "$BFG_URL" -o "$BFG_JAR"

# Run BFG
echo "🔍 Simulating cleanup using temp clone..."
java -jar "$BFG_JAR" --delete-files "$PATTERNS_TO_DELETE"

# Preview report
if [[ -f "$REPORT_FILE" ]]; then
  echo "📝 Report summary:"
  grep -E '^file ' "$REPORT_FILE" | tee /dev/tty | wc -l | xargs echo "🔎 Files to be deleted:"
  echo
else
  echo "⚠️  No report found. Did BFG run correctly?"
  exit 1
fi

# Confirm cleanup
read -r -p "⚠️  Proceed with reflog expire + GC on cleaned repo? (yes/no): " CONFIRM
if [[ "$CONFIRM" == "yes" ]]; then
  echo "🧼 Expiring reflogs and running GC..."
  git reflog expire --expire=now --all
  git gc --prune=now --aggressive

  echo "✅ Cleanup complete. Cleaned mirror is here:"
  echo "$CLEANED_REPO"
else
  echo "❌ Aborting after preview. No destructive actions taken."
fi
