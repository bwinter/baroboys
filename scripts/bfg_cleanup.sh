#!/bin/bash
set -euxo pipefail

echo "🧹 Starting BFG history cleanup..."

# ---- Config ----
TARGET_REPO_PATH="${1:-baroboys-bfg-clean}"   # You can pass a path as $1
SOURCE_REPO_PATH="$(pwd)"                     # Current repo assumed to be source
BFG_JAR_URL="https://repo1.maven.org/maven2/com/madgag/bfg/1.14.0/bfg-1.14.0.jar"
BFG_JAR="bfg.jar"

# ---- Setup ----
mkdir -p /tmp/bfg-cleanup
cd /tmp/bfg-cleanup

echo "📥 Cloning bare mirror..."
git clone --mirror "$SOURCE_REPO_PATH" "$TARGET_REPO_PATH.git"
cd "$TARGET_REPO_PATH.git"

if [ ! -f "$BFG_JAR" ]; then
  echo "📥 Downloading BFG..."
  curl -L "$BFG_JAR_URL" -o "$BFG_JAR"
fi

# ---- Define patterns to delete ----
echo "🗂️ Writing .bfg-repo-cleanup-files.txt"
tee bfg-patterns.txt > /dev/null <<EOF
VRising/Data/Saves/
Barotrauma/WorkshopMods/Installed/
*.save
*.ogg
EOF

# ---- Run BFG ----
echo "🚀 Running BFG to delete matching files from history..."
java -jar "$BFG_JAR" --delete-files-from-history bfg-patterns.txt

# ---- Cleanup Git objects and rebuild history ----
echo "🧼 Expiring reflog and running aggressive GC..."
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo "✅ Cleanup complete. Repo is now in: /tmp/bfg-cleanup/$TARGET_REPO_PATH.git"
echo "📝 You can inspect and push this repo using:"
echo "    cd /tmp/bfg-cleanup/$TARGET_REPO_PATH.git"
echo "    git remote set-url origin <your-remote-url>"
echo "    git push --force"

