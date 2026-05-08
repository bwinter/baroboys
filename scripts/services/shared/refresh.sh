#!/usr/bin/env bash
set -euxo pipefail

# shellcheck source=scripts/services/shared/env-vars.sh
source "$(dirname "${BASH_SOURCE[0]}")/env-vars.sh"

# Mark refresh start in log (dir already created by admin_server/refresh.sh as root)
touch "$LOG_FILE"
printf "\n==== %s ====\n" "$(date +%Y/%m/%d-%H:%M:%S)" >> "$LOG_FILE"

# shellcheck source=scripts/services/$GAME_NAME/env-vars.sh
# shellcheck disable=SC1091  # $GAME_NAME is runtime-resolved; shellcheck can't follow
source "$(dirname "${BASH_SOURCE[0]}")/../$GAME_NAME/env-vars.sh"

# Preconditions — fail fast before any side effects
: "${STEAM_APP_ID:?STEAM_APP_ID not set — check game env-vars.sh}"
: "${STEAM_PLATFORM:?STEAM_PLATFORM not set — check game env-vars.sh}"
: "${GAME_DIR:?GAME_DIR not set — check shared env-vars.sh}"
: "${CHECKOUT_LIST:?CHECKOUT_LIST not set — check game env-vars.sh}"

# Warm login before the real app_update. This works around intermittent SteamCMD failures
# that occur when the depot cache or config hasn't been initialised yet. Root cause is
# unknown; removing this call makes builds flaky. Do not simplify.
/usr/games/steamcmd \
  +login anonymous \
  +quit

/usr/games/steamcmd \
  +@sSteamCmdForcePlatformType "$STEAM_PLATFORM" \
  +force_install_dir "$GAME_DIR" \
  +login anonymous \
  +app_update "$STEAM_APP_ID" validate \
  +quit

# Restore canonical server configs
cd "$GAME_DIR"
# Intentional word splitting — CHECKOUT_LIST is space-separated paths.
# shellcheck disable=SC2086
git checkout -- $CHECKOUT_LIST

# shellcheck source=scripts/services/$GAME_NAME/post-checkout.sh
# shellcheck disable=SC1091  # $GAME_NAME is runtime-resolved; shellcheck can't follow
source "$(dirname "${BASH_SOURCE[0]}")/../$GAME_NAME/post-checkout.sh"

# === Decompress saves ===
# Decompress all .gz saves matching the prefix. Without -f, gunzip skips files
# that already exist — protecting uncommitted saves from being overwritten.
if [[ -d "${SAVE_FILE_PATH:-}" && -n "${SAVE_FILE_PREFIX:-}" ]]; then
  find "$SAVE_FILE_PATH" -maxdepth 1 -name "${SAVE_FILE_PREFIX}*.gz" -exec gunzip -k {} \; 2>/dev/null || true
fi

# Systemd unit installation is handled separately by install-game-units.sh
# (runs as root at Packer build time only — units are baked into the image).

# --- Write game manifest for cross-language consumers ---
# bash knows the game env-vars; admin_server.py needs them as JSON. The
# manifest at /etc/baroboys/manifest.json is the cross-language hand-off —
# same pattern as /etc/baroboys/active-game. Updated every game-refresh so
# a game switch (after image rebuild) propagates without admin_server
# needing a restart.
manifest_log_files=(game.log admin_server.log refresh_repo.log idle_check.log infrastructure.log)
[[ -n "${WINEARCH:-}" ]] && manifest_log_files+=(xvfb.log)
manifest_log_files_json="$(printf '"%s",' "${manifest_log_files[@]}" | sed 's/,$//')"
manifest_uses_wine=$([[ -n "${WINEARCH:-}" ]] && echo true || echo false)

cat > /tmp/baroboys-manifest.json <<EOF
{
  "game_name": "${GAME_NAME}",
  "process_name": "${PROCESS_NAME}",
  "uses_wine": ${manifest_uses_wine},
  "log_files": [${manifest_log_files_json}]
}
EOF
sudo install -m 644 /tmp/baroboys-manifest.json /etc/baroboys/manifest.json
rm -f /tmp/baroboys-manifest.json