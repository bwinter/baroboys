#!/bin/bash
set -euxo pipefail

echo "🧹 Starting BFG history cleanup..."

# ---- Config ----
REPO_SOURCE="${1:-$PWD}"                       # Path to repo (defaults to current)
TARGET_DIR="/tmp/bfg-cleanup"                  # Temp output dir
CLONE_NAME="baroboys-bfg-clean.git"
BFG_VERSION="1.15.0"
BFG_URL="https://repo1.maven.org/maven2/com/madgag/bfg/${BFG_VERSION}/bfg-${BFG_VERSION}.jar"
BFG_JAR="${TARGET_DIR}/bfg.jar"

# ---- Setup clean working area ----
rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

# ---- Clone mirror ----
echo "📦 Cloning bare mirror of repo..."
git clone --mirror "$REPO_SOURCE" "$CLONE_NAME"
cd "$CLONE_NAME"

# ---- Download BFG (latest) ----
if [ ! -f "$BFG_JAR" ]; then
  echo "⬇️ Downloading BFG v${BFG_VERSION}..."
  curl -L "$BFG_URL" -o "$BFG_JAR"
fi

# ---- Run dry run ----
echo "🧪 Running BFG dry run to preview deletions..."
java -jar "$BFG_JAR" \
  --delete-files '*.save' \
  --delete-files '*.ogg' \
  --dry-run > ../bfg-preview.log

echo "📊 Summary of deletions:"
grep '^file ' ../bfg-preview.log | sort -k3 -n -r | head -n 10 || echo "No files matched."

TOTAL=$(grep -c '^file ' ../bfg-preview.log || true)
echo "🗃️ Total blobs matching patterns: $TOTAL"

if [[ "$TOTAL" -eq 0 ]]; then
  echo "✅ Nothing to clean. Exiting."
  exit 0
fi

# ---- Ask for confirmation ----
echo
read -p "❓ Proceed with permanent deletion and rewrite? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
  echo "❌ Aborted by user."
  exit 1
fi

# ---- Real cleanup ----
echo "🚀 Running BFG for real..."
java -jar "$BFG_JAR" \
  --delete-files '*.save' \
  --delete-files '*.ogg'

# ---- Garbage collection ----
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo
echo "✅ Rewrite complete!"
echo "📁 Clean repo: $TARGET_DIR/$CLONE_NAME"
echo "🔁 You can inspect, then:"
echo "    cd $TARGET_DIR/$CLONE_NAME"
echo "    git remote set-url origin <your-remote-url>"
echo "    git push --force"
