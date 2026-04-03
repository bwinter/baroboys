#!/usr/bin/env bash
set -euxo pipefail

# shellcheck source=scripts/services/Barotrauma/env-vars.sh
source "$(dirname "${BASH_SOURCE[0]}")/env-vars.sh"

cd "$BAROBOYS"

# SETUP: OPTIONAL - Kill running gserver.
if pkill -0 DedicatedServer 2>/dev/null; then
    pkill DedicatedServer
else
    echo "DedicatedServer not running, nothing to kill"
fi

echo "🔃 Monitoring DedicatedServer status..."

if ! timeout 300 bash -c 'while ps -C DedicatedServer >/dev/null; do sleep 1; done'; then
  echo "⚠️ DedicatedServer did not exit in time."
else
  echo "✅ DedicatedServer exited cleanly."
fi

# SETUP: REQUIRED === Commit saves ===
find "$SAVE_FILE_PATH" -type f \( -name '*.save' -o -name '*_CharacterData.xml' \) ! -name '*.bk*' -print0 \
  | xargs -0 git add
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
