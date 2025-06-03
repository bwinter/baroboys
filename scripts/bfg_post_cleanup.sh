#!/usr/bin/env bash
set -euo pipefail

CLEANUP_DIR="/tmp/bfg-cleanup"
REPO_PATH="$CLEANUP_DIR/baroboys-bfg-clean.git"

if [[ -z "$CLEANUP_DIR" || ! -d "$REPO_PATH" ]]; then
  echo "❌ Error: Provide valid cleanup dir. Expected path: $REPO_PATH"
  exit 1
fi

echo "🧼 BFG post-cleanup checklist for: $REPO_PATH"

step() {
  echo -e "\n🔹 $1"
  read -rp "   ⏸️  Press [enter] to continue..."
}

# 1. View BFG logs
step "Inspect BFG logs (optional)"
echo "   Example:"
echo "     tail -n 20 $CLEANUP_DIR/logs/*.log"
echo "     open $REPO_PATH.bfg-report/"

# 2. Expire reflogs and run aggressive GC
step "Expire reflogs and garbage-collect unreachable blobs"
echo "   Example:"
echo "     git --git-dir=\"$REPO_PATH\" reflog expire --expire=now --all"
echo "     git --git-dir=\"$REPO_PATH\" gc --prune=now --aggressive"

# 5. Set remote origin (if not already configured)
step "Set the cleaned repo's remote URL"
echo "   Example:"
echo "     git --git-dir=\"$REPO_PATH\" remote set-url origin git@github.com:bwinter/baroboys.git"

# 6. Force push cleaned history
step "Push cleaned repository history (⚠️ this will overwrite remote history)"
echo "   Example:"
echo "     cd \"$REPO_PATH\""
echo "     git push --force"

echo -e "\n✅ Checklist complete. Proceed with caution and verify everything before pushing."

