#!/usr/bin/env bash
set -euxo pipefail

# shellcheck source=scripts/services/shared/env-vars.sh
source "$(dirname "${BASH_SOURCE[0]}")/env-vars.sh"
# shellcheck source=scripts/services/$GAME_NAME/env-vars.sh
source "$(dirname "${BASH_SOURCE[0]}")/../$GAME_NAME/env-vars.sh"

# === Graceful shutdown ===
# RCON-capable games warn players and let the engine save before killing.
# Others get a direct signal.
if [[ -n "${RCON_PORT:-}" && -n "${RCON_PASSWORD:-}" ]]; then
  mcrcon -H 127.0.0.1 -P "$RCON_PORT" -p "$RCON_PASSWORD" \
    "shutdown ${SHUTDOWN_DELAY_MINUTES:-1} \"Server will shut down in ~{t}m! Get to a safe place.\"" \
    || echo "⚠️ mcrcon failed to send shutdown command"
  echo "⏳ Waiting ${SHUTDOWN_DELAY_MINUTES:-1} minutes for graceful shutdown..."
  sleep "$(( ${SHUTDOWN_DELAY_MINUTES:-1} * 60 + 30 ))"
elif pkill -0 "$PROCESS_NAME" 2>/dev/null; then
  pkill "$PROCESS_NAME"
else
  echo "$PROCESS_NAME not running, nothing to kill"
fi

# === Wait for process exit ===
echo "🔃 Monitoring $PROCESS_NAME status..."
if ! timeout 300 bash -c "while ps -C $PROCESS_NAME >/dev/null; do sleep 1; done"; then
  echo "⚠️ $PROCESS_NAME did not exit in time."
else
  echo "✅ $PROCESS_NAME exited cleanly."
fi

cd "$GAME_DIR"

# === Stage saves for commit ===
# If there are numbered save files (e.g. AutoSave_1.save), compress the latest
# and track only the .gz. Otherwise, git-add matching files directly.
if [[ -n "${SAVE_FILE_PREFIX:-}" && -d "${SAVE_FILE_PATH:-}" ]]; then
  latest_numbered=$(find "$SAVE_FILE_PATH" -maxdepth 1 -type f -name "${SAVE_FILE_PREFIX}[0-9]*.save" 2>/dev/null | head -1)

  if [[ -n "$latest_numbered" ]]; then
    # Numbered saves: compress the latest one, clean old .gz from git
    latest_file=$(find "$SAVE_FILE_PATH" -type f -name "$SAVE_FILE_PREFIX*.save" |
      sed -E "s/.*${SAVE_FILE_PREFIX}([0-9]+)\.save/\1 \0/" |
      sort -n | tail -n1 | cut -d' ' -f2)

    if [[ -n "$latest_file" ]]; then
      echo "🗜 Compressing latest save: $latest_file"
      gzip -kf "$latest_file"
      gzipped_file="${latest_file}.gz"

      for tracked in $(git ls-files "$SAVE_FILE_PATH/$SAVE_FILE_PREFIX*.save.gz"); do
        [[ "$tracked" != "$gzipped_file" ]] && git rm --cached "$tracked"
      done

      git add "$gzipped_file"
    else
      echo "⚠️ No uncompressed .save file found"
    fi
  else
    # Non-numbered saves: add matching files directly
    git add "$SAVE_FILE_PATH/$SAVE_FILE_PREFIX"*
  fi
fi

git commit -m "Auto-save before shutdown $(date -u +'%Y-%m-%d %H:%M:%S UTC')" || echo "Nothing to commit"

# === Git sync ===
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
