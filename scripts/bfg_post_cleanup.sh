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

# 6. Force push cleaned history
step "Push cleaned repository history (⚠️ this will overwrite remote history)"
echo "   Example:"
echo "     cd \"$REPO_PATH\""
echo "     git push --force"

echo -e "\n✅ Checklist complete. Proceed with caution and verify everything before pushing."

