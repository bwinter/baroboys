#!/usr/bin/env bash
set -euxo pipefail

# shellcheck source=scripts/services/shared/env-vars.sh
source "$(dirname "${BASH_SOURCE[0]}")/env-vars.sh"
# shellcheck source=scripts/services/$GAME_NAME/env-vars.sh
# shellcheck disable=SC1091  # $GAME_NAME is runtime-resolved; shellcheck can't follow
source "$(dirname "${BASH_SOURCE[0]}")/../$GAME_NAME/env-vars.sh"

# process_name comes from the manifest (written by shared/refresh.sh from the
# per-game tfvars.json). Manifest is guaranteed present before shutdown runs:
# game-refresh writes it on every boot, before game-startup, before any
# poweroff path that would invoke this script.
PROCESS_NAME=$(jq -r .process_name /etc/baroboys/manifest.json)

# Preconditions — fail fast before any side effects
: "${PROCESS_NAME:?process_name missing from /etc/baroboys/manifest.json}"
: "${GAME_DIR:?GAME_DIR not set — check shared env-vars.sh}"

# `ps -C`/`pkill` match the kernel's 15-character comm name, which truncates
# Valheim's `valheim_server.x86_64`. Match the full command line instead, but
# escape the configured name so punctuation is treated literally as a string.
PROCESS_PATTERN=$(printf '%s' "$PROCESS_NAME" | sed 's/[][\\.^$*+?(){}|]/\\&/g')

process_pids() {
  pgrep -f -- "$PROCESS_PATTERN" 2>/dev/null || true
}

# === Graceful shutdown ===
# RCON-capable games warn players and let the engine save before killing.
# Others get a direct signal.
if [[ -n "${RCON_PORT:-}" && -n "${RCON_PASSWORD:-}" ]]; then
  mcrcon -H 127.0.0.1 -P "$RCON_PORT" -p "$RCON_PASSWORD" \
    "shutdown ${SHUTDOWN_DELAY_MINUTES:-1} \"Server will shut down in ~{t}m! Get to a safe place.\"" \
    || echo "⚠️ mcrcon failed to send shutdown command"
  echo "⏳ Waiting ${SHUTDOWN_DELAY_MINUTES:-1} minutes for graceful shutdown..."
  sleep "$(( ${SHUTDOWN_DELAY_MINUTES:-1} * 60 + 30 ))"
else
  mapfile -t pids < <(process_pids)
  if ((${#pids[@]})); then
    kill "${pids[@]}"
  else
    echo "$PROCESS_NAME not running, nothing to kill"
  fi
fi

# === Wait for process exit ===
echo "🔃 Monitoring $PROCESS_NAME status..."
# The child shell intentionally expands PROCESS_PATTERN from its environment.
# shellcheck disable=SC2016
if ! PROCESS_PATTERN="$PROCESS_PATTERN" timeout 300 bash -c \
  'while pgrep -f -- "$PROCESS_PATTERN" >/dev/null 2>&1; do sleep 1; done'; then
  echo "⚠️ $PROCESS_NAME did not exit in time."
else
  echo "✅ $PROCESS_NAME exited cleanly."
fi

# Create a durable bucket snapshot after the game has stopped. systemd keeps
# periodic and shutdown invocations of the same oneshot service serialized.
if systemctl cat save-backup.service >/dev/null 2>&1; then
  echo "☁️ Waiting for save-backup.service..."
  sudo systemctl start --wait save-backup.service \
    || echo "⚠️ Save-backup service failed; continuing shutdown"
else
  echo "ℹ️ save-backup.service is not installed; skipping bucket snapshot"
fi

cd "$GAME_DIR"

# === Stage saves for commit ===
# Compress all save files matching the pattern, git-add the .gz versions.
# Same path for all games — no branching on save format.
if [[ -n "${SAVE_FILE_PATTERN:-}" && -d "${SAVE_FILE_PATH:-}" ]]; then
  # Compress all matching non-gz files
  find "$SAVE_FILE_PATH" -maxdepth 1 -name "$SAVE_FILE_PATTERN" -type f ! -name "*.gz" -exec gzip -kf {} \;

  # Remove old .gz from git tracking, then add current ones
  while IFS= read -r -d '' tracked; do
    git rm --cached -- "$tracked" 2>/dev/null || true
  done < <(git ls-files -z -- "$SAVE_FILE_PATH/${SAVE_FILE_PATTERN}.gz")

  while IFS= read -r -d '' compressed; do
    git add -- "$compressed"
  done < <(find "$SAVE_FILE_PATH" -maxdepth 1 -name "${SAVE_FILE_PATTERN}.gz" -type f -print0)
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
