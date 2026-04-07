#!/usr/bin/env bash
set -euxo pipefail

# shellcheck source=scripts/services/VRising/env-vars.sh
source "$(dirname "${BASH_SOURCE[0]}")/env-vars.sh"

# SETUP: OPTIONAL - Tell players and trigger autosave
if ! mcrcon -H 127.0.0.1 -P "$RCON_PORT" -p "$RCON_PASSWORD" \
  "shutdown ${SHUTDOWN_DELAY_MINUTES} \"Server will shut down in ~{t}m! Get to a safe place.\""; then
  echo "⚠️ mcrcon failed to send shutdown command"
fi

echo "⏳ Waiting ${SHUTDOWN_DELAY_MINUTES} minutes for V Rising to shut down and save..."
sleep "$((SHUTDOWN_DELAY_MINUTES * 60 + 30))"

echo "🔃 Monitoring VRisingServer.exe status..."

if ! timeout 300 bash -c 'while ps -C VRisingServer.exe >/dev/null; do sleep 1; done'; then
  echo "⚠️ VRisingServer.exe did not exit in time."
else
  echo "✅ VRisingServer.exe exited cleanly."
fi

cd "$GAME_DIR"

# SETUP: OPTIONAL === Compress latest autosave ===
latest_file=$(find "$SAVE_FILE_PATH" -type f -name "$SAVE_FILE_PREFIX*.save" |
  sed -E "s/.*$SAVE_FILE_PREFIX([0-9]+)\.save/\1 \0/" |
  sort -n | tail -n1 | cut -d' ' -f2)

if [[ -z "$latest_file" ]]; then
  echo "❌ No uncompressed .save file found"
  exit 1
fi

echo "🗜 Compressing latest autosave: $latest_file"
gzip -kf "$latest_file"
gzipped_file="${latest_file}.gz"

# === Clean up Git tracking for older autosaves ===
for tracked in $(git ls-files "$SAVE_FILE_PATH/$SAVE_FILE_PREFIX*.save.gz"); do
  [[ "$tracked" != "$gzipped_file" ]] && git rm --cached "$tracked"
done

# SETUP: REQUIRED === Commit latest autosave ===
git add "$gzipped_file"
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
