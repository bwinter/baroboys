#!/usr/bin/env bash
set -euxo pipefail

# shellcheck source=scripts/services/Barotrauma/env-vars.sh
source "$(dirname "${BASH_SOURCE[0]}")/env-vars.sh"

# SETUP: OPTIONAL - Kill running game server.
if pkill -0 "$PROCESS_NAME" 2>/dev/null; then
    pkill "$PROCESS_NAME"
else
    echo "$PROCESS_NAME not running, nothing to kill"
fi

echo "🔃 Monitoring $PROCESS_NAME status..."

if ! timeout 300 bash -c "while ps -C $PROCESS_NAME >/dev/null; do sleep 1; done"; then
  echo "⚠️ $PROCESS_NAME did not exit in time."
else
  echo "✅ $PROCESS_NAME exited cleanly."
fi

cd "$GAME_DIR"

# SETUP: REQUIRED === Commit saves ===
git add "$SAVE_FILE_PATH/$SAVE_FILE_PREFIX"*
git commit -m "Auto-save before shutdown $(date -u +'%Y-%m-%d %H:%M:%S UTC')" || echo "Nothing to commit"

# Stash → pull --rebase → push → pop.
# The stash is intentional: the working tree can accumulate local taint (envsubst'd
# config files, steamcmd artifacts, etc.) that would cause `pull --rebase` to fail.
# Stashing clears that state before the rebase so the push lands cleanly, then pops
# it back. Do NOT simplify this to a bare `git fetch && git rebase` — the stash step
# is load-bearing.
git stash push --include-untracked --quiet || echo "Nothing to stash"
git pull --rebase
git push origin main
git stash pop --quiet || echo "No stash to pop"

sudo systemctl poweroff
